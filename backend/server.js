// server.js
// Point d'entrée principal du serveur

const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// ─────────────────────────────────────────
// MIDDLEWARES GLOBAUX
// ─────────────────────────────────────────

// Autorise les requêtes depuis Flutter (toutes origines en dev)
app.use(cors({
  origin: '*', // En production, remplace par l'URL de ton app
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Permet de lire le JSON dans les requêtes
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ─────────────────────────────────────────
// ROUTES
// ─────────────────────────────────────────
app.use('/api/auth',      require('./routes/auth'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/admin',     require('./routes/admin'));

// Route de test (vérifier que le serveur tourne)
app.get('/', (req, res) => {
  res.json({
    succes: true,
    message: '🏥 HealthApp API en ligne !',
    version: '1.0.0',
    routes: {
      auth: '/api/auth',
      dashboard: '/api/dashboard',
      admin: '/api/admin'
    }
  });
});

// Gestion des routes inexistantes (404)
app.use((req, res) => {
  res.status(404).json({ succes: false, message: 'Route introuvable.' });
});

// ─────────────────────────────────────────
// DÉMARRAGE DU SERVEUR
// ─────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 Serveur démarré sur http://localhost:${PORT}`);
  console.log(`📋 Routes disponibles:`);
  console.log(`   POST   /api/auth/inscription`);
  console.log(`   POST   /api/auth/connexion`);
  console.log(`   GET    /api/auth/moi`);
  console.log(`   POST   /api/auth/deconnexion`);
  console.log(`   POST   /api/auth/mot-de-passe-oublie`);
  console.log(`   POST   /api/auth/reinitialiser-mot-de-passe/:token`);
  console.log(`   GET    /api/dashboard`);
  console.log(`   GET    /api/admin/utilisateurs`);
  console.log(`\n✅ Prêt à recevoir les requêtes Flutter !\n`);
});
