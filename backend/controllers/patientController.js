// controllers/patientController.js
const db = require('../config/database');

// ─────────────────────────────────────────
// PROFIL MÉDICAL
// ─────────────────────────────────────────

const getProfilMedical = async (req, res) => {
  try {
    const patientId = req.utilisateur.id;
    const [rows] = await db.query(
      'SELECT * FROM profils_medicaux WHERE patient_id = ?',
      [patientId]
    );
    res.json({ succes: true, profil: rows[0] || null });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const sauvegarderProfilMedical = async (req, res) => {
  try {
    const patientId = req.utilisateur.id;
    const {
      groupe_sanguin, sexe, date_naissance, taille, poids,
      allergies, antecedents, medicaments_actuels, medecin_traitant, numero_assurance
    } = req.body;

    const [existant] = await db.query(
      'SELECT id FROM profils_medicaux WHERE patient_id = ?',
      [patientId]
    );

    if (existant.length > 0) {
      await db.query(
        `UPDATE profils_medicaux SET groupe_sanguin=?, sexe=?, date_naissance=?,
         taille=?, poids=?, allergies=?, antecedents=?, medicaments_actuels=?,
         medecin_traitant=?, numero_assurance=? WHERE patient_id=?`,
        [groupe_sanguin, sexe, date_naissance, taille, poids,
         allergies, antecedents, medicaments_actuels, medecin_traitant, numero_assurance, patientId]
      );
    } else {
      await db.query(
        `INSERT INTO profils_medicaux (patient_id, groupe_sanguin, sexe, date_naissance,
         taille, poids, allergies, antecedents, medicaments_actuels, medecin_traitant, numero_assurance)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [patientId, groupe_sanguin, sexe, date_naissance, taille, poids,
         allergies, antecedents, medicaments_actuels, medecin_traitant, numero_assurance]
      );
    }

    res.json({ succes: true, message: 'Profil médical sauvegardé !' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// CARNET DE SANTÉ (CONSULTATIONS)
// ─────────────────────────────────────────

const getConsultations = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM consultations WHERE patient_id = ? ORDER BY date_consultation DESC',
      [req.utilisateur.id]
    );
    res.json({ succes: true, consultations: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const ajouterConsultation = async (req, res) => {
  try {
    const { medecin_nom, motif, diagnostic, traitement, notes, date_consultation } = req.body;
    if (!motif || !date_consultation) {
      return res.status(400).json({ succes: false, message: 'Motif et date requis.' });
    }
    await db.query(
      `INSERT INTO consultations (patient_id, medecin_nom, motif, diagnostic, traitement, notes, date_consultation)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id, medecin_nom, motif, diagnostic, traitement, notes, date_consultation]
    );
    res.status(201).json({ succes: true, message: 'Consultation ajoutée !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const supprimerConsultation = async (req, res) => {
  try {
    await db.query(
      'DELETE FROM consultations WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    res.json({ succes: true, message: 'Consultation supprimée.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// VACCINATIONS
// ─────────────────────────────────────────

const getVaccinations = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM vaccinations WHERE patient_id = ? ORDER BY date_administration DESC',
      [req.utilisateur.id]
    );
    res.json({ succes: true, vaccinations: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const ajouterVaccination = async (req, res) => {
  try {
    const { nom_vaccin, dose, date_administration, prochain_rappel, administre_par, lieu, statut } = req.body;
    if (!nom_vaccin) {
      return res.status(400).json({ succes: false, message: 'Nom du vaccin requis.' });
    }
    await db.query(
      `INSERT INTO vaccinations (patient_id, nom_vaccin, dose, date_administration, prochain_rappel, administre_par, lieu, statut)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id, nom_vaccin, dose, date_administration, prochain_rappel, administre_par, lieu, statut || 'fait']
    );
    res.status(201).json({ succes: true, message: 'Vaccination ajoutée !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const mettreAJourVaccination = async (req, res) => {
  try {
    const { statut, date_administration, prochain_rappel } = req.body;
    await db.query(
      'UPDATE vaccinations SET statut=?, date_administration=?, prochain_rappel=? WHERE id=? AND patient_id=?',
      [statut, date_administration, prochain_rappel, req.params.id, req.utilisateur.id]
    );
    res.json({ succes: true, message: 'Vaccination mise à jour !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// RAPPELS
// ─────────────────────────────────────────

const getRappels = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM rappels WHERE patient_id = ? ORDER BY date_rappel ASC',
      [req.utilisateur.id]
    );
    res.json({ succes: true, rappels: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const ajouterRappel = async (req, res) => {
  try {
    const { titre, description, type, frequence, date_rappel, heure_rappel } = req.body;
    if (!titre || !type) {
      return res.status(400).json({ succes: false, message: 'Titre et type requis.' });
    }
    await db.query(
      `INSERT INTO rappels (patient_id, titre, description, type, frequence, date_rappel, heure_rappel)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id, titre, description, type, frequence || 'unique', date_rappel, heure_rappel]
    );
    res.status(201).json({ succes: true, message: 'Rappel créé !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const toggleRappel = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT actif FROM rappels WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ succes: false, message: 'Rappel introuvable.' });
    }
    const nouvelEtat = !rows[0].actif;
    await db.query('UPDATE rappels SET actif = ? WHERE id = ?', [nouvelEtat, req.params.id]);
    res.json({ succes: true, actif: nouvelEtat });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const supprimerRappel = async (req, res) => {
  try {
    await db.query('DELETE FROM rappels WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]);
    res.json({ succes: true, message: 'Rappel supprimé.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// SUIVI GROSSESSE
// ─────────────────────────────────────────

const getGrossesse = async (req, res) => {
  try {
    const [grossesse] = await db.query(
      'SELECT * FROM suivis_grossesse WHERE patient_id = ? AND actif = TRUE ORDER BY created_at DESC LIMIT 1',
      [req.utilisateur.id]
    );
    if (grossesse.length === 0) {
      return res.json({ succes: true, grossesse: null });
    }
    const [consultations] = await db.query(
      'SELECT * FROM consultations_prenatales WHERE grossesse_id = ? ORDER BY semaine ASC',
      [grossesse[0].id]
    );
    res.json({ succes: true, grossesse: grossesse[0], consultations });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const creerGrossesse = async (req, res) => {
  try {
    const { date_debut, date_terme } = req.body;
    if (!date_debut) {
      return res.status(400).json({ succes: false, message: 'Date de début requise.' });
    }
    // Désactiver les grossesses précédentes
    await db.query('UPDATE suivis_grossesse SET actif = FALSE WHERE patient_id = ?', [req.utilisateur.id]);

    const [result] = await db.query(
      'INSERT INTO suivis_grossesse (patient_id, date_debut, date_terme) VALUES (?, ?, ?)',
      [req.utilisateur.id, date_debut, date_terme]
    );

    // Créer le calendrier prénatal automatiquement
    const calendrier = [
      { semaine: 8, type: 'Échographie 1er trimestre' },
      { semaine: 12, type: 'Bilan sanguin' },
      { semaine: 20, type: 'Échographie morphologique' },
      { semaine: 28, type: 'Échographie 3ème trimestre' },
      { semaine: 32, type: 'Consultation prénatale' },
      { semaine: 36, type: 'Préparation à l\'accouchement' },
    ];

    for (const c of calendrier) {
      await db.query(
        'INSERT INTO consultations_prenatales (grossesse_id, semaine, type, statut) VALUES (?, ?, ?, ?)',
        [result.insertId, c.semaine, c.type, 'a_venir']
      );
    }

    res.status(201).json({ succes: true, message: 'Suivi de grossesse créé !', id: result.insertId });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const mettreAJourGrossesse = async (req, res) => {
  try {
    const { semaine_actuelle, poids_actuel, tension, glycemie, notes } = req.body;
    await db.query(
      `UPDATE suivis_grossesse SET semaine_actuelle=?, poids_actuel=?, tension=?, glycemie=?, notes=?
       WHERE patient_id=? AND actif=TRUE`,
      [semaine_actuelle, poids_actuel, tension, glycemie, notes, req.utilisateur.id]
    );
    res.json({ succes: true, message: 'Suivi mis à jour !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// ENFANTS & VACCINATIONS ENFANTS
// ─────────────────────────────────────────

const getEnfants = async (req, res) => {
  try {
    const [enfants] = await db.query(
      'SELECT * FROM enfants WHERE parent_id = ?',
      [req.utilisateur.id]
    );
    for (const enfant of enfants) {
      const [vaccins] = await db.query(
        'SELECT * FROM vaccinations_enfants WHERE enfant_id = ?',
        [enfant.id]
      );
      enfant.vaccinations = vaccins;
    }
    res.json({ succes: true, enfants });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const ajouterEnfant = async (req, res) => {
  try {
    const { nom, prenom, date_naissance, sexe } = req.body;
    if (!nom || !date_naissance || !sexe) {
      return res.status(400).json({ succes: false, message: 'Nom, date de naissance et sexe requis.' });
    }
    const [result] = await db.query(
      'INSERT INTO enfants (parent_id, nom, prenom, date_naissance, sexe) VALUES (?, ?, ?, ?, ?)',
      [req.utilisateur.id, nom, prenom, date_naissance, sexe]
    );

    // Vaccins recommandés automatiquement
    const vaccinsRecommandes = ['BCG', 'Hépatite B (1)', 'Pentavalent (1)', 'Pentavalent (2)', 'Pentavalent (3)', 'Rougeole', 'Méningite A'];
    for (const vaccin of vaccinsRecommandes) {
      await db.query(
        'INSERT INTO vaccinations_enfants (enfant_id, nom_vaccin, statut) VALUES (?, ?, ?)',
        [result.insertId, vaccin, 'non_fait']
      );
    }

    res.status(201).json({ succes: true, message: 'Enfant ajouté !', id: result.insertId });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const mettreAJourVaccinEnfant = async (req, res) => {
  try {
    const { statut, date_administration } = req.body;
    await db.query(
      'UPDATE vaccinations_enfants SET statut=?, date_administration=? WHERE id=?',
      [statut, date_administration, req.params.id]
    );
    res.json({ succes: true, message: 'Vaccination mise à jour !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ─────────────────────────────────────────
// DOSSIER MÉDICAL COMPLET
// ─────────────────────────────────────────

const getDossierMedical = async (req, res) => {
  try {
    const patientId = req.utilisateur.id;

    const [profil] = await db.query('SELECT * FROM profils_medicaux WHERE patient_id = ?', [patientId]);
    const [consultations] = await db.query('SELECT * FROM consultations WHERE patient_id = ? ORDER BY date_consultation DESC', [patientId]);
    const [vaccinations] = await db.query('SELECT * FROM vaccinations WHERE patient_id = ?', [patientId]);
    const [examens] = await db.query('SELECT * FROM examens WHERE patient_id = ? ORDER BY date_examen DESC', [patientId]);
    const [ordonnances] = await db.query('SELECT * FROM ordonnances WHERE patient_id = ? ORDER BY date_ordonnance DESC', [patientId]);
    const [utilisateur] = await db.query('SELECT nom, prenom, email, telephone FROM utilisateurs WHERE id = ?', [patientId]);

    res.json({
      succes: true,
      dossier: {
        patient: utilisateur[0],
        profil_medical: profil[0] || null,
        consultations,
        vaccinations,
        examens,
        ordonnances,
        derniere_sync: new Date().toISOString(),
      }
    });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// Examens
const getExamens = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM examens WHERE patient_id = ? ORDER BY date_examen DESC', [req.utilisateur.id]);
    res.json({ succes: true, examens: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const ajouterExamen = async (req, res) => {
  try {
    const { type_examen, resultat, statut, date_examen, medecin_nom } = req.body;
    if (!type_examen || !date_examen) {
      return res.status(400).json({ succes: false, message: 'Type et date requis.' });
    }
    await db.query(
      'INSERT INTO examens (patient_id, type_examen, resultat, statut, date_examen, medecin_nom) VALUES (?, ?, ?, ?, ?, ?)',
      [req.utilisateur.id, type_examen, resultat, statut || 'normal', date_examen, medecin_nom]
    );
    res.status(201).json({ succes: true, message: 'Examen ajouté !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// Ordonnances
const getOrdonnances = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM ordonnances WHERE patient_id = ? ORDER BY date_ordonnance DESC', [req.utilisateur.id]);
    res.json({ succes: true, ordonnances: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getProfilMedical, sauvegarderProfilMedical,
  getConsultations, ajouterConsultation, supprimerConsultation,
  getVaccinations, ajouterVaccination, mettreAJourVaccination,
  getRappels, ajouterRappel, toggleRappel, supprimerRappel,
  getGrossesse, creerGrossesse, mettreAJourGrossesse,
  getEnfants, ajouterEnfant, mettreAJourVaccinEnfant,
  getDossierMedical, getExamens, ajouterExamen,
  getOrdonnances,
};
