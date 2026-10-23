import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/pelada.dart';

class DemoCoverImages {
  static const List<String> assetPaths = [
    'assets/demo_covers/demo_1.jpg',
    'assets/demo_covers/demo_2.jpg',
    'assets/demo_covers/demo_3.jpg',
    'assets/demo_covers/demo_4.jpg',
  ];

  static Uint8List _generatePlaceholderPng(int index) {
    final palettes = <List<int>>[
      [0x0A, 0x6E, 0x41, 0x14, 0xB8, 0x6E],
      [0xE0, 0x6E, 0x5A, 0xF4, 0xA2, 0x61],
      [0x1E, 0x3A, 0x5F, 0x3B, 0x82, 0xAC],
      [0x2D, 0x34, 0x36, 0x5A, 0x62, 0x66],
    ];
    final palette = palettes[index % palettes.length];
    final w = 800, h = 450;
    final bytes = ByteData(54 + w * h * 3);
    bytes.setUint8(0, 0x42);
    bytes.setUint8(1, 0x4D);
    bytes.setUint32(2, 54 + w * h * 3, Endian.little);
    bytes.setUint32(10, 54, Endian.little);
    bytes.setUint32(14, 40, Endian.little);
    bytes.setInt32(18, w, Endian.little);
    bytes.setInt32(22, -h, Endian.little);
    bytes.setUint16(26, 1, Endian.little);
    bytes.setUint16(28, 24, Endian.little);
    bytes.setUint32(34, w * h * 3, Endian.little);
    bytes.setInt32(38, 2835, Endian.little);
    bytes.setInt32(42, 2835, Endian.little);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final t = y / h;
        final r = (palette[0] + (palette[3] - palette[0]) * t).toInt();
        final g = (palette[1] + (palette[4] - palette[1]) * t).toInt();
        final b = (palette[2] + (palette[5] - palette[2]) * t).toInt();
        final o = 54 + (y * w + x) * 3;
        bytes.setUint8(o, b.clamp(0, 255));
        bytes.setUint8(o + 1, g.clamp(0, 255));
        bytes.setUint8(o + 2, r.clamp(0, 255));
      }
    }
    return bytes.buffer.asUint8List();
  }

  static List<PeladaCapaFoto> _fallbackCovers() {
    final result = <PeladaCapaFoto>[];
    for (var i = 0; i < 4; i++) {
      final pngBytes = _generatePlaceholderPng(i);
      result.add(
        PeladaCapaFoto.fromBytes(bytes: pngBytes, mimeType: 'image/png'),
      );
    }
    if (kDebugMode) {
      debugPrint(
        'DemoCoverImages: usando imagens placeholder geradas em memória. '
        'Para fotos reais, adicione assets/demo_covers/demo_1.jpg..demo_4.jpg.',
      );
    }
    return result;
  }

  static Future<List<PeladaCapaFoto>> loadAll() async {
    final result = <PeladaCapaFoto>[];
    for (final path in assetPaths) {
      try {
        final data = await rootBundle.load(path);
        result.add(
          PeladaCapaFoto.fromBytes(
            bytes: data.buffer.asUint8List(),
            mimeType: _mimeTypeFromPath(path),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('DemoCoverImages: asset não encontrado: $path');
        }
      }
    }
    if (result.isNotEmpty) return result;
    return _fallbackCovers();
  }

  static String _mimeTypeFromPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
