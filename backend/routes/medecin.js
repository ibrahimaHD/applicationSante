// backend/routes/medecin.js

const express = require('express');
const router = express.Router();
const {
  getMonProfil, getStats,
  getMesPatients, getTousPatients, getDossierPatient,
  ajouterConsultation, getMesConsultations,
  creerOrdonnance, getMesOrdonnances,
  creerRappelPatient,
  genererQrCode, scannerQrCode,
  getMesRdv, majStatutRdv,
} = require('../controllers/medecinController');
const {
  creerExamen,
  getExamensMedecin,
  ajouterResultatMedecin,
  getResultatsMedecin,
} = require('../controllers/resultatsController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);
router.use(autoriserRoles('medecin', 'admin', 'superadmin'));

// Profil & stats
router.get('/profil', getMonProfil);
router.get('/stats',  getStats);

// Patients
router.get('/patients',                    getMesPatients);
router.get('/patients/tous',               getTousPatients);
router.get('/patients/:patientId/dossier', getDossierPatient);

// Consultations
router.get('/consultations',  getMesConsultations);
router.post('/consultations', ajouterConsultation);

// Ordonnances
router.get('/ordonnances',  getMesOrdonnances);
router.post('/ordonnances', creerOrdonnance);

// ── Examens ─────────────────────────────────────────────
router.get('/examens',  getExamensMedecin);
router.post('/examens', creerExamen);

// ── Résultats ────────────────────────────────────────────
router.get('/resultats',  getResultatsMedecin);
router.post('/resultats', ajouterResultatMedecin);

// Rappels
router.post('/rappels-patient', creerRappelPatient);

// QR code
router.post('/qr-code',  genererQrCode);
router.get('/qr/:token', scannerQrCode);

// Rendez-vous
router.get('/rendez-vous',       getMesRdv);
router.patch('/rendez-vous/:id', majStatutRdv);

module.exports = router;