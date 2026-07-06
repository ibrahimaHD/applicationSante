// routes/medicament.routes.js
const express = require('express');
const router = express.Router();
const MedicamentController = require('../controllers/medicamentController');

router.get('/', MedicamentController.getAll);
router.get('/:id', MedicamentController.getById);
router.post('/', MedicamentController.create);
router.put('/:id', MedicamentController.update);
router.delete('/:id', MedicamentController.remove);

module.exports = router;
