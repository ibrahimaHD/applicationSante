import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class QrCodeScreen extends StatelessWidget {
  final UserModel user;
  const QrCodeScreen({super.key, required this.user});

  // Génère un numéro de matricule unique basé sur l'id et le rôle
  String get _matricule {
    final id = user.id ?? 0;
    final annee = DateTime.now().year;
    // Format : LB-PATIENT-2026-00042
    final idPadded = id.toString().padLeft(5, '0');
    return 'LB-${user.role.toUpperCase()}-$annee-$idPadded';
  }

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'matricule': _matricule,
      'nom': user.fullName,
      'role': user.role,
      'app': 'LaafiBa',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Mon QR Code',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Color(0xFF1E88E5), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Montrez ce QR Code à votre médecin pour accéder rapidement à votre dossier médical.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E88E5)),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 32),

          // QR Code card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: [
              // Avatar patient
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF00ACC1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${user.prenom.isNotEmpty ? user.prenom[0] : ""}${user.nom.isNotEmpty ? user.nom[0] : ""}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(user.fullName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('Patient LaafiBa',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),

              const SizedBox(height: 8),

              // Numéro de matricule affiché
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 6),
                  Text(
                    _matricule,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E88E5),
                        letterSpacing: 0),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // QR Code
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1E88E5),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1A237E),
                ),
              ),

              const SizedBox(height: 12),

              // Info matricule
              Text(
                'Ce code contient votre matricule unique',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Note sécurité
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.security_outlined, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ne partagez ce QR Code qu\'avec des professionnels de santé de confiance.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
