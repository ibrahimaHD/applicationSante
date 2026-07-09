const db = require('../config/database');

const ensureValidationProfessionnelsTable = async () => {
  await db.query(`
    CREATE TABLE IF NOT EXISTS validations_professionnels (
      id INT AUTO_INCREMENT PRIMARY KEY,
      utilisateur_id INT NOT NULL UNIQUE,
      role VARCHAR(50) NOT NULL,
      numero_licence VARCHAR(120),
      lieu_travail VARCHAR(255),
      diplome_url TEXT,
      document_identite_url TEXT,
      notes TEXT,
      statut ENUM('en_attente', 'approuvee', 'rejetee') NOT NULL DEFAULT 'en_attente',
      admin_id INT NULL,
      raison_rejet TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT fk_validation_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
      CONSTRAINT fk_validation_admin
        FOREIGN KEY (admin_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
    )
  `);
};

module.exports = { ensureValidationProfessionnelsTable };
