import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'base_dashboard.dart';

// Livreur
import '../livreur/livraison_screen.dart';
import '../livreur/profil_livreur_screen.dart';
import '../livreur/historique_livraisons_screen.dart';

// Pharmacien
import '../pharmacien/ordonnances_pharmacien_screen.dart';
import '../pharmacien/stock_medicaments_screen.dart';
import '../pharmacien/commandes_pharmacien_screen.dart';
import '../pharmacien/historique_ventes_screen.dart';

// ─────────────────────────────────────────────────────────────────────
// DASHBOARD LIVREUR
// ─────────────────────────────────────────────────────────────────────
class LivreurDashboard extends StatelessWidget {
  final UserModel user;
  const LivreurDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: user,
      title: 'Espace Livreur',
      accentColor: const Color(0xFFF4511E),
      children: [
        // Bannière de bienvenue
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF4511E), Color(0xFFFF8F00)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bonjour, ${user.prenom} !',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('Prêt pour les livraisons du jour ?',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ]),
        ),

        const SizedBox(height: 24),
        const Text('Livraisons', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: "Livraisons du jour",
          subtitle: "Mes livraisons en cours et à faire",
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFFF4511E),
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => LivraisonsScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: "Historique",
          subtitle: "Mes livraisons effectuées",
          icon: Icons.history_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => HistoriqueLivraisonsScreen(user: user))),
        ),

        const SizedBox(height: 24),
        const Text('Mon compte', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: "Mon profil",
          subtitle: "Infos personnelles, zone, véhicule",
          icon: Icons.person_outline,
          color: const Color(0xFF1E88E5),
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProfilLivreurScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: "Carte & itinéraire",
          subtitle: "Navigation GPS pour les livraisons",
          icon: Icons.map_outlined,
          color: const Color(0xFF3949AB),
          // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CarteLivreurScreen(user: user))),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// DASHBOARD PHARMACIEN
// ─────────────────────────────────────────────────────────────────────
class PharmacienDashboard extends StatelessWidget {
  final UserModel user;
  const PharmacienDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: user,
      title: 'Espace Pharmacien',
      accentColor: const Color(0xFF8E24AA),
      children: [
        // Bannière
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E24AA), Color(0xFF1E88E5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.local_pharmacy_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bonjour, ${user.prenom} !',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('Gérez votre pharmacie facilement',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),

        const SizedBox(height: 24),
        const Text('Prescriptions & commandes', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: "Ordonnances reçues",
          subtitle: "Valider et traiter les ordonnances",
          icon: Icons.description_outlined,
          color: const Color(0xFF8E24AA),
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => OrdonnancesPharmacienScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: "Commandes en cours",
          subtitle: "Préparer et expédier les commandes",
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFFF4511E),
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CommandesPharmacienScreen(user: user))),
        ),

        const SizedBox(height: 24),
        const Text('Stock & statistiques', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: "Stock médicaments",
          subtitle: "Gérer l'inventaire et les prix",
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF1E88E5),
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => StockMedicamentsScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: "Historique & ventes",
          subtitle: "Chiffre d'affaires, top médicaments",
          icon: Icons.bar_chart_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => HistoriqueVentesScreen(user: user))),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}