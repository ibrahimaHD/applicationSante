const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);

// Livreur met à jour sa position
router.post('/position', autoriserRoles('livreur'), async (req, res) => {
  try {
    const { commande_id, latitude, longitude } = req.body;

    await db.query(
      `INSERT INTO positions_livreur 
        (livreur_id, commande_id, latitude, longitude)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         latitude   = VALUES(latitude),
         longitude  = VALUES(longitude),
         updated_at = NOW()`,
      [req.utilisateur.id, commande_id, latitude, longitude]
    );

    // Ajouter statut suivi
    await db.query(
      `INSERT INTO suivi_livraison (commande_id, statut, description)
       VALUES (?, ?, ?)`,
      [commande_id, 'En livraison',
       `Livreur en route — ${new Date().toLocaleTimeString('fr-FR')}`]
    );

    res.json({ succes: true });
  } catch (error) {
    res.status(500).json({ succes: false, message: error.message });
  }
});

// Patient récupère la position du livreur
router.get('/position/:commandeId', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT pl.*, u.nom AS livreur_nom, u.prenom AS livreur_prenom,
              u.telephone AS livreur_tel
       FROM positions_livreur pl
       JOIN utilisateurs u ON pl.livreur_id = u.id
       WHERE pl.commande_id = ?
       ORDER BY pl.updated_at DESC
       LIMIT 1`,
      [req.params.commandeId]
    );
    res.json({ succes: true, position: rows[0] || null });
  } catch (error) {
    res.status(500).json({ succes: false, message: error.message });
  }
});

module.exports = router;