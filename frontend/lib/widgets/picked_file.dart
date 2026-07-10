import 'dart:typed_data';

/// Représente un fichier choisi par l'utilisateur, quelle que soit la plateforme.
class PickedFileData {
  final String name;
  final Uint8List bytes;

  PickedFileData({required this.name, required this.bytes});
}