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

    if (!medecin_id || !date_rdv || !heure_rdv || !motif) {
      return res.status(400).json({ succes: false, message: 'Tous les champs sont requis.' });
    }

    // Vérifier que le médecin existe
    const [medecin] = await db.query(
      'SELECT id FROM utilisateurs WHERE id = ? AND est_actif = TRUE',
      [medecin_id]
    );

    if (medecin.length === 0) {
      return res.status(404).json({ succes: false, message: 'Médecin introuvable.' });
    }

    // Vérifier pas de double RDV
    const [existant] = await db.query(
      `SELECT id FROM rendez_vous 
       WHERE medecin_id = ? AND date_rdv = ? AND heure_rdv = ? 
       AND statut NOT IN ('annule', 'termine')`,
      [medecin_id, date_rdv, heure_rdv]
    );

    if (existant.length > 0) {
      return res.status(409).json({
        succes: false,
        message: 'Ce créneau est déjà pris. Choisissez un autre horaire.'
      });
    }

    const [result] = await db.query(
      `INSERT INTO rendez_vous (patient_id, medecin_id, date_rdv, heure_rdv, motif)
       VALUES (?, ?, ?, ?, ?)`,
      [req.utilisateur.id, medecin_id, date_rdv, heure_rdv, motif]
    );

    // Créer rappel automatique
    await db.query(
      `INSERT INTO rappels (patient_id, titre, description, type, date_rappel, heure_rappel)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id,
       'Rendez-vous médical',
       `Consultation - ${motif}`,
       'rdv', date_rdv, heure_rdv]
    );

    res.status(201).json({ succes: true, message: 'Demande de rendez-vous envoyée !', id: result.insertId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── PATIENT : Annuler un RDV ────────────────────────────
const annulerRendezVous = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, statut FROM rendez_vous WHERE id = ? AND patient_id = ?',
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

    if (!['confirme', 'annule', 'termine'].includes(statut)) {
      return res.status(400).json({ succes: false, message: 'Statut invalide.' });
    }

    await db.query(
      'UPDATE rendez_vous SET statut = ?, notes_medecin = ? WHERE id = ? AND medecin_id = ?',
      [statut, notes_medecin, req.params.id, req.utilisateur.id]
    );

    res.json({ succes: true, message: `Rendez-vous ${statut} !` });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getMesRendezVous, getMedecinsDisponibles, demanderRendezVous, annulerRendezVous,
  getRdvMedecin, majStatutRdv,
};
