const db = require('../config/database');
const { orangeMoneyPayer, moovMoneyPayer, corisMoneyPayer } = require('../services/mobileMoney');

const getMedicaments = async (req, res) => {
  try {
    const { search, categorie, pharmacie_id } = req.query;
    let query = `
      SELECT m.*,
             COALESCE(pp.nom, 'Pharmacie partenaire') AS pharmacie_nom,
             pp.adresse AS pharmacie_adresse,
             NULL AS pharmacie_quartier,
             pp.telephone AS pharmacie_telephone,
             pp.horaires AS pharmacie_horaires,
             0 AS pharmacie_est_garde,
             pp.delai_livraison_min,
             pp.frais_livraison
      FROM medicaments m
      LEFT JOIN pharmacies_partenaires pp ON pp.id = m.pharmacie_id AND pp.est_actif = TRUE
      WHERE m.est_actif = TRUE
        AND m.disponible_livraison = TRUE`;
    const params = [];

    if (search) {
      query += ' AND m.nom LIKE ?';
      params.push(`%${search}%`);
    }
    if (categorie) {
      query += ' AND m.categorie = ?';
      params.push(categorie);
    }
    if (pharmacie_id) {
      query += ' AND m.pharmacie_id = ?';
      params.push(pharmacie_id);
    }

    query += ' ORDER BY pharmacie_nom ASC, m.nom ASC';
    const [medicaments] = await db.query(query, params);

    res.json({ succes: true, medicaments });
  } catch (error) {
    console.error('getMedicaments patient:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getPharmacies = async (_req, res) => {
  try {
    const [pharmacies] = await db.query(
      `SELECT DISTINCT
              pp.id,
              pp.nom,
              pp.adresse,
              NULL AS quartier,
              pp.telephone,
              pp.horaires,
              0 AS est_garde,
              pp.delai_livraison_min,
              pp.frais_livraison
       FROM pharmacies_partenaires pp
       JOIN medicaments m ON m.pharmacie_id = pp.id
       WHERE pp.est_actif = TRUE
         AND m.est_actif = TRUE
         AND m.disponible_livraison = TRUE
       ORDER BY pp.nom ASC`
    );

    res.json({ succes: true, pharmacies });
  } catch (error) {
    console.error('getPharmacies patient:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getCategories = async (_req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT DISTINCT categorie
       FROM medicaments
       WHERE est_actif = TRUE AND disponible_livraison = TRUE AND categorie IS NOT NULL
       ORDER BY categorie ASC`
    );

    res.json({ succes: true, categories: rows.map((row) => row.categorie) });
  } catch (error) {
    console.error('getCategories patient:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const getMesCommandes = async (req, res) => {
  try {
    const [commandes] = await db.query(
      `SELECT *
       FROM commandes
       WHERE patient_id = ?
       ORDER BY created_at DESC`,
      [req.utilisateur.id]
    );

    for (const commande of commandes) {
      const [articles] = await db.query(
        `SELECT ca.*, m.nom AS medicament_nom
         FROM commande_articles ca
         JOIN medicaments m ON ca.medicament_id = m.id
         WHERE ca.commande_id = ?`,
        [commande.id]
      );
      commande.articles = articles;
    }

    res.json({ succes: true, commandes });
  } catch (error) {
    console.error('getMesCommandes:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const creerCommande = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const {
      articles,
      adresse_livraison,
      mode_paiement,
      notes,
      ordonnance_url,
      ordonnance_id,
      duree_traitement_jours,
    } = req.body;

    if (!adresse_livraison || !Array.isArray(articles) || articles.length === 0) {
      return res.status(400).json({
        succes: false,
        message: 'Adresse de livraison et panier requis.',
      });
    }

    await connection.beginTransaction();

    let montantTotal = 0;
    const lignes = [];

    for (const article of articles) {
      const quantite = Number(article.quantite || 0);
      if (!article.medicament_id || quantite <= 0) {
        throw new Error('Article invalide dans le panier.');
      }

      const [rows] = await connection.query(
        `SELECT id, nom, prix, stock, pharmacie_id, ordonnance_requise
         FROM medicaments
         WHERE id = ? AND est_actif = TRUE AND disponible_livraison = TRUE
         FOR UPDATE`,
        [article.medicament_id]
      );
      const medicament = rows[0];

      if (!medicament) {
        throw new Error('Médicament introuvable.');
      }
      if ((medicament.stock || 0) < quantite) {
        throw new Error(`Stock insuffisant pour ${medicament.nom}.`);
      }

      const prixUnitaire = Number(medicament.prix || 0);
      montantTotal += prixUnitaire * quantite;
      lignes.push({
        medicament_id: medicament.id,
        pharmacie_id: medicament.pharmacie_id,
        quantite,
        prix_unitaire: prixUnitaire,
        ordonnance_requise: medicament.ordonnance_requise === 1 || medicament.ordonnance_requise === true,
      });
    }

    const pharmaciesCommande = [...new Set(lignes.map((ligne) => ligne.pharmacie_id || 0))];
    if (pharmaciesCommande.length > 1) {
      throw new Error('Veuillez commander les médicaments d une seule pharmacie à la fois.');
    }

    let ordonnanceCommandeUrl = ordonnance_url || null;
    if (!ordonnanceCommandeUrl && lignes.some((ligne) => ligne.ordonnance_requise)) {
      const paramsOrdonnance = [req.utilisateur.id];
      let ordonnanceQuery = `SELECT id, fichier_path
         FROM ordonnances_uploadees
         WHERE patient_id = ? AND statut = 'en_attente'`;
      if (ordonnance_id) {
        ordonnanceQuery += ' AND id = ?';
        paramsOrdonnance.push(ordonnance_id);
      }
      ordonnanceQuery += ' ORDER BY created_at DESC LIMIT 1';

      const [uploads] = await connection.query(
        ordonnanceQuery,
        paramsOrdonnance
      );
      ordonnanceCommandeUrl = uploads[0]?.fichier_path || null;
    }

    if (lignes.some((ligne) => ligne.ordonnance_requise) && !ordonnanceCommandeUrl) {
      throw new Error('Une ordonnance est requise pour ce panier. Veuillez uploader ou sélectionner une ordonnance.');
    }

    const [commandeResult] = await connection.query(
      `INSERT INTO commandes
        (patient_id, pharmacie_id, adresse_livraison, montant_total, statut, mode_paiement, statut_paiement, ordonnance_url, notes)
       VALUES (?, ?, ?, ?, 'en_attente', ?, 'en_attente', ?, ?)`,
      [
        req.utilisateur.id,
        pharmaciesCommande[0] || null,
        adresse_livraison,
        montantTotal,
        mode_paiement || 'mobile_money',
        ordonnanceCommandeUrl,
        notes || null,
      ]
    );
    const commandeId = commandeResult.insertId;

    for (const ligne of lignes) {
      await connection.query(
        `INSERT INTO commande_articles (commande_id, medicament_id, quantite, prix_unitaire)
         VALUES (?, ?, ?, ?)`,
        [commandeId, ligne.medicament_id, ligne.quantite, ligne.prix_unitaire]
      );
      await connection.query(
        'UPDATE medicaments SET stock = stock - ? WHERE id = ?',
        [ligne.quantite, ligne.medicament_id]
      );
    }

    await connection.query(
      `INSERT INTO suivi_livraison (commande_id, statut, description)
       VALUES (?, 'Commande créée', 'Votre commande a été envoyée à la pharmacie')`,
      [commandeId]
    );

    if (lignes.some((ligne) => ligne.ordonnance_requise)) {
      await connection.query(
        `INSERT INTO suivi_livraison (commande_id, statut, description)
         VALUES (?, 'Ordonnance à vérifier', 'La pharmacie vérifiera l ordonnance avant la préparation')`,
        [commandeId]
      );
      const joursTraitement = Math.max(1, Number(duree_traitement_jours || 30));
      await connection.query(
        `INSERT INTO rappels (patient_id, titre, description, type, date_rappel, heure_rappel)
         VALUES (?, ?, ?, 'medicament', DATE_ADD(CURDATE(), INTERVAL ? DAY), '08:00')`,
        [
          req.utilisateur.id,
          'Renouvellement de traitement',
          `Pensez à renouveler ou vérifier le traitement de la commande #${commandeId}.`,
          joursTraitement,
        ]
      );
    }

    await connection.commit();

    res.status(201).json({
      succes: true,
      message: 'Commande enregistrée avec succès.',
      commande_id: commandeId,
      montant_total: montantTotal,
    });
  } catch (error) {
    await connection.rollback();
    console.error('creerCommande patient:', error);
    res.status(400).json({ succes: false, message: error.message });
  } finally {
    connection.release();
  }
};

