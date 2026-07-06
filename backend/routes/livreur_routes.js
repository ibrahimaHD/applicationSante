const express = require('express');
const router = express.Router();
const {
  getMonProfil, majProfil, toggleDisponibilite,
  getLivraisonsAujourdhui, getMesLivraisons,
  getHistorique, majStatutLivraison, majPosition,
} = require('../controllers/livreurController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

router.use(verifierToken);
router.use(autoriserRoles('livreur', 'admin', 'superadmin'));

router.get('/profil',                  getMonProfil);
router.put('/profil',                  majProfil);
router.patch('/disponibilite',         toggleDisponibilite);
router.get('/livraisons/aujourd-hui',  getLivraisonsAujourdhui);
router.get('/livraisons',              getMesLivraisons);
router.patch('/livraisons/:id',        majStatutLivraison);
router.post('/position',               majPosition);
router.get('/historique',              getHistorique);

module.exports = router;
