const db = require('../config/database');

// ── RÉSULTATS MÉDICAUX ──────────────────────────────────

// Patient : voir ses résultats
const getResultats = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.*, 
              u.nom AS medecin_nom, u.prenom AS medecin_prenom
       FROM resultats_medicaux r
       LEFT JOIN utilisateurs u ON r.medecin_id = u.id
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

// Patient : ajouter un résultat manuellement
const ajouterResultat = async (req, res) => {
  try {
    const { type, titre, description, date_resultat, medecin, statut } = req.body;

    if (!titre || !date_resultat) {
      return res.status(400).json({
        succes: false,
        message: 'Titre et date requis.'
      });
    }

    // Convertir la date si nécessaire
    let dateFormatee = date_resultat;
    if (date_resultat.includes('T')) {
      dateFormatee = date_resultat.split('T')[0];
    } else if (date_resultat.includes('/')) {
      const [j, m, a] = date_resultat.split('/');
      dateFormatee = `${a}-${m.padStart(2,'0')}-${j.padStart(2,'0')}`;
    }

    await db.query(
      `INSERT INTO resultats_medicaux 
        (patient_id, type, titre, description, date_resultat, medecin, statut)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        req.utilisateur.id,
        type || 'analyse',
        titre,
        description,
        dateFormatee,
        medecin,
        statut || 'normal'
      ]
    );

    res.status(201).json({ succes: true, message: 'Résultat ajouté !' });
  } catch (error) {
    console.error('Erreur ajouterResultat:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// Supprimer un résultat
const supprimerResultat = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id FROM resultats_medicaux WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        succes: false,
        message: 'Résultat introuvable.'
      });
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

// ── MÉDECIN : ajouter un résultat pour un patient ───────
const ajouterResultatMedecin = async (req, res) => {
  try {
    const { patient_id, type, titre, description, date_resultat, statut } = req.body;

    if (!patient_id || !titre || !date_resultat) {
      return res.status(400).json({
        succes: false,
        message: 'Patient, titre et date requis.'
      });
    }

    // Vérifier que le patient existe
    const [patient] = await db.query(
      'SELECT id FROM utilisateurs WHERE id = ? AND est_actif = TRUE',
      [patient_id]
    );

    if (patient.length === 0) {
      return res.status(404).json({
        succes: false,
        message: 'Patient introuvable.'
      });
    }

    // Convertir la date
    let dateFormatee = date_resultat;
    if (date_resultat.includes('T')) {
      dateFormatee = date_resultat.split('T')[0];
    } else if (date_resultat.includes('/')) {
      const [j, m, a] = date_resultat.split('/');
      dateFormatee = `${a}-${m.padStart(2,'0')}-${j.padStart(2,'0')}`;
    }

    const [result] = await db.query(
      `INSERT INTO resultats_medicaux 
        (patient_id, medecin_id, type, titre, description, 
         date_resultat, medecin, statut)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        patient_id,
        req.utilisateur.id,
        type || 'analyse',
        titre,
        description,
        dateFormatee,
        `Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom}`,
        statut || 'normal'
      ]
    );

    // Notifier le patient
    await db.query(
      `INSERT INTO notifications (utilisateur_id, titre, message, type, data_json)
       VALUES (?, ?, ?, ?, ?)`,
      [
        patient_id,
        'Nouveau résultat médical',
        `Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom} a ajouté un résultat : ${titre}`,
        'resultat',
        JSON.stringify({ resultat_id: result.insertId, titre, statut: statut || 'normal' })
      ]
    );

    res.status(201).json({
      succes: true,
      message: 'Résultat ajouté et patient notifié !',
      id: result.insertId
    });
  } catch (error) {
    console.error('Erreur ajouterResultatMedecin:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── AUDIT DES ACCÈS ─────────────────────────────────────
const getAudits = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT a.*, 
              u.nom AS nom_acces, u.prenom AS prenom_acces,
              r.nom AS role_nom
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
  getResultats,
  ajouterResultat,
  supprimerResultat,
  ajouterResultatMedecin,
  getAudits,
};