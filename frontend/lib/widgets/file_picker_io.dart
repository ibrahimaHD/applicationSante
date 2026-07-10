import 'package:file_picker/file_picker.dart';
import 'picked_file.dart';

Future<PickedFileData?> pickDocumentFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final fichier = result.files.first;
  if (fichier.bytes == null) return null;

  return PickedFileData(name: fichier.name, bytes: fichier.bytes!);
}