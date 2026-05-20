// controllers/adminController.js
// Gestion des utilisateurs par admin/superadmin

const bcrypt = require('bcryptjs');
const db = require('../config/database');

// Lister tous les utilisateurs
const listerUtilisateurs = async (req, res) => {
  try {
    const [utilisateurs] = await db.query(
      `SELECT u.id, u.nom, u.prenom, u.email, u.telephone, u.est_actif,
              r.nom AS role, u.created_at
       FROM utilisateurs u
       JOIN roles r ON u.role_id = r.id
       ORDER BY u.created_at DESC`
    );
    res.json({ succes: true, utilisateurs });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// Activer / désactiver un compte
const toggleActivation = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await db.query('SELECT est_actif FROM utilisateurs WHERE id = ?', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ succes: false, message: 'Utilisateur introuvable.' });
    }

    const nouvelEtat = !rows[0].est_actif;
    await db.query('UPDATE utilisateurs SET est_actif = ? WHERE id = ?', [nouvelEtat, id]);

    res.json({
      succes: true,
      message: `Compte ${nouvelEtat ? 'activé' : 'désactivé'} avec succès.`
    });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// Supprimer un utilisateur (superadmin seulement)
const supprimerUtilisateur = async (req, res) => {
  try {
    const { id } = req.params;

    // Empêcher de se supprimer soi-même
    if (parseInt(id) === req.utilisateur.id) {
      return res.status(400).json({ succes: false, message: 'Vous ne pouvez pas supprimer votre propre compte.' });
    }

    await db.query('DELETE FROM utilisateurs WHERE id = ?', [id]);
    res.json({ succes: true, message: 'Utilisateur supprimé.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// Changer le rôle d'un utilisateur (superadmin seulement)
const changerRole = async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    const [roleData] = await db.query('SELECT id FROM roles WHERE nom = ?', [role]);
    if (roleData.length === 0) {
      return res.status(400).json({ succes: false, message: 'Rôle invalide.' });
    }

    await db.query('UPDATE utilisateurs SET role_id = ? WHERE id = ?', [roleData[0].id, id]);
    res.json({ succes: true, message: `Rôle changé en "${role}" avec succès.` });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = { listerUtilisateurs, toggleActivation, supprimerUtilisateur, changerRole };
