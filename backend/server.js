const express = require('express');
const cors = require('cors');
require('dotenv').config();
const path = require('path');

const app = express();

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

app.use('/api/auth',         require('./routes/auth'));
app.use('/api/dashboard',    require('./routes/dashboard'));
app.use('/api/admin',        require('./routes/admin'));
app.use('/api/patient',      require('./routes/patient'));
app.use('/api/rendez-vous',  require('./routes/rendezVous'));
app.use('/api/cartographie', require('./routes/cartographie_routes'));
app.use('/api/pharmacie',    require('./routes/pharmacien_routes'));   // côté patient
app.use('/api/medecins',     require('./routes/medecin'));
app.use('/api/pharmacien',   require('./routes/pharmacien_routes')); // ← nouveau
app.use('/api/livreur',      require('./routes/livreur_routes'));     // ← nouveau

app.use(express.static(path.join(__dirname, '../frontend/build/web')));

app.use((req, res) => {
  res.status(404).json({ succes: false, message: 'Route introuvable.' });
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Serveur démarré sur http://localhost:${PORT}`);
  console.log(`✅ Routes: auth | dashboard | admin | patient | rendez-vous`);
  console.log(`✅ Routes: cartographie | pharmacie | medecins | pharmacien | livreur\n`);
});