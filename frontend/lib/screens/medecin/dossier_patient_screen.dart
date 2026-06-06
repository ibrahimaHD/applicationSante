import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';
 
class DossierPatientScreen extends StatefulWidget {
  final UserModel user;
  final int patientId;
  final String patientNom;
  const DossierPatientScreen({
    super.key,
    required this.user,
    required this.patientId,
    required this.patientNom,
  });
 
  @override
  State<DossierPatientScreen> createState() => _DossierPatientScreenState();
}
 
class _DossierPatientScreenState extends State<DossierPatientScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _dossier = {};
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
    final token = prefs.getString(AppConstants.tokenKey);
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }
 
  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/patients/${widget.patientId}/dossier'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        setState(() => _dossier = jsonDecode(response.body)['dossier'] ?? {});
      }
    } catch (e) { debugPrint('Erreur: $e'); }
    setState(() => _isLoading = false);
  }
 
  Future<void> _ajouterConsultation() async {
    final motifCtrl = TextEditingController();
    final diagCtrl = TextEditingController();
    final traitCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
        text: DateTime.now().toString().substring(0, 10));
 
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Consultation — ${widget.patientNom}', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              AppTextField(label: 'Motif *', hint: 'Raison de la consultation', prefixIcon: Icons.medical_services_outlined, controller: motifCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Diagnostic', hint: 'Diagnostic posé', prefixIcon: Icons.assignment_outlined, controller: diagCtrl, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(label: 'Traitement', hint: 'Traitement prescrit', prefixIcon: Icons.medication_outlined, controller: traitCtrl, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(label: 'Notes', hint: 'Observations complémentaires', prefixIcon: Icons.notes_outlined, controller: notesCtrl, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(label: 'Date', hint: 'AAAA-MM-JJ', prefixIcon: Icons.calendar_today_outlined, controller: dateCtrl),
              const SizedBox(height: 20),
              AppButton(
                text: 'Enregistrer la consultation',
                icon: Icons.save_outlined,
                color: const Color(0xFF00897B),
                onPressed: () async {
                  if (motifCtrl.text.isEmpty) return;
                  Navigator.pop(context);
                  final response = await http.post(
                    Uri.parse('${AppConstants.baseUrl}/medecin/consultations'),
                    headers: await _headers(),
                    body: jsonEncode({
                      'patient_id': widget.patientId,
                      'motif': motifCtrl.text,
                      'diagnostic': diagCtrl.text,
                      'traitement': traitCtrl.text,
                      'notes': notesCtrl.text,
                      'date_consultation': dateCtrl.text,
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
 
  Future<void> _creerOrdonnance() async {
    final medsCtrl = TextEditingController();
    final instrCtrl = TextEditingController();
 
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
            Text('Ordonnance — ${widget.patientNom}', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            AppTextField(label: 'Médicaments *', hint: 'Ex: Paracétamol 500mg - 3x/jour\nAmoxicilline 500mg - 2x/jour', prefixIcon: Icons.medication_outlined, controller: medsCtrl, maxLines: 4),
            const SizedBox(height: 12),
            AppTextField(label: 'Instructions', hint: 'Conseils et instructions au patient', prefixIcon: Icons.info_outline, controller: instrCtrl, maxLines: 3),
            const SizedBox(height: 20),
            AppButton(
              text: 'Créer l\'ordonnance',
              icon: Icons.description_outlined,
              color: const Color(0xFF8E24AA),
              onPressed: () async {
                if (medsCtrl.text.isEmpty) return;
                Navigator.pop(context);
                final response = await http.post(
                  Uri.parse('${AppConstants.baseUrl}/medecin/ordonnances'),
                  headers: await _headers(),
                  body: jsonEncode({
                    'patient_id': widget.patientId,
                    'medicaments': medsCtrl.text,
                    'instructions': instrCtrl.text,
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
    );
  }
 
  Future<void> _ajouterRappel() async {
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final heureCtrl = TextEditingController();
    String type = 'traitement';
 
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
              Text('Rappel pour ${widget.patientNom}', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              AppTextField(label: 'Titre *', hint: 'Ex: Prendre Metformine', prefixIcon: Icons.title, controller: titreCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Description', hint: 'Instructions détaillées', prefixIcon: Icons.description_outlined, controller: descCtrl),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                for (final t in ['traitement', 'vaccin', 'rdv', 'mesure'])
                  ChoiceChip(label: Text(t), selected: type == t,
                      onSelected: (_) => setStateModal(() => type = t),
                      selectedColor: const Color(0xFF00897B).withOpacity(0.2)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppTextField(label: 'Date', hint: 'JJ/MM/AAAA', prefixIcon: Icons.calendar_today_outlined, controller: dateCtrl)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Heure', hint: 'HH:MM', prefixIcon: Icons.access_time, controller: heureCtrl)),
              ]),
              const SizedBox(height: 20),
              AppButton(
                text: 'Créer le rappel',
                icon: Icons.notifications_outlined,
                color: const Color(0xFF00897B),
                onPressed: () async {
                  if (titreCtrl.text.isEmpty) return;
                  Navigator.pop(context);
                  final response = await http.post(
                    Uri.parse('${AppConstants.baseUrl}/medecin/rappels-patient'),
                    headers: await _headers(),
                    body: jsonEncode({
                      'patient_id': widget.patientId,
                      'titre': titreCtrl.text,
                      'description': descCtrl.text,
                      'type': type,
                      'date_rappel': dateCtrl.text,
                      'heure_rappel': heureCtrl.text,
                    }),
                  );
                  final data = jsonDecode(response.body);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(data['message'] ?? ''),
                      backgroundColor: data['succes'] == true ? AppColors.success : AppColors.error,
                    ));
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
 
  @override
  Widget build(BuildContext context) {
    final patient = _dossier['patient'] ?? {};
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: Text(widget.patientNom,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'consultation': _ajouterConsultation(); break;
                case 'ordonnance': _creerOrdonnance(); break;
                case 'rappel': _ajouterRappel(); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'consultation', child: Row(children: [Icon(Icons.medical_services_outlined, size: 18), SizedBox(width: 8), Text('Consultation')])),
              const PopupMenuItem(value: 'ordonnance', child: Row(children: [Icon(Icons.description_outlined, size: 18), SizedBox(width: 8), Text('Ordonnance')])),
              const PopupMenuItem(value: 'rappel', child: Row(children: [Icon(Icons.notifications_outlined, size: 18), SizedBox(width: 8), Text('Rappel patient')])),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 11),
          tabs: const [
            Tab(text: 'Infos'),
            Tab(text: 'Consultations'),
            Tab(text: 'Ordonnances'),
            Tab(text: 'Examens'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInfos(patient),
                _buildListe(_dossier['consultations'], 'Aucune consultation', _buildConsultationCard),
                _buildListe(_dossier['ordonnances'], 'Aucune ordonnance', _buildOrdonnanceCard),
                _buildListe(_dossier['examens'], 'Aucun examen', _buildExamenCard),
              ],
            ),
    );
  }
 
  Widget _buildInfos(Map<String, dynamic> p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Avatar
        Center(child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF00ACC1)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(child: Text(
            '${(p['prenom'] ?? 'P')[0]}${(p['nom'] ?? 'N')[0]}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
          )),
        )),
        const SizedBox(height: 16),
        _infoCard('Identité', Icons.person_outline, const Color(0xFF1E88E5), [
          _infoRow('Nom complet', '${p['prenom'] ?? ''} ${p['nom'] ?? ''}'),
          _infoRow('Email', p['email'] ?? '--'),
          _infoRow('Téléphone', p['telephone'] ?? '--'),
          _infoRow('Date naissance', p['date_naissance'] ?? '--'),
          _infoRow('Groupe sanguin', p['groupe_sanguin'] ?? '--'),
        ]),
        const SizedBox(height: 16),
        _infoCard('Médical', Icons.medical_information_outlined, const Color(0xFF00897B), [
          _infoRow('Allergies', p['allergies'] ?? '--'),
          _infoRow('Antécédents', p['antecedents'] ?? '--'),
          _infoRow('Traitements', p['medicaments_actuels'] ?? '--'),
        ]),
      ]),
    );
  }
 
  Widget _buildListe(List? liste, String emptyMsg, Widget Function(dynamic) builder) {
    if (liste == null || liste.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(emptyMsg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: liste.length,
      itemBuilder: (_, i) => builder(liste[i]),
    );
  }
 
  Widget _buildConsultationCard(dynamic c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.medical_services_outlined, color: Color(0xFF00897B), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(c['motif'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          Text(c['date_consultation'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        if (c['diagnostic'] != null) ...[const SizedBox(height: 6), _infoRow('Diagnostic', c['diagnostic'])],
        if (c['traitement'] != null) _infoRow('Traitement', c['traitement']),
      ]),
    );
  }
 
  Widget _buildOrdonnanceCard(dynamic o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.description_outlined, color: Color(0xFF8E24AA), size: 18),
          const SizedBox(width: 8),
          Text('Ordonnance du ${o['date_ordonnance'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 8),
        Text(o['medicaments'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (o['instructions'] != null) ...[
          const SizedBox(height: 4),
          Text(o['instructions'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }
 
  Widget _buildExamenCard(dynamic e) {
    final statut = e['statut'] ?? 'normal';
    final color = statut == 'normal' ? AppColors.success : statut == 'attention' ? Colors.orange : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Icon(Icons.science_outlined, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e['type_examen'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (e['resultat'] != null) Text(e['resultat'], style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          Text(e['date_examen'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Icon(statut == 'normal' ? Icons.check_circle : Icons.warning_amber, color: color, size: 20),
      ]),
    );
  }
 
  Widget _infoCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
        const Divider(height: 16),
        ...children,
      ]),
    );
  }
 
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ]),
    );
  }
}
 