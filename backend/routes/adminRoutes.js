import express from "express";
import { verifyToken } from "../middleware/authMiddleware.js";
import { checkRole } from "../middleware/roleMiddleware.js";

const router = express.Router();

router.get(
"/dashboard",
verifyToken,
checkRole(["admin", "super_admin"]),
(req, res) => {

res.json({
message: "Bienvenue admin"
});

}
);

export default router;