// models/medicament.model.js
const pool = require('../config/database');

const MedicamentModel = {
    async findAll() {
        const [rows] = await pool.query(`SELECT * FROM medicaments ORDER BY nom ASC`);
        return rows;
    },

    async findById(id) {
        const [rows] = await pool.query(`SELECT * FROM medicaments WHERE id = ?`, [id]);
        return rows[0];
    },

    async create({ nom, description, forme, prix_unitaire, stock, necessite_ordonnance }) {
        const [result] = await pool.query(
            `INSERT INTO medicaments (nom, description, forme, prix_unitaire, stock, necessite_ordonnance)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [nom, description || null, forme || null, prix_unitaire, stock || 0, !!necessite_ordonnance]
        );
        return this.findById(result.insertId);
    },

    async update(id, { nom, description, forme, prix_unitaire, stock, necessite_ordonnance }) {
        await pool.query(
            `UPDATE medicaments 
             SET nom = ?, description = ?, forme = ?, prix_unitaire = ?, stock = ?, necessite_ordonnance = ?
             WHERE id = ?`,
            [nom, description, forme, prix_unitaire, stock, !!necessite_ordonnance, id]
        );
        return this.findById(id);
    },

    async decrementerStock(id, quantite) {
        await pool.query(`UPDATE medicaments SET stock = stock - ? WHERE id = ?`, [quantite, id]);
    },

    async remove(id) {
        const [result] = await pool.query(`DELETE FROM medicaments WHERE id = ?`, [id]);
        return result.affectedRows > 0;
    },
};

module.exports = MedicamentModel;
