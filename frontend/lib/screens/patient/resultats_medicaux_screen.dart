import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class ResultatsMedicauxScreen extends StatefulWidget {
  final UserModel user;
  const ResultatsMedicauxScreen({super.key, required this.user});

  @override
  State<ResultatsMedicauxScreen> createState() => _ResultatsMedicauxScreenState();
}

class _ResultatsMedicauxScreenState extends State<ResultatsMedicauxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _resultats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/resultats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _resultats = data['resultats'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  List<dynamic> _filtrerParType(String type) =>
      type == 'tous' ? _resultats : _resultats.where((r) => r['type'] == type).toList();

  Color _statutColor(String statut) {
    switch (statut) {
      case 'normal': return AppColors.success;
      case 'attention': return Colors.orange;
      case 'urgent': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'analyse': return Icons.science_outlined;
      case 'imagerie': return Icons.image_outlined;
      default: return Icons.description_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'analyse': return const Color(0xFF1E88E5);
      case 'imagerie': return const Color(0xFF8E24AA);
      default: return const Color(0xFF00897B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Résultats médicaux',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Analyses'),
            Tab(text: 'Imageries'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Stats
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                color: const Color(0xFF3949AB),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _statItem('Total', '${_resultats.length}', Icons.science_outlined),
                    _statItem('Analyses', '${_filtrerParType('analyse').length}', Icons.biotech_outlined),
                    _statItem('Imageries', '${_filtrerParType('imagerie').length}', Icons.image_outlined),
                  ]),
                  const SizedBox(height: 12),
                  // Info message
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Les résultats sont ajoutés par votre médecin après consultation.',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      )),
                    ]),
                  ),
                ]),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListe(_filtrerParType('tous')),
                    _buildListe(_filtrerParType('analyse')),
                    _buildListe(_filtrerParType('imagerie')),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _buildListe(List<dynamic> liste) {
    if (liste.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.science_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Aucun résultat', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Vos résultats apparaîtront ici après consultation',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: liste.length,
        itemBuilder: (context, index) {
          final r = liste[index];
          final statut = r['statut'] ?? 'normal';
          final type = r['type'] ?? 'analyse';
          final statutColor = _statutColor(statut);
          final typeColor = _typeColor(type);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statutColor.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(type), color: typeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['titre'] ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (r['medecin'] != null)
                    Text('Dr. ${r['medecin']}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statut == 'normal' ? 'Normal' : statut == 'attention' ? 'Attention' : 'Urgent',
                      style: TextStyle(fontSize: 11, color: statutColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(r['date_resultat'] ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ]),
              if (r['description'] != null && r['description'].toString().isNotEmpty) ...[
                const Divider(height: 16),
                Text(r['description'],
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}
