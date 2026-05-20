-- ============================================
-- SCHÉMA DE BASE DE DONNÉES - health_db
-- Exécute ce fichier dans MySQL Workbench ou phpMyAdmin
-- ============================================

CREATE DATABASE IF NOT EXISTS health_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE health_db;

-- Table des rôles
CREATE TABLE IF NOT EXISTS roles (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nom VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertion des rôles par défaut
INSERT INTO roles (nom, description) VALUES
  ('superadmin', 'Super administrateur avec tous les droits'),
  ('admin', 'Administrateur de la plateforme'),
  ('medecin', 'Médecin pouvant gérer les patients et consultations'),
  ('pharmacien', 'Pharmacien pouvant gérer les médicaments et ordonnances'),
  ('livreur', 'Livreur de médicaments'),
  ('patient', 'Patient utilisant la plateforme')
ON DUPLICATE KEY UPDATE nom=nom;

-- Table principale des utilisateurs
CREATE TABLE IF NOT EXISTS utilisateurs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  telephone VARCHAR(20),
  mot_de_passe VARCHAR(255) NOT NULL,
  role_id INT NOT NULL DEFAULT 6,  -- 6 = patient par défaut
  est_actif BOOLEAN DEFAULT TRUE,
  photo_profil VARCHAR(255),
  reset_token VARCHAR(255),        -- token pour reset mot de passe
  reset_token_expire DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (role_id) REFERENCES roles(id)
);

-- Table spécifique aux médecins
CREATE TABLE IF NOT EXISTS medecins (
  id INT PRIMARY KEY AUTO_INCREMENT,
  utilisateur_id INT NOT NULL UNIQUE,
  specialite VARCHAR(100),
  numero_ordre VARCHAR(50),        -- numéro d'ordre médical
  hopital_clinique VARCHAR(150),
  disponible BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Table spécifique aux patients
CREATE TABLE IF NOT EXISTS patients (
  id INT PRIMARY KEY AUTO_INCREMENT,
  utilisateur_id INT NOT NULL UNIQUE,
  date_naissance DATE,
  sexe ENUM('M', 'F', 'autre'),
  groupe_sanguin VARCHAR(5),
  adresse TEXT,
  numero_assurance VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Table spécifique aux pharmaciens
CREATE TABLE IF NOT EXISTS pharmaciens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  utilisateur_id INT NOT NULL UNIQUE,
  nom_pharmacie VARCHAR(150),
  adresse_pharmacie TEXT,
  numero_licence VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Table spécifique aux livreurs
CREATE TABLE IF NOT EXISTS livreurs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  utilisateur_id INT NOT NULL UNIQUE,
  zone_livraison VARCHAR(150),
  vehicule VARCHAR(100),
  disponible BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Table des logs de connexion (pour le tableau de bord admin)
CREATE TABLE IF NOT EXISTS logs_connexion (
  id INT PRIMARY KEY AUTO_INCREMENT,
  utilisateur_id INT,
  action VARCHAR(50),              -- 'login', 'logout', 'register'
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
);

-- Créer un superadmin par défaut (mot de passe: Admin@1234)
-- Tu pourras le changer après connexion
INSERT INTO utilisateurs (nom, prenom, email, mot_de_passe, role_id) VALUES
  ('Super', 'Admin', 'superadmin@health.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4oRCHHe.2e', 1)
ON DUPLICATE KEY UPDATE email=email;
