// routes/rendezVous.js
const express = require('express');
const router = express.Router();
const {
  getMesRendezVous, getMedecinsDisponibles, demanderRendezVous, annulerRendezVous,
  getRdvMedecin, majStatutRdv,
} = require('../controllers/rendezVousController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);

// Patient
router.get('/', autoriserRoles('patient', 'admin', 'superadmin'), getMesRendezVous);
router.get('/medecins', autoriserRoles('patient', 'admin', 'superadmin'), getMedecinsDisponibles);
router.post('/', autoriserRoles('patient'), demanderRendezVous);
router.patch('/:id/annuler', autoriserRoles('patient'), annulerRendezVous);

// Médecin
router.get('/medecin', autoriserRoles('medecin', 'admin', 'superadmin'), getRdvMedecin);
router.patch('/:id/statut', autoriserRoles('medecin'), majStatutRdv);

module.exports = router;
