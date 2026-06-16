import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class HistoriqueVentesScreen extends StatefulWidget {
  final UserModel user;
  const HistoriqueVentesScreen({super.key, required this.user});
  @override State<HistoriqueVentesScreen> createState() => _HistoriqueVentesState();
}

class _HistoriqueVentesState extends State<HistoriqueVentesScreen> {
  List<dynamic> _commandes   = [];
  List<dynamic> _topMeds     = [];
  Map<String,dynamic> _stats = {};
  bool _isLoading = true;
  String _periode = '30';

  @override void initState() { super.initState(); _charger(); }

  Future<Map<String,String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {'Content-Type':'application/json','Authorization':'Bearer ${prefs.getString(AppConstants.tokenKey)}'};
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse('${AppConstants.baseUrl}/pharmacien/ventes?periode=$_periode'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        setState(() {
          _commandes = d['commandes']??[];
          _topMeds   = d['top_medicaments']??[];
          _stats     = d['stats']??{};
        });
      }
    } catch (e) { debugPrint('$e'); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Historique & ventes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, color: Colors.white),
            onSelected: (v) { setState(() => _periode = v); _charger(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: '7',   child: Text('7 derniers jours')),
              const PopupMenuItem(value: '30',  child: Text('30 derniers jours')),
              const PopupMenuItem(value: '90',  child: Text('3 derniers mois')),
              const PopupMenuItem(value: '365', child: Text('Cette année')),
            ],
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _charger,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Stats globales
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF00ACC1)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    Text('Période : derniers $_periode jours',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _bigStat('Revenu total', '${_stats['revenu_total']?.toStringAsFixed(0)??'0'} F', Icons.payments_outlined),
                      _divV(),
                      _bigStat('Commandes', '${_stats['total_commandes']??0}', Icons.shopping_bag_outlined),
                      _divV(),
                      _bigStat('Panier moyen', '${_stats['panier_moyen']??0} F', Icons.analytics_outlined),
                    ]),
                  ]),
                ),

                const SizedBox(height: 20),

                // Top médicaments
                if (_topMeds.isNotEmpty) ...[
                  const Text('Top médicaments vendus', style: AppTextStyles.heading2),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                    child: Column(children: _topMeds.asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final m    = e.value;
                      final pct  = (_topMeds.isNotEmpty && (_topMeds[0]['total_vendu']??0) > 0)
                          ? ((m['total_vendu']??0) / (_topMeds[0]['total_vendu']??1) * 100).toDouble()
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Container(width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey[300] : Colors.brown[100],
                              shape: BoxShape.circle),
                            child: Center(child: Text('$rank',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m['nom']??'', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                backgroundColor: Colors.grey[100],
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
                                minHeight: 6,
                              ),
                            ),
                          ])),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${m['total_vendu']??0} unités',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E88E5))),
                            Text('${m['revenu']?.toStringAsFixed(0)??'0'} F',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ]),
                        ]),
                      );
                    }).toList()),
                  ),
                  const SizedBox(height: 20),
                ],

                // Liste commandes
                const Text('Commandes livrées', style: AppTextStyles.heading2),
                const SizedBox(height: 12),
                if (_commandes.isEmpty)
                  Center(child: Column(children: [
                    const SizedBox(height: 32),
                    Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('Aucune vente sur cette période', style: TextStyle(color: AppColors.textSecondary)),
                  ]))
                else
                  ..._commandes.map((c) {
                    final articles = c['articles'] as List? ?? [];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                      child: Row(children: [
                        Container(width: 44, height: 44,
                          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('#${c['id']} — ${c['patient_prenom']??''} ${c['patient_nom']??''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          if (articles.isNotEmpty)
                            Text(articles.map((a)=>'${a['medicament_nom']??''} x${a['quantite']??1}').join(', '),
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis),
                          Text(c['created_at']?.toString().substring(0,10)??'',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ])),
                        Text('${c['montant_total']??0} F',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                      ]),
                    );
                  }),
                const SizedBox(height: 32),
              ]),
            ),
          ),
    );
  }

  Widget _bigStat(String l, String v, IconData i) => Column(children: [
    Icon(i, color: Colors.white70, size: 20),
    const SizedBox(height: 4),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
  ]);

  Widget _divV() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3));
}

// ignore: non_constant_identifier_names
TextStyle get AppTextStyles_heading2 => const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A237E));