// routes/commande.routes.js
const express = require('express');
const router = express.Router();
const CommandeController = require('../controllers/commandeController');

router.get('/', CommandeController.getAll);
router.get('/patient/:patientId', CommandeController.getByPatient);
router.get('/:id', CommandeController.getById);
router.post('/', CommandeController.create);
router.patch('/:id/statut', CommandeController.updateStatut);
router.delete('/:id', CommandeController.remove);

module.exports = router;
