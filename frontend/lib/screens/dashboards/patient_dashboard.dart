import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'base_dashboard.dart';
import '../patient/profil_medical_screen.dart';
import '../patient/carnet_sante_screen.dart';
import '../patient/vaccinations_screen.dart';
import '../patient/rappels_screen.dart';
import '../patient/suivi_grossesse_screen.dart';
import '../patient/vaccinations_enfants_screen.dart';
import '../patient/dossier_medical_screen.dart';
import '../patient/informations_personnelles_screen.dart';
import '../patient/rendez_vous_screen.dart';
import '../patient/audit_acces_screen.dart';
import '../patient/cartographie_screen.dart';
import '../patient/pharmacie_screen.dart';
import '../patient/qr_code_screen.dart';

class PatientDashboard extends StatefulWidget {
  final UserModel user;
  const PatientDashboard({super.key, required this.user});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final _service = PatientService();
  UserModel? _userMaj;

  @override
  void initState() {
    super.initState();
    _chargerInfos();
  }

  Future<void> _chargerInfos() async {
    final result = await _service.getInfosPersonnelles();
    if (result['succes'] == true && mounted) {
      final infos = result['infos'] ?? {};
      setState(() {
        _userMaj = widget.user.copyWith(
          nom: infos['nom'] ?? widget.user.nom,
          prenom: infos['prenom'] ?? widget.user.prenom,
          telephone: infos['telephone'] ?? widget.user.telephone,
        );
      });
    }
  }

  UserModel get _user => _userMaj ?? widget.user;

  Future<void> _contacterDernierMedecin() async {
    final result = await _service.getDernierMedecinConsulte();
    if (!mounted) return;
    if (result['succes'] != true || result['medecin'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Aucun médecin à contacter.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final medecin = result['medecin'];
    final phone =
        _normaliserTelephoneWhatsApp(medecin['telephone']?.toString() ?? '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le médecin n a pas de numéro WhatsApp renseigné.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final nom = 'Dr. ${medecin['prenom'] ?? ''} ${medecin['nom'] ?? ''}'.trim();
    final message = Uri.encodeComponent(
      'Bonjour $nom, je suis ${_user.fullName}, patient LaafiBa. Je souhaite échanger avec vous concernant ma consultation.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Impossible d ouvrir WhatsApp.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  String _normaliserTelephoneWhatsApp(String raw) {
    var phone = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('00')) phone = phone.substring(2);
    if (phone.length == 8) phone = '226$phone';
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: _user,
      title: 'Espace Patient',
      accentColor: const Color(0xFF1E88E5),
      children: [
        // ── Bannière de bienvenue ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF00ACC1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.health_and_safety_outlined,
                  color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenue ${_user.prenom} !',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Text('Votre santé, notre priorité',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Section Profil & Infos ─────────────────────────────────────
        const Text('Mon Profil', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Informations personnelles',
          subtitle: 'Gérer mes données personnelles',
          icon: Icons.person_outline,
          color: const Color(0xFF1E88E5),
          onTap: () async {
            final refresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InformationsPersonnellesScreen(user: _user),
              ),
            );
            if (refresh == true) _chargerInfos();
          },
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Profil médical',
          subtitle: 'Créer et modifier mon profil médical',
          icon: Icons.medical_information_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfilMedicalScreen(user: _user))),
        ),

        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mon QR Code',
          subtitle: 'Accès rapide à mon dossier',
          icon: Icons.qr_code_2_outlined,
          color: const Color(0xFF3949AB),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => QrCodeScreen(user: _user))),
        ),

        const SizedBox(height: 24),

        // ── Section Santé ──────────────────────────────────────────────
        const Text('Ma Santé', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Mes rendez-vous',
          subtitle: 'Prendre et gérer mes RDV',
          icon: Icons.calendar_today_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => RendezVousScreen(user: _user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mon dossier médical',
          subtitle: 'Consulter et exporter mon dossier',
          icon: Icons.folder_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DossierMedicalScreen(user: _user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Contacter mon médecin',
          subtitle: 'Ouvrir WhatsApp avec le dernier médecin consulté',
          icon: Icons.chat_outlined,
          color: const Color(0xFF3949AB),
          onTap: _contacterDernierMedecin,
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Formations sanitaires',
          subtitle: 'Hôpitaux, CSPS, pharmacies à Bobo',
          icon: Icons.map_outlined,
          color: const Color(0xFF1E88E5),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CartographieScreen(user: _user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Audit des accès',
          subtitle: 'Qui a consulté mon dossier',
          icon: Icons.visibility_outlined,
          color: const Color(0xFF37474F),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AuditAccesScreen(user: _user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Carnet de santé',
          subtitle: 'Historique de mes consultations',
          icon: Icons.book_outlined,
          color: const Color(0xFF1E88E5),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CarnetSanteScreen(user: _user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mes vaccinations',
          subtitle: 'Historique et calendrier vaccinal',
          icon: Icons.vaccines_outlined,
          color: const Color(0xFF8E24AA),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VaccinationsScreen(user: _user))),
        ),

        const SizedBox(height: 24),

        // ── Section Rappels & Suivi ────────────────────────────────────
        const Text('Suivi & Rappels', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Mes rappels',
          subtitle: 'Vaccins, traitements, rendez-vous',
          icon: Icons.notifications_outlined,
          color: const Color(0xFFF4511E),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => RappelsScreen(user: _user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Suivi de grossesse',
          subtitle: 'Suivre ma grossesse semaine par semaine',
          icon: Icons.pregnant_woman_outlined,
          color: const Color(0xFFE91E8C),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SuiviGrossesseScreen(user: _user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Vaccinations des enfants',
          subtitle: 'Carnet vaccinal de mes enfants',
          icon: Icons.child_care_outlined,
          color: const Color(0xFF00ACC1),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VaccinationsEnfantsScreen(user: _user))),
        ),

        const SizedBox(height: 24),

        // ── Section Données ────────────────────────────────────────────
        const Text('Mes Données', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Pharmacie en ligne',
          subtitle: 'Commander vos médicaments',
          icon: Icons.medication_outlined,
          color: const Color(0xFF8E24AA),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => PharmacieScreen(user: _user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Accès hors ligne',
          subtitle: 'Dossier médical disponible sans internet',
          icon: Icons.offline_bolt_outlined,
          color: const Color(0xFF3949AB),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      DossierMedicalScreen(user: _user, horsLigne: true))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Exporter en PDF',
          subtitle: 'Télécharger mon dossier médical',
          icon: Icons.picture_as_pdf_outlined,
          color: const Color(0xFFC62828),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      DossierMedicalScreen(user: _user, exportPdf: true))),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
