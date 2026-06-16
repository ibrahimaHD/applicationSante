import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'base_dashboard.dart';

// ── Livreur screens ──────────────────────────────────────────────────
import '../livreur/livraison_screen.dart';
import '../livreur/profil_livreur_screen.dart';
import '../livreur/historique_livraisons_screen.dart';

// ── Pharmacien screens ───────────────────────────────────────────────
import '../pharmacien/ordonnances_pharmacien_screen.dart';
import '../pharmacien/stock_medicaments_screen.dart';
import '../pharmacien/commandes_pharmacien_screen.dart';
import '../pharmacien/historique_ventes_screen.dart';

// ═════════════════════════════════════════════════════════════════════
// DASHBOARD LIVREUR
// ═════════════════════════════════════════════════════════════════════
class LivreurDashboard extends StatefulWidget {
  final UserModel user;
  const LivreurDashboard({super.key, required this.user});
  @override
  State<LivreurDashboard> createState() => _LivreurDashboardState();
}

class _LivreurDashboardState extends State<LivreurDashboard> {
  Map<String, dynamic> _stats     = {};
  Map<String, dynamic> _profil    = {};
  List<dynamic>        _enCours   = [];
  bool _isLoading  = true;
  bool _disponible = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${prefs.getString(AppConstants.tokenKey)}',
    };
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final h = await _headers();
      final results = await Future.wait([
        http.get(Uri.parse('${AppConstants.baseUrl}/livreur/profil'),                   headers: h),
        http.get(Uri.parse('${AppConstants.baseUrl}/livreur/livraisons/aujourd-hui'),   headers: h),
      ]);

      if (results[0].statusCode == 200) {
        final d = jsonDecode(results[0].body);
        final p = d['profil'] ?? {};
        setState(() {
          _profil    = p;
          _stats     = d['stats'] ?? {};
          _disponible = p['disponible'] == true || p['disponible'] == 1;
        });
      }
      if (results[1].statusCode == 200) {
        final d = jsonDecode(results[1].body);
        setState(() => _enCours = (d['livraisons'] as List? ?? [])
            .where((l) => l['statut'] == 'en_livraison').toList());
      }
    } catch (e) {
      debugPrint('LivreurDashboard charger: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleDisponibilite() async {
    try {
      final r = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/livreur/disponibilite'),
        headers: await _headers(),
      );
      final d = jsonDecode(r.body);
      if (d['succes'] == true && mounted) {
        setState(() => _disponible = d['disponible'] == true);
        _snack(d['message'] ?? '', AppColors.success);
      }
    } catch (e) {
      _snack('Erreur réseau', AppColors.error);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _naviguer(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
          .then((_) => _charger());

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: widget.user,
      title: 'Espace Livreur',
      accentColor: const Color(0xFFF4511E),
      children: [
        // ── Bannière disponibilité ─────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF4511E), Color(0xFFFF8F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.local_shipping_outlined,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bonjour, ${widget.user.prenom} !',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(
                    _disponible ? '🟢 Vous êtes disponible' : '🔴 Vous êtes hors ligne',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ]),
              ),
              Switch(
                value: _disponible,
                onChanged: (_) => _toggleDisponibilite(),
                activeColor: Colors.greenAccent,
                activeTrackColor: Colors.white.withOpacity(0.3),
                inactiveThumbColor: Colors.white60,
                inactiveTrackColor: Colors.white.withOpacity(0.2),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Stats rapides ─────────────────────────────────────────
        Row(children: [
          _statCard("Aujourd'hui",  '${_stats['aujourd_hui'] ?? 0}',     Icons.today_outlined,          const Color(0xFFF4511E)),
          const SizedBox(width: 10),
          _statCard('En cours',     '${_stats['en_cours'] ?? 0}',        Icons.directions_bike_outlined, Colors.orange),
          const SizedBox(width: 10),
          _statCard('Total',        '${_stats['total_livraisons'] ?? 0}',Icons.check_circle_outline,     const Color(0xFF00897B)),
        ]),

        const SizedBox(height: 24),

        // ── Livraisons en cours (alertes) ─────────────────────────
        if (_enCours.isNotEmpty) ...[
          Row(children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFFF4511E), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('${_enCours.length} livraison(s) en cours',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF4511E))),
          ]),
          const SizedBox(height: 10),
          ..._enCours.take(2).map((l) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4511E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF4511E).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.local_shipping_outlined, color: Color(0xFFF4511E), size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Commande #${l['id']}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${l['patient_prenom'] ?? ''} ${l['patient_nom'] ?? ''} — ${l['adresse_livraison'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ])),
              TextButton(
                onPressed: () => _naviguer(LivraisonsScreen(user: widget.user)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFF4511E)),
                child: const Text('Voir', style: TextStyle(fontSize: 12)),
              ),
            ]),
          )),
          const SizedBox(height: 16),
        ],

        // ── Actions ───────────────────────────────────────────────
        const Text('Mes livraisons', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        _actionCard(
          title: "Livraisons du jour",
          subtitle: "Commandes à livrer aujourd'hui",
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFFF4511E),
          badge: _enCours.length,
          onTap: () => _naviguer(LivraisonsScreen(user: widget.user)),
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: "Historique",
          subtitle: "Toutes mes livraisons effectuées",
          icon: Icons.history_outlined,
          color: const Color(0xFF00897B),
          onTap: () => _naviguer(HistoriqueLivraisonsScreen(user: widget.user)),
        ),

        const SizedBox(height: 24),
        const Text('Mon compte', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        _actionCard(
          title: "Mon profil",
          subtitle: "Zone de livraison, véhicule, infos",
          icon: Icons.person_outline,
          color: const Color(0xFF1E88E5),
          onTap: () => _naviguer(ProfilLivreurScreen(user: widget.user)),
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: "Carte & itinéraire",
          subtitle: "Navigation GPS (bientôt disponible)",
          icon: Icons.map_outlined,
          color: const Color(0xFF3949AB),
          disabled: true,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _statCard(String label, String valeur, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(valeur, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    int badge = 0,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: disabled ? Colors.grey[200] : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: disabled ? Colors.grey : color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: disabled ? Colors.grey : AppColors.textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 12,
                color: disabled ? Colors.grey[400] : AppColors.textSecondary)),
          ])),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            )
          else if (!disabled)
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// DASHBOARD PHARMACIEN
// ═════════════════════════════════════════════════════════════════════
class PharmacienDashboard extends StatefulWidget {
  final UserModel user;
  const PharmacienDashboard({super.key, required this.user});
  @override
  State<PharmacienDashboard> createState() => _PharmacienDashboardState();
}

