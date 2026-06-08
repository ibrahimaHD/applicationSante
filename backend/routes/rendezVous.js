const express = require('express');
const router = express.Router();
const {
  getMesRendezVous, getMedecinsDisponibles, demanderRendezVous, annulerRendezVous,
  getRdvMedecin, majStatutRdv,
  getNotifications, marquerLues,
} = require('../controllers/rendezVousController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);

// ── Routes fixes d'abord (AVANT les routes avec :id) ──
router.get('/medecins',            autoriserRoles('patient', 'admin', 'superadmin'), getMedecinsDisponibles);
router.get('/notifications',       getNotifications);
router.patch('/notifications/lues', marquerLues);
router.get('/mes-rdv',             autoriserRoles('medecin', 'admin', 'superadmin'), getRdvMedecin);

// ── Routes avec paramètre :id ensuite ──
router.get('/',                    autoriserRoles('patient', 'admin', 'superadmin'), getMesRendezVous);
router.post('/',                   autoriserRoles('patient'), demanderRendezVous);
router.patch('/:id/annuler',       autoriserRoles('patient'), annulerRendezVous);
router.patch('/:id/statut',        autoriserRoles('medecin', 'admin', 'superadmin'), majStatutRdv);

module.exports = router;