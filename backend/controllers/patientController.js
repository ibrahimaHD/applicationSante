const db = require('../config/database');
 
// Convertir JJ/MM/AAAA → AAAA-MM-JJ pour MySQL
const convertirDate = (date) => {
  if (!date) return null;
  if (date.includes('/')) {
    const [jour, mois, annee] = date.split('/');
    return `${annee}-${mois}-${jour}`;
  }
  return date;
};
 
// ─────────────────────────────────────────
// PROFIL MÉDICAL
// ─────────────────────────────────────────
 
const getProfilMedical = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM profils_medicaux WHERE utilisateur_id = ?',
      [req.utilisateur.id]
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
      allergies, antecedents, medicaments_actuels, 
      medecin_traitant, numero_assurance
    } = req.body;

    const dateConverti = convertirDate(date_naissance);

    // ✅ Utiliser INSERT ... ON DUPLICATE KEY UPDATE
    // pour éviter tout problème de doublon
    await db.query(
      `INSERT INTO profils_medicaux 
        (utilisateur_id, groupe_sanguin, sexe, date_naissance,
         taille, poids, allergies, antecedents, medicaments_actuels,
         medecin_traitant, numero_assurance)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         groupe_sanguin        = VALUES(groupe_sanguin),
         sexe                  = VALUES(sexe),
         date_naissance        = VALUES(date_naissance),
         taille                = VALUES(taille),
         poids                 = VALUES(poids),
         allergies             = VALUES(allergies),
         antecedents           = VALUES(antecedents),
         medicaments_actuels   = VALUES(medicaments_actuels),
         medecin_traitant      = VALUES(medecin_traitant),
         numero_assurance      = VALUES(numero_assurance)`,
      [
        patientId, groupe_sanguin, sexe, dateConverti,
        taille, poids, allergies, antecedents,
        medicaments_actuels, medecin_traitant, numero_assurance
      ]
    );

    res.json({ succes: true, message: 'Profil médical sauvegardé !' });

  } catch (error) {
    console.error('Erreur sauvegarderProfilMedical:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur: ' + error.message });
  }
};
 
