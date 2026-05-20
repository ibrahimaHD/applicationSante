// controllers/authController.js
// Toute la logique d'authentification

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/database');
const { envoyerEmailReset } = require('../utils/email');

// ─────────────────────────────────────────
// INSCRIPTION
// POST /api/auth/inscription
// ─────────────────────────────────────────
const inscription = async (req, res) => {
  try {
    const { nom, prenom, email, mot_de_passe, telephone, role } = req.body;

    // Validation des champs obligatoires
    if (!nom || !prenom || !email || !mot_de_passe) {
      return res.status(400).json({
        succes: false,
        message: 'Nom, prénom, email et mot de passe sont obligatoires.'
      });
    }

    // Vérifier si l'email existe déjà
    const [existant] = await db.query(
      'SELECT id FROM utilisateurs WHERE email = ?',
      [email]
    );

    if (existant.length > 0) {
      return res.status(409).json({
        succes: false,
        message: 'Cet email est déjà utilisé.'
      });
    }

    // Trouver l'ID du rôle (par défaut: patient)
    const roleNom = role || 'patient';
    const [roleData] = await db.query(
      'SELECT id FROM roles WHERE nom = ?',
      [roleNom]
    );

    // Empêcher la création de superadmin via inscription publique
    if (roleNom === 'superadmin') {
      return res.status(403).json({
        succes: false,
        message: 'Impossible de créer un compte superadmin via inscription.'
      });
    }

    if (roleData.length === 0) {
      return res.status(400).json({ succes: false, message: 'Rôle invalide.' });
    }

    // Hasher le mot de passe (sécurité)
    const motDePasseHash = await bcrypt.hash(mot_de_passe, 12);

    // Créer l'utilisateur
    const [resultat] = await db.query(
      `INSERT INTO utilisateurs (nom, prenom, email, mot_de_passe, telephone, role_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [nom, prenom, email, motDePasseHash, telephone || null, roleData[0].id]
    );

    const utilisateurId = resultat.insertId;

    // Créer le profil spécifique selon le rôle
    await creerProfilRole(roleNom, utilisateurId, req.body);

    // Log de l'action
    await db.query(
      'INSERT INTO logs_connexion (utilisateur_id, action, ip_address) VALUES (?, ?, ?)',
      [utilisateurId, 'register', req.ip]
    );

    res.status(201).json({
      succes: true,
      message: 'Compte créé avec succès ! Vous pouvez maintenant vous connecter.'
    });

  } catch (error) {
    console.error('Erreur inscription:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// CONNEXION (LOGIN)
// POST /api/auth/connexion
// ─────────────────────────────────────────
const connexion = async (req, res) => {
  try {
    const { email, mot_de_passe } = req.body;

    if (!email || !mot_de_passe) {
      return res.status(400).json({
        succes: false,
        message: 'Email et mot de passe obligatoires.'
      });
    }

    // Chercher l'utilisateur avec son rôle
    const [rows] = await db.query(
      `SELECT u.*, r.nom AS role 
       FROM utilisateurs u 
       JOIN roles r ON u.role_id = r.id 
       WHERE u.email = ?`,
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        succes: false,
        message: 'Email ou mot de passe incorrect.'
      });
    }

    const utilisateur = rows[0];

    // Vérifier si le compte est actif
    if (!utilisateur.est_actif) {
      return res.status(403).json({
        succes: false,
        message: 'Votre compte est désactivé. Contactez l\'administrateur.'
      });
    }

    // Vérifier le mot de passe
    const motDePasseCorrect = await bcrypt.compare(mot_de_passe, utilisateur.mot_de_passe);

    if (!motDePasseCorrect) {
      return res.status(401).json({
        succes: false,
        message: 'Email ou mot de passe incorrect.'
      });
    }

    // Générer le token JWT
    const token = jwt.sign(
      { id: utilisateur.id, role: utilisateur.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    // Log de connexion
    await db.query(
      'INSERT INTO logs_connexion (utilisateur_id, action, ip_address) VALUES (?, ?, ?)',
      [utilisateur.id, 'login', req.ip]
    );

    // Retourner le token et les infos utilisateur (sans le mot de passe)
    const { mot_de_passe: _, reset_token: __, ...utilisateurSansPassword } = utilisateur;

    res.json({
      succes: true,
      message: 'Connexion réussie !',
      token,
      utilisateur: utilisateurSansPassword
    });

  } catch (error) {
    console.error('Erreur connexion:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// DÉCONNEXION (LOGOUT)
// POST /api/auth/deconnexion
// ─────────────────────────────────────────
const deconnexion = async (req, res) => {
  try {
    // Log de déconnexion
    await db.query(
      'INSERT INTO logs_connexion (utilisateur_id, action, ip_address) VALUES (?, ?, ?)',
      [req.utilisateur.id, 'logout', req.ip]
    );

    res.json({ succes: true, message: 'Déconnexion réussie.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// DEMANDE DE RÉINITIALISATION MOT DE PASSE
// POST /api/auth/mot-de-passe-oublie
// ─────────────────────────────────────────
const motDePasseOublie = async (req, res) => {
  try {
    const { email } = req.body;

    const [rows] = await db.query(
      'SELECT id, nom, prenom FROM utilisateurs WHERE email = ?',
      [email]
    );

    // Toujours répondre OK (sécurité: ne pas révéler si l'email existe)
    if (rows.length === 0) {
      return res.json({
        succes: true,
        message: 'Si cet email existe, un lien de réinitialisation a été envoyé.'
      });
    }

    const utilisateur = rows[0];

    // Générer un token unique
    const resetToken = crypto.randomBytes(32).toString('hex');
    const expiration = new Date(Date.now() + 3600000); // 1 heure

    await db.query(
      'UPDATE utilisateurs SET reset_token = ?, reset_token_expire = ? WHERE id = ?',
      [resetToken, expiration, utilisateur.id]
    );

    // Envoyer l'email
    await envoyerEmailReset(email, utilisateur.prenom, resetToken);

    res.json({
      succes: true,
      message: 'Un lien de réinitialisation a été envoyé à votre email.'
    });

  } catch (error) {
    console.error('Erreur reset password:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// RÉINITIALISER LE MOT DE PASSE
// POST /api/auth/reinitialiser-mot-de-passe/:token
// ─────────────────────────────────────────
const reinitialiserMotDePasse = async (req, res) => {
  try {
    const { token } = req.params;
    const { nouveau_mot_de_passe } = req.body;

    if (!nouveau_mot_de_passe) {
      return res.status(400).json({ succes: false, message: 'Nouveau mot de passe requis.' });
    }

    // Vérifier le token et sa validité
    const [rows] = await db.query(
      `SELECT id FROM utilisateurs 
       WHERE reset_token = ? AND reset_token_expire > NOW()`,
      [token]
    );

    if (rows.length === 0) {
      return res.status(400).json({
        succes: false,
        message: 'Token invalide ou expiré. Refaites une demande.'
      });
    }

    // Hasher le nouveau mot de passe
    const nouveauHash = await bcrypt.hash(nouveau_mot_de_passe, 12);

    // Mettre à jour et effacer le token
    await db.query(
      `UPDATE utilisateurs 
       SET mot_de_passe = ?, reset_token = NULL, reset_token_expire = NULL 
       WHERE id = ?`,
      [nouveauHash, rows[0].id]
    );

    res.json({ succes: true, message: 'Mot de passe réinitialisé avec succès !' });

  } catch (error) {
    console.error('Erreur reinitialisation:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// PROFIL CONNECTÉ
// GET /api/auth/moi
// ─────────────────────────────────────────
const monProfil = async (req, res) => {
  const { mot_de_passe, reset_token, reset_token_expire, ...profil } = req.utilisateur;
  res.json({ succes: true, utilisateur: profil });
};

// ─────────────────────────────────────────
// FONCTION INTERNE: Créer profil selon rôle
// ─────────────────────────────────────────
const creerProfilRole = async (role, utilisateurId, body) => {
  switch (role) {
    case 'medecin':
      await db.query(
        'INSERT INTO medecins (utilisateur_id, specialite, numero_ordre, hopital_clinique) VALUES (?, ?, ?, ?)',
        [utilisateurId, body.specialite || null, body.numero_ordre || null, body.hopital_clinique || null]
      );
      break;
    case 'patient':
      await db.query(
        'INSERT INTO patients (utilisateur_id, date_naissance, sexe, groupe_sanguin, adresse) VALUES (?, ?, ?, ?, ?)',
        [utilisateurId, body.date_naissance || null, body.sexe || null, body.groupe_sanguin || null, body.adresse || null]
      );
      break;
    case 'pharmacien':
      await db.query(
        'INSERT INTO pharmaciens (utilisateur_id, nom_pharmacie, adresse_pharmacie, numero_licence) VALUES (?, ?, ?, ?)',
        [utilisateurId, body.nom_pharmacie || null, body.adresse_pharmacie || null, body.numero_licence || null]
      );
      break;
    case 'livreur':
      await db.query(
        'INSERT INTO livreurs (utilisateur_id, zone_livraison, vehicule) VALUES (?, ?, ?)',
        [utilisateurId, body.zone_livraison || null, body.vehicule || null]
      );
      break;
    default:
      break;
  }
};

module.exports = {
  inscription,
  connexion,
  deconnexion,
  motDePasseOublie,
  reinitialiserMotDePasse,
  monProfil
};
