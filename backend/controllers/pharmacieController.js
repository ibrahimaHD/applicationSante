const db = require('../config/database');

// ── CATALOGUE MÉDICAMENTS ───────────────────────────────
const getMedicaments = async (req, res) => {
  try {
    const { categorie, search, pharmacie_id } = req.query;
    let query = 'SELECT * FROM medicaments WHERE est_actif = TRUE';
    const params = [];

    if (categorie) { query += ' AND categorie = ?'; params.push(categorie); }
    if (search) { query += ' AND (nom LIKE ? OR description LIKE ?)'; params.push(`%${search}%`, `%${search}%`); }
    if (pharmacie_id) { query += ' AND pharmacie_id = ?'; params.push(pharmacie_id); }

    query += ' ORDER BY nom ASC';
    const [rows] = await db.query(query, params);
    res.json({ succes: true, medicaments: rows });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getCategories = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT DISTINCT categorie FROM medicaments WHERE est_actif = TRUE ORDER BY categorie ASC'
    );
    res.json({ succes: true, categories: rows.map(r => r.categorie) });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── COMMANDES ───────────────────────────────────────────
const getMesCommandes = async (req, res) => {
  try {
    const [commandes] = await db.query(
      `SELECT c.*, p.nom AS pharmacie_nom
       FROM commandes c
       LEFT JOIN pharmacies p ON c.pharmacie_id = p.id
       WHERE c.patient_id = ?
       ORDER BY c.created_at DESC`,
      [req.utilisateur.id]
    );

    for (const commande of commandes) {
      const [articles] = await db.query(
        `SELECT ca.*, m.nom AS medicament_nom, m.image_url
         FROM commande_articles ca
         JOIN medicaments m ON ca.medicament_id = m.id
         WHERE ca.commande_id = ?`,
        [commande.id]
      );
      commande.articles = articles;
    }

    res.json({ succes: true, commandes });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const passerCommande = async (req, res) => {
  try {
    const { articles, adresse_livraison, mode_paiement, pharmacie_id, notes } = req.body;

    if (!articles || articles.length === 0) {
      return res.status(400).json({ succes: false, message: 'Aucun article dans la commande.' });
    }
    if (!adresse_livraison) {
      return res.status(400).json({ succes: false, message: 'Adresse de livraison requise.' });
    }

    // Calculer le montant total
    let montantTotal = 0;
    for (const article of articles) {
      const [med] = await db.query('SELECT prix, stock FROM medicaments WHERE id = ?', [article.medicament_id]);
      if (med.length === 0) return res.status(404).json({ succes: false, message: `Médicament introuvable.` });
      if (med[0].stock < article.quantite) {
        return res.status(400).json({ succes: false, message: `Stock insuffisant.` });
      }
      montantTotal += med[0].prix * article.quantite;
      article.prix_unitaire = med[0].prix;
    }

    // Créer la commande
    const [result] = await db.query(
      `INSERT INTO commandes (patient_id, pharmacie_id, montant_total, adresse_livraison, mode_paiement, notes)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id, pharmacie_id, montantTotal, adresse_livraison, mode_paiement || 'mobile_money', notes]
    );

    const commandeId = result.insertId;

    // Ajouter les articles
    for (const article of articles) {
      await db.query(
        'INSERT INTO commande_articles (commande_id, medicament_id, quantite, prix_unitaire) VALUES (?, ?, ?, ?)',
        [commandeId, article.medicament_id, article.quantite, article.prix_unitaire]
      );
      // Décrémenter le stock
      await db.query('UPDATE medicaments SET stock = stock - ? WHERE id = ?', [article.quantite, article.medicament_id]);
    }

    // Premier suivi
    await db.query(
      'INSERT INTO suivi_livraison (commande_id, statut, description) VALUES (?, ?, ?)',
      [commandeId, 'Commande reçue', 'Votre commande a été reçue et est en cours de traitement.']
    );

    // Créer rappel renouvellement
    await db.query(
      `INSERT INTO rappels (patient_id, titre, description, type, date_rappel)
       VALUES (?, ?, ?, ?, DATE_ADD(CURDATE(), INTERVAL 30 DAY))`,
      [req.utilisateur.id, 'Renouvellement médicaments', `Pensez à renouveler votre commande`, 'traitement']
    );

    res.status(201).json({ succes: true, message: 'Commande passée avec succès !', commande_id: commandeId, montant_total: montantTotal });
  } catch (error) {
    console.error(error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const annulerCommande = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT statut FROM commandes WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    if (rows.length === 0) return res.status(404).json({ succes: false, message: 'Commande introuvable.' });
    if (!['en_attente', 'confirmee'].includes(rows[0].statut)) {
      return res.status(400).json({ succes: false, message: 'Impossible d\'annuler cette commande.' });
    }
    await db.query('UPDATE commandes SET statut = ? WHERE id = ?', ['annulee', req.params.id]);
    res.json({ succes: true, message: 'Commande annulée.' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const renouvelerCommande = async (req, res) => {
  try {
    const [commande] = await db.query(
      'SELECT * FROM commandes WHERE id = ? AND patient_id = ?',
      [req.params.id, req.utilisateur.id]
    );
    if (commande.length === 0) return res.status(404).json({ succes: false, message: 'Commande introuvable.' });

    const [articles] = await db.query(
      'SELECT * FROM commande_articles WHERE commande_id = ?',
      [req.params.id]
    );

    // Nouvelle commande avec les mêmes articles
    const [result] = await db.query(
      `INSERT INTO commandes (patient_id, pharmacie_id, montant_total, adresse_livraison, mode_paiement, notes)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [req.utilisateur.id, commande[0].pharmacie_id, commande[0].montant_total,
       commande[0].adresse_livraison, commande[0].mode_paiement, 'Renouvellement automatique']
    );

    for (const article of articles) {
      await db.query(
        'INSERT INTO commande_articles (commande_id, medicament_id, quantite, prix_unitaire) VALUES (?, ?, ?, ?)',
        [result.insertId, article.medicament_id, article.quantite, article.prix_unitaire]
      );
    }

    res.status(201).json({ succes: true, message: 'Commande renouvelée !', commande_id: result.insertId });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── SUIVI LIVRAISON ─────────────────────────────────────
const getSuiviLivraison = async (req, res) => {
  try {
    const [suivi] = await db.query(
      `SELECT s.*, c.statut AS statut_commande, c.montant_total,
              u.nom AS livreur_nom, u.prenom AS livreur_prenom, u.telephone AS livreur_tel
       FROM suivi_livraison s
       JOIN commandes c ON s.commande_id = c.id
       LEFT JOIN utilisateurs u ON c.livreur_id = u.id
       WHERE s.commande_id = ? AND c.patient_id = ?
       ORDER BY s.created_at ASC`,
      [req.params.id, req.utilisateur.id]
    );
    res.json({ succes: true, suivi });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

// ── PAIEMENT ────────────────────────────────────────────
const initierPaiement = async (req, res) => {
  try {
    const { commande_id, numero_mobile } = req.body;
    const [commande] = await db.query(
      'SELECT * FROM commandes WHERE id = ? AND patient_id = ?',
      [commande_id, req.utilisateur.id]
    );
    if (commande.length === 0) return res.status(404).json({ succes: false, message: 'Commande introuvable.' });

    // Simulation paiement mobile (Orange Money, Moov Money)
    await db.query('UPDATE commandes SET statut_paiement = ? WHERE id = ?', ['paye', commande_id]);
    await db.query('UPDATE commandes SET statut = ? WHERE id = ?', ['confirmee', commande_id]);
    await db.query(
      'INSERT INTO suivi_livraison (commande_id, statut, description) VALUES (?, ?, ?)',
      [commande_id, 'Paiement confirmé', `Paiement de ${commande[0].montant_total} FCFA reçu via ${numero_mobile}`]
    );

    res.json({ succes: true, message: 'Paiement effectué avec succès !' });
  } catch (error) {
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getMedicaments, getCategories,
  getMesCommandes, passerCommande, annulerCommande, renouvelerCommande,
  getSuiviLivraison, initierPaiement,
};
