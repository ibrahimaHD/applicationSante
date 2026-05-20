// utils/email.js
// Envoi d'emails (réinitialisation mot de passe)

const nodemailer = require('nodemailer');
require('dotenv').config();

// Configuration du transporteur email
const transporteur = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Envoyer l'email de réinitialisation
const envoyerEmailReset = async (email, prenom, token) => {
  // L'URL que le frontend Flutter utilisera
  const lienReset = `http://localhost:3000/api/auth/reinitialiser-mot-de-passe/${token}`;

  const options = {
    from: `"HealthApp" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Réinitialisation de votre mot de passe',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2196F3;">Réinitialisation de mot de passe</h2>
        <p>Bonjour <strong>${prenom}</strong>,</p>
        <p>Vous avez demandé à réinitialiser votre mot de passe.</p>
        <p>Cliquez sur le bouton ci-dessous (valable 1 heure) :</p>
        <a href="${lienReset}" 
           style="background-color: #2196F3; color: white; padding: 12px 24px; 
                  text-decoration: none; border-radius: 4px; display: inline-block; margin: 16px 0;">
          Réinitialiser mon mot de passe
        </a>
        <p>Si vous n'avez pas fait cette demande, ignorez cet email.</p>
        <hr/>
        <p style="color: #999; font-size: 12px;">HealthApp - Ne pas répondre à cet email.</p>
      </div>
    `,
  };

  await transporteur.sendMail(options);
};

module.exports = { envoyerEmailReset };
