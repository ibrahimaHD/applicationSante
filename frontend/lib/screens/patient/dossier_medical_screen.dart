import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';
import '../../services/pdf_service.dart';

class DossierMedicalScreen extends StatefulWidget {
  final UserModel user;
  final bool horsLigne;
  final bool exportPdf;

  const DossierMedicalScreen({
    super.key,
    required this.user,
    this.horsLigne = false,
    this.exportPdf = false,
  });

  @override
  State<DossierMedicalScreen> createState() => _DossierMedicalScreenState();
}

class _DossierMedicalScreenState extends State<DossierMedicalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = PatientService();
  Map<String, dynamic> _dossier = {};
  bool _isLoading = true;
  bool _synchronisation = false;
  bool _exportEnCours = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _charger();
    if (widget.exportPdf) {
      // Exporter après chargement des données
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted && _dossier.isNotEmpty) _exporterPdf();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    final result = await _service.getDossierMedical();
    if (result['succes'] == true) {
      setState(() => _dossier = result['dossier'] ?? {});
    }
    setState(() => _isLoading = false);
  }

  Future<void> _synchroniser() async {
    if (_synchronisation) return;
    setState(() => _synchronisation = true);
    await _charger();
    setState(() => _synchronisation = false);
    if (mounted) {
      _showSnack('Données synchronisées avec succès !', AppColors.success);
    }
  }

  Future<void> _exporterPdf() async {
    if (_exportEnCours) return;

    if (_dossier.isEmpty) {
      _showSnack('Chargement du dossier en cours, veuillez patienter...', Colors.orange);
      await _charger();
      if (_dossier.isEmpty) {
        _showSnack('Impossible de récupérer le dossier médical.', AppColors.error);
        return;
      }
    }

    setState(() => _exportEnCours = true);

    try {
      final patient = _dossier['patient'] ?? {};
      final nomPatient =
          '${patient['prenom'] ?? widget.user.prenom} ${patient['nom'] ?? widget.user.nom}';

      await PdfService.exporterDossierMedical(
        context: context,
        dossier: _dossier,
        nomPatient: nomPatient,
      );
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur lors de la génération du PDF : $e', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          color == AppColors.success
              ? Icons.check_circle_outline
              : color == AppColors.error
                  ? Icons.error_outline
                  : Icons.info_outline,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: Text(
          widget.horsLigne ? 'Dossier (Hors ligne)' : 'Dossier médical',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Bouton Synchroniser
          Tooltip(
            message: 'Synchroniser',
            child: IconButton(
              icon: _synchronisation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.sync, color: Colors.white),
              onPressed: _synchronisation ? null : _synchroniser,
            ),
          ),
          // Bouton Exporter PDF
          Tooltip(
            message: 'Exporter PDF',
            child: IconButton(
              icon: _exportEnCours
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              onPressed: _exportEnCours ? null : _exporterPdf,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Consultations'),
            Tab(text: 'Vaccinations'),
            Tab(text: 'Examens'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildResume(),
                _buildConsultations(),
                _buildVaccinations(),
                _buildExamens(),
              ],
            ),
    );
  }

  // ── RÉSUMÉ ──────────────────────────────────────────────────────
  Widget _buildResume() {
    final patient = _dossier['patient'] ?? {};
    final profil = _dossier['profil_medical'] ?? {};
    final consultations = _dossier['consultations'] as List? ?? [];
    final vaccinations = _dossier['vaccinations'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Bandeau hors-ligne
        if (widget.horsLigne)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.offline_bolt, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Mode hors ligne — données locales',
                      style: TextStyle(fontSize: 12, color: Colors.orange))),
            ]),
          ),

        // Statistiques rapides
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('Groupe sanguin', profil['groupe_sanguin'] ?? '—'),
            _divider(),
            _statItem('Consultations', '${consultations.length}'),
            _divider(),
            _statItem('Vaccins', '${vaccinations.length}'),
          ]),
        ),

        const SizedBox(height: 16),

        _buildSection('Identité', Icons.person_outline,
            const Color(0xFF00897B), [
          _infoRow('Nom', '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'),
          _infoRow('Email', patient['email'] ?? '—'),
          _infoRow('Téléphone', patient['telephone'] ?? '—'),
          _infoRow('Groupe sanguin', profil['groupe_sanguin'] ?? '—'),
          _infoRow('Date de naissance',
              profil['date_naissance']?.toString() ?? '—'),
        ]),

        const SizedBox(height: 16),

        _buildSection('Antécédents', Icons.history_outlined,
            const Color(0xFF1E88E5), [
          _infoRow('Antécédents', profil['antecedents'] ?? '—'),
          _infoRow('Allergies', profil['allergies'] ?? '—'),
        ]),

        const SizedBox(height: 16),

        _buildSection('Traitements', Icons.medication_outlined,
            const Color(0xFF8E24AA), [
          _infoRow('Médicaments', profil['medicaments_actuels'] ?? '—'),
          _infoRow('Médecin traitant', profil['medecin_traitant'] ?? '—'),
        ]),

        const SizedBox(height: 24),

        // Boutons d'action
        Row(children: [
          Expanded(
            child: _actionButton(
              label: _synchronisation ? 'Synchro...' : 'Synchroniser',
              icon: Icons.sync,
              color: const Color(0xFF00897B),
              onPressed: _synchronisation ? null : _synchroniser,
              isLoading: _synchronisation,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionButton(
              label: _exportEnCours ? 'Export...' : 'Exporter PDF',
              icon: Icons.picture_as_pdf_outlined,
              color: const Color(0xFFC62828),
              onPressed: _exportEnCours ? null : _exporterPdf,
              isLoading: _exportEnCours,
            ),
          ),
        ]),

        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withOpacity(0.6),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── CONSULTATIONS ────────────────────────────────────────────────
  Widget _buildConsultations() {
    final consultations = _dossier['consultations'] as List? ?? [];
    if (consultations.isEmpty) {
      return _buildEmptyState('Aucune consultation', Icons.medical_services_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: consultations.length,
      itemBuilder: (context, i) {
        final c = consultations[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.medical_services_outlined,
                  color: Color(0xFF00897B), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c['motif'] ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Text(c['date_consultation']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
            if (c['diagnostic'] != null) ...[
              const SizedBox(height: 6),
              _infoRow('Diagnostic', c['diagnostic']),
            ],
            if (c['traitement'] != null) _infoRow('Traitement', c['traitement']),
          ]),
        );
      },
    );
  }

  // ── VACCINATIONS ─────────────────────────────────────────────────
  Widget _buildVaccinations() {
    final vaccinations = _dossier['vaccinations'] as List? ?? [];
    if (vaccinations.isEmpty) {
      return _buildEmptyState('Aucune vaccination', Icons.vaccines_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: vaccinations.length,
      itemBuilder: (context, i) {
        final v = vaccinations[i];
        final statut = v['statut'] ?? 'non_fait';
        final color = statut == 'fait' ? AppColors.success : Colors.orange;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(statut == 'fait' ? Icons.check_circle : Icons.schedule,
                color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v['nom_vaccin'] ?? '',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              if (v['date_vaccination'] != null)
                Text('Date: ${v['date_vaccination']}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Text(statut == 'fait' ? 'Fait' : 'À faire',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ]),
        );
      },
    );
  }

  // ── EXAMENS ──────────────────────────────────────────────────────
  Widget _buildExamens() {
    final examens = _dossier['examens'] as List? ?? [];
    if (examens.isEmpty) {
      return _buildEmptyState('Aucun examen', Icons.science_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: examens.length,
      itemBuilder: (context, i) {
        final e = examens[i];
        final color =
            e['statut'] == 'normal' ? AppColors.success : Colors.orange;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.science_outlined, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(e['type_examen'] ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (e['resultat'] != null)
                    Text(e['resultat'],
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500)),
                  if (e['date_examen'] != null)
                    Text(e['date_examen'],
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                ])),
            Icon(
                e['statut'] == 'normal'
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: color,
                size: 20),
          ]),
        );
      },
    );
  }

  // ── WIDGETS PARTAGÉS ─────────────────────────────────────────────
  Widget _buildSection(String title, IconData icon, Color color,
      List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ]),
        const Divider(height: 16),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary))),
      ]),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  Widget _divider() {
    return Container(
        width: 1, height: 30, color: Colors.white.withOpacity(0.3));
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text(message,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 16)),
    ]));
  }
}