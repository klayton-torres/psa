import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageValidationResult {
  final bool valid;
  final String? errorMessage;
  final int? width;
  final int? height;
  final int? sizeBytes;

  const ImageValidationResult._({
    required this.valid,
    this.errorMessage,
    this.width,
    this.height,
    this.sizeBytes,
  });

  factory ImageValidationResult.ok(int w, int h, int size) =>
      ImageValidationResult._(
        valid: true,
        width: w,
        height: h,
        sizeBytes: size,
      );

  factory ImageValidationResult.fail(String m) =>
      ImageValidationResult._(valid: false, errorMessage: m);
}

enum _ImageMagicFormat { jpeg, png, webp, gif, unknown }

class ProfileAvatarHelper {
  static const int maxSizeBytes = 5 * 1024 * 1024;
  static const int minWidth = 200;
  static const int minHeight = 200;
  static const int outputSizePx = 512;
  static const int thumbSizePx = 128;
  static const _allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const _allowedMimes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  static _ImageMagicFormat _detectFormatByMagicBytes(Uint8List bytes) {
    if (bytes.length < 12) return _ImageMagicFormat.unknown;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return _ImageMagicFormat.jpeg;
    }
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return _ImageMagicFormat.png;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return _ImageMagicFormat.webp;
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return _ImageMagicFormat.gif;
    }
    return _ImageMagicFormat.unknown;
  }

  static bool _isAllowedMagicFormat(_ImageMagicFormat fmt) {
    return fmt == _ImageMagicFormat.jpeg ||
        fmt == _ImageMagicFormat.png ||
        fmt == _ImageMagicFormat.webp;
  }

  static bool _isAllowedByMimeOrExtension(String? path, String? mime) {
    if (mime != null && _allowedMimes.contains(mime.toLowerCase())) {
      return true;
    }
    if (path == null) return false;
    final ext = path.toLowerCase();
    return _allowedExtensions.any(ext.endsWith);
  }

  static ImageValidationResult validateBytes(
    Uint8List bytes, {
    String? path,
    String? mime,
  }) {
    if (bytes.isEmpty) return ImageValidationResult.fail('Arquivo vazio.');
    if (bytes.length > maxSizeBytes) {
      return ImageValidationResult.fail(
        'A imagem deve ter no máximo 5MB (arquivo atual: ${_fmtSize(bytes.length)}).',
      );
    }
    final magicFormat = _detectFormatByMagicBytes(bytes);
    final allowedByMagic = _isAllowedMagicFormat(magicFormat);
    final allowedByMeta = _isAllowedByMimeOrExtension(path, mime);
    if (!allowedByMagic && !allowedByMeta) {
      return ImageValidationResult.fail(
        'Formato inválido. Use JPG, PNG ou WEBP.',
      );
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return ImageValidationResult.fail(
        'Não foi possível interpretar a imagem. Verifique o arquivo.',
      );
    }
    if (decoded.width < minWidth || decoded.height < minHeight) {
      return ImageValidationResult.fail(
        'Resolução mínima de ${minWidth}x${minHeight}px (atual: ${decoded.width}x${decoded.height}px).',
      );
    }
    return ImageValidationResult.ok(
      decoded.width,
      decoded.height,
      bytes.length,
    );
  }

  static Uint8List _squareCropCenter(img.Image src) {
    final side = min(src.width, src.height);
    final offsetX = (src.width - side) ~/ 2;
    final offsetY = (src.height - side) ~/ 2;
    final cropped = img.copyCrop(
      src,
      x: offsetX,
      y: offsetY,
      width: side,
      height: side,
    );
    return _encodeJpeg(cropped, outputSizePx, quality: 86);
  }

  static Uint8List cropSquare(
    Uint8List bytes, {
    int? offsetX,
    int? offsetY,
    int? size,
  }) {
    final src = img.decodeImage(bytes);
    if (src == null) return bytes;
    final s = size ?? min(src.width, src.height);
    final ox = offsetX ?? (src.width - s) ~/ 2;
    final oy = offsetY ?? (src.height - s) ~/ 2;
    final sx = ox.clamp(0, src.width - 1);
    final sy = oy.clamp(0, src.height - 1);
    final side = min(s, src.width - sx);
    final sideClamped = min(side, src.height - sy);
    if (sideClamped <= 0) return _squareCropCenter(src);
    final cropped = img.copyCrop(
      src,
      x: sx,
      y: sy,
      width: sideClamped,
      height: sideClamped,
    );
    return _encodeJpeg(cropped, outputSizePx, quality: 86);
  }

  static Uint8List generateThumbnail(Uint8List squareBytes) {
    final src = img.decodeImage(squareBytes);
    if (src == null) return squareBytes;
    return _encodeJpeg(src, thumbSizePx, quality: 78);
  }

  static Uint8List _encodeJpeg(
    img.Image src,
    int targetSide, {
    int quality = 82,
  }) {
    final resized = img.copyResize(
      src,
      width: targetSide,
      height: targetSide,
      interpolation: img.Interpolation.average,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  static String buildDataUrl(
    Uint8List jpegBytes, {
    String mime = 'image/jpeg',
  }) {
    return 'data:$mime;base64,${base64Encode(jpegBytes)}';
  }

  static String avatarStoragePath(String userId, {bool thumb = false}) {
    final prefix = thumb ? 'thumbs' : 'avatars';
    return '$prefix/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  static String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static Uint8List readAsBytesSyncOrWeb(Uint8List bytes, File? file) {
    if (kIsWeb) return bytes;
    return bytes;
  }
}
