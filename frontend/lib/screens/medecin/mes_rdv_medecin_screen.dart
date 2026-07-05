import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class MesRdvMedecinScreen extends StatefulWidget {
  final UserModel user;
  const MesRdvMedecinScreen({super.key, required this.user});

  @override
  State<MesRdvMedecinScreen> createState() => _RdvMedecinScreenState();
}

class _RdvMedecinScreenState extends State<MesRdvMedecinScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _rdv = [];
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
      // ✅ Bonne route : /rendez-vous/mes-rdv
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/rendez-vous/mes-rdv'),
        headers: await _headers(),
      );
      debugPrint('Mes RDV status: ${response.statusCode}');
      debugPrint('Mes RDV body: ${response.body}');
      if (response.statusCode == 200) {
        setState(() => _rdv = jsonDecode(response.body)['rendez_vous'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur chargement RDV médecin: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _majStatut(int id, String statut) async {
    String? notes;

    if (statut == 'annule') {
      final ctrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Raison du refus'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Motif du refus...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                notes = ctrl.text;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Confirmer le refus',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    try {
      final headers = await _headers();
      
      // ✅ Bonne route : /rendez-vous/:id/statut
      final url = '${AppConstants.baseUrl}/rendez-vous/$id/statut';
      debugPrint('=== MAJ STATUT ===');
      debugPrint('URL: $url');
      debugPrint('Statut: $statut');

      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'statut': statut,
          'notes_medecin': notes,
        }),
      );

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse: ${response.body}');

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
    } catch (e) {
      debugPrint('Erreur maj statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  List<dynamic> _filtrer(String statut) =>
      statut == 'tous'
          ? _rdv
          : _rdv.where((r) => r['statut'] == statut).toList();

  Color _statutColor(String s) {
    switch (s) {
      case 'en_attente': return Colors.orange;
      case 'confirme':   return AppColors.success;
      case 'annule':     return AppColors.error;
      case 'termine':    return AppColors.textSecondary;
      default:           return AppColors.primary;
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'en_attente': return 'En attente';
      case 'confirme':   return 'Confirmé';
      case 'annule':     return 'Annulé';
      case 'termine':    return 'Terminé';
      default:           return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enAttente = _filtrer('en_attente').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Mes rendez-vous',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
          tabs: [
            Tab(text: 'En attente${enAttente > 0 ? ' ($enAttente)' : ''}'),
            const Tab(text: 'Confirmés'),
            const Tab(text: 'Historique'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListe(_filtrer('en_attente'), showActions: true),
                _buildListe(_filtrer('confirme'), showActionsTerminer: true),
                _buildListe([
                  ..._filtrer('termine'),
                  ..._filtrer('annule'),
                ]),
              ],
            ),
    );
  }

  Widget _buildListe(
    List<dynamic> liste, {
    bool showActions = false,
    bool showActionsTerminer = false,
  }) {
    if (liste.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucun rendez-vous',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: liste.length,
        itemBuilder: (context, index) {
          final r = liste[index];
          final statut = r['statut'] ?? 'en_attente';
          final color = _statutColor(statut);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 8)
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // En-tête patient
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Color(0xFF00897B), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r['patient_prenom'] ?? ''} ${r['patient_nom'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    Text(r['patient_tel'] ?? r['patient_telephone'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statutLabel(statut),
                    style: TextStyle(
                        fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),

              const Divider(height: 16),

              // Date et heure
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(r['date_rdv']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(r['heure_rdv']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ]),

              if (r['motif'] != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.notes_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r['motif'],
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ]),
              ],

              // Boutons confirmer / refuser
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _majStatut(r['id'], 'annule'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _majStatut(r['id'], 'confirme'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Confirmer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
              ],

              // Bouton terminer
              if (showActionsTerminer) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _majStatut(r['id'], 'termine'),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Marquer comme terminé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}