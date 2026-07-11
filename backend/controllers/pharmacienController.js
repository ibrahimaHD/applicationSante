const db = require('../config/database');

// ── Helper : récupérer l'ID pharmacien ──────────────────────────────
const getPharmacienId = async (utilisateurId) => {
  const [rows] = await db.query(
    'SELECT id FROM pharmaciens WHERE utilisateur_id = ?',
    [utilisateurId]
  );
  return rows[0]?.id || null;
};

const choisirLivreurDisponible = async () => {
  const [rows] = await db.query(
    `SELECT u.id
     FROM utilisateurs u
     JOIN livreurs l ON u.id = l.utilisateur_id
     LEFT JOIN commandes c
       ON c.livreur_id = u.id
      AND c.statut IN ('en_livraison', 'confirmee', 'en_preparation')
     WHERE u.est_actif = TRUE
       AND l.disponible = TRUE
     GROUP BY u.id
     ORDER BY COUNT(c.id) ASC, u.id ASC
     LIMIT 1`
  );
  return rows[0]?.id || null;
};

// ── PROFIL ───────────────────────────────────────────────────────────
const getMonProfil = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.nom, u.prenom, u.email, u.telephone, u.photo_profil,
              p.nom_pharmacie, p.adresse_pharmacie, p.numero_licence
       FROM utilisateurs u
       LEFT JOIN pharmaciens p ON u.id = p.utilisateur_id
       WHERE u.id = ?`,
      [req.utilisateur.id]
    );
    res.json({ succes: true, profil: rows[0] || {} });
  } catch (e) {
    console.error('getMonProfil:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const majProfil = async (req, res) => {
  try {
    const { nom, prenom, telephone, nom_pharmacie, adresse_pharmacie } = req.body;
    await db.query(
      'UPDATE utilisateurs SET nom=?, prenom=?, telephone=? WHERE id=?',
      [nom, prenom, telephone, req.utilisateur.id]
    );
    await db.query(
      'UPDATE pharmaciens SET nom_pharmacie=?, adresse_pharmacie=? WHERE utilisateur_id=?',
      [nom_pharmacie, adresse_pharmacie, req.utilisateur.id]
    );
    res.json({ succes: true, message: 'Profil mis à jour !' });
  } catch (e) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── STOCK MÉDICAMENTS ────────────────────────────────────────────────
const getStock = async (req, res) => {
  try {
    const { search, categorie } = req.query;
    let query = `SELECT * FROM medicaments WHERE est_actif = TRUE`;
    const params = [];
    if (search) { query += ' AND nom LIKE ?'; params.push(`%${search}%`); }
    if (categorie) { query += ' AND categorie = ?'; params.push(categorie); }
    query += ' ORDER BY nom ASC';
    const [rows] = await db.query(query, params);

    const [categories] = await db.query(
      'SELECT DISTINCT categorie FROM medicaments WHERE est_actif = TRUE ORDER BY categorie ASC'
    );

    // Stats
    const total      = rows.length;
    const rupture    = rows.filter(m => (m.stock || 0) === 0).length;
    const faible     = rows.filter(m => (m.stock || 0) > 0 && (m.stock || 0) <= 10).length;
    const disponible = rows.filter(m => (m.stock || 0) > 10).length;

    res.json({
      succes: true,
      medicaments: rows,
      categories: categories.map(c => c.categorie),
      stats: { total, rupture, faible, disponible },
    });
  } catch (e) {
    console.error('getStock:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const ajouterMedicament = async (req, res) => {
  try {
    const { nom, description, categorie, prix, stock, ordonnance_requise, dosage } = req.body;
    if (!nom || prix === undefined) {
      return res.status(400).json({ succes: false, message: 'Nom et prix requis.' });
    }
    await db.query(
      `INSERT INTO medicaments (nom, description, categorie, prix, stock, ordonnance_requise, dosage, est_actif, disponible_livraison)
       VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)`,
      [nom, description || null, categorie || 'Général', prix, stock || 0,
       ordonnance_requise ? 1 : 0, dosage || null]
    );
    res.status(201).json({ succes: true, message: 'Médicament ajouté !' });
  } catch (e) {
    console.error('ajouterMedicament:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const majStock = async (req, res) => {
  try {
    const { stock, prix } = req.body;
    const updates = [];
    const params  = [];
    if (stock !== undefined) { updates.push('stock = ?'); params.push(stock); }
    if (prix  !== undefined) { updates.push('prix = ?');  params.push(prix);  }
    if (updates.length === 0) {
      return res.status(400).json({ succes: false, message: 'Rien à mettre à jour.' });
    }
    params.push(req.params.id);
    await db.query(`UPDATE medicaments SET ${updates.join(', ')} WHERE id = ?`, params);
    res.json({ succes: true, message: 'Stock mis à jour !' });
  } catch (e) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── COMMANDES ────────────────────────────────────────────────────────
const getCommandes = async (req, res) => {
  try {
    const { statut } = req.query;
    let query = `
      SELECT c.*,
             u.nom AS patient_nom, u.prenom AS patient_prenom, u.telephone AS patient_tel
      FROM commandes c
      JOIN utilisateurs u ON c.patient_id = u.id
      WHERE 1=1`;
    const params = [];
    if (statut) { query += ' AND c.statut = ?'; params.push(statut); }
    query += ' ORDER BY c.created_at DESC';

    const [commandes] = await db.query(query, params);

    for (const commande of commandes) {
      const [articles] = await db.query(
        `SELECT ca.*, m.nom AS medicament_nom, m.prix AS prix_unitaire_actuel
         FROM commande_articles ca
         JOIN medicaments m ON ca.medicament_id = m.id
         WHERE ca.commande_id = ?`,
        [commande.id]
      );
      commande.articles = articles;
    }

    const stats = {
      en_attente:    commandes.filter(c => c.statut === 'en_attente').length,
      en_cours:      commandes.filter(c => ['confirmee','en_preparation','en_livraison'].includes(c.statut)).length,
      livrees:       commandes.filter(c => c.statut === 'livree').length,
      total:         commandes.length,
    };

    res.json({ succes: true, commandes, stats });
  } catch (e) {
    console.error('getCommandes:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const majStatutCommande = async (req, res) => {
  try {
    const { statut, livreur_id } = req.body;
    const statutsValides = ['confirmee','en_preparation','en_livraison','livree','annulee'];
    if (!statutsValides.includes(statut)) {
      return res.status(400).json({ succes: false, message: 'Statut invalide.' });
    }

    const updates = ['statut = ?'];
    const params  = [statut];

    let livreurAssigne = livreur_id || null;
    if (statut === 'en_livraison' && !livreurAssigne) {
      livreurAssigne = await choisirLivreurDisponible();
      if (!livreurAssigne) {
        return res.status(400).json({
          succes: false,
          message: 'Aucun livreur disponible pour le moment.',
        });
      }
    }

    if (livreurAssigne) { updates.push('livreur_id = ?'); params.push(livreurAssigne); }
    params.push(req.params.id);

    await db.query(`UPDATE commandes SET ${updates.join(', ')} WHERE id = ?`, params);

    // Ajouter au suivi
    const messages = {
      confirmee:      'Validation pharmacie',
      en_preparation: 'Préparation de la commande',
      en_livraison:   livreurAssigne ? 'Livreur affecté - commande prête à être récupérée' : 'Commande en cours de livraison',
      livree:         'Commande livrée avec succès',
      annulee:        'Commande annulée par la pharmacie',
    };
    await db.query(
      'INSERT INTO suivi_livraison (commande_id, statut, description) VALUES (?, ?, ?)',
      [req.params.id, messages[statut] || statut, messages[statut] || '']
    );

    if (livreurAssigne) {
      await db.query(
        'UPDATE livreurs SET disponible = FALSE WHERE utilisateur_id = ?',
        [livreurAssigne]
      );
    }

    res.json({
      succes: true,
      message: livreurAssigne
        ? 'Commande prête. Un livreur disponible a été affecté automatiquement.'
        : `Commande ${statut} !`,
      livreur_id: livreurAssigne,
    });
  } catch (e) {
    console.error('majStatutCommande:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── ORDONNANCES ──────────────────────────────────────────────────────
const getOrdonnances = async (req, res) => {
  try {
    const { statut } = req.query;
    let query = `
      SELECT o.*,
             u.nom AS patient_nom, u.prenom AS patient_prenom, u.telephone AS patient_tel,
             m.nom AS medecin_nom, m2.specialite
      FROM ordonnances o
      JOIN utilisateurs u  ON o.patient_id = u.id
      JOIN utilisateurs m  ON o.medecin_id = m.id
      LEFT JOIN medecins m2 ON o.medecin_id = m2.utilisateur_id
      WHERE 1=1`;
    const params = [];
    if (statut) { query += ' AND o.statut = ?'; params.push(statut); }
    query += ' ORDER BY o.date_ordonnance DESC';

    const [rows] = await db.query(query, params);
    res.json({
      succes: true,
      ordonnances: rows,
      stats: {
        total:     rows.length,
        nouvelles: rows.filter(o => (o.statut || 'nouvelle') === 'nouvelle').length,
        traitees:  rows.filter(o => o.statut === 'traitee').length,
      },
    });
  } catch (e) {
    console.error('getOrdonnances:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const traiterOrdonnance = async (req, res) => {
  try {
    const { statut, notes } = req.body;
    await db.query(
      'UPDATE ordonnances SET statut = ?, notes_pharmacien = ? WHERE id = ?',
      [statut || 'traitee', notes || null, req.params.id]
    );
    res.json({ succes: true, message: 'Ordonnance mise à jour !' });
  } catch (e) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── VENTES / STATISTIQUES ────────────────────────────────────────────
const getVentes = async (req, res) => {
  try {
    const { periode = '30' } = req.query;

    const [commandes] = await db.query(
      `SELECT c.*, u.nom AS patient_nom, u.prenom AS patient_prenom
       FROM commandes c
       JOIN utilisateurs u ON c.patient_id = u.id
       WHERE c.statut = 'livree'
         AND c.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
       ORDER BY c.created_at DESC`,
      [parseInt(periode)]
    );

    let totalRevenu = 0;
    for (const c of commandes) {
      totalRevenu += parseFloat(c.montant_total || 0);
      const [articles] = await db.query(
        `SELECT ca.*, m.nom AS medicament_nom
         FROM commande_articles ca
         JOIN medicaments m ON ca.medicament_id = m.id
         WHERE ca.commande_id = ?`,
        [c.id]
      );
      c.articles = articles;
    }

    // Top médicaments vendus
    const [topMeds] = await db.query(
      `SELECT m.nom, SUM(ca.quantite) AS total_vendu, SUM(ca.quantite * ca.prix_unitaire) AS revenu
       FROM commande_articles ca
       JOIN medicaments m ON ca.medicament_id = m.id
       JOIN commandes c ON ca.commande_id = c.id
       WHERE c.statut = 'livree'
         AND c.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
       GROUP BY m.id, m.nom
       ORDER BY total_vendu DESC
       LIMIT 5`,
      [parseInt(periode)]
    );

    res.json({
      succes: true,
      commandes,
      top_medicaments: topMeds,
      stats: {
        total_commandes: commandes.length,
        revenu_total:    totalRevenu,
        panier_moyen:    commandes.length > 0 ? (totalRevenu / commandes.length).toFixed(0) : 0,
      },
    });
  } catch (e) {
    console.error('getVentes:', e);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── LIVREURS DISPONIBLES ─────────────────────────────────────────────
const getLivreursDisponibles = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.nom, u.prenom, u.telephone, l.zone_livraison, l.vehicule
       FROM utilisateurs u
       JOIN livreurs l ON u.id = l.utilisateur_id
       WHERE u.est_actif = TRUE AND l.disponible = TRUE
       ORDER BY u.nom ASC`
    );
    res.json({ succes: true, livreurs: rows });
  } catch (e) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getMonProfil, majProfil,
  getStock, ajouterMedicament, majStock,
  getCommandes, majStatutCommande,
  getOrdonnances, traiterOrdonnance,
  getVentes,
  getLivreursDisponibles,
}; 
