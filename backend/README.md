# 🏥 HealthApp Backend - Guide Complet

## Structure du projet

```
health-backend/
├── config/
│   ├── database.js       → Connexion MySQL
│   └── schema.sql        → Script création des tables
├── controllers/
│   ├── authController.js    → Login, Inscription, Reset password
│   ├── dashboardController.js → Tableaux de bord par rôle
│   └── adminController.js   → Gestion utilisateurs
├── middleware/
│   └── auth.js           → Vérification JWT et rôles
├── routes/
│   ├── auth.js           → Routes /api/auth/...
│   ├── dashboard.js      → Routes /api/dashboard/...
│   └── admin.js          → Routes /api/admin/...
├── utils/
│   └── email.js          → Envoi d'emails
├── .env.example          → Modèle de configuration
├── package.json          → Dépendances Node.js
└── server.js             → Point d'entrée principal
```

---

## 🚀 Installation étape par étape

### Étape 1 — Installer Node.js
1. Va sur https://nodejs.org
2. Télécharge la version **LTS** (Long Term Support)
3. Installe-la normalement

Vérifie l'installation :
```bash
node --version   # doit afficher v18 ou plus
npm --version    # doit afficher un numéro
```

### Étape 2 — Installer MySQL
1. Va sur https://dev.mysql.com/downloads/mysql/
2. Télécharge et installe MySQL Community Server
3. Note bien le mot de passe root que tu choisis pendant l'installation

### Étape 3 — Créer la base de données
1. Ouvre **MySQL Workbench** (installé avec MySQL)
2. Connecte-toi avec ton mot de passe root
3. Ouvre le fichier `config/schema.sql`
4. Clique sur le bouton **⚡ Exécuter**

### Étape 4 — Configurer le projet
1. Copie le fichier `.env.example` et renomme-le `.env`
2. Ouvre `.env` et remplis tes informations :
```
DB_PASSWORD=ton_mot_de_passe_mysql
JWT_SECRET=mets_une_longue_phrase_secrete_ici_minimum_32_caracteres
```

### Étape 5 — Installer les dépendances
Ouvre un terminal dans le dossier `health-backend` et lance :
```bash
npm install
```

### Étape 6 — Démarrer le serveur
```bash
# Pour le développement (redémarre automatiquement si tu modifies le code)
npm run dev

# Pour la production
npm start
```

Tu devrais voir :
```
✅ Connecté à MySQL avec succès
🚀 Serveur démarré sur http://localhost:3000
```

---

## 📡 Liste des routes API

### Authentification (`/api/auth`)

| Méthode | Route | Description | Protégé |
|---------|-------|-------------|---------|
| POST | `/api/auth/inscription` | Créer un compte | Non |
| POST | `/api/auth/connexion` | Se connecter | Non |
| GET | `/api/auth/moi` | Voir son profil | Oui |
| POST | `/api/auth/deconnexion` | Se déconnecter | Oui |
| POST | `/api/auth/mot-de-passe-oublie` | Demander reset | Non |
| POST | `/api/auth/reinitialiser-mot-de-passe/:token` | Nouveau mdp | Non |

### Dashboard (`/api/dashboard`)

| Méthode | Route | Rôle requis |
|---------|-------|-------------|
| GET | `/api/dashboard` | Tout rôle (auto) |
| GET | `/api/dashboard/patient` | patient, admin |
| GET | `/api/dashboard/medecin` | medecin, admin |
| GET | `/api/dashboard/pharmacien` | pharmacien, admin |
| GET | `/api/dashboard/livreur` | livreur, admin |
| GET | `/api/dashboard/admin` | admin, superadmin |
| GET | `/api/dashboard/superadmin` | superadmin |

### Administration (`/api/admin`)

| Méthode | Route | Rôle requis |
|---------|-------|-------------|
| GET | `/api/admin/utilisateurs` | admin, superadmin |
| PATCH | `/api/admin/utilisateurs/:id/activation` | admin, superadmin |
| PATCH | `/api/admin/utilisateurs/:id/role` | superadmin |
| DELETE | `/api/admin/utilisateurs/:id` | superadmin |
| GET | `/api/admin/validations-professionnels` | admin, superadmin |
| PATCH | `/api/admin/validations-professionnels/:id/approuver` | admin, superadmin |
| PATCH | `/api/admin/validations-professionnels/:id/rejeter` | admin, superadmin |

---

## Paiement Mobile Money

Le backend accepte `orange_money`, `moov_money` et `coris_money` dans `/api/pharmacie/paiement`.
Sans clés API, le paiement reste en mode simulation pour le développement.

Ajoute les vraies clés dans `backend/.env` :

```env
APP_URL=http://localhost:3000

ORANGE_ACCESS_TOKEN=ton_token_orange
ORANGE_MERCHANT_KEY=ta_cle_marchand_orange

MOOV_CLIENT_ID=ton_client_id_moov
MOOV_CLIENT_SECRET=ton_client_secret_moov

CORIS_API_URL=https://url_api_coris_a_confirmer
CORIS_API_KEY=ta_cle_api_coris
CORIS_MERCHANT_ID=ton_identifiant_marchand_coris
```

Étapes d'intégration :

1. Créer un compte marchand chez l'opérateur choisi.
2. Récupérer les clés sandbox, puis tester une commande avec un petit montant.
3. Configurer les URLs callback/notif publiques avec l'URL de ton backend.
4. Remplacer les clés sandbox par les clés production quand l'opérateur valide le compte.
5. Vérifier dans la table `paiements` et `transactions_paiement` que la référence est bien enregistrée.

---

## 📱 Connexion avec Flutter

Dans Flutter, utilise le package `http` ou `dio`. Voici un exemple :

```dart
// Inscription
final response = await http.post(
  Uri.parse('http://localhost:3000/api/auth/inscription'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'nom': 'Dupont',
    'prenom': 'Jean',
    'email': 'jean@email.com',
    'mot_de_passe': 'MonMotDePasse123',
    'role': 'patient', // ou 'medecin', 'pharmacien', etc.
  }),
);

// Connexion + récupération du token
final response = await http.post(
  Uri.parse('http://localhost:3000/api/auth/connexion'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': 'jean@email.com',
    'mot_de_passe': 'MonMotDePasse123',
  }),
);
final token = jsonDecode(response.body)['token'];

// Accéder au dashboard (avec le token)
final dashboard = await http.get(
  Uri.parse('http://localhost:3000/api/dashboard'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token', // Important !
  },
);
```

---

## 🔑 Compte SuperAdmin par défaut
- **Email:** superadmin@health.com  
- **Mot de passe:** Admin@1234  
- ⚠️ Change ce mot de passe dès la première connexion !

---

## 🛡️ Rôles disponibles

| Rôle | Description |
|------|-------------|
| `superadmin` | Accès total, gestion de tout |
| `admin` | Gestion utilisateurs, stats |
| `medecin` | Espace médecin, patients |
| `pharmacien` | Gestion pharmacie |
| `livreur` | Livraisons |
| `patient` | Espace patient |
