import 'dart:typed_data';

/// 비-웹 플랫폼용 스텁 (실제 구현은 media_file_picker_web.dart)
Future<Uint8List?> pickMediaFile(String acceptTypes) async => null;
