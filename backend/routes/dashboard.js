// routes/dashboard.js
// Routes pour les tableaux de bord

const express = require('express');
const router = express.Router();
const {
  monDashboard,
  dashboardPatient,
  dashboardMedecin,
  dashboardPharmacien,
  dashboardLivreur,
  dashboardAdmin,
  dashboardSuperAdmin
} = require('../controllers/dashboardController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

// Route intelligente: renvoie le dashboard selon le rôle de l'utilisateur connecté
router.get('/', verifierToken, monDashboard);

// Routes spécifiques par rôle (accès restreint)
router.get('/patient',    verifierToken, autoriserRoles('patient', 'admin', 'superadmin'), dashboardPatient);
router.get('/medecin',    verifierToken, autoriserRoles('medecin', 'admin', 'superadmin'), dashboardMedecin);
router.get('/pharmacien', verifierToken, autoriserRoles('pharmacien', 'admin', 'superadmin'), dashboardPharmacien);
router.get('/livreur',    verifierToken, autoriserRoles('livreur', 'admin', 'superadmin'), dashboardLivreur);
router.get('/admin',      verifierToken, autoriserRoles('admin', 'superadmin'), dashboardAdmin);
router.get('/superadmin', verifierToken, autoriserRoles('superadmin'), dashboardSuperAdmin);

module.exports = router;
