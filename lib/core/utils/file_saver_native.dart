import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final directory = await getTemporaryDirectory();
  final path = '${directory.path}/$fileName';
  final file = File(path);
  await file.writeAsBytes(bytes);

  final xFile = XFile(path, mimeType: mimeType);
  await SharePlus.instance.share(ShareParams(files: [xFile]));
}
