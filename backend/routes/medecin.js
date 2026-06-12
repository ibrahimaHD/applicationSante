// routes/medecin.js
const express = require('express');
const router = express.Router();
const {
  getMonProfil, getStats,
  getMesPatients, getTousPatients, getDossierPatient,
  ajouterConsultation, getMesConsultations,
  creerOrdonnance, getMesOrdonnances,
  ajouterExamen, creerRappelPatient,
  genererQrCode, scannerQrCode,
  getMesRdv, majStatutRdv,
} = require('../controllers/medecinController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);
router.use(autoriserRoles('medecin', 'admin', 'superadmin'));

// Profil & stats
router.get('/profil',  getMonProfil);
router.get('/stats',   getStats);       // ← nouveau, corrige le dashboard

// Patients
router.get('/patients',               getMesPatients);
router.get('/patients/tous',          getTousPatients);   // ← nouveau, pour créer consultation
router.get('/patients/:patientId/dossier', getDossierPatient);

// Consultations
router.get('/consultations',  getMesConsultations);  // ← nouveau
router.post('/consultations', ajouterConsultation);

// Ordonnances
router.get('/ordonnances',  getMesOrdonnances);
router.post('/ordonnances', creerOrdonnance);

// Examens
router.post('/examens', ajouterExamen);

// Rappels
router.post('/rappels-patient', creerRappelPatient);

// QR code
router.post('/qr-code',  genererQrCode);
router.get('/qr/:token', scannerQrCode);

// Rendez-vous
router.get('/rendez-vous',      getMesRdv);
router.patch('/rendez-vous/:id', majStatutRdv);

module.exports = router;