// config/database.js
// Ce fichier gère la connexion à MySQL

const mysql = require('mysql2');
require('dotenv').config();

// Création du "pool" de connexions (permet plusieurs connexions simultanées)
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

// Version "promise" pour utiliser async/await
const db = pool.promise();

// Test de connexion au démarrage
pool.getConnection((err, connection) => {
  if (err) {
    console.error('❌ Erreur connexion MySQL:', err.message);
  } else {
    console.log('✅ Connecté à MySQL avec succès');
    connection.release();
  }
});

module.exports = db;
