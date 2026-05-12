import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_native.dart' as platform;

Future<void> saveAndShareFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  return platform.saveAndShareFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
}
