import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class LivraisonsScreen extends StatefulWidget {
  final UserModel user;
  const LivraisonsScreen({super.key, required this.user});
  @override State<LivraisonsScreen> createState() => _LivraisonsState();
}

class _LivraisonsState extends State<LivraisonsScreen> {
  List<dynamic> _livraisons = [];
  Map<String,dynamic> _stats = {};
  bool _isLoading = true;
  bool _disponible = true;

  @override void initState() { super.initState(); _charger(); }

  Future<Map<String,String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {'Content-Type':'application/json',
            'Authorization':'Bearer ${prefs.getString(AppConstants.tokenKey)}'};
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse('${AppConstants.baseUrl}/livreur/livraisons/aujourd-hui'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        setState(() { _livraisons = d['livraisons']??[]; _stats = d['stats']??{}; });
      }
      // Charger aussi le profil pour état disponibilité
      final rp = await http.get(Uri.parse('${AppConstants.baseUrl}/livreur/profil'), headers: await _headers());
      if (rp.statusCode == 200) {
        final dp = jsonDecode(rp.body);
        setState(() => _disponible = dp['profil']?['disponible'] == true || dp['profil']?['disponible'] == 1);
      }
    } catch (e) { debugPrint('charger livraisons: $e'); }
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
        _snack(d['message']??'', AppColors.success);
      }
    } catch (e) { _snack('Erreur réseau', AppColors.error); }
  }

  Future<void> _majStatut(Map<String,dynamic> livraison, String statut) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(statut == 'livree' ? 'Confirmer la livraison ?' : 'Démarrer la livraison ?'),
        content: Text(statut == 'livree'
          ? 'Avez-vous bien remis la commande #${livraison['id']} au patient ?'
          : 'Vous êtes en route pour la commande #${livraison['id']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: statut == 'livree' ? AppColors.success : const Color(0xFFF4511E),
              foregroundColor: Colors.white,
            ),
            child: Text(statut == 'livree' ? 'Confirmer livraison' : 'Démarrer'),
          ),
        ],
      ),
    );
    if (confirmation != true) return;

    try {
      final r = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/livreur/livraisons/${livraison['id']}'),
        headers: await _headers(),
        body: jsonEncode({'statut': statut}),
      );
      final d = jsonDecode(r.body);
      if (mounted) {
        _snack(d['message']??'', d['succes']==true ? AppColors.success : AppColors.error);
        if (d['succes']==true) _charger();
      }
    } catch (e) { _snack('Erreur réseau', AppColors.error); }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: color,
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             margin: const EdgeInsets.all(16)));

  Color _statutColor(String s) {
    switch (s) {
      case 'confirmee':      return const Color(0xFF1E88E5);
      case 'en_preparation': return const Color(0xFF8E24AA);
      case 'en_livraison':   return const Color(0xFFF4511E);
      case 'livree':         return AppColors.success;
      default:               return Colors.grey;
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'confirmee':      return 'Confirmée';
      case 'en_preparation': return 'En préparation';
      case 'en_livraison':   return 'En livraison';
      case 'livree':         return 'Livrée ✓';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4511E),
        title: const Text("Livraisons du jour", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _charger)],
      ),
      body: Column(children: [
        // Header disponibilité + stats
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF4511E),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Column(children: [
            // Toggle disponibilité
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(_disponible ? Icons.circle : Icons.circle_outlined, color: _disponible ? Colors.greenAccent : Colors.white60, size: 12),
                const SizedBox(width: 8),
                Text(_disponible ? 'En ligne — disponible' : 'Hors ligne',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: _disponible,
                  onChanged: (_) => _toggleDisponibilite(),
                  activeColor: Colors.greenAccent,
                  activeTrackColor: Colors.white.withOpacity(0.3),
                  inactiveThumbColor: Colors.white60,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                ),
              ]),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statItem('Total',    '${_stats['total']??0}',    Icons.local_shipping_outlined),
              _statItem('En cours', '${_stats['en_cours']??0}', Icons.directions_bike_outlined),
              _statItem('Livrées',  '${_stats['livrees']??0}',  Icons.check_circle_outline),
            ]),
          ]),
        ),

        // Liste livraisons
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _livraisons.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Aucune livraison aujourd'hui", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("Revenez plus tard !", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]))
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _livraisons.length,
                    itemBuilder: (_, i) {
                      final l = _livraisons[i];
                      final statut = l['statut']??'confirmee';
                      final color  = _statutColor(statut);
                      final articles = l['articles'] as List? ?? [];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: color.withOpacity(0.3)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // En-tête carte
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                child: Icon(Icons.local_shipping_outlined, color: color, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Commande #${l['id']}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                Text('${l['patient_prenom']??''} ${l['patient_nom']??''}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Text(_statutLabel(statut), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          ),

                          // Adresse + téléphone
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                            child: Column(children: [
                              Row(children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFF4511E)),
                                const SizedBox(width: 6),
                                Expanded(child: Text(l['adresse_livraison']??'Adresse non précisée',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF1E88E5)),
                                const SizedBox(width: 6),
                                Text(l['patient_tel']??'—', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                              ]),
                            ]),
                          ),

                          // Articles
                          if (articles.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              child: Wrap(
                                spacing: 6, runSpacing: 4,
                                children: articles.map((a) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${a['medicament_nom']??''} ×${a['quantite']??1}',
                                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                                )).toList(),
                              ),
                            ),

                          // Montant
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(children: [
                              const Text('Montant :', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(width: 6),
                              Text('${l['montant_total']??0} FCFA',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFF4511E))),
                            ]),
                          ),

                          // Boutons action
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildActions(l, statut),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildActions(Map<String,dynamic> l, String statut) {
    if (statut == 'confirmee' || statut == 'en_preparation') {
      return SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () => _majStatut(l, 'en_livraison'),
        icon: const Icon(Icons.directions_bike_outlined, size: 18),
        label: const Text('Démarrer la livraison'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4511E), foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
    }
    if (statut == 'en_livraison') {
      return SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () => _majStatut(l, 'livree'),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('Confirmer la livraison'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
    }
    return const SizedBox.shrink();
  }

  Widget _statItem(String l, String v, IconData i) => Column(children: [
    Icon(i, color: Colors.white70, size: 20),
    const SizedBox(height: 3),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]);
}