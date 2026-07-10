import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import 'file_picker_service.dart';
import 'picked_file.dart';


/// Widget réutilisable pour sélectionner et téléverser un document
/// (diplôme, pièce d'identité...). Met à jour un TextEditingController
/// avec l'URL retournée par le backend une fois l'upload terminé.
class DocumentPickerField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextEditingController urlController;
  final String? Function(String?)? validator;

  const DocumentPickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.urlController,
    this.validator,
  });

  @override
  State<DocumentPickerField> createState() => _DocumentPickerFieldState();
}

class _DocumentPickerFieldState extends State<DocumentPickerField> {
  String? _nomFichierChoisi;
  bool _isUploading = false;
  String? _erreur;

  Future<void> _choisirEtUploaderFichier() async {
    setState(() => _erreur = null);

    PickedFileData? fichier;
    try {
      fichier = await pickDocumentFile();
    } catch (e) {
      setState(() => _erreur = 'Impossible d\'ouvrir le sélecteur de fichiers : $e');
      return;
    }

    if (fichier == null) return; // annulé par l'utilisateur

    setState(() {
      _isUploading = true;
      _nomFichierChoisi = fichier!.name;
    });

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/upload/document');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
        'fichier',
        fichier.bytes,
        filename: fichier.name,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['succes'] == true) {
        widget.urlController.text = data['url'];
      } else {
        setState(() {
          _erreur = data['message'] ?? 'Échec du téléversement.';
          _nomFichierChoisi = null;
        });
      }
    } catch (e) {
      setState(() {
        _erreur = 'Erreur réseau : impossible de téléverser le fichier.';
        _nomFichierChoisi = null;
      });
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.urlController,
      builder: (context, value, _) {
        final bool aUnFichier = value.text.isNotEmpty;

        return FormField<String>(
          validator: widget.validator,
          initialValue: value.text,
          builder: (fieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _isUploading ? null : _choisirEtUploaderFichier,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (fieldState.hasError && !aUnFichier)
                            ? AppColors.error
                            : (aUnFichier ? AppColors.success : AppColors.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_isUploading)
                          const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Icon(
                            aUnFichier ? Icons.check_circle : widget.icon,
                            size: 20,
                            color: aUnFichier ? AppColors.success : AppColors.primary,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isUploading
                                ? 'Téléversement en cours...'
                                : (_nomFichierChoisi ??
                                    (aUnFichier ? 'Document téléversé ✓' : 'Choisir un fichier (PDF, JPG, PNG)')),
                            style: TextStyle(
                              fontSize: 14,
                              color: aUnFichier ? AppColors.success : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (fieldState.hasError && !aUnFichier)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(fieldState.errorText!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
                if (_erreur != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(_erreur!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}