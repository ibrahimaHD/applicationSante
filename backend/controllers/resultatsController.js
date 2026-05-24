const db = require('../config/database');

// ── RÉSULTATS MÉDICAUX ──────────────────────────────────

const getResultats = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM resultats_medicaux WHERE patient_id = ? ORDER BY date_resultat DESC',
      [req.utilisateur.id]
    );
    res.json({ succes: true, resultats: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const ajouterResultat = async (req, res) => {
  try {
    const { type, titre, description, date_resultat, medecin, statut } = req.body;
    if (!titre || !date_resultat) {
      return res.status(400).json({ succes: false, message: 'Titre et date requis.' });
    }
    await db.query(
      `INSERT INTO resultats_medicaux (patient_id, type, titre, description, date_resultat, medecin, statut)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id, type || 'analyse', titre, description, date_resultat, medecin, statut || 'normal']
    );

    // Enregistrer l'audit
    await _enregistrerAudit(req.utilisateur.id, req.utilisateur.id, req.utilisateur.role, 'Ajout résultat médical', req.ip);

    res.status(201).json({ succes: true, message: 'Résultat ajouté !' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const supprimerResultat = async (req, res) => {
  try {
    await db.query(
      'DELETE FROM resultats_medicaux WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    res.json({ succes: true, message: 'Résultat supprimé.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── AUDIT DES ACCÈS ─────────────────────────────────────

const getAudits = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT a.*, u.nom AS nom_acces, u.prenom AS prenom_acces
       FROM audits_acces a
       JOIN utilisateurs u ON a.accede_par = u.id
       WHERE a.patient_id = ?
       ORDER BY a.created_at DESC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, audits: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// Fonction interne pour enregistrer les audits
const _enregistrerAudit = async (patientId, accedeParId, role, typeAcces, ip) => {
  try {
    await db.query(
      'INSERT INTO audits_acces (patient_id, accede_par, role_acces, type_acces, ip_address) VALUES (?, ?, ?, ?, ?)',
      [patientId, accedeParId, role, typeAcces, ip]
    );
  } catch (error) {
    console.error('Erreur audit:', error);
  }
};

module.exports = { getResultats, ajouterResultat, supprimerResultat, getAudits, _enregistrerAudit };
