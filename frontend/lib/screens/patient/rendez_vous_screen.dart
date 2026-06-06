import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class RendezVousScreen extends StatefulWidget {
  final UserModel user;
  const RendezVousScreen({super.key, required this.user});

  @override
  State<RendezVousScreen> createState() => _RendezVousScreenState();
}

class _RendezVousScreenState extends State<RendezVousScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _rendezVous = [];
  List<dynamic> _medecins = [];
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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _charger() async {
  setState(() => _isLoading = true);
  try {
    final headers = await _headers();

    final results = await Future.wait([
      http.get(Uri.parse('${AppConstants.baseUrl}/rendez-vous'), headers: headers),
      http.get(Uri.parse('${AppConstants.baseUrl}/rendez-vous/medecins'), headers: headers),
    ]);

    final rdvResponse     = results[0];
    final medecinResponse = results[1];

    debugPrint('RDV status: ${rdvResponse.statusCode}');
    debugPrint('Médecins status: ${medecinResponse.statusCode} | body: ${medecinResponse.body}');

    if (rdvResponse.statusCode == 200) {
      final data = jsonDecode(rdvResponse.body);
      setState(() => _rendezVous = data['rendez_vous'] ?? []);
    }

    if (medecinResponse.statusCode == 200) {
      final data = jsonDecode(medecinResponse.body);
      setState(() => _medecins = data['medecins'] ?? []);
    } else {
      // Affiche le vrai message d'erreur de l'API
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Impossible de charger les médecins (${medecinResponse.statusCode})'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  } catch (e) {
    debugPrint('Erreur _charger: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur réseau. Vérifiez votre connexion.'),
        backgroundColor: AppColors.error,
      ));
    }
  }
  setState(() => _isLoading = false);
}

  Future<void> _demanderRdv() async {
    int? medecinId;
    final dateController = TextEditingController();
    final heureController = TextEditingController();
    final motifController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Demander un rendez-vous', style: AppTextStyles.heading2),
              const SizedBox(height: 16),

              // Sélection médecin
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Médecin', style: AppTextStyles.label),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: medecinId,
                  onChanged: (v) => setStateModal(() => medecinId = v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_outlined, color: AppColors.primary, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  hint: const Text('Choisir un médecin'),
                  items: _medecins.map((m) => DropdownMenuItem<int>(
                    value: m['id'],
                    child: Text('Dr. ${m['prenom']} ${m['nom']} - ${m['specialite'] ?? 'Généraliste'}'),
                  )).toList(),
                ),
              ]),

              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Date *',
                  hint: 'JJ/MM/AAAA',
                  prefixIcon: Icons.calendar_today_outlined,
                  controller: dateController,
                )),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  label: 'Heure *',
                  hint: 'HH:MM',
                  prefixIcon: Icons.access_time,
                  controller: heureController,
                )),
              ]),

              const SizedBox(height: 12),

              AppTextField(
                label: 'Motif *',
                hint: 'Raison de la consultation',
                prefixIcon: Icons.medical_services_outlined,
                controller: motifController,
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              AppButton(
                text: 'Envoyer la demande',
                icon: Icons.send_outlined,
                color: const Color(0xFF00897B),
                onPressed: () async {
                  if (medecinId == null || dateController.text.isEmpty ||
                      heureController.text.isEmpty || motifController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Remplissez tous les champs obligatoires'),
                          backgroundColor: AppColors.error));
                    return;
                  }
                  Navigator.pop(context);

                  final headers = await _headers();
                  final date = dateController.text;
                  final dateParts = date.split('/');
                  final dateFormatee = dateParts.length == 3
                      ? '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}'
                      : date;

                  final response = await http.post(
                    Uri.parse('${AppConstants.baseUrl}/rendez-vous'),
                    headers: headers,
                    body: jsonEncode({
                      'medecin_id': medecinId,
                      'date_rdv': dateFormatee,
                      'heure_rdv': heureController.text,
                      'motif': motifController.text,
                    }),
                  );

                  final data = jsonDecode(response.body);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(data['message'] ?? ''),
                      backgroundColor: data['succes'] == true ? AppColors.success : AppColors.error,
                    ));
                    if (data['succes'] == true) _charger();
                  }
                },
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _annulerRdv(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: const Text('Voulez-vous vraiment annuler ce rendez-vous ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final headers = await _headers();
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/rendez-vous/$id/annuler'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? ''),
          backgroundColor: data['succes'] == true ? AppColors.success : AppColors.error,
        ));
        if (data['succes'] == true) _charger();
      }
    }
  }

  List<dynamic> _filtrerParStatut(String statut) {
    return _rendezVous.where((r) => r['statut'] == statut).toList();
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'en_attente': return Colors.orange;
      case 'confirme': return AppColors.success;
      case 'annule': return AppColors.error;
      case 'termine': return AppColors.textSecondary;
      default: return AppColors.primary;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'confirme': return 'Confirmé';
      case 'annule': return 'Annulé';
      case 'termine': return 'Terminé';
      default: return statut;
    }
  }

  IconData _statutIcon(String statut) {
    switch (statut) {
      case 'en_attente': return Icons.schedule;
      case 'confirme': return Icons.check_circle;
      case 'annule': return Icons.cancel;
      case 'termine': return Icons.done_all;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aVenir = _filtrerParStatut('confirme').length + _filtrerParStatut('en_attente').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Mes rendez-vous',
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
            Tab(text: 'À venir'),
            Tab(text: 'En attente'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _demanderRdv,
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau RDV', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Stats
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                color: const Color(0xFF00897B),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _statItem('À venir', '$aVenir', Icons.upcoming_outlined),
                  _statItem('Total', '${_rendezVous.length}', Icons.calendar_month_outlined),
                ]),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListe([..._filtrerParStatut('confirme')]),
                    _buildListe(_filtrerParStatut('en_attente')),
                    _buildListe([..._filtrerParStatut('termine'), ..._filtrerParStatut('annule')]),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _buildListe(List<dynamic> liste) {
    if (liste.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Aucun rendez-vous', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: liste.length,
        itemBuilder: (context, index) {
          final r = liste[index];
          final statut = r['statut'] ?? 'en_attente';
          final color = _statutColor(statut);
          final peutAnnuler = statut == 'en_attente' || statut == 'confirme';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medical_services_outlined, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dr. ${r['medecin_prenom'] ?? ''} ${r['medecin_nom'] ?? ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(r['specialite'] ?? 'Médecin généraliste',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statutIcon(statut), color: color, size: 12),
                    const SizedBox(width: 4),
                    Text(_statutLabel(statut),
                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),

              const Divider(height: 16),

              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(r['date_rdv'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(r['heure_rdv'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ]),

              if (r['motif'] != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.notes_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r['motif'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                ]),
              ],

              if (peutAnnuler) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _annulerRdv(r['id']),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                    label: const Text('Annuler', style: TextStyle(color: AppColors.error, fontSize: 13)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),
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
