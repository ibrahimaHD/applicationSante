const express = require('express');
const cors = require('cors');
require('dotenv').config();
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});
app.set('io', io);
const medicamentRoutes = require('./routes/medicament_routes');
const commandeRoutes = require('./routes/commande_routes');
const livraisonRoutes = require('./routes/livraison_routes');
const uploadRoutes = require('./routes/upload');




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
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/auth',         require('./routes/auth'));
app.use('/api/dashboard',    require('./routes/dashboard'));
app.use('/api/admin',        require('./routes/admin'));
app.use('/api/patient',      require('./routes/patient'));
app.use('/api/rendez-vous',  require('./routes/rendezVous'));
app.use('/api/cartographie', require('./routes/cartographie_routes'));
app.use('/api/pharmacie',    require('./routes/pharmacie_routes'));   // côté patient
app.use('/api/medecin',     require('./routes/medecin'));
app.use('/api/pharmacien',   require('./routes/pharmacien_routes')); // ← nouveau
app.use('/api/livreur',      require('./routes/livreur_routes'));     // ← nouveau
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));  // ← ajouter ici (fichiers statiques)
app.use('/api/upload', uploadRoutes);                                   // ← ajouter ici (route d'upload)


app.use('/api/medicaments', medicamentRoutes);
app.use('/api/commandes', commandeRoutes);
app.use('/api/livraisons', livraisonRoutes);
app.use('/api/livraison', livraisonRoutes);



app.use(express.static(path.join(__dirname, '../frontend/build/web')));

app.use((req, res) => {
  res.status(404).json({ succes: false, message: 'Route introuvable.' });
});

const PORT = 3000;
io.on('connection', (socket) => {
  socket.on('suivre_commande', (commandeId) => {
    if (commandeId) socket.join(`commande:${commandeId}`);
  });

  socket.on('arreter_suivi_commande', (commandeId) => {
    if (commandeId) socket.leave(`commande:${commandeId}`);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Serveur démarré sur http://localhost:${PORT}`);
  console.log(`✅ Routes: auth | dashboard | admin | patient | rendez-vous`);
  console.log(`✅ Routes: cartographie | pharmacie | medecins | pharmacien | livreur\n`);
});
