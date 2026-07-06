// models/livraison.model.js
const pool = require('../config/database');

const LivraisonModel = {

    async findAll() {
        const [rows] = await pool.query(
            `SELECT l.*, c.patient_id, c.adresse_livraison, c.statut AS statut_commande,
                    u.nom AS livreur_nom
             FROM livraisons l
             JOIN commandes c ON c.id = l.commande_id
             LEFT JOIN users u ON u.id = l.livreur_id
             ORDER BY l.created_at DESC`
        );
        return rows;
    },

    async findByCommande(commandeId) {
        const [rows] = await pool.query(
            `SELECT l.*, u.nom AS livreur_nom
             FROM livraisons l
             LEFT JOIN users u ON u.id = l.livreur_id
             WHERE l.commande_id = ?`,
            [commandeId]
        );
        return rows[0];
    },

    async findByLivreur(livreurId) {
        const [rows] = await pool.query(
            `SELECT l.*, c.adresse_livraison, c.patient_id
             FROM livraisons l
             JOIN commandes c ON c.id = l.commande_id
             WHERE l.livreur_id = ?
             ORDER BY l.date_livraison_prevue ASC`,
            [livreurId]
        );
        return rows;
    },

    async assignerLivreur(commandeId, livreurId, dateLivraisonPrevue) {
        await pool.query(
            `UPDATE livraisons 
             SET livreur_id = ?, statut_livraison = 'assignee', date_livraison_prevue = ?
             WHERE commande_id = ?`,
            [livreurId, dateLivraisonPrevue || null, commandeId]
        );
        // On synchronise le statut global de la commande
        await pool.query(`UPDATE commandes SET statut = 'en_preparation' WHERE id = ?`, [commandeId]);
        return this.findByCommande(commandeId);
    },

    async mettreAJourStatut(commandeId, statut_livraison, commentaire) {
        const dateEffective = statut_livraison === 'livree' ? new Date() : null;

        await pool.query(
            `UPDATE livraisons 
             SET statut_livraison = ?, commentaire = ?, 
                 date_livraison_effective = COALESCE(?, date_livraison_effective)
             WHERE commande_id = ?`,
            [statut_livraison, commentaire || null, dateEffective, commandeId]
        );

        // Synchronisation du statut de la commande
        const statutCommandeMap = {
            non_assignee: 'validee',
            assignee: 'en_preparation',
            en_route: 'en_livraison',
            livree: 'livree',
            echouee: 'en_attente',
        };
        await pool.query(`UPDATE commandes SET statut = ? WHERE id = ?`, [
            statutCommandeMap[statut_livraison] || 'en_attente',
            commandeId,
        ]);

        return this.findByCommande(commandeId);
    },
};

module.exports = LivraisonModel;
