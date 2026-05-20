// controllers/dashboardController.js
// Tableau de bord personnalisé pour chaque rôle

const db = require('../config/database');

// ─────────────────────────────────────────
// TABLEAU DE BORD PATIENT
// GET /api/dashboard/patient
// ─────────────────────────────────────────
const dashboardPatient = async (req, res) => {
  try {
    const utilisateurId = req.utilisateur.id;

    // Infos du patient
    const [patient] = await db.query(
      `SELECT u.nom, u.prenom, u.email, u.telephone, u.photo_profil,
              p.date_naissance, p.sexe, p.groupe_sanguin, p.adresse, p.numero_assurance
       FROM utilisateurs u
       LEFT JOIN patients p ON u.id = p.utilisateur_id
       WHERE u.id = ?`,
      [utilisateurId]
    );

    res.json({
      succes: true,
      role: 'patient',
      donnees: {
        profil: patient[0] || {},
        message: `Bonjour ${req.utilisateur.prenom} ! Bienvenue sur votre espace patient.`
      }
    });
  } catch (error) {
    console.error('Erreur dashboard patient:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// TABLEAU DE BORD MÉDECIN
// GET /api/dashboard/medecin
// ─────────────────────────────────────────
const dashboardMedecin = async (req, res) => {
  try {
    const utilisateurId = req.utilisateur.id;

    // Infos du médecin
    const [medecin] = await db.query(
      `SELECT u.nom, u.prenom, u.email, u.telephone,
              m.specialite, m.numero_ordre, m.hopital_clinique, m.disponible
       FROM utilisateurs u
       LEFT JOIN medecins m ON u.id = m.utilisateur_id
       WHERE u.id = ?`,
      [utilisateurId]
    );

    // Nombre de patients enregistrés (stat simple)
    const [totalPatients] = await db.query(
      'SELECT COUNT(*) AS total FROM patients'
    );

    res.json({
      succes: true,
      role: 'medecin',
      donnees: {
        profil: medecin[0] || {},
        statistiques: {
          total_patients: totalPatients[0].total
        },
        message: `Bonjour Dr. ${req.utilisateur.prenom} ! Votre espace médecin.`
      }
    });
  } catch (error) {
    console.error('Erreur dashboard médecin:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// TABLEAU DE BORD PHARMACIEN
// GET /api/dashboard/pharmacien
// ─────────────────────────────────────────
const dashboardPharmacien = async (req, res) => {
  try {
    const utilisateurId = req.utilisateur.id;

    const [pharmacien] = await db.query(
      `SELECT u.nom, u.prenom, u.email, u.telephone,
              ph.nom_pharmacie, ph.adresse_pharmacie, ph.numero_licence
       FROM utilisateurs u
       LEFT JOIN pharmaciens ph ON u.id = ph.utilisateur_id
       WHERE u.id = ?`,
      [utilisateurId]
    );

    res.json({
      succes: true,
      role: 'pharmacien',
      donnees: {
        profil: pharmacien[0] || {},
        message: `Bonjour ${req.utilisateur.prenom} ! Votre espace pharmacien.`
      }
    });
  } catch (error) {
    console.error('Erreur dashboard pharmacien:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// TABLEAU DE BORD LIVREUR
// GET /api/dashboard/livreur
// ─────────────────────────────────────────
const dashboardLivreur = async (req, res) => {
  try {
    const utilisateurId = req.utilisateur.id;

    const [livreur] = await db.query(
      `SELECT u.nom, u.prenom, u.email, u.telephone,
              l.zone_livraison, l.vehicule, l.disponible
       FROM utilisateurs u
       LEFT JOIN livreurs l ON u.id = l.utilisateur_id
       WHERE u.id = ?`,
      [utilisateurId]
    );

    res.json({
      succes: true,
      role: 'livreur',
      donnees: {
        profil: livreur[0] || {},
        message: `Bonjour ${req.utilisateur.prenom} ! Votre espace livreur.`
      }
    });
  } catch (error) {
    console.error('Erreur dashboard livreur:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// TABLEAU DE BORD ADMIN
// GET /api/dashboard/admin
// ─────────────────────────────────────────
const dashboardAdmin = async (req, res) => {
  try {
    // Statistiques globales
    const [totalUtilisateurs] = await db.query(
      'SELECT COUNT(*) AS total FROM utilisateurs WHERE est_actif = TRUE'
    );

    const [parRole] = await db.query(
      `SELECT r.nom AS role, COUNT(u.id) AS total
       FROM roles r
       LEFT JOIN utilisateurs u ON r.id = u.role_id AND u.est_actif = TRUE
       GROUP BY r.id, r.nom`
    );

    const [derniersInscrits] = await db.query(
      `SELECT u.id, u.nom, u.prenom, u.email, r.nom AS role, u.created_at
       FROM utilisateurs u
       JOIN roles r ON u.role_id = r.id
       ORDER BY u.created_at DESC
       LIMIT 10`
    );

    const [connexionsRecentes] = await db.query(
      `SELECT l.action, l.ip_address, l.created_at,
              u.nom, u.prenom
       FROM logs_connexion l
       LEFT JOIN utilisateurs u ON l.utilisateur_id = u.id
       ORDER BY l.created_at DESC
       LIMIT 20`
    );

    res.json({
      succes: true,
      role: 'admin',
      donnees: {
        statistiques: {
          total_utilisateurs: totalUtilisateurs[0].total,
          par_role: parRole
        },
        derniers_inscrits: derniersInscrits,
        connexions_recentes: connexionsRecentes,
        message: `Bienvenue Admin ${req.utilisateur.prenom} !`
      }
    });
  } catch (error) {
    console.error('Erreur dashboard admin:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// TABLEAU DE BORD SUPERADMIN
// GET /api/dashboard/superadmin
// ─────────────────────────────────────────
const dashboardSuperAdmin = async (req, res) => {
  try {
    // Toutes les stats + gestion complète
    const [stats] = await db.query(`
      SELECT
        (SELECT COUNT(*) FROM utilisateurs) AS total_utilisateurs,
        (SELECT COUNT(*) FROM utilisateurs WHERE est_actif = FALSE) AS comptes_desactives,
        (SELECT COUNT(*) FROM logs_connexion WHERE DATE(created_at) = CURDATE()) AS connexions_aujourd_hui,
        (SELECT COUNT(*) FROM medecins) AS total_medecins,
        (SELECT COUNT(*) FROM patients) AS total_patients,
        (SELECT COUNT(*) FROM pharmaciens) AS total_pharmaciens,
        (SELECT COUNT(*) FROM livreurs) AS total_livreurs
    `);

    const [tousUtilisateurs] = await db.query(
      `SELECT u.id, u.nom, u.prenom, u.email, u.telephone, u.est_actif,
              r.nom AS role, u.created_at
       FROM utilisateurs u
       JOIN roles r ON u.role_id = r.id
       ORDER BY u.created_at DESC`
    );

    res.json({
      succes: true,
      role: 'superadmin',
      donnees: {
        statistiques: stats[0],
        tous_utilisateurs: tousUtilisateurs,
        message: `Bienvenue Super Admin ${req.utilisateur.prenom} !`
      }
    });
  } catch (error) {
    console.error('Erreur dashboard superadmin:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// ROUTE INTELLIGENTE: redirige selon le rôle
// GET /api/dashboard
// ─────────────────────────────────────────
const monDashboard = async (req, res) => {
  const role = req.utilisateur.role;

  switch (role) {
    case 'patient':     return dashboardPatient(req, res);
    case 'medecin':     return dashboardMedecin(req, res);
    case 'pharmacien':  return dashboardPharmacien(req, res);
    case 'livreur':     return dashboardLivreur(req, res);
    case 'admin':       return dashboardAdmin(req, res);
    case 'superadmin':  return dashboardSuperAdmin(req, res);
    default:
      return res.status(403).json({ succes: false, message: 'Rôle non reconnu.' });
  }
};

module.exports = {
  monDashboard,
  dashboardPatient,
  dashboardMedecin,
  dashboardPharmacien,
  dashboardLivreur,
  dashboardAdmin,
  dashboardSuperAdmin
};
