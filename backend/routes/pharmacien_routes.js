const express = require('express');
const router = express.Router();
const {
  getMonProfil, majProfil,
  getStock, ajouterMedicament, majStock,
  getCommandes, majStatutCommande,
  getOrdonnances, traiterOrdonnance,
  getVentes,
  getLivreursDisponibles,
} = require('../controllers/pharmacienController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);
router.use(autoriserRoles('pharmacien', 'admin', 'superadmin'));

router.get('/profil',            getMonProfil);
router.put('/profil',            majProfil);
router.get('/stock',             getStock);
router.post('/stock',            ajouterMedicament);
router.patch('/stock/:id',       majStock);
router.get('/commandes',         getCommandes);
router.patch('/commandes/:id',   majStatutCommande);
router.get('/ordonnances',       getOrdonnances);
router.patch('/ordonnances/:id', traiterOrdonnance);
router.get('/ventes',            getVentes);
router.get('/livreurs',          getLivreursDisponibles);

module.exports = router;