// ─────────────────────────────────────────
// CARNET DE SANTÉ
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
      [req.utilisateur.id, medecin_nom, motif, diagnostic, traitement, notes, convertirDate(date_consultation)]
    );
    res.status(201).json({ succes: true, message: 'Consultation ajoutée !' });
  } catch (error) {
    console.error(error);
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
      'SELECT * FROM vaccinations WHERE patient_id = ? ORDER BY created_at DESC',
      [req.utilisateur.id]
    );
    res.json({ succes: true, vaccinations: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
const ajouterVaccination = async (req, res) => {
  try {
    const { nom_vaccin, dose, date_administration, prochain_rappel, administre_par, statut } = req.body;
    if (!nom_vaccin) {
      return res.status(400).json({ succes: false, message: 'Nom du vaccin requis.' });
    }
    await db.query(
      `INSERT INTO vaccinations (patient_id, nom_vaccin, dose, date_vaccination, prochain_rappel, medecin, statut)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id, nom_vaccin, dose,
       convertirDate(date_administration),
       convertirDate(prochain_rappel),
       administre_par, statut || 'fait']
    );
    res.status(201).json({ succes: true, message: 'Vaccination ajoutée !' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
const mettreAJourVaccination = async (req, res) => {
  try {
    const { statut, date_administration, prochain_rappel } = req.body;
    await db.query(
      'UPDATE vaccinations SET statut=?, date_vaccination=?, prochain_rappel=? WHERE id=? AND patient_id=?',
      [statut, convertirDate(date_administration), convertirDate(prochain_rappel), req.params.id, req.utilisateur.id]
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
      'SELECT * FROM rappels WHERE patient_id = ? ORDER BY created_at DESC',
      [req.utilisateur.id]
    );
    res.json({ succes: true, rappels: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
const ajouterRappel = async (req, res) => {
  try {
    const { titre, description, type, date_rappel, heure_rappel } = req.body;
    if (!titre || !type) {
      return res.status(400).json({ succes: false, message: 'Titre et type requis.' });
    }
    await db.query(
      `INSERT INTO rappels (patient_id, titre, description, type, date_rappel, heure_rappel)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id, titre, description, type, date_rappel, heure_rappel]
    );
    res.status(201).json({ succes: true, message: 'Rappel créé !' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
const toggleRappel = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT est_actif FROM rappels WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ succes: false, message: 'Rappel introuvable.' });
    }
    const nouvelEtat = !rows[0].est_actif;
    await db.query('UPDATE rappels SET est_actif = ? WHERE id = ?', [nouvelEtat, req.params.id]);
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
// ──────────────────────────────────────-
 
const getGrossesse = async (req, res) => {
  try {
    const [grossesse] = await db.query(
      'SELECT * FROM suivis_grossesse WHERE patient_id = ? ORDER BY created_at DESC LIMIT 1',
      [req.utilisateur.id]
    );
    if (grossesse.length === 0) {
      return res.json({ succes: true, grossesse: null, consultations: [] });
    }
    const [consultations] = await db.query(
      'SELECT * FROM consultations_prenatales WHERE suivi_id = ? ORDER BY semaine ASC',
      [grossesse[0].id]
    );
    res.json({ succes: true, grossesse: grossesse[0], consultations });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
const creerGrossesse = async (req, res) => {
  try {
    const { date_debut, date_accouchement_prevue } = req.body;
    if (!date_debut) {
      return res.status(400).json({ succes: false, message: 'Date de début requise.' });
    }
 
    const [result] = await db.query(
      'INSERT INTO suivis_grossesse (patient_id, date_debut, date_accouchement_prevue) VALUES (?, ?, ?)',
      [req.utilisateur.id, convertirDate(date_debut), convertirDate(date_accouchement_prevue)]
    );
 
    const calendrier = [
      { semaine: 8,  type: 'Échographie 1er trimestre' },
      { semaine: 12, type: 'Bilan sanguin' },
      { semaine: 20, type: 'Échographie morphologique' },
      { semaine: 28, type: 'Échographie 3ème trimestre' },
      { semaine: 32, type: 'Consultation prénatale' },
      { semaine: 36, type: 'Préparation à l\'accouchement' },
    ];
 
    for (const c of calendrier) {
      await db.query(
        'INSERT INTO consultations_prenatales (suivi_id, semaine, type_consultation, statut) VALUES (?, ?, ?, ?)',
        [result.insertId, c.semaine, c.type, 'a_venir']
      );
    }
 
    res.status(201).json({ succes: true, message: 'Suivi de grossesse créé !', id: result.insertId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
const mettreAJourGrossesse = async (req, res) => {
  try {
    const { semaine_actuelle, poids_actuel, tension, glycemie, notes } = req.body;
    await db.query(
      `UPDATE suivis_grossesse SET semaine_actuelle=?, poids_actuel=?, tension=?, glycemie=?, notes=?
       WHERE patient_id=? ORDER BY created_at DESC LIMIT 1`,
      [semaine_actuelle, poids_actuel, tension, glycemie, notes, req.utilisateur.id]
    );
    res.json({ succes: true, message: 'Suivi mis à jour !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
// ─────────────────────────────────────────
// ENFANTS
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
      [req.utilisateur.id, nom, prenom, convertirDate(date_naissance), sexe]
    );
 
    const vaccinsRecommandes = ['BCG', 'Hépatite B (1)', 'Pentavalent (1)', 'Pentavalent (2)', 'Pentavalent (3)', 'Rougeole', 'Méningite A'];
    for (const vaccin of vaccinsRecommandes) {
      await db.query(
        'INSERT INTO vaccinations_enfants (enfant_id, nom_vaccin, statut) VALUES (?, ?, ?)',
        [result.insertId, vaccin, 'non_fait']
      );
    }
 
    res.status(201).json({ succes: true, message: 'Enfant ajouté !', id: result.insertId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
const mettreAJourVaccinEnfant = async (req, res) => {
  try {
    const { statut, date_administration } = req.body;
    await db.query(
      'UPDATE vaccinations_enfants SET statut=?, date_vaccination=? WHERE id=?',
      [statut, convertirDate(date_administration), req.params.id]
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
    const [profil] = await db.query('SELECT * FROM profils_medicaux WHERE utilisateur_id = ?', [patientId]);
    const [consultations] = await db.query('SELECT * FROM consultations WHERE patient_id = ? ORDER BY date_consultation DESC', [patientId]);
    const [vaccinations] = await db.query('SELECT * FROM vaccinations WHERE patient_id = ?', [patientId]);
    const [utilisateur] = await db.query('SELECT nom, prenom, email, telephone FROM utilisateurs WHERE id = ?', [patientId]);
 
    res.json({
      succes: true,
      dossier: {
        patient: utilisateur[0],
        profil_medical: profil[0] || {},
        consultations,
        vaccinations,
        examens: [],
        ordonnances: [],
        derniere_sync: new Date().toISOString(),
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};
 
const getExamens = async (req, res) => {
  res.json({ succes: true, examens: [] });
};
 
const ajouterExamen = async (req, res) => {
  res.json({ succes: true, message: 'Fonctionnalité bientôt disponible.' });
};
 
const getOrdonnances = async (req, res) => {
  res.json({ succes: true, ordonnances: [] });
};
 
const getInfosPersonnelles = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.nom, u.prenom, u.email, u.telephone,
              p.adresse, p.date_naissance, p.sexe, p.groupe_sanguin
       FROM utilisateurs u
       LEFT JOIN patients p ON u.id = p.utilisateur_id
       WHERE u.id = ?`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, infos: rows[0] });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const majInfosPersonnelles = async (req, res) => {
  try {
    const { nom, prenom, telephone, adresse } = req.body;

    // Mettre à jour utilisateurs
    await db.query(
      'UPDATE utilisateurs SET nom=?, prenom=?, telephone=? WHERE id=?',
      [nom, prenom, telephone, req.utilisateur.id]
    );

    // ✅ Utiliser INSERT ... ON DUPLICATE KEY UPDATE
    // pour la table patients aussi
    await db.query(
      `INSERT INTO patients (utilisateur_id, adresse)
       VALUES (?, ?)
       ON DUPLICATE KEY UPDATE adresse = VALUES(adresse)`,
      [req.utilisateur.id, adresse]
    );

    res.json({ succes: true, message: 'Informations mises à jour !' });

  } catch (error) {
    console.error('Erreur majInfosPersonnelles:', error);
    res.status(500).json({
      succes: false,
      message: 'Erreur serveur: ' + error.message
    });
  }
};
module.exports = {
  getProfilMedical, sauvegarderProfilMedical,
  getInfosPersonnelles, majInfosPersonnelles,
  getConsultations, ajouterConsultation, supprimerConsultation,
  getVaccinations, ajouterVaccination, mettreAJourVaccination,
  getRappels, ajouterRappel, toggleRappel, supprimerRappel,
  getGrossesse, creerGrossesse, mettreAJourGrossesse,
  getEnfants, ajouterEnfant, mettreAJourVaccinEnfant,
  getDossierMedical, getExamens, ajouterExamen, getOrdonnances,
};