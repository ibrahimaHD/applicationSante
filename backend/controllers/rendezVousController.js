const db = require('../config/database');

// ── PATIENT : Voir ses RDV ──────────────────────────────
const getMesRendezVous = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.*, 
              u.nom AS medecin_nom, u.prenom AS medecin_prenom,
              m.specialite
       FROM rendez_vous r
       JOIN utilisateurs u ON r.medecin_id = u.id
       LEFT JOIN medecins m ON u.id = m.utilisateur_id
       WHERE r.patient_id = ?
       ORDER BY r.date_rdv DESC, r.heure_rdv DESC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, rendez_vous: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── PATIENT : Liste des médecins disponibles ────────────
const getMedecinsDisponibles = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.nom, u.prenom, m.specialite, m.hopital_clinique
       FROM utilisateurs u
       JOIN medecins m ON u.id = m.utilisateur_id
       WHERE u.est_actif = TRUE
       ORDER BY u.nom ASC`
    );
    res.json({ succes: true, medecins: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── PATIENT : Demander un RDV ───────────────────────────

const demanderRendezVous = async (req, res) => {
  try {
    const { medecin_id, date_rdv, heure_rdv, motif } = req.body;

    console.log('=== DEMANDE RDV ===');
    console.log('Body:', req.body);

    if (!medecin_id || !date_rdv || !heure_rdv || !motif) {
      return res.status(400).json({
        succes: false,
        message: 'Tous les champs sont requis.'
      });
    }

    // Vérifier que le médecin existe
    const [medecin] = await db.query(
      `SELECT u.id, u.nom, u.prenom FROM utilisateurs u
       WHERE u.id = ? AND u.est_actif = TRUE`,
      [medecin_id]
    );

    if (medecin.length === 0) {
      return res.status(404).json({
        succes: false,
        message: 'Médecin introuvable.'
      });
    }

    // ✅ Vérifier uniquement si ce PATIENT a déjà un RDV actif
    // avec CE médecin (pas terminé, pas annulé)
    const [dejaRdv] = await db.query(
      `SELECT id, statut FROM rendez_vous 
       WHERE patient_id = ? 
       AND medecin_id = ? 
       AND statut IN ('en_attente', 'confirme')`,
      [req.utilisateur.id, medecin_id]
    );

    if (dejaRdv.length > 0) {
      return res.status(409).json({
        succes: false,
        message: `Vous avez déjà un rendez-vous en cours avec ce médecin (statut: ${dejaRdv[0].statut}). Attendez qu'il soit terminé ou annulé.`
      });
    }

    // ✅ Vérifier que le créneau n'est pas déjà pris par quelqu'un d'autre
    const [creneauPris] = await db.query(
      `SELECT id FROM rendez_vous 
       WHERE medecin_id = ? 
       AND date_rdv = ? 
       AND heure_rdv = ? 
       AND statut IN ('en_attente', 'confirme')`,
      [medecin_id, date_rdv, heure_rdv]
    );

    if (creneauPris.length > 0) {
      return res.status(409).json({
        succes: false,
        message: 'Ce créneau est déjà pris par un autre patient. Choisissez un autre horaire.'
      });
    }

    // Créer le RDV
    const [result] = await db.query(
      `INSERT INTO rendez_vous (patient_id, medecin_id, date_rdv, heure_rdv, motif)
       VALUES (?, ?, ?, ?, ?)`,
      [req.utilisateur.id, medecin_id, date_rdv, heure_rdv, motif]
    );

    console.log('RDV créé:', result.insertId);

    // Rappel patient
    await db.query(
      `INSERT INTO rappels (patient_id, titre, description, type, date_rappel, heure_rappel)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        req.utilisateur.id,
        'Rendez-vous médical',
        `Consultation - ${motif}`,
        'rdv',
        date_rdv,
        heure_rdv
      ]
    );

    // Notification médecin
    await db.query(
      `INSERT INTO notifications (utilisateur_id, titre, message, type, data_json)
       VALUES (?, ?, ?, ?, ?)`,
      [
        medecin_id,
        'Nouvelle demande de RDV',
        `${req.utilisateur.prenom} ${req.utilisateur.nom} demande un rendez-vous le ${date_rdv} à ${heure_rdv}. Motif : ${motif}`,
        'rdv',
        JSON.stringify({
          rdv_id: result.insertId,
          patient_id: req.utilisateur.id,
          patient_nom: `${req.utilisateur.prenom} ${req.utilisateur.nom}`,
          date_rdv,
          heure_rdv,
          motif
        })
      ]
    );

    res.status(201).json({
      succes: true,
      message: `Demande envoyée au Dr. ${medecin[0].prenom} ${medecin[0].nom} !`,
      id: result.insertId
    });

  } catch (error) {
    console.error('ERREUR demanderRendezVous:', error);
    res.status(500).json({
      succes: false,
      message: 'Erreur serveur: ' + error.message
    });
  }
};

// ── PATIENT : Annuler un RDV ────────────────────────────
const annulerRendezVous = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, statut, medecin_id FROM rendez_vous WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ succes: false, message: 'Rendez-vous introuvable.' });
    }

    if (rows[0].statut === 'termine') {
      return res.status(400).json({ succes: false, message: 'Impossible d\'annuler un RDV terminé.' });
    }

    await db.query(
      'UPDATE rendez_vous SET statut = ? WHERE id = ?',
      ['annule', req.params.id]
    );

    // Notifier le médecin de l'annulation
    await db.query(
      `INSERT INTO notifications (utilisateur_id, titre, message, type, data_json)
       VALUES (?, ?, ?, ?, ?)`,
      [
        rows[0].medecin_id,
        'RDV annulé',
        `${req.utilisateur.prenom} ${req.utilisateur.nom} a annulé son rendez-vous.`,
        'annulation',
        JSON.stringify({ rdv_id: req.params.id })
      ]
    );

    res.json({ succes: true, message: 'Rendez-vous annulé.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── MÉDECIN : Voir ses RDV ──────────────────────────────
const getRdvMedecin = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.*,
              u.nom AS patient_nom, u.prenom AS patient_prenom,
              u.telephone AS patient_telephone
       FROM rendez_vous r
       JOIN utilisateurs u ON r.patient_id = u.id
       WHERE r.medecin_id = ?
       ORDER BY r.date_rdv ASC, r.heure_rdv ASC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, rendez_vous: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── MÉDECIN : Confirmer/Refuser un RDV ─────────────────
const majStatutRdv = async (req, res) => {
  try {
    const { statut, notes_medecin } = req.body;
    const rdvId = req.params.id;

    console.log('=== MAJ STATUT RDV ===');
    console.log('RDV ID:', rdvId);
    console.log('Médecin ID:', req.utilisateur.id);
    console.log('Nouveau statut:', statut);

    if (!['confirme', 'annule', 'termine'].includes(statut)) {
      return res.status(400).json({ succes: false, message: 'Statut invalide.' });
    }

    // Récupérer le RDV — sans filtrer par medecin_id pour déboguer
    const [rdv] = await db.query(
      `SELECT r.*, 
              u.nom AS patient_nom, u.prenom AS patient_prenom,
              u.id AS patient_user_id
       FROM rendez_vous r
       JOIN utilisateurs u ON r.patient_id = u.id
       WHERE r.id = ?`,
      [rdvId]
    );

    console.log('RDV trouvé:', rdv);

    if (rdv.length === 0) {
      return res.status(404).json({ succes: false, message: 'RDV introuvable.' });
    }

    // Vérifier que ce RDV appartient bien à ce médecin
    if (rdv[0].medecin_id !== req.utilisateur.id) {
      return res.status(403).json({ succes: false, message: 'Accès refusé.' });
    }

    await db.query(
      'UPDATE rendez_vous SET statut = ?, notes_medecin = ? WHERE id = ?',
      [statut, notes_medecin || null, rdvId]
    );

    // Notifier le patient
    const messages = {
      confirme: `Votre rendez-vous du ${rdv[0].date_rdv} à ${rdv[0].heure_rdv} a été confirmé par Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom}.`,
      annule:   `Votre rendez-vous du ${rdv[0].date_rdv} à ${rdv[0].heure_rdv} a été refusé par Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom}.${notes_medecin ? ' Motif : ' + notes_medecin : ''}`,
      termine:  `Votre consultation du ${rdv[0].date_rdv} est marquée comme terminée.`,
    };

    const titres = {
      confirme: 'RDV confirmé',
      annule:   'RDV refusé',
      termine:  'Consultation terminée',
    };

    await db.query(
      `INSERT INTO notifications (utilisateur_id, titre, message, type, data_json)
       VALUES (?, ?, ?, ?, ?)`,
      [
        rdv[0].patient_user_id,
        titres[statut],
        messages[statut],
        statut,
        JSON.stringify({ rdv_id: rdvId }),
      ]
    );

    console.log('Notification patient envoyée');

    res.json({ succes: true, message: `Rendez-vous ${statut} !` });

  } catch (error) {
    console.error('ERREUR majStatutRdv:', error);
    res.status(500).json({ succes: false, message: 'Erreur: ' + error.message });
  }
};
// ── NOTIFICATIONS ───────────────────────────────────────
const getNotifications = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT * FROM notifications 
       WHERE utilisateur_id = ? 
       ORDER BY created_at DESC 
       LIMIT 50`,
      [req.utilisateur.id]
    );
    const [count] = await db.query(
      'SELECT COUNT(*) AS total FROM notifications WHERE utilisateur_id = ? AND lu = FALSE',
      [req.utilisateur.id]
    );
    res.json({ succes: true, notifications: rows, non_lues: count[0].total });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const marquerLues = async (req, res) => {
  try {
    await db.query(
      'UPDATE notifications SET lu = TRUE WHERE utilisateur_id = ?',
      [req.utilisateur.id]
    );
    res.json({ succes: true });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getMesRendezVous, getMedecinsDisponibles, demanderRendezVous, annulerRendezVous,
  getRdvMedecin, majStatutRdv,
  getNotifications, marquerLues,
};