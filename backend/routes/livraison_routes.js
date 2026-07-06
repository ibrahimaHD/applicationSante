// routes/livraison.routes.js
const express = require('express');
const router = express.Router();
const LivraisonController = require('../controllers/livraisonController');

router.get('/', LivraisonController.getAll);
router.get('/position/:commandeId', LivraisonController.getPosition);
router.get('/commande/:commandeId', LivraisonController.getByCommande);
router.get('/livreur/:livreurId', LivraisonController.getByLivreur);
router.patch('/commande/:commandeId/assigner', LivraisonController.assigner);
router.patch('/commande/:commandeId/statut', LivraisonController.updateStatut);

module.exports = router;
