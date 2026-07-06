// middleware/auth.js
// Ce fichier protège les routes : vérifie le token JWT et le rôle

const jwt = require('jsonwebtoken');
const db = require('../config/database');

// ─────────────────────────────────────────
// Vérifie que le token JWT est valide
// ─────────────────────────────────────────
const verifierToken = async (req, res, next) => {
  try {
    // Le token doit être dans le header : Authorization: Bearer <token>
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // "Bearer TOKEN"

    if (!token) {
      return res.status(401).json({
        succes: false,
        message: 'Accès refusé. Token manquant.'
      });
      
    }

    // Décoder le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Récupérer l'utilisateur depuis la BDD
    const [rows] = await db.query(
      `SELECT u.*, r.nom AS role 
       FROM utilisateurs u 
       JOIN roles r ON u.role_id = r.id 
       WHERE u.id = ? AND u.est_actif = TRUE`,
      [decoded.id]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        succes: false,
        message: 'Utilisateur introuvable ou compte désactivé.'
      });
    }

    // Ajouter l'utilisateur à la requête pour les prochains middlewares
    req.utilisateur = rows[0];
    next();

  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ succes: false, message: 'Token expiré. Reconnectez-vous.' });
    }
    return res.status(401).json({ succes: false, message: 'Token invalide.' });
  }
};

// ─────────────────────────────────────────
// Vérifie que l'utilisateur a le bon rôle
// Usage: autoriserRoles('admin', 'superadmin')
// ─────────────────────────────────────────
const autoriserRoles = (...rolesAutorises) => {
  return (req, res, next) => {
    if (!req.utilisateur) {
      return res.status(401).json({ succes: false, message: 'Non authentifié.' });
    }

    if (!rolesAutorises.includes(req.utilisateur.role)) {
      return res.status(403).json({
        succes: false,
        message: `Accès refusé. Rôle requis: ${rolesAutorises.join(' ou ')}`
      });
    }

    next();
  };
};

module.exports = { verifierToken, autoriserRoles };
