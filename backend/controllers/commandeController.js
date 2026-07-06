// controllers/commande.controller.js
const CommandeModel = require('../models/Commande');

const CommandeController = {
    async getAll(req, res) {
        try {
            res.status(200).json(await CommandeModel.findAll());
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async getById(req, res) {
        try {
            const commande = await CommandeModel.findById(req.params.id);
            if (!commande) return res.status(404).json({ message: 'Commande introuvable' });
            res.status(200).json(commande);
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async getByPatient(req, res) {
        try {
            res.status(200).json(await CommandeModel.findByPatient(req.params.patientId));
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async create(req, res) {
        try {
            const { patient_id, adresse_livraison, lignes } = req.body;

            if (!patient_id || !adresse_livraison || !Array.isArray(lignes) || lignes.length === 0) {
                return res.status(400).json({
                    message: 'Champs requis : patient_id, adresse_livraison, lignes (tableau non vide)',
                });
            }

            const commande = await CommandeModel.create({ patient_id, adresse_livraison, lignes });
            res.status(201).json(commande);
        } catch (err) {
            res.status(400).json({ message: err.message });
        }
    },

    async updateStatut(req, res) {
        try {
            const { statut } = req.body;
            const statutsValides = [
                'en_attente', 'validee', 'en_preparation', 'en_livraison', 'livree', 'annulee',
            ];
            if (!statutsValides.includes(statut)) {
                return res.status(400).json({ message: 'Statut invalide' });
            }
            res.status(200).json(await CommandeModel.updateStatut(req.params.id, statut));
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async remove(req, res) {
        try {
            const supprime = await CommandeModel.remove(req.params.id);
            if (!supprime) return res.status(404).json({ message: 'Commande introuvable' });
            res.status(200).json({ message: 'Commande supprimée avec succès' });
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },
};

module.exports = CommandeController;
