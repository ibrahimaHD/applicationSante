import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'dossier_patient_screen.dart';

class ScannerQrScreen extends StatefulWidget {
  final UserModel user;
  const ScannerQrScreen({super.key, required this.user});

  @override
  State<ScannerQrScreen> createState() => _ScannerQrScreenState();
}

class _ScannerQrScreenState extends State<ScannerQrScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.first;
    final raw = barcode.rawValue;
    if (raw == null) return;

    setState(() => _scanned = true);
    controller.stop();

    try {
      final data = jsonDecode(raw);
      final patientId = data['patient_id'];
      final patientNom = data['nom'] ?? 'Patient';

      if (patientId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DossierPatientScreen(
              user: widget.user,
              patientId: patientId is int
                  ? patientId
                  : int.parse(patientId.toString()),
              patientNom: patientNom,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _scanned = false);
      controller.start();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('QR Code invalide'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scanner QR Patient',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: controller,
          onDetect: _onDetect,
        ),
        // Cadre de scan
        Center(
          child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF00897B), width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Instructions
        Positioned(
          bottom: 60,
          left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pointez le QR Code du patient',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}