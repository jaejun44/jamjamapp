import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// 웹: Uint8List → Blob URL 변환 (video_player가 URL만 받으므로)
String? createVideoBlobUrl(Uint8List bytes) {
  try {
    final blob = web.Blob(
      [bytes.buffer.toJS].toJS,
      web.BlobPropertyBag(type: 'video/mp4'),
    );
    return web.URL.createObjectURL(blob);
  } catch (_) {
    return null;
  }
}

void revokeVideoBlobUrl(String url) {
  try {
    web.URL.revokeObjectURL(url);
  } catch (_) {}
}
