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
  State<ResultatsMedicauxScreen> createState() =>
      _ResultatsMedicauxScreenState();
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

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/resultats'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _resultats = data['resultats'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur résultats: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _supprimerResultat(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/patient/resultats/$id'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? ''),
        backgroundColor: data['succes'] == true
            ? AppColors.success
            : AppColors.error,
      ));
      if (data['succes'] == true) _charger();
    }
  }

  // ── Helpers ──────────────────────────────────────────
  List<dynamic> _filtrer(String type) => type == 'tous'
      ? _resultats
      : _resultats.where((r) => r['type'] == type).toList();

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'normal':    return AppColors.success;
      case 'attention': return Colors.orange;
      case 'urgent':    return AppColors.error;
      default:          return AppColors.success;
    }
  }

  IconData _statutIcon(String? statut) {
    switch (statut) {
      case 'normal':    return Icons.check_circle;
      case 'attention': return Icons.warning_amber_rounded;
      case 'urgent':    return Icons.error;
      default:          return Icons.check_circle;
    }
  }

  String _statutLabel(String? statut) {
    switch (statut) {
      case 'normal':    return 'Normal';
      case 'attention': return 'Attention';
      case 'urgent':    return 'Urgent';
      default:          return 'Normal';
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'analyse':  return const Color(0xFF1E88E5);
      case 'imagerie': return const Color(0xFF8E24AA);
      default:         return const Color(0xFF00897B);
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'analyse':  return Icons.science_outlined;
      case 'imagerie': return Icons.image_outlined;
      default:         return Icons.description_outlined;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'analyse':  return 'Analyse';
      case 'imagerie': return 'Imagerie';
      default:         return 'Autre';
    }
  }

  // ── Formater la date proprement ───────────────────────
  String _formaterDate(dynamic date) {
    if (date == null) return '';
    final s = date.toString();
    if (s.isEmpty) return '';
    // Prendre seulement AAAA-MM-JJ
    final dateOnly = s.contains('T') ? s.split('T')[0] : s;
    if (dateOnly.length >= 10) {
      final parts = dateOnly.substring(0, 10).split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }
    return dateOnly;
  }

  // ── Nom du médecin ────────────────────────────────────
  String _nomMedecin(Map<String, dynamic> r) {
    if (r['medecin'] != null &&
        r['medecin'].toString().isNotEmpty) {
      return r['medecin'].toString();
    }
    if (r['medecin_prenom'] != null || r['medecin_nom'] != null) {
      return 'Dr. ${r['medecin_prenom'] ?? ''} ${r['medecin_nom'] ?? ''}'
          .trim();
    }
    return 'Médecin non renseigné';
  }

  @override
  Widget build(BuildContext context) {
    final total     = _resultats.length;
    final normaux   = _resultats.where((r) => r['statut'] == 'normal').length;
    final attention = _resultats.where((r) => r['statut'] == 'attention').length;
    final urgents   = _resultats.where((r) => r['statut'] == 'urgent').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Résultats médicaux',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _charger,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12),
          tabs: [
            Tab(text: 'Tous ($total)'),
            Tab(text: 'Analyses (${_filtrer('analyse').length})'),
            Tab(text: 'Imageries (${_filtrer('imagerie').length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // ── Stats header ────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                color: const Color(0xFF3949AB),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('Total',    '$total',    Icons.science_outlined,         Colors.white),
                      _statItem('Normaux',  '$normaux',  Icons.check_circle_outline,     Colors.greenAccent),
                      _statItem('Attention','$attention',Icons.warning_amber_outlined,   Colors.orangeAccent),
                      _statItem('Urgents',  '$urgents',  Icons.emergency_outlined,       Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Les résultats sont ajoutés par votre médecin.',
                          style: TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),

              // ── Contenu ─────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListe(_filtrer('tous')),
                    _buildListe(_filtrer('analyse')),
                    _buildListe(_filtrer('imagerie')),
                  ],
                ),
              ),
            ]),
    );
  }

  // ── Liste des résultats ───────────────────────────────
  Widget _buildListe(List<dynamic> liste) {
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Aucun résultat',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Vos résultats apparaîtront ici\naprès consultation',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: liste.length,
        itemBuilder: (context, index) {
          final r           = liste[index] as Map<String, dynamic>;
          final statut      = r['statut']?.toString() ?? 'normal';
          final type        = r['type']?.toString() ?? 'analyse';
          final statutColor = _statutColor(statut);
          final typeColor   = _typeColor(type);
          final description = r['description']?.toString() ?? '';
          final dateStr     = _formaterDate(r['date_resultat']);
          final medecin     = _nomMedecin(r);

          return Dismissible(
            key: Key('res_${r['id']}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 24),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Supprimer ce résultat ?'),
                  content: const Text(
                      'Cette action est irréversible.'),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      child: const Text('Supprimer',
                          style:
                              TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ) ?? false;
            },
            onDismissed: (_) {
              final id = r['id'];
              if (id != null) _supprimerResultat(id);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: statutColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── En-tête ──────────────────────────
                  Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_typeIcon(type),
                          color: typeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['titre']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          // Badges type + statut
                          Wrap(
                            spacing: 6,
                            children: [
                              _badge(
                                  _typeLabel(type), typeColor),
                              _badge(_statutLabel(statut),
                                  statutColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(_statutIcon(statut),
                        color: statutColor, size: 24),
                  ]),

                  // ── Description ──────────────────────
                  if (description.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],

                  const SizedBox(height: 10),

                  // ── Pied : médecin + date ─────────────
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 13,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(medecin,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Widgets utilitaires ───────────────────────────────
  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _statItem(
      String label, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700)),
      Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 11)),
    ]);
  }
}