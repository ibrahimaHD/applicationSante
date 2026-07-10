import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'picked_file.dart';

Future<PickedFileData?> pickDocumentFile() async {
  final completer = Completer<PickedFileData?>();

  final input = html.FileUploadInputElement();
  input.accept = '.pdf,.jpg,.jpeg,.png';
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    reader.onLoadEnd.listen((event) {
      final bytes = reader.result as Uint8List;
      completer.complete(PickedFileData(name: file.name, bytes: bytes));
    });

    reader.onError.listen((event) {
      completer.completeError('Erreur de lecture du fichier.');
    });
  });

  return completer.future;
}