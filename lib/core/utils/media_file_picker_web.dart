import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// 웹 플랫폼용 파일 피커 — 브라우저 native <input type="file"> 사용
/// [acceptTypes] 예: 'video/*', 'audio/*', 'image/*'
Future<Uint8List?> pickMediaFile(String acceptTypes) async {
  final completer = Completer<Uint8List?>();

  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = acceptTypes;
  input.style.display = 'none';

  web.document.body?.appendChild(input);

  input.addEventListener(
    'change',
    (web.Event event) {
      final files = input.files;
      if (files == null || files.length == 0) {
        completer.complete(null);
        input.remove();
        return;
      }

      final file = files.item(0)!;
      final reader = web.FileReader();

      reader.addEventListener(
        'load',
        (web.Event _) {
          final result = reader.result;
          if (result == null) {
            completer.complete(null);
          } else {
            // result is a JSArrayBuffer
            final jsBuffer = result as JSArrayBuffer;
            final byteData = jsBuffer.toDart.asUint8List();
            completer.complete(byteData);
          }
          input.remove();
        }.toJS,
      );

      reader.addEventListener(
        'error',
        (web.Event _) {
          completer.complete(null);
          input.remove();
        }.toJS,
      );

      reader.readAsArrayBuffer(file);
    }.toJS,
  );

  // 사용자가 파일 선택 취소하면 'cancel' 이벤트 (Chrome 113+)
  input.addEventListener(
    'cancel',
    (web.Event _) {
      completer.complete(null);
      input.remove();
    }.toJS,
  );

  input.click();

  return completer.future;
}
