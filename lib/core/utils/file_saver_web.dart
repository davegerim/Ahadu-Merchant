import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> saveAndShareFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final jsArray = bytes.toJS;
  final parts = [jsArray].toJS;
  final options = web.BlobPropertyBag(type: mimeType);
  final blob = web.Blob(parts, options);
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();

  web.URL.revokeObjectURL(url);
}
