const express = require('express');
const router = express.Router();
const {
  getMonProfil, majProfil,
  getStock, ajouterMedicament, majStock,
  getOrdonnances, traiterOrdonnance,
  getVentes,
  getLivreursDisponibles,
  getMedicaments, getCategoriesMedicaments,
  getMesCommandes, creerCommande,
  effectuerPaiement, getSuiviCommande, renouvelerCommande,
} = require('../controllers/pharmacienController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);
router.use(autoriserRoles('pharmacien', 'admin', 'superadmin','patient'));

router.get('/medicaments',               getMedicaments);
router.get('/medicaments/categories',    getCategoriesMedicaments);
router.get('/commandes',                 getMesCommandes);
router.post('/commandes',                creerCommande);
router.post('/paiement',                 effectuerPaiement);
router.get('/commandes/:id/suivi',       getSuiviCommande);
router.post('/commandes/:id/renouveler', renouvelerCommande);
router.get('/profil',            getMonProfil);
router.put('/profil',            majProfil);
router.get('/stock',             getStock);
router.post('/stock',            ajouterMedicament);
router.patch('/stock/:id',       majStock);
router.get('/ordonnances',       getOrdonnances);
router.patch('/ordonnances/:id', traiterOrdonnance);
router.get('/ventes',            getVentes);
router.get('/livreurs',          getLivreursDisponibles);
module.exports = router;