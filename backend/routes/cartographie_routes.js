const express = require('express');
const router = express.Router();
const { getFormations, getFormationById, getPharmacies, getSpecialites } = require('../controllers/cartographieController');
const { verifierToken } = require('../middleware/auth');

router.use(verifierToken);

router.get('/formations', getFormations);
router.get('/formations/:id', getFormationById);
router.get('/pharmacies', getPharmacies);
router.get('/specialites', getSpecialites);

module.exports = router;
