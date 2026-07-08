// routes/auth.js
// Définition des routes d'authentification

const express = require('express');
const router = express.Router();
const {
  inscription,
  connexion,
  deconnexion,
  motDePasseOublie,
  reinitialiserMotDePasse,
  formulaireReinitialisation,
  monProfil
} = require('../controllers/authController');
const { verifierToken } = require('../middleware/auth');

// Routes publiques (pas besoin d'être connecté)
router.post('/inscription', inscription);
router.post('/connexion', connexion);
router.post('/mot-de-passe-oublie', motDePasseOublie);
router.get('/reinitialiser-mot-de-passe/:token', formulaireReinitialisation);
router.post('/reinitialiser-mot-de-passe/:token', reinitialiserMotDePasse);

// Routes protégées (token JWT requis)
router.post('/deconnexion', verifierToken, deconnexion);
router.get('/moi', verifierToken, monProfil);

module.exports = router;
