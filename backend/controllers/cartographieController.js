const db = require('../config/database');

// ── Formations sanitaires ───────────────────────────────
const getFormations = async (req, res) => {
  try {
    const { type, specialite } = req.query;
    let query = 'SELECT * FROM formations_sanitaires WHERE est_actif = TRUE';
    const params = [];

    if (type) {
      query += ' AND type = ?';
      params.push(type);
    }

    if (specialite) {
      query = `SELECT DISTINCT f.* FROM formations_sanitaires f
               JOIN specialites_disponibles s ON f.id = s.formation_id
               WHERE f.est_actif = TRUE AND s.specialite LIKE ? AND s.disponible = TRUE`;
      params.push(`%${specialite}%`);
    }

    query += ' ORDER BY nom ASC';
    const [rows] = await db.query(query, params);

    // Ajouter les spécialités pour chaque formation
    for (const f of rows) {
      const [specs] = await db.query(
        'SELECT specialite, medecin_nom FROM specialites_disponibles WHERE formation_id = ? AND disponible = TRUE',
        [f.id]
      );
      f.specialites = specs;
    }

    res.json({ succes: true, formations: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getFormationById = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM formations_sanitaires WHERE id = ?',
      [req.params.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ succes: false, message: 'Formation introuvable.' });
    }
    const [specs] = await db.query(
      'SELECT * FROM specialites_disponibles WHERE formation_id = ?',
      [req.params.id]
    );
    rows[0].specialites = specs;
    res.json({ succes: true, formation: rows[0] });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── Pharmacies ──────────────────────────────────────────
const getPharmacies = async (req, res) => {
  try {
    const { garde } = req.query;
    let query = 'SELECT * FROM pharmacies WHERE est_actif = TRUE';
    const params = [];

    if (garde === 'true') {
      query += ' AND est_garde = TRUE';
    }

    query += ' ORDER BY nom ASC';
    const [rows] = await db.query(query, params);
    res.json({ succes: true, pharmacies: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── Spécialités disponibles ─────────────────────────────
const getSpecialites = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT DISTINCT specialite FROM specialites_disponibles WHERE disponible = TRUE ORDER BY specialite ASC'
    );
    res.json({ succes: true, specialites: rows.map(r => r.specialite) });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = { getFormations, getFormationById, getPharmacies, getSpecialites };
