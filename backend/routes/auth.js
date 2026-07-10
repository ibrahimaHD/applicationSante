// routes/auth.js
// Définition des routes d'authentification

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
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

const storageValidation = multer.diskStorage({
  destination: (_req, _file, cb) => {
    const dir = path.join(__dirname, '..', 'uploads', 'validations');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (_req, file, cb) => {
    const safeName = file.originalname
      .replace(/\s+/g, '_')
      .replace(/[^a-zA-Z0-9_.-]/g, '');
    cb(null, `doc_${Date.now()}_${safeName}`);
  },
});

const uploadValidation = multer({
  storage: storageValidation,
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
    cb(null, allowed.includes(file.mimetype));
  },
});

// Routes publiques (pas besoin d'être connecté)
router.post(
  '/inscription',
  uploadValidation.fields([
    { name: 'diplome', maxCount: 1 },
    { name: 'document_identite', maxCount: 1 },
    { name: 'autorisation_exercice', maxCount: 1 },
    { name: 'permis_conduire', maxCount: 1 },
  ]),
  inscription
);
router.post('/connexion', connexion);
router.post('/mot-de-passe-oublie', motDePasseOublie);
router.get('/reinitialiser-mot-de-passe/:token', formulaireReinitialisation);
router.post('/reinitialiser-mot-de-passe/:token', reinitialiserMotDePasse);

// Routes protégées (token JWT requis)
router.post('/deconnexion', verifierToken, deconnexion);
router.get('/moi', verifierToken, monProfil);

module.exports = router;
