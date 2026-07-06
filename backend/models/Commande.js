// models/commande.model.js
const pool = require('../config/database');

const CommandeModel = {

    async findAll() {
        const [commandes] = await pool.query(
            `SELECT c.*, p.nom AS patient_nom, p.prenom AS patient_prenom
             FROM commandes c
             JOIN patients p ON p.id = c.patient_id
             ORDER BY c.date_commande DESC`
        );
        return commandes;
    },

    async findById(id) {
        const [rows] = await pool.query(
            `SELECT c.*, p.nom AS patient_nom, p.prenom AS patient_prenom
             FROM commandes c
             JOIN patients p ON p.id = c.patient_id
             WHERE c.id = ?`,
            [id]
        );
        if (!rows[0]) return null;

        const [lignes] = await pool.query(
            `SELECT cl.*, m.nom AS medicament_nom
             FROM commande_lignes cl
             JOIN medicaments m ON m.id = cl.medicament_id
             WHERE cl.commande_id = ?`,
            [id]
        );

        return { ...rows[0], lignes };
    },

    async findByPatient(patientId) {
        const [rows] = await pool.query(
            `SELECT * FROM commandes WHERE patient_id = ? ORDER BY date_commande DESC`,
            [patientId]
        );
        return rows;
    },

    // Création transactionnelle : commande + lignes + décrément stock + entrée livraison
    async create({ patient_id, adresse_livraison, lignes }) {
        const connection = await pool.getConnection();
        try {
            await connection.beginTransaction();

            // Calcul du montant total à partir des prix actuels des médicaments
            let montantTotal = 0;
            const lignesAvecPrix = [];

            for (const ligne of lignes) {
                const [medRows] = await connection.query(
                    `SELECT id, prix_unitaire, stock FROM medicaments WHERE id = ? FOR UPDATE`,
                    [ligne.medicament_id]
                );
                const medicament = medRows[0];
                if (!medicament) throw new Error(`Médicament ${ligne.medicament_id} introuvable`);
                if (medicament.stock < ligne.quantite) {
                    throw new Error(`Stock insuffisant pour le médicament ${ligne.medicament_id}`);
                }

                montantTotal += medicament.prix_unitaire * ligne.quantite;
                lignesAvecPrix.push({
                    medicament_id: ligne.medicament_id,
                    quantite: ligne.quantite,
                    prix_unitaire: medicament.prix_unitaire,
                });
            }

            const [commandeResult] = await connection.query(
                `INSERT INTO commandes (patient_id, adresse_livraison, montant_total, statut)
                 VALUES (?, ?, ?, 'en_attente')`,
                [patient_id, adresse_livraison, montantTotal]
            );
            const commandeId = commandeResult.insertId;

            for (const ligne of lignesAvecPrix) {
                await connection.query(
                    `INSERT INTO commande_lignes (commande_id, medicament_id, quantite, prix_unitaire)
                     VALUES (?, ?, ?, ?)`,
                    [commandeId, ligne.medicament_id, ligne.quantite, ligne.prix_unitaire]
                );
                await connection.query(
                    `UPDATE medicaments SET stock = stock - ? WHERE id = ?`,
                    [ligne.quantite, ligne.medicament_id]
                );
            }

            // Création automatique de l'entrée livraison associée
            await connection.query(
                `INSERT INTO livraisons (commande_id, statut_livraison) VALUES (?, 'non_assignee')`,
                [commandeId]
            );

            await connection.commit();
            return this.findById(commandeId);
        } catch (err) {
            await connection.rollback();
            throw err;
        } finally {
            connection.release();
        }
    },

    async updateStatut(id, statut) {
        await pool.query(`UPDATE commandes SET statut = ? WHERE id = ?`, [statut, id]);
        return this.findById(id);
    },

    async remove(id) {
        const [result] = await pool.query(`DELETE FROM commandes WHERE id = ?`, [id]);
        return result.affectedRows > 0;
    },
};

module.exports = CommandeModel;
