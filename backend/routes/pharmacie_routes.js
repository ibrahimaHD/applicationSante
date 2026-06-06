const express = require('express');
const router = express.Router();
const {
  getMedicaments, getCategories,
  getMesCommandes, passerCommande, annulerCommande, renouvelerCommande,
  getSuiviLivraison, initierPaiement,
} = require('../controllers/pharmacieController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);

// Catalogue
router.get('/medicaments', getMedicaments);
router.get('/medicaments/categories', getCategories);

// Commandes patient
router.get('/commandes', autoriserRoles('patient', 'admin', 'superadmin'), getMesCommandes);
router.post('/commandes', autoriserRoles('patient'), passerCommande);
router.patch('/commandes/:id/annuler', autoriserRoles('patient'), annulerCommande);
router.post('/commandes/:id/renouveler', autoriserRoles('patient'), renouvelerCommande);

// Suivi
router.get('/commandes/:id/suivi', getSuiviLivraison);

// Paiement
router.post('/paiement', autoriserRoles('patient'), initierPaiement);

module.exports = router;
