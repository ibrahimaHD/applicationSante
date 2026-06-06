// ── PROFIL MÉDECIN ──────────────────────────────────────
const getMonProfil = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.*, m.specialite, m.numero_ordre, m.hopital_clinique, m.disponible
       FROM utilisateurs u
       LEFT JOIN medecins m ON u.id = m.utilisateur_id
       WHERE u.id = ?`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, profil: rows[0] });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── MES PATIENTS ────────────────────────────────────────
const getMesPatients = async (req, res) => {
  try {
    // Patients ayant eu au moins une consultation avec ce médecin
    const [rows] = await db.query(
      `SELECT DISTINCT u.id, u.nom, u.prenom, u.email, u.telephone,
              p.date_naissance, p.groupe_sanguin,
              pm.allergies, pm.antecedents,
              MAX(c.date_consultation) AS derniere_consultation
       FROM utilisateurs u
       JOIN consultations c ON u.id = c.patient_id
       LEFT JOIN patients p ON u.id = p.utilisateur_id
       LEFT JOIN profils_medicaux pm ON u.id = pm.utilisateur_id
       WHERE c.medecin_id = ?
       GROUP BY u.id
       ORDER BY derniere_consultation DESC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, patients: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getDossierPatient = async (req, res) => {
  try {
    const patientId = req.params.patientId;

    const [patient] = await db.query(
      `SELECT u.*, p.date_naissance, p.sexe, p.groupe_sanguin, p.adresse,
              pm.allergies, pm.antecedents, pm.medicaments_actuels, pm.medecin_traitant
       FROM utilisateurs u
       LEFT JOIN patients p ON u.id = p.utilisateur_id
       LEFT JOIN profils_medicaux pm ON u.id = pm.utilisateur_id
       WHERE u.id = ?`,
      [patientId]
    );

    const [consultations] = await db.query(
      'SELECT * FROM consultations WHERE patient_id = ? ORDER BY date_consultation DESC',
      [patientId]
    );

    const [vaccinations] = await db.query(
      'SELECT * FROM vaccinations WHERE patient_id = ? ORDER BY created_at DESC',
      [patientId]
    );

    const [ordonnances] = await db.query(
      'SELECT * FROM ordonnances WHERE patient_id = ? ORDER BY date_ordonnance DESC',
      [patientId]
    );

    const [examens] = await db.query(
      'SELECT * FROM examens WHERE patient_id = ? ORDER BY date_examen DESC',
      [patientId]
    );

    // Enregistrer audit
    await db.query(
      'INSERT INTO audits_acces (patient_id, accede_par, role_acces, type_acces) VALUES (?, ?, ?, ?)',
      [patientId, req.utilisateur.id, 'medecin', 'Consultation dossier médical']
    );

    res.json({
      succes: true,
      dossier: { patient: patient[0], consultations, vaccinations, ordonnances, examens }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── CONSULTATIONS ───────────────────────────────────────
const ajouterConsultation = async (req, res) => {
  try {
    const { patient_id, motif, diagnostic, traitement, notes, date_consultation, rdv_id } = req.body;

    if (!patient_id || !motif || !date_consultation) {
      return res.status(400).json({ succes: false, message: 'Patient, motif et date requis.' });
    }

    const [result] = await db.query(
      `INSERT INTO consultations (patient_id, medecin_id, medecin_nom, motif, diagnostic, traitement, notes, date_consultation)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [patient_id, req.utilisateur.id,
       `Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom}`,
       motif, diagnostic, traitement, notes, date_consultation]
    );

    // Marquer le RDV comme terminé
    if (rdv_id) {
      await db.query('UPDATE rendez_vous SET statut = ? WHERE id = ?', ['termine', rdv_id]);
    }

    res.status(201).json({ succes: true, message: 'Consultation ajoutée !', id: result.insertId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── ORDONNANCES ─────────────────────────────────────────
const creerOrdonnance = async (req, res) => {
  try {
    const { patient_id, medicaments, instructions, consultation_id } = req.body;

    if (!patient_id || !medicaments) {
      return res.status(400).json({ succes: false, message: 'Patient et médicaments requis.' });
    }

    await db.query(
      `INSERT INTO ordonnances (patient_id, medecin_id, consultation_id, medicaments, instructions, date_ordonnance)
       VALUES (?, ?, ?, ?, ?, CURDATE())`,
      [patient_id, req.utilisateur.id, consultation_id, medicaments, instructions]
    );

    res.status(201).json({ succes: true, message: 'Ordonnance créée !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getMesOrdonnances = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT o.*, u.nom AS patient_nom, u.prenom AS patient_prenom
       FROM ordonnances o
       JOIN utilisateurs u ON o.patient_id = u.id
       WHERE o.medecin_id = ?
       ORDER BY o.date_ordonnance DESC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, ordonnances: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── EXAMENS / RÉSULTATS ─────────────────────────────────
const ajouterExamen = async (req, res) => {
  try {
    const { patient_id, type_examen, resultat, statut, date_examen } = req.body;

    if (!patient_id || !type_examen || !date_examen) {
      return res.status(400).json({ succes: false, message: 'Patient, type et date requis.' });
    }

    await db.query(
      `INSERT INTO examens (patient_id, medecin_id, type_examen, resultat, statut, date_examen)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [patient_id, req.utilisateur.id, type_examen, resultat, statut || 'normal', date_examen]
    );

    // Ajouter aussi dans résultats_medicaux pour que le patient voit
    await db.query(
      `INSERT INTO resultats_medicaux (patient_id, type, titre, description, date_resultat, medecin, statut)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [patient_id, 'analyse', type_examen, resultat,
       date_examen, `Dr. ${req.utilisateur.prenom} ${req.utilisateur.nom}`, statut || 'normal']
    );

    res.status(201).json({ succes: true, message: 'Examen ajouté !' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── RAPPELS POUR PATIENTS ───────────────────────────────
const creerRappelPatient = async (req, res) => {
  try {
    const { patient_id, titre, description, type, date_rappel, heure_rappel } = req.body;

    if (!patient_id || !titre || !type) {
      return res.status(400).json({ succes: false, message: 'Patient, titre et type requis.' });
    }

    await db.query(
      `INSERT INTO rappels (patient_id, titre, description, type, date_rappel, heure_rappel)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [patient_id, titre, description, type, date_rappel, heure_rappel]
    );

    res.status(201).json({ succes: true, message: 'Rappel créé pour le patient !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── QR CODE ACCÈS DOSSIER ───────────────────────────────
const genererQrCode = async (req, res) => {
  try {
    const { patient_id } = req.body;
    const token = crypto.randomBytes(32).toString('hex');
    const expiration = new Date(Date.now() + 3600000); // 1 heure

    await db.query(
      'INSERT INTO qr_acces (patient_id, token, expire_at) VALUES (?, ?, ?)',
      [patient_id, token, expiration]
    );

    res.json({
      succes: true,
      token,
      qr_url: `${process.env.APP_URL || 'http://localhost:3000'}/api/medecin/qr/${token}`,
      expire_at: expiration
    });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const scannerQrCode = async (req, res) => {
  try {
    const { token } = req.params;

    const [rows] = await db.query(
      'SELECT * FROM qr_acces WHERE token = ? AND expire_at > NOW() AND utilise = FALSE',
      [token]
    );

    if (rows.length === 0) {
      return res.status(400).json({ succes: false, message: 'QR Code invalide ou expiré.' });
    }

    await db.query('UPDATE qr_acces SET utilise = TRUE WHERE token = ?', [token]);

    // Rediriger vers le dossier du patient
    res.redirect(`/api/medecin/patients/${rows[0].patient_id}/dossier`);
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── RENDEZ-VOUS MÉDECIN ─────────────────────────────────
const getMesRdv = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.*, u.nom AS patient_nom, u.prenom AS patient_prenom, u.telephone AS patient_tel
       FROM rendez_vous r
       JOIN utilisateurs u ON r.patient_id = u.id
       WHERE r.medecin_id = ?
       ORDER BY r.date_rdv ASC, r.heure_rdv ASC`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, rendez_vous: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const majStatutRdv = async (req, res) => {
  try {
    const { statut, notes_medecin } = req.body;
    await db.query(
      'UPDATE rendez_vous SET statut = ?, notes_medecin = ? WHERE id = ? AND medecin_id = ?',
      [statut, notes_medecin, req.params.id, req.utilisateur.id]
    );
    res.json({ succes: true, message: `Rendez-vous ${statut} !` });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getMonProfil, getMesPatients, getDossierPatient,
  ajouterConsultation, creerOrdonnance, getMesOrdonnances,
  ajouterExamen, creerRappelPatient,
  genererQrCode, scannerQrCode,
  getMesRdv, majStatutRdv,
};