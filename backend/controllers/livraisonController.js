// controllers/livraison.controller.js
const LivraisonModel = require('../models/Livraison');
const db = require('../config/database');

const LivraisonController = {
    async getAll(req, res) {
        try {
            res.status(200).json(await LivraisonModel.findAll());
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async getByCommande(req, res) {
        try {
            const livraison = await LivraisonModel.findByCommande(req.params.commandeId);
            if (!livraison) return res.status(404).json({ message: 'Livraison introuvable' });
            res.status(200).json(livraison);
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async getByLivreur(req, res) {
        try {
            res.status(200).json(await LivraisonModel.findByLivreur(req.params.livreurId));
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async assigner(req, res) {
        try {
            const { livreur_id, date_livraison_prevue } = req.body;
            if (!livreur_id) return res.status(400).json({ message: 'livreur_id requis' });

            const livraison = await LivraisonModel.assignerLivreur(
                req.params.commandeId,
                livreur_id,
                date_livraison_prevue
            );
            res.status(200).json(livraison);
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async updateStatut(req, res) {
        try {
            const { statut_livraison, commentaire } = req.body;
            const statutsValides = ['non_assignee', 'assignee', 'en_route', 'livree', 'echouee'];

            if (!statutsValides.includes(statut_livraison)) {
                return res.status(400).json({ message: 'Statut de livraison invalide' });
            }

            const livraison = await LivraisonModel.mettreAJourStatut(
                req.params.commandeId,
                statut_livraison,
                commentaire
            );
            res.status(200).json(livraison);
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async getPosition(req, res) {
        try {
            const [rows] = await db.query(
                `SELECT p.*,
                        c.statut AS statut_commande,
                        u.nom AS livreur_nom,
                        u.prenom AS livreur_prenom,
                        u.telephone AS livreur_tel
                 FROM commandes c
                 LEFT JOIN positions_livreurs p ON p.livreur_id = c.livreur_id
                 LEFT JOIN utilisateurs u ON u.id = c.livreur_id
                 WHERE c.id = ?
                 ORDER BY p.updated_at DESC
                 LIMIT 1`,
                [req.params.commandeId]
            );

            if (rows.length === 0 || rows[0].latitude == null) {
                return res.status(404).json({
                    succes: false,
                    message: 'Position du livreur indisponible.',
                });
            }

            res.json({ succes: true, position: rows[0] });
        } catch (err) {
            res.status(500).json({ succes: false, message: 'Erreur serveur', error: err.message });
        }
    },
};

module.exports = LivraisonController;
