const db = require('../config/database');
const crypto = require('crypto'); // ← manquait dans l'original !

// ── PROFIL MÉDECIN ──────────────────────────────────────────────────
const getMonProfil = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.*, m.specialite, m.numero_ordre, m.hopital_clinique, m.disponible
       FROM utilisateurs u
       LEFT JOIN medecins m ON u.id = m.utilisateur_id
       WHERE u.id = ?`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, profil: rows[0] });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── STATISTIQUES DASHBOARD ──────────────────────────────────────────
const getStats = async (req, res) => {
  try {
    const medecinId = req.utilisateur.id;
    

    const [rdvAujourdhui] = await db.query(
      `SELECT COUNT(*) AS total FROM rendez_vous 
       WHERE medecin_id = ? AND date_rdv = CURDATE() AND statut NOT IN ('annule')`,
      [medecinId]
    );

    const [rdvEnAttente] = await db.query(
      `SELECT COUNT(*) AS total FROM rendez_vous 
       WHERE medecin_id = ? AND statut = 'en_attente'`,
      [medecinId]
    );

    const [totalPatients] = await db.query(
      `SELECT COUNT(DISTINCT patient_id) AS total FROM consultations WHERE medecin_id = ?`,
      [medecinId]
    );

    // RDV du jour avec infos patient
    const [rdvDuJour] = await db.query(
      `SELECT r.*, u.nom AS patient_nom, u.prenom AS patient_prenom, u.telephone AS patient_tel
       FROM rendez_vous r
       JOIN utilisateurs u ON r.patient_id = u.id
       WHERE r.medecin_id = ? AND r.date_rdv = CURDATE() AND r.statut NOT IN ('annule')
       ORDER BY r.heure_rdv ASC`,
      [medecinId]
    );

    res.json({
      succes: true,
      stats: {
        rdv_aujourd_hui: rdvAujourdhui[0].total,
        rdv_en_attente:  rdvEnAttente[0].total,
        total_patients:  totalPatients[0].total,
      },
      rdv_du_jour: rdvDuJour,
    });
  } catch (error) {
    console.error('getStats:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── MES PATIENTS ─────────────────────────────────────────────────────
const getMesPatients = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT DISTINCT u.id, u.nom, u.prenom, u.email, u.telephone,
              p.date_naissance, p.groupe_sanguin,
              pm.allergies, pm.antecedents,
              MAX(c.date_consultation) AS derniere_consultation
       FROM utilisateurs u
       JOIN consultations c ON u.id = c.patient_id
       LEFT JOIN patients p ON u.id = p.utilisateur_id
       LEFT JOIN profils_medicaux pm ON u.id = pm.utilisateur_id
       WHERE c.medecin_id = ?
       GROUP BY u.id
       ORDER BY derniere_consultation DESC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, patients: rows });
  } catch (error) {
    console.error('getMesPatients:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── TOUS LES PATIENTS (pour créer consultation sans RDV) ─────────────
const getTousPatients = async (req, res) => {
  try {
    const { search } = req.query;
    let query = `SELECT u.id, u.nom, u.prenom, u.email, u.telephone
                 FROM utilisateurs u
                 JOIN roles r ON u.role_id = r.id
                 WHERE r.nom = 'patient' AND u.est_actif = TRUE`;
    const params = [];

    if (search) {
      query += ` AND (u.nom LIKE ? OR u.prenom LIKE ? OR u.email LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    query += ' ORDER BY u.nom ASC LIMIT 50';
    const [rows] = await db.query(query, params);
    res.json({ succes: true, patients: rows });
  } catch (error) {
    console.error('getTousPatients:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── DOSSIER PATIENT ──────────────────────────────────────────────────
const getDossierPatient = async (req, res) => {
  try {
    const patientId = req.params.patientId;

    const [patient] = await db.query(
      `SELECT u.*, p.date_naissance, p.sexe, p.groupe_sanguin, p.adresse,
              pm.allergies, pm.antecedents, pm.medicaments_actuels, pm.medecin_traitant
       FROM utilisateurs u
       LEFT JOIN patients p ON u.id = p.utilisateur_id
       LEFT JOIN profils_medicaux pm ON u.id = pm.utilisateur_id
       WHERE u.id = ?`,
      [patientId]
    );

    const [consultations] = await db.query(
      'SELECT * FROM consultations WHERE patient_id = ? ORDER BY date_consultation DESC',
      [patientId]
    );
    const [vaccinations] = await db.query(
      'SELECT * FROM vaccinations WHERE patient_id = ? ORDER BY created_at DESC',
      [patientId]
    );
    const [ordonnances] = await db.query(
      'SELECT * FROM ordonnances WHERE patient_id = ? ORDER BY date_ordonnance DESC',
      [patientId]
    );
    const [examens] = await db.query(
      'SELECT * FROM examens WHERE patient_id = ? ORDER BY date_examen DESC',
      [patientId]
    );

    // Audit
    await db.query(
      'INSERT INTO audits_acces (patient_id, accede_par, role_acces, type_acces) VALUES (?, ?, ?, ?)',
      [patientId, req.utilisateur.id, 'medecin', 'Consultation dossier médical']
    );

    res.json({
      succes: true,
      dossier: { patient: patient[0], consultations, vaccinations, ordonnances, examens }
    });
  } catch (error) {
    console.error('getDossierPatient:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── AJOUTER CONSULTATION ─────────────────────────────────────────────
const ajouterConsultation = async (req, res) => {
  try {
    const { patient_id, motif, diagnostic, traitement, notes, date_consultation, rdv_id } = req.body;

    if (!patient_id || !motif || !date_consultation) {
      return res.status(400).json({ succes: false, message: 'Patient, motif et date requis.' });
    }

    const [result] = await db.query(
      `INSERT INTO consultations 
         (patient_id, medecin_id, medecin_nom, motif, diagnostic, traitement, notes, date_consultation)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        patient_id,
        req.utilisateur.id,
        `Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom}`,
        motif,
        diagnostic || null,
        traitement || null,
        notes || null,
        date_consultation,
      ]
    );

    // Marquer le RDV comme terminé si fourni
    if (rdv_id) {
      await db.query(
        'UPDATE rendez_vous SET statut = ? WHERE id = ? AND medecin_id = ?',
        ['termine', rdv_id, req.utilisateur.id]
      );
    }

    res.status(201).json({
      succes: true,
      message: 'Consultation enregistrée avec succès !',
      id: result.insertId,
    });
  } catch (error) {
    console.error('ajouterConsultation:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── MES CONSULTATIONS (liste) ────────────────────────────────────────
const getMesConsultations = async (req, res) => {
  try {
    const { patient_id, limit = 50 } = req.query;
    let query = `
      SELECT c.*, u.nom AS patient_nom, u.prenom AS patient_prenom
      FROM consultations c
      JOIN utilisateurs u ON c.patient_id = u.id
      WHERE c.medecin_id = ?`;
    const params = [req.utilisateur.id];

    if (patient_id) {
      query += ' AND c.patient_id = ?';
      params.push(patient_id);
    }

    query += ' ORDER BY c.date_consultation DESC LIMIT ?';
    params.push(parseInt(limit));

    const [rows] = await db.query(query, params);
    res.json({ succes: true, consultations: rows });
  } catch (error) {
    console.error('getMesConsultations:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── ORDONNANCES ──────────────────────────────────────────────────────
const creerOrdonnance = async (req, res) => {
  try {
    const { patient_id, medicaments, instructions, consultation_id } = req.body;
    if (!patient_id || !medicaments) {
      return res.status(400).json({ succes: false, message: 'Patient et médicaments requis.' });
    }
    await db.query(
      `INSERT INTO ordonnances (patient_id, medecin_id, consultation_id, medicaments, instructions, date_ordonnance)
       VALUES (?, ?, ?, ?, ?, CURDATE())`,
      [patient_id, req.utilisateur.id, consultation_id || null, medicaments, instructions || null]
    );
    res.status(201).json({ succes: true, message: 'Ordonnance créée !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getMesOrdonnances = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT o.*, u.nom AS patient_nom, u.prenom AS patient_prenom
       FROM ordonnances o
       JOIN utilisateurs u ON o.patient_id = u.id
       WHERE o.medecin_id = ?
       ORDER BY o.date_ordonnance DESC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, ordonnances: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── EXAMENS ──────────────────────────────────────────────────────────
const ajouterExamen = async (req, res) => {
  try {
    const { patient_id, type_examen, resultat, statut, date_examen } = req.body;
    if (!patient_id || !type_examen || !date_examen) {
      return res.status(400).json({ succes: false, message: 'Patient, type et date requis.' });
    }
    await db.query(
      `INSERT INTO examens (patient_id, medecin_id, type_examen, resultat, statut, date_examen)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [patient_id, req.utilisateur.id, type_examen, resultat || null, statut || 'normal', date_examen]
    );
    // Visible aussi dans résultats_medicaux du patient
    await db.query(
      `INSERT INTO resultats_medicaux (patient_id, type, titre, description, date_resultat, medecin, statut)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        patient_id, 'analyse', type_examen, resultat || null, date_examen,
        `Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom}`,
        statut || 'normal',
      ]
    );
    res.status(201).json({ succes: true, message: 'Examen ajouté !' });
  } catch (error) {
    console.error('ajouterExamen:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── RAPPELS PATIENT ──────────────────────────────────────────────────
const creerRappelPatient = async (req, res) => {
  try {
    const { patient_id, titre, description, type, date_rappel, heure_rappel } = req.body;
    if (!patient_id || !titre || !type) {
      return res.status(400).json({ succes: false, message: 'Patient, titre et type requis.' });
    }
    await db.query(
      `INSERT INTO rappels (patient_id, titre, description, type, date_rappel, heure_rappel)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [patient_id, titre, description || null, type, date_rappel || null, heure_rappel || null]
    );
    res.status(201).json({ succes: true, message: 'Rappel créé pour le patient !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── QR CODE ──────────────────────────────────────────────────────────
const genererQrCode = async (req, res) => {
  try {
    const { patient_id } = req.body;
    const token      = crypto.randomBytes(32).toString('hex');
    const expiration = new Date(Date.now() + 3600000);
    await db.query(
      'INSERT INTO qr_acces (patient_id, token, expire_at) VALUES (?, ?, ?)',
      [patient_id, token, expiration]
    );
    res.json({
      succes: true, token,
      qr_url: `${process.env.APP_URL || 'http://localhost:3000'}/api/medecin/qr/${token}`,
      expire_at: expiration,
    });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.'});
  }
};

const scannerQrCode = async (req, res) => {
  try {
    const { token } = req.params;
    const [rows] = await db.query(
      'SELECT * FROM qr_acces WHERE token = ? AND expire_at > NOW() AND utilise = FALSE',
      [token]
    );
    if (rows.length === 0) {
      return res.status(400).json({ succes: false, message: 'QR Code invalide ou expiré.' });
    }
    await db.query('UPDATE qr_acces SET utilise = TRUE WHERE token = ?', [token]);
    res.redirect(`/api/medecin/patients/${rows[0].patient_id}/dossier`);
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── RENDEZ-VOUS MÉDECIN ──────────────────────────────────────────────
const getMesRdv = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.*, u.nom AS patient_nom, u.prenom AS patient_prenom, u.telephone AS patient_tel
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

const majStatutRdv = async (req, res) => {
  try {
    const { statut, notes_medecin } = req.body;
    if (!['confirme', 'annule', 'termine'].includes(statut)) {
      return res.status(400).json({ succes: false, message: 'Statut invalide.' });
    }
    await db.query(
      'UPDATE rendez_vous SET statut = ?, notes_medecin = ? WHERE id = ? AND medecin_id = ?',
      [statut, notes_medecin || null, req.params.id, req.utilisateur.id]
    );
    res.json({ succes: true, message: `Rendez-vous ${statut} !` });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getMonProfil, getStats,
  getMesPatients, getTousPatients, getDossierPatient,
  ajouterConsultation, getMesConsultations,
  creerOrdonnance, getMesOrdonnances,
  ajouterExamen, creerRappelPatient,
  genererQrCode, scannerQrCode,
  getMesRdv, majStatutRdv,
};