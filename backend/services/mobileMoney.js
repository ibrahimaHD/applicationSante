const axios = require('axios');

// ── Orange Money Burkina Faso ───────────────────────────
const orangeMoneyPayer = async ({
  montant,
  numero,
  reference,
  description,
}) => {
  try {
    // Documentation : https://developer.orange.com/apis/om-webpay-bf
    const response = await axios.post(
      'https://api.orange.com/orange-money-webpay/bf/v1/webpayment',
      {
        merchant_key:   process.env.ORANGE_MERCHANT_KEY,
        currency:       'XOF',
        order_id:       reference,
        amount:         montant,
        return_url:     `${process.env.APP_URL}/api/paiement/callback/orange`,
        cancel_url:     `${process.env.APP_URL}/api/paiement/cancel`,
        notif_url:      `${process.env.APP_URL}/api/paiement/notification`,
        lang:           'fr',
        reference:      description,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.ORANGE_ACCESS_TOKEN}`,
          'Content-Type': 'application/json',
        },
      }
    );
    return { succes: true, data: response.data };
  } catch (error) {
    console.error('Orange Money erreur:', error.response?.data);
    return { succes: false, message: error.message };
  }
};

// ── Moov Money Burkina Faso ─────────────────────────────
const moovMoneyPayer = async ({
  montant,
  numero,
  reference,
}) => {
  try {
    const response = await axios.post(
      'https://openapi.moov-africa.com/bf/v1/payment',
      {
        amount:      montant,
        currency:    'XOF',
        subscriber:  { msisdn: numero },
        ref_command: reference,
        description: 'Paiement LaafiBa',
      },
      {
        headers: {
          Authorization: `Basic ${Buffer.from(
            `${process.env.MOOV_CLIENT_ID}:${process.env.MOOV_CLIENT_SECRET}`
          ).toString('base64')}`,
          'Content-Type': 'application/json',
        },
      }
    );
    return { succes: true, data: response.data };
  } catch (error) {
    console.error('Moov Money erreur:', error.response?.data);
    return { succes: false, message: error.message };
  }
};

// ── Coris Money ─────────────────────────────────────────
const corisMoneyPayer = async ({
  montant,
  numero,
  reference,
  description,
}) => {
  try {
    const response = await axios.post(
      process.env.CORIS_API_URL,
      {
        merchant_id: process.env.CORIS_MERCHANT_ID,
        amount: montant,
        currency: 'XOF',
        customer_phone: numero,
        reference,
        description: description || 'Paiement LaafiBa',
        callback_url: `${process.env.APP_URL}/api/paiement/callback/coris`,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.CORIS_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );
    return { succes: true, data: response.data };
  } catch (error) {
    console.error('Coris Money erreur:', error.response?.data || error.message);
    return { succes: false, message: error.message };
  }
};

module.exports = { orangeMoneyPayer, moovMoneyPayer, corisMoneyPayer };
