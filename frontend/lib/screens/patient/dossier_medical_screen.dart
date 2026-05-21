import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

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
  bool _synchronisation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.exportPdf) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _exporterPdf());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exporterPdf() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Génération du PDF...'),
        ]),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('PDF exporté avec succès !'),
          ]),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _synchroniser() async {
    setState(() => _synchronisation = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _synchronisation = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données synchronisées !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            widget.horsLigne ? 'Dossier médical (Hors ligne)' : 'Dossier médical',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (widget.horsLigne)
            const Text('Mode hors ligne', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.horsLigne)
            IconButton(
              icon: _synchronisation
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.sync, color: Colors.white),
              onPressed: _synchronisation ? null : _synchroniser,
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            onPressed: _exporterPdf,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Diagnostics'),
            Tab(text: 'Ordonnances'),
            Tab(text: 'Examens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResume(),
          _buildDiagnostics(),
          _buildOrdonnances(),
          _buildExamens(),
        ],
      ),
    );
  }

  Widget _buildResume() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Statut hors ligne
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
              Expanded(child: Text('Mode hors ligne — Dernière synchronisation: 20/05/2026',
                  style: TextStyle(fontSize: 12, color: Colors.orange))),
            ]),
          ),

        // Identité
        _buildSection('Identité du patient', Icons.person_outline, const Color(0xFF00897B), [
          _infoRow('Nom complet', widget.user.fullName),
          _infoRow('Email', widget.user.email),
          _infoRow('Téléphone', widget.user.telephone),
          _infoRow('Groupe sanguin', 'A+'),
          _infoRow('Date de naissance', '01/01/1990'),
        ]),

        const SizedBox(height: 16),

        _buildSection('Antécédents', Icons.history_outlined, const Color(0xFF1E88E5), [
          _infoRow('Maladies chroniques', 'Diabète type 2'),
          _infoRow('Allergies', 'Pénicilline'),
          _infoRow('Chirurgies', 'Appendicectomie (2015)'),
        ]),

        const SizedBox(height: 16),

        _buildSection('Traitements en cours', Icons.medication_outlined, const Color(0xFF8E24AA), [
          _infoRow('Médicament 1', 'Metformine 500mg - 2x/jour'),
          _infoRow('Médicament 2', 'Paracétamol 1g - si douleur'),
        ]),

        const SizedBox(height: 24),

        // Boutons d'action
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _synchroniser,
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Synchroniser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _exporterPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Exporter PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDiagnostics() {
    final diagnostics = [
      {'date': '15/05/2026', 'diagnostic': 'Rhinite allergique', 'medecin': 'Dr. Traoré', 'traitement': 'Antihistaminique'},
      {'date': '02/04/2026', 'diagnostic': 'Gastrite légère', 'medecin': 'Dr. Ouédraogo', 'traitement': 'Oméprazole'},
      {'date': '05/01/2026', 'diagnostic': 'Infection virale', 'medecin': 'Dr. Traoré', 'traitement': 'Repos + Paracétamol'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: diagnostics.length,
      itemBuilder: (context, i) {
        final d = diagnostics[i];
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
              Text(d['diagnostic']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              Text(d['date']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 8),
            _infoRow('Médecin', d['medecin']!),
            _infoRow('Traitement', d['traitement']!),
          ]),
        );
      },
    );
  }

  Widget _buildOrdonnances() {
    final ordonnances = [
      {'date': '15/05/2026', 'medecin': 'Dr. Traoré', 'medicaments': ['Cetirizine 10mg - 1/jour', 'Sérum physiologique - 3x/jour']},
      {'date': '02/04/2026', 'medecin': 'Dr. Ouédraogo', 'medicaments': ['Oméprazole 20mg - 1/jour avant repas', 'Régime sans alcool']},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: ordonnances.length,
      itemBuilder: (context, i) {
        final o = ordonnances[i];
        final meds = o['medicaments'] as List;
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
              Text('Ordonnance du ${o['date']}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 4),
            Text(o['medecin'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Divider(height: 16),
            ...meds.map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                const Icon(Icons.medication_outlined, size: 14, color: Color(0xFF8E24AA)),
                const SizedBox(width: 8),
                Expanded(child: Text(m as String, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
              ]),
            )),
          ]),
        );
      },
    );
  }

  Widget _buildExamens() {
    final examens = [
      {'date': '12/04/2026', 'type': 'Bilan sanguin', 'resultat': 'Normal', 'statut': 'normal'},
      {'date': '10/03/2026', 'type': 'Glycémie à jeun', 'resultat': '1.26 g/L', 'statut': 'attention'},
      {'date': '05/02/2026', 'type': 'ECG', 'resultat': 'Rythme sinusal normal', 'statut': 'normal'},
      {'date': '15/01/2026', 'type': 'Radiographie thorax', 'resultat': 'Poumons clairs', 'statut': 'normal'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: examens.length,
      itemBuilder: (context, i) {
        final e = examens[i];
        final color = e['statut'] == 'normal' ? AppColors.success : Colors.orange;
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.science_outlined, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['type']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(e['resultat']!, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
              Text(e['date']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Icon(e['statut'] == 'normal' ? Icons.check_circle : Icons.warning_amber,
                color: color, size: 22),
          ]),
        );
      },
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ]),
    );
  }
}
