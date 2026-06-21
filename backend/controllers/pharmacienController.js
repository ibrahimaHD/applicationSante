const db = require('../config/database');

// ── Helper : récupérer l'ID pharmacien ──────────────────────────────
const getPharmacienId = async (utilisateurId) => {
  const [rows] = await db.query(
    'SELECT id FROM pharmaciens WHERE utilisateur_id = ?',
    [utilisateurId]
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
      `INSERT INTO medicaments (nom, description, categorie, prix, stock, ordonnance_requise, dosage, est_actif)
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

// ── Catalogue ────────────────────────────────────────────
const getMedicaments = async (req, res) => {
  try {
    const { search, categorie } = req.query;
    let query = `SELECT id, nom, description, categorie, prix, stock, ordonnance_requise, dosage
                 FROM medicaments WHERE est_actif = TRUE`;
    const params = [];
    if (search) { query += ' AND nom LIKE ?'; params.push(`%${search}%`); }
    if (categorie) { query += ' AND categorie = ?'; params.push(categorie); }
    query += ' ORDER BY nom ASC';
    const [rows] = await db.query(query, params);
    res.json({ succes: true, medicaments: rows });
  } catch (error) {
    console.error('getMedicaments:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getCategoriesMedicaments = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT DISTINCT categorie FROM medicaments WHERE est_actif = TRUE ORDER BY categorie ASC'
    );
    res.json({ succes: true, categories: rows.map(r => r.categorie) });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── Commandes du patient ─────────────────────────────────
const getMesCommandes = async (req, res) => {
  try {
    const [commandes] = await db.query(
      'SELECT * FROM commandes WHERE patient_id = ? ORDER BY created_at DESC',
      [req.utilisateur.id]
    );
    for (const c of commandes) {
      const [articles] = await db.query(
        `SELECT ca.quantite, ca.prix_unitaire, m.nom AS medicament_nom
         FROM commande_articles ca
         JOIN medicaments m ON ca.medicament_id = m.id
         WHERE ca.commande_id = ?`,
        [c.id]
      );
      c.articles = articles;
    }
    res.json({ succes: true, commandes });
  } catch (error) {
    console.error('getMesCommandes:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const creerCommande = async (req, res) => {
  try {
    const { articles, adresse_livraison, mode_paiement } = req.body;

    if (!articles || !Array.isArray(articles) || articles.length === 0) {
      return res.status(400).json({ succes: false, message: 'Le panier est vide.' });
    }
    if (!adresse_livraison) {
      return res.status(400).json({ succes: false, message: 'Adresse de livraison requise.' });
    }

    let montantTotal = 0;
    const lignes = [];
    for (const a of articles) {
      const [med] = await db.query(
        'SELECT id, prix FROM medicaments WHERE id = ? AND est_actif = TRUE',
        [a.medicament_id]
      );
      if (med.length === 0) {
        return res.status(400).json({ succes: false, message: `Médicament introuvable (id ${a.medicament_id}).` });
      }
      const quantite = parseInt(a.quantite) || 1;
      montantTotal += med[0].prix * quantite;
      lignes.push({ medicament_id: med[0].id, quantite, prix_unitaire: med[0].prix });
    }

    const [result] = await db.query(
      `INSERT INTO commandes (patient_id, montant_total, adresse_livraison, mode_paiement, statut)
       VALUES (?, ?, ?, ?, 'en_attente')`,
      [req.utilisateur.id, montantTotal, adresse_livraison, mode_paiement || 'especes']
    );

    for (const l of lignes) {
      await db.query(
        'INSERT INTO commande_articles (commande_id, medicament_id, quantite, prix_unitaire) VALUES (?, ?, ?, ?)',
        [result.insertId, l.medicament_id, l.quantite, l.prix_unitaire]
      );
    }

    await db.query(
      'INSERT INTO suivi_livraison (commande_id, statut, description) VALUES (?, ?, ?)',
      [result.insertId, 'Commande passée', 'Votre commande a été enregistrée et est en attente de confirmation par la pharmacie.']
    );

    res.status(201).json({
      succes: true,
      message: 'Commande passée avec succès !',
      commande_id: result.insertId,
    });
  } catch (error) {
    console.error('creerCommande:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur: ' + error.message });
  }
};

// ── Paiement mobile money ────────────────────────────────
const effectuerPaiement = async (req, res) => {
  try {
    const { commande_id, numero_mobile } = req.body;
    if (!commande_id || !numero_mobile) {
      return res.status(400).json({ succes: false, message: 'Commande et numéro requis.' });
    }
    const [rows] = await db.query(
      'SELECT id FROM commandes WHERE id = ? AND patient_id = ?',
      [commande_id, req.utilisateur.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ succes: false, message: 'Commande introuvable.' });
    }
    res.json({ succes: true, message: 'Paiement initié. Confirmez sur votre téléphone.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── Suivi de livraison ───────────────────────────────────
const getSuiviCommande = async (req, res) => {
  try {
    const [commande] = await db.query(
      'SELECT id FROM commandes WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    if (commande.length === 0) {
      return res.status(404).json({ succes: false, message: 'Commande introuvable.' });
    }
    const [suivi] = await db.query(
      'SELECT statut, description, created_at FROM suivi_livraison WHERE commande_id = ? ORDER BY created_at ASC',
      [req.params.id]
    );
    res.json({ succes: true, suivi });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── Renouveler une commande ──────────────────────────────
const renouvelerCommande = async (req, res) => {
  try {
    const [commande] = await db.query(
      'SELECT adresse_livraison, mode_paiement FROM commandes WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    if (commande.length === 0) {
      return res.status(404).json({ succes: false, message: 'Commande introuvable.' });
    }
    const [anciens] = await db.query(
      'SELECT medicament_id, quantite FROM commande_articles WHERE commande_id = ?',
      [req.params.id]
    );

    let montantTotal = 0;
    const lignes = [];
    for (const a of anciens) {
      const [med] = await db.query(
        'SELECT id, prix FROM medicaments WHERE id = ? AND est_actif = TRUE',
        [a.medicament_id]
      );
      if (med.length === 0) continue;
      montantTotal += med[0].prix * a.quantite;
      lignes.push({ medicament_id: med[0].id, quantite: a.quantite, prix_unitaire: med[0].prix });
    }

    if (lignes.length === 0) {
      return res.status(400).json({ succes: false, message: 'Ces médicaments ne sont plus disponibles.' });
    }

    const [result] = await db.query(
      `INSERT INTO commandes (patient_id, montant_total, adresse_livraison, mode_paiement, statut)
       VALUES (?, ?, ?, ?, 'en_attente')`,
      [req.utilisateur.id, montantTotal, commande[0].adresse_livraison, commande[0].mode_paiement]
    );

    for (const l of lignes) {
      await db.query(
        'INSERT INTO commande_articles (commande_id, medicament_id, quantite, prix_unitaire) VALUES (?, ?, ?, ?)',
        [result.insertId, l.medicament_id, l.quantite, l.prix_unitaire]
      );
    }

    await db.query(
      'INSERT INTO suivi_livraison (commande_id, statut, description) VALUES (?, ?, ?)',
      [result.insertId, 'Commande passée', 'Renouvellement de votre précédente commande.']
    );

    res.status(201).json({ succes: true, message: 'Commande renouvelée !', commande_id: result.insertId });
  } catch (error) {
    console.error('renouvelerCommande:', error);
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
  getOrdonnances, traiterOrdonnance,
  getVentes,
  getLivreursDisponibles,
   getMedicaments, getCategoriesMedicaments,
 getMesCommandes, creerCommande,
 effectuerPaiement, getSuiviCommande, renouvelerCommande,
};



