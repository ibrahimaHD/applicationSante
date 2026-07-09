// routes/admin.js
// Routes de gestion des utilisateurs (admin et superadmin)

const express = require('express');
const router = express.Router();
const {
  listerUtilisateurs,
  toggleActivation,
  supprimerUtilisateur,
  changerRole,
  listerValidationsProfessionnels,
  approuverValidationProfessionnel,
  rejeterValidationProfessionnel
} = require('../controllers/adminController');
const { verifierToken, autoriserRoles } = require('../middleware/auth');

// Lister tous les utilisateurs (admin + superadmin)
router.get('/utilisateurs', verifierToken, autoriserRoles('admin', 'superadmin'), listerUtilisateurs);

// Demandes de validation médecin/pharmacien
router.get('/validations-professionnels', verifierToken, autoriserRoles('admin', 'superadmin'), listerValidationsProfessionnels);
router.patch('/validations-professionnels/:id/approuver', verifierToken, autoriserRoles('admin', 'superadmin'), approuverValidationProfessionnel);
router.patch('/validations-professionnels/:id/rejeter', verifierToken, autoriserRoles('admin', 'superadmin'), rejeterValidationProfessionnel);

// Activer/désactiver un compte (admin + superadmin)
router.patch('/utilisateurs/:id/activation', verifierToken, autoriserRoles('admin', 'superadmin'), toggleActivation);

// Changer le rôle (superadmin uniquement)
router.patch('/utilisateurs/:id/role', verifierToken, autoriserRoles('superadmin'), changerRole);

// Supprimer un utilisateur (superadmin uniquement)
router.delete('/utilisateurs/:id', verifierToken, autoriserRoles('superadmin'), supprimerUtilisateur);

module.exports = router;
