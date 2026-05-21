// utils/email.js
const nodemailer = require('nodemailer');
require('dotenv').config();
 
const transporteur = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
  tls: {
    rejectUnauthorized: false,
  },
});
 
// Tester la connexion au démarrage
transporteur.verify((error, success) => {
  if (error) {
    console.error('❌ Erreur configuration email:', error.message);
  } else {
    console.log('✅ Email configuré et prêt à envoyer');
  }
});
 
const envoyerEmailReset = async (email, prenom, token) => {
  const lienReset = `http://localhost:3000/reinitialiser-mot-de-passe?token=${token}`;
 
  const options = {
    from: `"LaafiBa" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Réinitialisation de votre mot de passe - LaafiBa',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #1E88E5, #00ACC1); padding: 30px; border-radius: 16px 16px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 24px;">🏥 LaafiBa</h1>
          <p style="color: rgba(255,255,255,0.8); margin: 8px 0 0;">Votre santé, notre priorité</p>
        </div>
        
        <div style="background: white; padding: 30px; border-radius: 0 0 16px 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
          <h2 style="color: #1A237E; margin-top: 0;">Bonjour ${prenom} 👋</h2>
          
          <p style="color: #546E7A; line-height: 1.6;">
            Vous avez demandé à réinitialiser votre mot de passe. 
            Cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe.
          </p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${lienReset}" 
               style="background: linear-gradient(135deg, #1E88E5, #00ACC1); 
                      color: white; 
                      padding: 14px 32px; 
                      text-decoration: none; 
                      border-radius: 10px; 
                      font-weight: bold;
                      font-size: 16px;
                      display: inline-block;">
              Réinitialiser mon mot de passe
            </a>
          </div>
          
          <p style="color: #546E7A; font-size: 13px;">
            ⏰ Ce lien est valable pendant <strong>1 heure</strong>.
          </p>
          
          <p style="color: #546E7A; font-size: 13px;">
            Si vous n'avez pas demandé cette réinitialisation, ignorez cet email. 
            Votre mot de passe restera inchangé.
          </p>
          
          <hr style="border: none; border-top: 1px solid #E0E0E0; margin: 20px 0;">
          
          <p style="color: #9E9E9E; font-size: 12px; text-align: center; margin: 0;">
            LaafiBa - Ne pas répondre à cet email
          </p>
        </div>
      </div>
    `,
  };
 
  try {
    const info = await transporteur.sendMail(options);
    console.log('✅ Email envoyé à:', email, '| ID:', info.messageId);
    return true;
  } catch (error) {
    console.error('❌ Erreur envoi email:', error.message);
    throw error;
  }
};
 
module.exports = { envoyerEmailReset };
