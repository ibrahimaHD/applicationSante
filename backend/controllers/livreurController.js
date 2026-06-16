const db = require('../config/database');

// ── PROFIL ───────────────────────────────────────────────────────────
const getMonProfil = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.nom, u.prenom, u.email, u.telephone, u.photo_profil,
              l.zone_livraison, l.vehicule, l.disponible
       FROM utilisateurs u
       LEFT JOIN livreurs l ON u.id = l.utilisateur_id
       WHERE u.id = ?`,
      [req.utilisateur.id]
    );

    // Stats du livreur
    const [stats] = await db.query(
      `SELECT
         COUNT(*) AS total_livraisons,
         SUM(CASE WHEN statut = 'livree' THEN 1 ELSE 0 END) AS livrees,
         SUM(CASE WHEN statut = 'en_livraison' THEN 1 ELSE 0 END) AS en_cours,
         SUM(CASE WHEN DATE(created_at) = CURDATE() THEN 1 ELSE 0 END) AS aujourd_hui
       FROM commandes
       WHERE livreur_id = ?`,
      [req.utilisateur.id]
    );

    res.json({ succes: true, profil: rows[0] || {}, stats: stats[0] || {} });
  } catch (e) {
    console.error('livreur getMonProfil:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const majProfil = async (req, res) => {
  try {
    const { nom, prenom, telephone, zone_livraison, vehicule } = req.body;
    await db.query(
      'UPDATE utilisateurs SET nom=?, prenom=?, telephone=? WHERE id=?',
      [nom, prenom, telephone, req.utilisateur.id]
    );
    await db.query(
      'UPDATE livreurs SET zone_livraison=?, vehicule=? WHERE utilisateur_id=?',
      [zone_livraison, vehicule, req.utilisateur.id]
    );
    res.json({ succes: true, message: 'Profil mis à jour !' });
  } catch (e) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const toggleDisponibilite = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT disponible FROM livreurs WHERE utilisateur_id = ?',
      [req.utilisateur.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ succes: false, message: 'Profil livreur introuvable.' });
    }
    const nouvelEtat = !rows[0].disponible;
    await db.query(
      'UPDATE livreurs SET disponible = ? WHERE utilisateur_id = ?',
      [nouvelEtat, req.utilisateur.id]
    );
    res.json({ succes: true, disponible: nouvelEtat,
      message: nouvelEtat ? 'Vous êtes maintenant disponible' : 'Vous êtes hors ligne' });
  } catch (e) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── LIVRAISONS DU JOUR ───────────────────────────────────────────────
const getLivraisonsAujourdhui = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT c.*,
              u.nom AS patient_nom, u.prenom AS patient_prenom,
              u.telephone AS patient_tel
       FROM commandes c
       JOIN utilisateurs u ON c.patient_id = u.id
       WHERE c.livreur_id = ?
         AND c.statut IN ('en_livraison', 'confirmee', 'en_preparation')
       ORDER BY c.created_at ASC`,
      [req.utilisateur.id]
    );

    for (const c of rows) {
      const [articles] = await db.query(
        `SELECT ca.quantite, m.nom AS medicament_nom
         FROM commande_articles ca
         JOIN medicaments m ON ca.medicament_id = m.id
         WHERE ca.commande_id = ?`,
        [c.id]
      );
      c.articles = articles;
    }

    // Stats du jour
    const [stats] = await db.query(
      `SELECT
         COUNT(*) AS total,
         SUM(CASE WHEN statut = 'livree'       THEN 1 ELSE 0 END) AS livrees,
         SUM(CASE WHEN statut = 'en_livraison' THEN 1 ELSE 0 END) AS en_cours
       FROM commandes
       WHERE livreur_id = ? AND DATE(created_at) = CURDATE()`,
      [req.utilisateur.id]
    );

    res.json({ succes: true, livraisons: rows, stats: stats[0] || {} });
  } catch (e) {
    console.error('getLivraisonsAujourdhui:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── TOUTES LES LIVRAISONS ASSIGNÉES ─────────────────────────────────
const getMesLivraisons = async (req, res) => {
  try {
    const { statut } = req.query;
    let query = `
      SELECT c.*,
             u.nom AS patient_nom, u.prenom AS patient_prenom,
             u.telephone AS patient_tel
      FROM commandes c
      JOIN utilisateurs u ON c.patient_id = u.id
      WHERE c.livreur_id = ?`;
    const params = [req.utilisateur.id];
    if (statut) { query += ' AND c.statut = ?'; params.push(statut); }
    query += ' ORDER BY c.created_at DESC';

    const [rows] = await db.query(query, params);
    for (const c of rows) {
      const [articles] = await db.query(
        `SELECT ca.quantite, m.nom AS medicament_nom
         FROM commande_articles ca
         JOIN medicaments m ON ca.medicament_id = m.id
         WHERE ca.commande_id = ?`,
        [c.id]
      );
      c.articles = articles;
    }

    res.json({ succes: true, livraisons: rows });
  } catch (e) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── HISTORIQUE ───────────────────────────────────────────────────────
const getHistorique = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT c.*,
              u.nom AS patient_nom, u.prenom AS patient_prenom
       FROM commandes c
       JOIN utilisateurs u ON c.patient_id = u.id
       WHERE c.livreur_id = ? AND c.statut = 'livree'
       ORDER BY c.updated_at DESC`,
      [req.utilisateur.id]
    );

    // Stats globales
    const [stats] = await db.query(
      `SELECT
         COUNT(*) AS total_livrees,
         SUM(CASE WHEN DATE(created_at) = CURDATE()                   THEN 1 ELSE 0 END) AS aujourd_hui,
         SUM(CASE WHEN YEARWEEK(created_at) = YEARWEEK(NOW())         THEN 1 ELSE 0 END) AS cette_semaine,
         SUM(CASE WHEN MONTH(created_at) = MONTH(NOW())
                   AND YEAR(created_at) = YEAR(NOW())                 THEN 1 ELSE 0 END) AS ce_mois
       FROM commandes
       WHERE livreur_id = ? AND statut = 'livree'`,
      [req.utilisateur.id]
    );

    res.json({ succes: true, historique: rows, stats: stats[0] || {} });
  } catch (e) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── CHANGER STATUT LIVRAISON ─────────────────────────────────────────
const majStatutLivraison = async (req, res) => {
  try {
    const { statut } = req.body;
    if (!['en_livraison', 'livree'].includes(statut)) {
      return res.status(400).json({ succes: false, message: 'Statut invalide.' });
    }

    // Vérifier que cette commande est bien assignée à ce livreur
    const [rows] = await db.query(
      'SELECT id FROM commandes WHERE id = ? AND livreur_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    if (rows.length === 0) {
      return res.status(403).json({ succes: false, message: 'Commande non assignée.' });
    }

    await db.query('UPDATE commandes SET statut = ? WHERE id = ?', [statut, req.params.id]);

    const msg = statut === 'livree'
      ? 'Livraison confirmée ! Merci.'
      : 'Livraison en cours…';
    await db.query(
      'INSERT INTO suivi_livraison (commande_id, statut, description) VALUES (?, ?, ?)',
      [req.params.id, msg, msg]
    );

    // Si livré, remettre le livreur disponible
    if (statut === 'livree') {
      const enCours = await db.query(
        'SELECT COUNT(*) AS nb FROM commandes WHERE livreur_id = ? AND statut = ?',
        [req.utilisateur.id, 'en_livraison']
      );
      if (enCours[0][0].nb === 0) {
        await db.query(
          'UPDATE livreurs SET disponible = TRUE WHERE utilisateur_id = ?',
          [req.utilisateur.id]
        );
      }
    }

    res.json({ succes: true, message: msg });
  } catch (e) {
    console.error('majStatutLivraison:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getMonProfil, majProfil, toggleDisponibilite,
  getLivraisonsAujourdhui, getMesLivraisons,
  getHistorique, majStatutLivraison,
};