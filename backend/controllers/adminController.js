// controllers/adminController.js
// Gestion des utilisateurs par admin/superadmin

const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { ensureValidationProfessionnelsTable } = require('../utils/validationProfessionnels');

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

const listerValidationsProfessionnels = async (_req, res) => {
  try {
    await ensureValidationProfessionnelsTable();
    const [demandes] = await db.query(
      `SELECT v.*, u.nom, u.prenom, u.email, u.telephone, u.est_actif
       FROM validations_professionnels v
       JOIN utilisateurs u ON u.id = v.utilisateur_id
       ORDER BY
         CASE v.statut WHEN 'en_attente' THEN 0 WHEN 'rejetee' THEN 1 ELSE 2 END,
         v.created_at DESC`
    );
    res.json({ succes: true, demandes });
  } catch (error) {
    console.error('listerValidationsProfessionnels:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const approuverValidationProfessionnel = async (req, res) => {
  try {
    await ensureValidationProfessionnelsTable();
    const { id } = req.params;

    const [demandes] = await db.query(
      'SELECT utilisateur_id FROM validations_professionnels WHERE id = ?',
      [id]
    );
    if (demandes.length === 0) {
      return res.status(404).json({ succes: false, message: 'Demande introuvable.' });
    }

    await db.query('UPDATE utilisateurs SET est_actif = TRUE WHERE id = ?', [demandes[0].utilisateur_id]);
    await db.query(
      `UPDATE validations_professionnels
       SET statut = 'approuvee', admin_id = ?, raison_rejet = NULL
       WHERE id = ?`,
      [req.utilisateur.id, id]
    );

    res.json({ succes: true, message: 'Compte professionnel approuvé et activé.' });
  } catch (error) {
    console.error('approuverValidationProfessionnel:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const rejeterValidationProfessionnel = async (req, res) => {
  try {
    await ensureValidationProfessionnelsTable();
    const { id } = req.params;
    const { raison } = req.body;

    const [demandes] = await db.query(
      'SELECT utilisateur_id FROM validations_professionnels WHERE id = ?',
      [id]
    );
    if (demandes.length === 0) {
      return res.status(404).json({ succes: false, message: 'Demande introuvable.' });
    }

    await db.query('UPDATE utilisateurs SET est_actif = FALSE WHERE id = ?', [demandes[0].utilisateur_id]);
    await db.query(
      `UPDATE validations_professionnels
       SET statut = 'rejetee', admin_id = ?, raison_rejet = ?
       WHERE id = ?`,
      [req.utilisateur.id, raison || null, id]
    );

    res.json({ succes: true, message: 'Demande rejetée. Le compte reste inactif.' });
  } catch (error) {
    console.error('rejeterValidationProfessionnel:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  listerUtilisateurs,
  toggleActivation,
  supprimerUtilisateur,
  changerRole,
  listerValidationsProfessionnels,
  approuverValidationProfessionnel,
  rejeterValidationProfessionnel,
};
