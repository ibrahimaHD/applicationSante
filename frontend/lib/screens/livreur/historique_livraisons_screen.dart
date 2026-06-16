import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class HistoriqueLivraisonsScreen extends StatefulWidget {
  final UserModel user;
  const HistoriqueLivraisonsScreen({super.key, required this.user});
  @override State<HistoriqueLivraisonsScreen> createState() => _HistLivState();
}

class _HistLivState extends State<HistoriqueLivraisonsScreen> {
  List<dynamic> _historique = [];
  Map<String,dynamic> _stats = {};
  bool _isLoading = true;

  @override void initState() { super.initState(); _charger(); }

  Future<Map<String,String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {'Content-Type':'application/json','Authorization':'Bearer ${prefs.getString(AppConstants.tokenKey)}'};
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(Uri.parse('${AppConstants.baseUrl}/livreur/historique'), headers: await _headers());
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        setState(() { _historique = d['historique']??[]; _stats = d['stats']??{}; });
      }
    } catch (e) { debugPrint('$e'); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Historique livraisons', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _charger)],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF00897B),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem("Aujourd'hui", '${_stats['aujourd_hui']??0}', Icons.today_outlined),
            _statItem('Semaine',     '${_stats['cette_semaine']??0}', Icons.date_range_outlined),
            _statItem('Ce mois',     '${_stats['ce_mois']??0}', Icons.calendar_month_outlined),
            _statItem('Total',       '${_stats['total_livrees']??0}', Icons.check_circle_outline),
          ]),
        ),
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _historique.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.history_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Aucune livraison effectuée', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ]))
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _historique.length,
                    itemBuilder: (_, i) {
                      final l = _historique[i];
                      final date = l['updated_at']?.toString().substring(0,10) ?? l['created_at']?.toString().substring(0,10) ?? '—';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Commande #${l['id']}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('${l['patient_prenom']??''} ${l['patient_nom']??''}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('📍 ${l['adresse_livraison']??'—'}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${l['montant_total']??0} F',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                            const SizedBox(height: 4),
                            Text(date, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _statItem(String l, String v, IconData i) => Column(children: [
    Icon(i, color: Colors.white70, size: 18),
    const SizedBox(height: 2),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
  ]);
}