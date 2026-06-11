import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class QrCodeScreen extends StatelessWidget {
  final UserModel user;
  const QrCodeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Données encodées dans le QR
    final qrData = jsonEncode({
      'patient_id': user.id,
      'nom': user.fullName,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
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
              border: Border.all(
                  color: const Color(0xFF1E88E5).withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline,
                  color: Color(0xFF1E88E5), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Montrez ce QR Code à votre médecin pour qu\'il accède rapidement à votre dossier médical.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF1E88E5)),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 32),

          // QR Code
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
                    '${user.prenom[0]}${user.nom[0]}',
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
                      fontSize: 12,
                      color: AppColors.textSecondary)),

              const SizedBox(height: 20),

              // QR
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

              const SizedBox(height: 16),

              // ID patient
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ID : ${user.id ?? 'N/A'}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1),
                ),
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
              border: Border.all(
                  color: Colors.orange.withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.security_outlined,
                  color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ne partagez ce QR Code qu\'avec des professionnels de santé de confiance.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.orange),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}