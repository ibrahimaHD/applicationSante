// backend/controllers/resultatsController.js

const db = require('../config/database');

const TYPES_EXAMEN = {
  analyse_sang:  'Analyse de sang',
  analyse_urine: "Analyse d'urine",
  irm:           'IRM',
  echographie:   'Échographie',
  radiographie:  'Radiographie',
  scanner:       'Scanner',
  ecg:           'ECG',
  autre:         'Autre',
};

const formaterDate = (date) => {
  if (!date) return null;
  const s = date instanceof Date ? date.toISOString() : date.toString();
  return s.includes('T') ? s.split('T')[0] : s.substring(0, 10);
};

const auditerAccesPatient = async (patientId, utilisateur, typeAcces) => {
  if (!patientId) return;
  try {
    await db.query(
      'INSERT INTO audits_acces (patient_id, accede_par, role_acces, type_acces) VALUES (?, ?, ?, ?)',
      [patientId, utilisateur.id, utilisateur.role || 'medecin', typeAcces]
    );
  } catch (error) {
    console.warn('Audit accès non enregistré:', error.message);
  }
};

// ═══════════════════════════════════════════════════════
// MÉDECIN — créer un examen pour un patient
// POST /api/medecin/examens
// Body: { patient_id, nom_examen, type_examen, date_examen }
// ═══════════════════════════════════════════════════════
const creerExamen = async (req, res) => {
  try {
    const { patient_id, nom_examen, type_examen, date_examen } = req.body;

    if (!patient_id || !nom_examen || !type_examen || !date_examen) {
      return res.status(400).json({
        succes: false,
        message: 'Patient, nom, type et date sont requis.',
      });
    }

    if (!TYPES_EXAMEN[type_examen]) {
      return res.status(400).json({
        succes: false,
        message: 'Type d\'examen invalide.',
      });
    }

    // Vérifier que le patient existe
    const [patient] = await db.query(
      `SELECT u.id, u.nom, u.prenom FROM utilisateurs u
       JOIN roles r ON u.role_id = r.id
       WHERE u.id = ? AND u.est_actif = TRUE AND r.nom = 'patient'`,
      [patient_id]
    );
    if (patient.length === 0) {
      return res.status(404).json({ succes: false, message: 'Patient introuvable.' });
    }

    const [result] = await db.query(
      `INSERT INTO examens (patient_id, medecin_id, nom_examen, type_examen, date_examen)
       VALUES (?, ?, ?, ?, ?)`,
      [patient_id, req.utilisateur.id, nom_examen, type_examen, formaterDate(date_examen)]
    );

    res.status(201).json({
      succes: true,
      message: `Examen "${nom_examen}" créé pour ${patient[0].prenom} ${patient[0].nom} !`,
      id: result.insertId,
    });
  } catch (error) {
    console.error('Erreur creerExamen:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ═══════════════════════════════════════════════════════
// MÉDECIN — voir les examens qu'il a créés
// GET /api/medecin/examens?patient_id=xx
// ═══════════════════════════════════════════════════════
const getExamensMedecin = async (req, res) => {
  try {
    const { patient_id } = req.query;
    let query = `
      SELECT e.*,
             u.nom AS patient_nom, u.prenom AS patient_prenom,
             COUNT(r.id) AS nb_resultats
      FROM examens e
      JOIN utilisateurs u ON e.patient_id = u.id
      LEFT JOIN resultats_medicaux r ON r.examen_id = e.id
      WHERE e.medecin_id = ?`;
    const params = [req.utilisateur.id];

    if (patient_id) {
      query += ' AND e.patient_id = ?';
      params.push(patient_id);
    }

    query += ' GROUP BY e.id ORDER BY e.date_examen DESC LIMIT 100';
    const [rows] = await db.query(query, params);
    if (patient_id) {
      await auditerAccesPatient(patient_id, req.utilisateur, 'Consultation examens médicaux');
    }
    res.json({ succes: true, examens: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ═══════════════════════════════════════════════════════
// MÉDECIN — ajouter le résultat d'un examen
// POST /api/medecin/resultats
// Body: { examen_id, resultat, conclusion, observation, statut, date_resultat }
// ═══════════════════════════════════════════════════════
const ajouterResultatMedecin = async (req, res) => {
  try {
    const {
      examen_id,
      resultat,
      conclusion,
      observation,
      statut,
      date_resultat,
    } = req.body;

    if (!examen_id || !date_resultat) {
      return res.status(400).json({
        succes: false,
        message: "L'examen et la date sont requis.",
      });
    }

    // Vérifier que l'examen existe et récupérer le patient
    const [examen] = await db.query(
      `SELECT e.*, u.nom AS patient_nom, u.prenom AS patient_prenom
       FROM examens e
       JOIN utilisateurs u ON e.patient_id = u.id
       WHERE e.id = ? AND e.medecin_id = ?`,
      [examen_id, req.utilisateur.id]
    );

    if (examen.length === 0) {
      return res.status(404).json({
        succes: false,
        message: 'Examen introuvable ou non autorisé.',
      });
    }

    const ex = examen[0];
    const nomMedecin = `Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom}`;

    const [result] = await db.query(
      `INSERT INTO resultats_medicaux
        (examen_id, patient_id, medecin_id, type_examen,
         resultat, conclusion, observation,
         date_resultat, medecin, statut)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        examen_id,
        ex.patient_id,
        req.utilisateur.id,
        ex.type_examen,
        resultat    || null,
        conclusion  || null,
        observation || null,
        formaterDate(date_resultat),
        nomMedecin,
        statut || 'normal',
      ]
    );

    // Notification patient
    try {
      await db.query(
        `INSERT INTO notifications (utilisateur_id, titre, message, type, data_json)
         VALUES (?, ?, ?, ?, ?)`,
        [
          ex.patient_id,
          'Nouveau résultat médical',
          `${nomMedecin} a ajouté le résultat de votre ${TYPES_EXAMEN[ex.type_examen]}`,
          'resultat',
          JSON.stringify({ resultat_id: result.insertId, examen_id, statut: statut || 'normal' }),
        ]
      );
    } catch (e) {
      console.warn('Notification non envoyée:', e.message);
    }

    res.status(201).json({
      succes: true,
      message: `Résultat ajouté pour ${ex.patient_prenom} ${ex.patient_nom} !`,
      id: result.insertId,
    });
  } catch (error) {
    console.error('Erreur ajouterResultatMedecin:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ═══════════════════════════════════════════════════════
// MÉDECIN — voir les résultats qu'il a ajoutés
// GET /api/medecin/resultats?patient_id=xx
// ═══════════════════════════════════════════════════════
const getResultatsMedecin = async (req, res) => {
  try {
    const { patient_id } = req.query;
    let query = `
      SELECT r.*,
             u.nom AS patient_nom, u.prenom AS patient_prenom,
             e.nom_examen
      FROM resultats_medicaux r
      JOIN utilisateurs u ON r.patient_id = u.id
      LEFT JOIN examens e ON r.examen_id = e.id
      WHERE r.medecin_id = ?`;
    const params = [req.utilisateur.id];

    if (patient_id) {
      query += ' AND r.patient_id = ?';
      params.push(patient_id);
    }

    query += ' ORDER BY r.date_resultat DESC LIMIT 100';
    const [rows] = await db.query(query, params);
    if (patient_id) {
      await auditerAccesPatient(patient_id, req.utilisateur, 'Consultation résultats médicaux');
    }
    res.json({ succes: true, resultats: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ═══════════════════════════════════════════════════════
// PATIENT — voir ses résultats (avec examen lié)
// GET /api/patient/resultats
// ═══════════════════════════════════════════════════════
const getResultats = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.*,
              u.nom AS medecin_nom, u.prenom AS medecin_prenom,
              e.nom_examen
       FROM resultats_medicaux r
       LEFT JOIN utilisateurs u ON r.medecin_id = u.id
       LEFT JOIN examens e ON r.examen_id = e.id
       WHERE r.patient_id = ?
       ORDER BY r.date_resultat DESC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, resultats: rows });
  } catch (error) {
    console.error('Erreur getResultats:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ═══════════════════════════════════════════════════════
// PATIENT — supprimer un résultat
// DELETE /api/patient/resultats/:id
// ═══════════════════════════════════════════════════════
const supprimerResultat = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id FROM resultats_medicaux WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ succes: false, message: 'Résultat introuvable.' });
    }
    await db.query(
      'DELETE FROM resultats_medicaux WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    res.json({ succes: true, message: 'Résultat supprimé.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ═══════════════════════════════════════════════════════
// PATIENT — audits
// GET /api/patient/audits
// ═══════════════════════════════════════════════════════
const getAudits = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT a.*,
              u.nom AS nom_acces, u.prenom AS prenom_acces,
              r.nom AS role_acces
       FROM audits_acces a
       JOIN utilisateurs u ON a.accede_par = u.id
       JOIN roles r ON u.role_id = r.id
       WHERE a.patient_id = ?
       ORDER BY a.created_at DESC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, audits: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  creerExamen,
  getExamensMedecin,
  ajouterResultatMedecin,
  getResultatsMedecin,
  getResultats,
  supprimerResultat,
  getAudits,
};
