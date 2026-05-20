import db from "../config/db.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";


// ================= REGISTER =================
export const register = async (req, res) => {

    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({
            message: "Tous les champs sont obligatoires"
        });
    }

    try {

        const hashedPassword = await bcrypt.hash(password, 10);

        const sql =
            "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)";

        db.query(sql,
            [name, email, hashedPassword, role || "patient"],
            (err, result) => {

                if (err) {
                    return res.status(500).json(err);
                }

                res.status(201).json({
                    message: "Utilisateur créé"
                });

            });

    } catch (error) {
        res.status(500).json(error);
    }

};


// ================= LOGIN =================
export const login = (req, res) => {

    const { email, password } = req.body;

    const sql = "SELECT * FROM users WHERE email=?";

    db.query(sql, [email], async (err, result) => {

        if (err) {
            return res.status(500).json(err);
        }

        if (result.length === 0) {
            return res.status(404).json({
                message: "Utilisateur non trouvé"
            });
        }

        const user = result[0];

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({
                message: "Mot de passe incorrect"
            });
        }

        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: "1d" }
        );

        res.json({
            message: "Connexion réussie",
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    });

};