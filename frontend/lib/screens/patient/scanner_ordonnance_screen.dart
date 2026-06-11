import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class ScannerOrdonnanceScreen extends StatefulWidget {
  final UserModel user;
  const ScannerOrdonnanceScreen({super.key, required this.user});

  @override
  State<ScannerOrdonnanceScreen> createState() =>
      _ScannerOrdonnanceScreenState();
}

class _ScannerOrdonnanceScreenState
    extends State<ScannerOrdonnanceScreen> {
  File? _image;
  bool _isUploading = false;
  String? _resultat;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _prendrePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _image    = File(picked.path);
        _resultat = null;
      });
    }
  }

  Future<void> _envoyer() async {
    if (_image == null) return;
    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/patient/ordonnances/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
          'ordonnance', _image!.path));
      request.fields['notes'] = _notesController.text;

      final response = await request.send();
      final body =
          await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (mounted) {
        setState(() {
          _resultat    = data['message'] ?? '';
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? ''),
          backgroundColor: data['succes'] == true
              ? AppColors.success
              : AppColors.error,
        ));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        title: const Text('Scanner une ordonnance',
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
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8E24AA).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF8E24AA).withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF8E24AA), size: 20),
                  SizedBox(width: 8),
                  Text('Comment scanner votre ordonnance',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E24AA))),
                ]),
                SizedBox(height: 8),
                Text(
                  '1. Posez l\'ordonnance sur une surface plane\n'
                  '2. Prenez une photo nette et lisible\n'
                  '3. Envoyez — la pharmacie la recevra directement',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Zone image
          GestureDetector(
            onTap: () => _prendrePhoto(ImageSource.gallery),
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _image != null
                      ? const Color(0xFF8E24AA)
                      : AppColors.divider,
                  width: _image != null ? 2 : 1,
                ),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text('Appuyez pour choisir une image',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Boutons source
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _prendrePhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined,
                    size: 18),
                label: const Text('Caméra'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8E24AA),
                  side: const BorderSide(
                      color: Color(0xFF8E24AA)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _prendrePhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined,
                    size: 18),
                label: const Text('Galerie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8E24AA),
                  side: const BorderSide(
                      color: Color(0xFF8E24AA)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Notes
          AppTextField(
            label: 'Notes (optionnel)',
            hint: 'Ex: Traitement urgent, allergie pénicilline...',
            prefixIcon: Icons.notes_outlined,
            controller: _notesController,
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Bouton envoyer
          AppButton(
            text: 'Envoyer l\'ordonnance',
            icon: Icons.send_outlined,
            color: const Color(0xFF8E24AA),
            isLoading: _isUploading,
            onPressed: _image == null ? null : _envoyer,
          ),

          if (_resultat != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_resultat!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.success)),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}