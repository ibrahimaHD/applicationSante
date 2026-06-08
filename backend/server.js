const express = require('express');
const cors = require('cors');
require('dotenv').config();
const path = require('path');
 
const app = express();
 
// CORS
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', '*');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Access-Control-Allow-Credentials', 'false');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});
 
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
 
// ── Routes API (AVANT le static) ──────────────────────
app.use('/api/auth',      require('./routes/auth'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/admin',     require('./routes/admin'));
app.use('/api/patient',   require('./routes/patient'));

app.use('/api/rendez-vous', require('./routes/rendezVous'));


app.use('/api/cartographie', require('./routes/cartographie_routes'));


app.use('/api/pharmacie', require('./routes/pharmacie_routes'));


app.use('/api/medecin', require('./routes/medecin'));


 
// ── Flutter web (APRÈS les routes API) ────────────────
app.use(express.static(path.join(__dirname, '../frontend/build/web')));
 
// ── 404 (EN DERNIER) ──────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ succes: false, message: 'Route introuvable.' });
});





const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Serveur démarré sur http://localhost:${PORT}`);
  console.log(`✅ Routes: /api/auth | /api/dashboard | /api/admin | /api/patient\n`);
});
