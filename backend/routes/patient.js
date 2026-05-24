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
 
module.exports = router;
 