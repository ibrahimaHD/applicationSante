const express = require('express');
const router = express.Router();
const {
  getMonProfil, getMesPatients, getDossierPatient,
  ajouterConsultation, creerOrdonnance, getMesOrdonnances,
  ajouterExamen, creerRappelPatient,
  genererQrCode, scannerQrCode,
  getMesRdv, majStatutRdv,
} = require('../controllers/medecinController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);
router.use(autoriserRoles('medecin', 'admin', 'superadmin'));

router.get('/profil', getMonProfil);
router.get('/patients', getMesPatients);
router.get('/patients/:patientId/dossier', getDossierPatient);
router.post('/consultations', ajouterConsultation);
router.get('/ordonnances', getMesOrdonnances);
router.post('/ordonnances', creerOrdonnance);
router.post('/examens', ajouterExamen);
router.post('/rappels-patient', creerRappelPatient);
router.post('/qr-code', genererQrCode);
router.get('/qr/:token', scannerQrCode);
router.get('/rendez-vous', getMesRdv);
router.patch('/rendez-vous/:id', majStatutRdv);

module.exports = router;