class _PharmacienDashboardState extends State<PharmacienDashboard> {
  Map<String, dynamic> _statsCommandes    = {};
  Map<String, dynamic> _statsOrdonnances  = {};
  Map<String, dynamic> _statsStock        = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${prefs.getString(AppConstants.tokenKey)}',
    };
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final h = await _headers();
      final results = await Future.wait([
        http.get(Uri.parse('${AppConstants.baseUrl}/pharmacien/commandes'),    headers: h),
        http.get(Uri.parse('${AppConstants.baseUrl}/pharmacien/ordonnances'),  headers: h),
        http.get(Uri.parse('${AppConstants.baseUrl}/pharmacien/stock'),        headers: h),
      ]);
      if (results[0].statusCode == 200)
        setState(() => _statsCommandes   = jsonDecode(results[0].body)['stats'] ?? {});
      if (results[1].statusCode == 200)
        setState(() => _statsOrdonnances = jsonDecode(results[1].body)['stats'] ?? {});
      if (results[2].statusCode == 200)
        setState(() => _statsStock       = jsonDecode(results[2].body)['stats'] ?? {});
    } catch (e) {
      debugPrint('PharmacienDashboard charger: $e');
    }
    setState(() => _isLoading = false);
  }

  void _naviguer(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
          .then((_) => _charger());

  @override
  Widget build(BuildContext context) {
    final attente   = _statsCommandes['en_attente']   ?? 0;
    final nouvelles = _statsOrdonnances['nouvelles']  ?? 0;
    final rupture   = _statsStock['rupture']          ?? 0;
    final faible    = _statsStock['faible']           ?? 0;

    return BaseDashboard(
      user: widget.user,
      title: 'Espace Pharmacien',
      accentColor: const Color(0xFF8E24AA),
      children: [
        // ── Bannière ──────────────────────────────────────────────
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
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.local_pharmacy_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bonjour, ${widget.user.prenom} !',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('Gérez votre pharmacie facilement',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Alertes urgentes ──────────────────────────────────────
        if (attente > 0 || nouvelles > 0 || rupture > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.notifications_active_outlined, color: Colors.orange, size: 18),
                SizedBox(width: 6),
                Text('Actions requises', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange)),
              ]),
              const SizedBox(height: 8),
              if (attente > 0)
                _alerteLine('$attente commande(s) en attente de confirmation', const Color(0xFF8E24AA)),
              if (nouvelles > 0)
                _alerteLine('$nouvelles ordonnance(s) à traiter', const Color(0xFF1E88E5)),
              if (rupture > 0)
                _alerteLine('$rupture médicament(s) en rupture de stock', AppColors.error),
              if (faible > 0)
                _alerteLine('$faible médicament(s) à stock faible (≤10)', Colors.orange),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // ── Stats rapides ─────────────────────────────────────────
        Row(children: [
          _statCard('Commandes\nattente', '$attente',   Icons.hourglass_top_outlined,   const Color(0xFF8E24AA)),
          const SizedBox(width: 10),
          _statCard('Ordonnances\nnouvelles', '$nouvelles', Icons.description_outlined,     const Color(0xFF1E88E5)),
          const SizedBox(width: 10),
          _statCard('Ruptures\nstock', '$rupture',  Icons.warning_amber_outlined,    AppColors.error),
        ]),

        const SizedBox(height: 24),

        // ── Prescriptions & commandes ─────────────────────────────
        const Text('Prescriptions & commandes', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        _actionCard(
          title: 'Ordonnances reçues',
          subtitle: 'Valider et traiter les prescriptions',
          icon: Icons.description_outlined,
          color: const Color(0xFF8E24AA),
          badge: nouvelles,
          onTap: () => _naviguer(OrdonnancesPharmacienScreen(user: widget.user)),
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Commandes en cours',
          subtitle: 'Préparer et expédier les commandes',
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFFF4511E),
          badge: attente,
          onTap: () => _naviguer(CommandesPharmacienScreen(user: widget.user)),
        ),

        const SizedBox(height: 24),
        const Text('Stock & statistiques', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        _actionCard(
          title: 'Stock médicaments',
          subtitle: 'Inventaire, prix et ruptures',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF1E88E5),
          badge: rupture + faible,
          badgeColor: rupture > 0 ? AppColors.error : Colors.orange,
          onTap: () => _naviguer(StockMedicamentsScreen(user: widget.user)),
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: "Historique & ventes",
          subtitle: "Chiffre d'affaires, top médicaments",
          icon: Icons.bar_chart_outlined,
          color: const Color(0xFF00897B),
          onTap: () => _naviguer(HistoriqueVentesScreen(user: widget.user)),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _alerteLine(String msg, Color color) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _statCard(String label, String valeur, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(valeur, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    int badge = 0,
    Color? badgeColor,
    bool disabled = false,
  }) {
    final bc = badgeColor ?? color;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: bc, borderRadius: BorderRadius.circular(12)),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            )
          else
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}