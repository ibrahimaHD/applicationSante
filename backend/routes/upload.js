// routes/upload.js
// Upload de documents (diplômes, pièces d'identité, etc.)

const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

// Créer le dossier d'upload s'il n'existe pas
const dossierUpload = path.join(__dirname, '..', 'uploads', 'documents');
if (!fs.existsSync(dossierUpload)) {
  fs.mkdirSync(dossierUpload, { recursive: true });
}

// Config stockage
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, dossierUpload),
  filename: (req, file, cb) => {
    const suffixeUnique = crypto.randomBytes(16).toString('hex');
    const extension = path.extname(file.originalname);
    cb(null, `${Date.now()}-${suffixeUnique}${extension}`);
  }
});

// Filtrer les types de fichiers acceptés (validation par extension uniquement,
// le mimetype envoyé par le client n'étant pas fiable selon la plateforme)
const filtreFichier = (req, file, cb) => {
  const typesAutorises = /\.(jpe?g|png|pdf)$/i;
  const extensionValide = typesAutorises.test(file.originalname);

  if (extensionValide) {
    cb(null, true);
  } else {
    cb(new Error('Seuls les fichiers JPG, PNG et PDF sont acceptés.'));
  }
};

const upload = multer({
  storage,
  fileFilter: filtreFichier,
  limits: { fileSize: 10 * 1024 * 1024 } // 10 Mo max
});

// ─────────────────────────────────────────
// POST /api/upload/document
// Upload d'un seul document, retourne son URL
// ─────────────────────────────────────────
router.post('/document', (req, res) => {
  upload.single('fichier')(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ succes: false, message: `Erreur upload: ${err.message}` });
    } else if (err) {
      return res.status(400).json({ succes: false, message: err.message });
    }

    if (!req.file) {
      return res.status(400).json({ succes: false, message: 'Aucun fichier reçu.' });
    }

    const urlFichier = `/uploads/documents/${req.file.filename}`;

    res.status(201).json({
      succes: true,
      message: 'Fichier téléversé avec succès.',
      url: urlFichier,
      nom_original: req.file.originalname
    });
  });
});

module.exports = router;