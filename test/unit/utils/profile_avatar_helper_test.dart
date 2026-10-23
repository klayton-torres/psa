import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:peladeiros_sa/utils/profile_avatar_helper.dart';

Uint8List _makeJpeg({int w = 400, int h = 400, int quality = 85}) {
  final image = img.Image(width: w, height: h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      image.setPixelRgb(x, y, x % 256, y % 256, (x + y) % 256);
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}

Uint8List _makePng({int w = 400, int h = 400}) {
  final image = img.Image(width: w, height: h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      image.setPixelRgba(x, y, 100, 200, 50, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _makeWebp({int w = 400, int h = 400}) {
  final image = img.Image(width: w, height: h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      image.setPixelRgb(x, y, 50, 80, 200);
    }
  }
  return Uint8List.fromList(img.encodeWebP(image));
}

void main() {
  group('ProfileAvatarHelper - Validação de Magic Bytes', () {
    test('CENÁRIO DO BUG: JPEG válido + path memory:// SEM extensão deve passar', () {
      final bytes = _makeJpeg();
      final result = ProfileAvatarHelper.validateBytes(
        bytes,
        path: 'memory://123456789',
        mime: null,
      );
      expect(result.valid, isTrue,
          reason:
              'Deve aceitar JPEG mesmo sem extensão no path (causa raiz do bug). '
              'Erro: ${result.errorMessage}');
    });

    test('CENÁRIO DO BUG: PNG válido + path memory:// SEM extensão deve passar', () {
      final bytes = _makePng();
      final result = ProfileAvatarHelper.validateBytes(
        bytes,
        path: 'memory://987654321',
        mime: null,
      );
      expect(result.valid, isTrue,
          reason:
              'Deve aceitar PNG mesmo sem extensão no path. Erro: ${result.errorMessage}');
    });

    test('CENÁRIO DO BUG: WEBP válido + path memory:// SEM extensão deve passar', () {
      final bytes = _makeWebp();
      final result = ProfileAvatarHelper.validateBytes(
        bytes,
        path: 'memory://abcdef',
        mime: null,
      );
      expect(result.valid, isTrue,
          reason:
              'Deve aceitar WEBP mesmo sem extensão no path. Erro: ${result.errorMessage}');
    });

    test('JPEG com extensão e MIME válidos deve passar', () {
      final bytes = _makeJpeg();
      final result = ProfileAvatarHelper.validateBytes(
        bytes,
        path: 'foto.jpg',
        mime: 'image/jpeg',
      );
      expect(result.valid, isTrue);
      expect(result.width, 400);
      expect(result.height, 400);
      expect(result.sizeBytes, bytes.length);
    });

    test('PNG com extensão e MIME válidos deve passar', () {
      final bytes = _makePng();
      final result = ProfileAvatarHelper.validateBytes(
        bytes,
        path: 'foto.PNG',
        mime: 'image/png',
      );
      expect(result.valid, isTrue);
    });

    test('WEBP com extensão e MIME válidos deve passar', () {
      final bytes = _makeWebp();
      final result = ProfileAvatarHelper.validateBytes(
        bytes,
        path: 'foto.webp',
        mime: 'image/webp',
      );
      expect(result.valid, isTrue);
    });

    test('Arquivo vazio deve falhar', () {
      final result = ProfileAvatarHelper.validateBytes(Uint8List(0));
      expect(result.valid, isFalse);
      expect(result.errorMessage, contains('Arquivo vazio'));
    });

    test('Arquivo muito grande (> 5MB) deve falhar', () {
      final rand = Random(42);
      final big = Uint8List(6 * 1024 * 1024);
      big[0] = 0xFF;
      big[1] = 0xD8;
      big[2] = 0xFF;
      for (int i = 3; i < big.length; i++) {
        big[i] = rand.nextInt(256);
      }
      final result = ProfileAvatarHelper.validateBytes(big);
      expect(result.valid, isFalse);
      expect(result.errorMessage, contains('5MB'));
    });

    test('Resolução abaixo do mínimo (200x200) deve falhar', () {
      final bytes = _makeJpeg(w: 150, h: 150);
      final result = ProfileAvatarHelper.validateBytes(bytes);
      expect(result.valid, isFalse);
      expect(result.errorMessage, contains('200x200'));
    });

    test('Resolução exatamente no mínimo (200x200) deve passar', () {
      final bytes = _makeJpeg(w: 200, h: 200);
      final result = ProfileAvatarHelper.validateBytes(bytes);
      expect(result.valid, isTrue);
    });

    test('Bytes aleatórios SEM assinatura válida devem falhar', () {
      final rand = Random(123);
      final fake = Uint8List(1024);
      for (int i = 0; i < fake.length; i++) {
        fake[i] = rand.nextInt(256);
      }
      fake[0] = 0x00;
      fake[1] = 0x00;
      fake[2] = 0x00;
      final result = ProfileAvatarHelper.validateBytes(fake);
      expect(result.valid, isFalse,
          reason:
              'Bytes aleatórios não devem passar como imagem. Erro: ${result.errorMessage}');
      expect(result.errorMessage, contains('Formato inválido'));
    });

    test('Texto puro .txt renomeado para .jpg deve falhar magic bytes', () {
      final txt = Uint8List.fromList('Hello, this is not an image.'.codeUnits);
      final result = ProfileAvatarHelper.validateBytes(
        txt,
        path: 'fake.jpg',
        mime: 'image/jpeg',
      );
      expect(result.valid, isFalse,
          reason:
              'Arquivo de texto com extensão .jpg deve falhar por magic bytes. '
              'Erro: ${result.errorMessage}');
    });

    test('JPEG válido, extensão errada, MIME nulo -> deve passar por magic bytes', () {
      final bytes = _makeJpeg(w: 300, h: 300);
      final result = ProfileAvatarHelper.validateBytes(
        bytes,
        path: 'arquivo.semext',
        mime: null,
      );
      expect(result.valid, isTrue,
          reason:
              'Magic bytes são a prova definitiva. Extensão ausente não deve bloquear.');
    });

    test('JPEG válido, MIME incorreto (texto), path nulo -> deve passar por magic bytes', () {
      final bytes = _makeJpeg(w: 350, h: 350);
      final result = ProfileAvatarHelper.validateBytes(
        bytes,
        path: null,
        mime: 'text/plain',
      );
      expect(result.valid, isTrue);
    });
  });

  group('ProfileAvatarHelper - cropSquare e generateThumbnail', () {
    test('cropSquare deve produzir bytes decodificáveis', () {
      final bytes = _makeJpeg(w: 600, h: 800);
      final cropped = ProfileAvatarHelper.cropSquare(bytes);
      expect(cropped.isNotEmpty, isTrue);
      final decoded = img.decodeImage(cropped);
      expect(decoded, isNotNull);
      expect(decoded!.width, 512);
      expect(decoded.height, 512);
    });

    test('generateThumbnail deve ter lado 128', () {
      final square = ProfileAvatarHelper.cropSquare(_makeJpeg(w: 500, h: 500));
      final thumb = ProfileAvatarHelper.generateThumbnail(square);
      expect(thumb.isNotEmpty, isTrue);
      final decoded = img.decodeImage(thumb);
      expect(decoded, isNotNull);
      expect(decoded!.width, 128);
      expect(decoded.height, 128);
    });
  });
}
