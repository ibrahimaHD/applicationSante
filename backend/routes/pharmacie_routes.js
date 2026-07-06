const express = require('express');
const router = express.Router();
const {
  getMedicaments,
  getPharmacies,
  getCategories,
  getMesCommandes,
  creerCommande,
  payerCommande,
  getSuiviCommande,
  renouvelerCommande,
} = require('../controllers/pharmaciePatientController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);
router.use(autoriserRoles('patient', 'admin', 'superadmin'));

router.get('/pharmacies', getPharmacies);
router.get('/medicaments/categories', getCategories);
router.get('/medicaments', getMedicaments);
router.get('/commandes/:id/suivi', getSuiviCommande);
router.post('/commandes/:id/renouveler', renouvelerCommande);
router.get('/commandes', getMesCommandes);
router.post('/commandes', creerCommande);
router.post('/paiement', payerCommande);

module.exports = router;
