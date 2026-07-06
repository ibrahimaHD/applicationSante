// controllers/medicament.controller.js
const MedicamentModel = require('../models/Medicament');

const MedicamentController = {
    async getAll(req, res) {
        try {
            res.status(200).json(await MedicamentModel.findAll());
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async getById(req, res) {
        try {
            const med = await MedicamentModel.findById(req.params.id);
            if (!med) return res.status(404).json({ message: 'Médicament introuvable' });
            res.status(200).json(med);
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async create(req, res) {
        try {
            const { nom, prix_unitaire } = req.body;
            if (!nom || prix_unitaire === undefined) {
                return res.status(400).json({ message: 'Champs requis : nom, prix_unitaire' });
            }
            const med = await MedicamentModel.create(req.body);
            res.status(201).json(med);
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async update(req, res) {
        try {
            const existant = await MedicamentModel.findById(req.params.id);
            if (!existant) return res.status(404).json({ message: 'Médicament introuvable' });
            res.status(200).json(await MedicamentModel.update(req.params.id, req.body));
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },

    async remove(req, res) {
        try {
            const supprime = await MedicamentModel.remove(req.params.id);
            if (!supprime) return res.status(404).json({ message: 'Médicament introuvable' });
            res.status(200).json({ message: 'Médicament supprimé avec succès' });
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    },
};

module.exports = MedicamentController;
