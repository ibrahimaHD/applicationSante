# 🏥 HealthCare — Frontend Flutter

Application de santé avec gestion multi-rôles, construite avec Flutter + Node.js + MySQL.

---

## 📁 Structure du projet

```
lib/
├── main.dart                          # Point d'entrée
├── constants/
│   └── app_constants.dart             # Couleurs, styles, rôles, config API
├── models/
│   └── user_model.dart                # Modèle utilisateur
├── services/
│   └── auth_service.dart              # API login / register / session
├── widgets/
│   └── app_widgets.dart               # TextField, Button, RoleDropdown réutilisables
└── screens/
    ├── splash_screen.dart             # Écran de démarrage + vérification session
    ├── role_redirect.dart             # Routeur de rôle vers dashboard
    ├── auth/
    │   ├── login_screen.dart          # Connexion
    │   └── register_screen.dart      # Inscription (champs dynamiques par rôle)
    └── dashboards/
        ├── base_dashboard.dart        # Widget partagé (header, logout)
        ├── patient_dashboard.dart     # Dashboard Patient
        ├── medecin_dashboard.dart     # Dashboard Médecin
        ├── pharmacien_dashboard.dart  # Dashboard Pharmacien
        ├── livreur_dashboard.dart     # Dashboard Livreur
        ├── admin_dashboard.dart       # Dashboard Admin JDS
        └── super_admin_dashboard.dart # Dashboard Super Admin
```

---

## 👥 Rôles gérés

| Rôle | Couleur | Champs spécifiques |
|------|---------|-------------------|
| Patient | Bleu | — |
| Médecin | Vert | Spécialité, Numéro licence |
| Pharmacien | Violet | Nom pharmacie, Numéro licence |
| Livreur | Orange | Type véhicule, Zone |
| Admin JDS | Indigo | (créé par Super Admin) |
| Super Admin | Rouge | (créé manuellement en BDD) |

---

## 🚀 Installation

### 1. Installer les dépendances
```bash
flutter pub get
```

### 2. Configurer l'URL de l'API
Dans `lib/constants/app_constants.dart` :
```dart
static const String baseUrl = 'http://VOTRE_IP:3000/api';
```

### 3. Lancer l'application
```bash
flutter run
```

---

## 🔗 Endpoints API attendus (Node.js)

### POST `/api/auth/login`
```json
// Body
{ "email": "...", "password": "..." }

// Réponse succès
{ "success": true, "token": "jwt...", "user": { "id": 1, "nom": "...", "role": "patient", ... } }
```

### POST `/api/auth/register`
```json
// Body (patient)
{ "nom": "...", "prenom": "...", "email": "...", "telephone": "...", "password": "...", "role": "patient" }

// Body (médecin) — champs supplémentaires
{ ..., "specialite": "Cardiologie", "numero_licence": "MED-001" }

// Body (pharmacien)
{ ..., "nom_pharmacie": "Pharmacie X", "numero_licence": "PH-001" }

// Body (livreur)
{ ..., "vehicle_type": "Moto", "zone": "Centre-ville" }

// Réponse succès
{ "success": true, "message": "Compte créé avec succès" }
```

### GET `/api/auth/verify`
```
Header: Authorization: Bearer <token>
Réponse: 200 OK si token valide
```

---

## 📦 Dépendances Flutter

```yaml
http: ^1.2.0              # Appels API
shared_preferences: ^2.2.2 # Stockage token
go_router: ^13.0.0        # Navigation
```

---

## 🎨 Design System

- **Couleur principale :** #1E88E5 (Bleu)
- **Accent :** #00ACC1 (Cyan)
- **Background :** #F5F9FF
- **Police :** Poppins (à ajouter dans assets/fonts/)

---

## 🔄 Flux d'authentification

```
App démarre
    │
    ▼
SplashScreen
    │── Token valide? ──Yes──▶ RoleRedirectScreen ──▶ Dashboard (selon rôle)
    │
    No
    ▼
LoginScreen ──────────────────▶ RoleRedirectScreen ──▶ Dashboard
    │
    │ (pas de compte)
    ▼
RegisterScreen ──▶ LoginScreen
```

---

## 📋 Prochaines étapes

- [ ] Backend Node.js (routes auth, middleware JWT)
- [ ] Base de données MySQL (tables users, roles)
- [ ] Module rendez-vous (Patient ↔ Médecin)
- [ ] Module ordonnances & pharmacie
- [ ] Module livraison avec suivi GPS
- [ ] Notifications push