const payerCommande = async (req, res) => {
  try {
    const { commande_id, numero_mobile, operateur } = req.body;

    if (!commande_id || !numero_mobile) {
      return res.status(400).json({
        succes: false,
        message: 'Commande et numéro mobile money requis.',
      });
    }

    const [commandes] = await db.query(
      'SELECT id, montant_total FROM commandes WHERE id = ? AND patient_id = ?',
      [commande_id, req.utilisateur.id]
    );

    if (commandes.length === 0) {
      return res.status(404).json({ succes: false, message: 'Commande introuvable.' });
    }

    const methode = ['orange_money', 'moov_money', 'coris_money'].includes(operateur)
      ? operateur
      : 'orange_money';
    const reference = `MM-${Date.now()}-${commande_id}`;
    let paiementExterne = { succes: true, simulation: true };

    if (methode === 'orange_money' && process.env.ORANGE_ACCESS_TOKEN && process.env.ORANGE_MERCHANT_KEY) {
      paiementExterne = await orangeMoneyPayer({
        montant: commandes[0].montant_total || 0,
        numero: numero_mobile,
        reference,
        description: `Commande LaafiBa #${commande_id}`,
      });
    } else if (methode === 'moov_money' && process.env.MOOV_CLIENT_ID && process.env.MOOV_CLIENT_SECRET) {
      paiementExterne = await moovMoneyPayer({
        montant: commandes[0].montant_total || 0,
        numero: numero_mobile,
        reference,
      });
    } else if (methode === 'coris_money' && process.env.CORIS_API_URL && process.env.CORIS_API_KEY && process.env.CORIS_MERCHANT_ID) {
      paiementExterne = await corisMoneyPayer({
        montant: commandes[0].montant_total || 0,
        numero: numero_mobile,
        reference,
        description: `Commande LaafiBa #${commande_id}`,
      });
    }

    if (!paiementExterne.succes) {
      await db.query(
        `UPDATE commandes
         SET statut_paiement = 'echoue', mode_paiement = 'mobile_money'
         WHERE id = ? AND patient_id = ?`,
        [commande_id, req.utilisateur.id]
      );
      await db.query(
        `INSERT INTO paiements
          (commande_id, patient_id, montant, methode, numero_mobile, reference_transaction, statut)
         VALUES (?, ?, ?, ?, ?, ?, 'echec')`,
        [
          commande_id,
          req.utilisateur.id,
          commandes[0].montant_total || 0,
          methode,
          numero_mobile,
          reference,
        ]
      );
      return res.status(400).json({
        succes: false,
        message: paiementExterne.message || 'Paiement mobile money refusé.',
      });
    }

    await db.query(
      `UPDATE commandes
       SET statut_paiement = 'paye', mode_paiement = 'mobile_money'
       WHERE id = ? AND patient_id = ?`,
      [commande_id, req.utilisateur.id]
    );

    await db.query(
      `INSERT INTO paiements
        (commande_id, patient_id, montant, methode, numero_mobile, reference_transaction, statut)
       VALUES (?, ?, ?, ?, ?, ?, 'valide')`,
      [
        commande_id,
        req.utilisateur.id,
        commandes[0].montant_total || 0,
        methode,
        numero_mobile,
        reference,
      ]
    );

    await db.query(
      `INSERT INTO transactions_paiement (commande_id, reference, operateur, montant, statut)
       VALUES (?, ?, ?, ?, 'paye')`,
      [commande_id, reference, methode, commandes[0].montant_total || 0]
    );

    await db.query(
      `INSERT INTO suivi_livraison (commande_id, statut, description)
       VALUES (?, 'Paiement confirmé', 'Paiement mobile money reçu')`,
      [commande_id]
    );

    res.json({
      succes: true,
      message: paiementExterne.simulation
        ? 'Paiement confirmé en mode simulation.'
        : 'Paiement mobile money initialisé.',
      reference,
      simulation: !!paiementExterne.simulation,
    });
  } catch (error) {
    console.error('payerCommande:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

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
      `SELECT *
       FROM suivi_livraison
       WHERE commande_id = ?
       ORDER BY created_at ASC`,
      [req.params.id]
    );

    res.json({ succes: true, suivi });
  } catch (error) {
    console.error('getSuiviCommande:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

const renouvelerCommande = async (req, res) => {
  try {
    const [commandes] = await db.query(
      `SELECT adresse_livraison
       FROM commandes
       WHERE id = ? AND patient_id = ?`,
      [req.params.id, req.utilisateur.id]
    );

    if (commandes.length === 0) {
      return res.status(404).json({ succes: false, message: 'Commande introuvable.' });
    }

    const [articles] = await db.query(
      `SELECT medicament_id, quantite
       FROM commande_articles
       WHERE commande_id = ?`,
      [req.params.id]
    );

    req.body = {
      articles,
      adresse_livraison: commandes[0].adresse_livraison,
    };

    return creerCommande(req, res);
  } catch (error) {
    console.error('renouvelerCommande:', error);
    res.status(500).json({ succes: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getMedicaments,
  getPharmacies,
  getCategories,
  getMesCommandes,
  creerCommande,
  payerCommande,
  getSuiviCommande,
  renouvelerCommande,
};
