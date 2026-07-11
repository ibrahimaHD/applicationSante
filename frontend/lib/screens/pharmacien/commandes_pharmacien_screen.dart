import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class CommandesPharmacienScreen extends StatefulWidget {
  final UserModel user;
  const CommandesPharmacienScreen({super.key, required this.user});
  @override
  State<CommandesPharmacienScreen> createState() => _CommandesPharmacienState();
}

class _CommandesPharmacienState extends State<CommandesPharmacienScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _commandes = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${prefs.getString(AppConstants.tokenKey)}'
    };
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final h = await _headers();
      final response = await http.get(
          Uri.parse('${AppConstants.baseUrl}/pharmacien/commandes'),
          headers: h);
      if (response.statusCode == 200) {
        final d = jsonDecode(response.body);
        setState(() {
          _commandes = d['commandes'] ?? [];
          _stats = d['stats'] ?? {};
        });
      }
    } catch (e) {
      debugPrint('$e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _majStatut(int id, String statut, {int? livreurId}) async {
    final r = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/pharmacien/commandes/$id'),
      headers: await _headers(),
      body: jsonEncode(
          {'statut': statut, if (livreurId != null) 'livreur_id': livreurId}),
    );
    final d = jsonDecode(r.body);
    if (mounted) {
      _snack(d['message'] ?? '',
          d['succes'] == true ? AppColors.success : AppColors.error);
      if (d['succes'] == true) _charger();
    }
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16)));

  List<dynamic> _filtrer(String statut) => statut == 'tous'
      ? _commandes
      : _commandes.where((c) => c['statut'] == statut).toList();

  Color _statutColor(String s) {
    switch (s) {
      case 'en_attente':
        return Colors.orange;
      case 'confirmee':
        return const Color(0xFF1E88E5);
      case 'en_preparation':
        return const Color(0xFF8E24AA);
      case 'en_livraison':
        return const Color(0xFFF4511E);
      case 'livree':
        return AppColors.success;
      case 'annulee':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'en_attente':
        return 'En attente';
      case 'confirmee':
        return 'Validation pharmacie';
      case 'en_preparation':
        return 'Préparation';
      case 'en_livraison':
        return 'Livreur affecté';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        title: const Text('Commandes',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _charger)
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 11),
          tabs: [
            Tab(text: 'Att.(${_filtrer('en_attente').length})'),
            Tab(text: 'Prép.(${_filtrer('en_preparation').length})'),
            const Tab(text: 'Livraison'),
            const Tab(text: 'Toutes'),
          ],
        ),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          color: const Color(0xFF8E24AA),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('En attente', '${_stats['en_attente'] ?? 0}',
                Icons.hourglass_top_outlined),
            _statItem('En cours', '${_stats['en_cours'] ?? 0}',
                Icons.local_shipping_outlined),
            _statItem('Livrées', '${_stats['livrees'] ?? 0}',
                Icons.check_circle_outline),
            _statItem('Total', '${_stats['total'] ?? 0}',
                Icons.receipt_long_outlined),
          ]),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(controller: _tabController, children: [
                  _buildListe(_filtrer('en_attente'), showActions: true),
                  _buildListe(_filtrer('en_preparation'), showActions: true),
                  _buildListe(_filtrer('en_livraison'), showActions: true),
                  _buildListe(_commandes, showActions: true),
                ]),
        ),
      ]),
    );
  }

  Widget _buildListe(List<dynamic> liste, {bool showActions = false}) {
    if (liste.isEmpty)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Aucune commande',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      ]));
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: liste.length,
        itemBuilder: (_, i) {
          final c = liste[i];
          final statut = c['statut'] ?? 'en_attente';
          final color = _statutColor(statut);
          final articles = c['articles'] as List? ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.shopping_bag_outlined,
                          color: color, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Commande #${c['id']}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text(
                            '${c['patient_prenom'] ?? ''} ${c['patient_nom'] ?? ''} — ${c['patient_tel'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(_statutLabel(statut),
                          style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 4),
                    Text('${c['montant_total'] ?? 0} FCFA',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8E24AA))),
                  ]),
                ]),
              ),
              if (articles.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: articles
                          .take(3)
                          .map((a) => Text(
                              '• ${a['medicament_nom'] ?? ''} x${a['quantite'] ?? 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)))
                          .toList()),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text('📍 ${c['adresse_livraison'] ?? '—'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ),
              if (showActions) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildActions(c, statut),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> c, String statut) {
    switch (statut) {
      case 'en_attente':
        return Row(children: [
          Expanded(
              child: OutlinedButton.icon(
            onPressed: () => _majStatut(c['id'], 'annulee'),
            icon: const Icon(Icons.close, size: 14),
            label: const Text('Refuser', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error)),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: ElevatedButton.icon(
            onPressed: () => _majStatut(c['id'], 'confirmee'),
            icon: const Icon(Icons.check, size: 14),
            label: const Text('Confirmer', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white),
          )),
        ]);
      case 'confirmee':
        return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _majStatut(c['id'], 'en_preparation'),
              icon: const Icon(Icons.inventory_2_outlined, size: 14),
              label: const Text('Démarrer préparation',
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E24AA),
                  foregroundColor: Colors.white),
            ));
      case 'en_preparation':
        return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _majStatut(c['id'], 'en_livraison'),
              icon: const Icon(Icons.local_shipping_outlined, size: 14),
              label:
                  const Text('Commande prête', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4511E),
                  foregroundColor: Colors.white),
            ));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _statItem(String l, String v, IconData i) => Column(children: [
        Icon(i, color: Colors.white70, size: 18),
        const SizedBox(height: 2),
        Text(v,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ]);
}
