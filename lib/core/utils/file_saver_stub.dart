import 'dart:typed_data';

Future<void> saveAndShareFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  throw UnsupportedError('Cannot save files on this platform');
}
