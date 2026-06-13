// routes/patient.js
const express = require('express');
const router = express.Router();
const {
  getProfilMedical, sauvegarderProfilMedical,
  getInfosPersonnelles, majInfosPersonnelles, 
  getConsultations, ajouterConsultation, supprimerConsultation,
  getVaccinations, ajouterVaccination, mettreAJourVaccination,
  getRappels, ajouterRappel, toggleRappel, supprimerRappel,
  getGrossesse, creerGrossesse, mettreAJourGrossesse,
  getEnfants, ajouterEnfant, mettreAJourVaccinEnfant,
  getDossierMedical, getExamens, ajouterExamen, getOrdonnances,
} = require('../controllers/patientController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');
const { getResultats, supprimerResultat, getAudits } = require('../controllers/resultatsController');
 const multer = require('multer');
const path   = require('path');
const fs     = require('fs');

// Config multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads/ordonnances';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, `ord_${req.utilisateur.id}_${Date.now()}${path.extname(file.originalname)}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
    cb(null, allowed.includes(file.mimetype));
  },
});

// Ajouter dans patient.js
router.post('/ordonnances/upload',
  upload.single('ordonnance'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          succes: false,
          message: 'Fichier requis (JPG, PNG ou PDF, max 5MB).'
        });
      }

      const { notes } = req.body;

      // Sauvegarder en base
      await db.query(
        `INSERT INTO ordonnances_uploadees 
          (patient_id, fichier_path, notes, statut)
         VALUES (?, ?, ?, 'en_attente')`,
        [req.utilisateur.id, req.file.path, notes || null]
      );

      res.json({
        succes: true,
        message: 'Ordonnance envoyée ! La pharmacie va la traiter sous 30 min.',
        fichier: req.file.filename,
      });
    } catch (error) {
      res.status(500).json({
        succes: false,
        message: 'Erreur: ' + error.message
      });
    }
  }
);
// Tous les endpoints nécessitent d'être connecté
router.use(verifierToken);
router.use(autoriserRoles('patient', 'admin', 'superadmin'));
 
// Profil médical
router.get('/profil-medical', getProfilMedical);
router.post('/profil-medical', sauvegarderProfilMedical);
 
// Carnet de santé
router.get('/consultations', getConsultations);
router.post('/consultations', ajouterConsultation);
router.delete('/consultations/:id', supprimerConsultation);
 
// Vaccinations
router.get('/vaccinations', getVaccinations);
router.post('/vaccinations', ajouterVaccination);
router.patch('/vaccinations/:id', mettreAJourVaccination);
 
// Rappels
router.get('/rappels', getRappels);
router.post('/rappels', ajouterRappel);
router.patch('/rappels/:id/toggle', toggleRappel);
router.delete('/rappels/:id', supprimerRappel);
 
// Suivi grossesse
router.get('/grossesse', getGrossesse);
router.post('/grossesse', creerGrossesse);
router.patch('/grossesse', mettreAJourGrossesse);
 
// Enfants
router.get('/enfants', getEnfants);
router.post('/enfants', ajouterEnfant);
router.patch('/enfants/vaccins/:id', mettreAJourVaccinEnfant);
 
// Dossier médical
router.get('/dossier-medical', getDossierMedical);
 
// Examens
router.get('/examens', getExamens);
router.post('/examens', ajouterExamen);
 
// Ordonnances
router.get('/ordonnances', getOrdonnances);

// Informations personnelles
router.get('/infos-personnelles', getInfosPersonnelles);
router.put('/infos-personnelles', majInfosPersonnelles);
 

router.get('/resultats', getResultats);
router.delete('/resultats/:id', supprimerResultat);
router.get('/audits', getAudits);
module.exports = router;
 