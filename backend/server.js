const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
require('dotenv').config();
const path = require('path');
 
const app = express();
 
// CORS ultra permissif pour le développement
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', '*');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Access-Control-Allow-Credentials', 'false');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});
 
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
 
app.use('/api/auth',      require('./routes/auth'));
// Servir l'application Flutter
app.use(express.static(path.join(__dirname, '../frontend/build/web')));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/admin',     require('./routes/admin'));
 
app.get('/', (req, res) => {
  res.json({ succes: true, message: '🏥 HealthApp API en ligne !', version: '1.0.0' });
});
 
app.use((req, res) => {
  res.status(404).json({ succes: false, message: 'Route introuvable.' });
});
app.use('/api/patient', require('./routes/patient'));

 
// Démarrer sur 2 ports : 3000 et 3001
const PORT1 = 3000;
const PORT2 = 3001;
 
app.listen(PORT1, '0.0.0.0', () => {
  console.log(`\n🚀 Serveur démarré sur http://localhost:${PORT1}`);
  console.log(`🚀 Aussi disponible sur http://127.0.0.1:${PORT1}`);
});
 
app.listen(PORT2, '0.0.0.0', () => {
  console.log(`🚀 Aussi disponible sur http://localhost:${PORT2}\n`);
});
