import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../utils/profile_avatar_helper.dart';

class ProfileImageResult {
  final Uint8List bytes;
  final String mimeType;
  final String fileName;
  final int width;
  final int height;
  ProfileImageResult({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
    required this.width,
    required this.height,
  });
}

Uint8List _resizeIfNeededSync(Uint8List bytes, int max) {
  try {
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final maior = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    if (maior <= max) return bytes;
    final redimensionado = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? max : null,
      height: decoded.height > decoded.width ? max : null,
      interpolation: img.Interpolation.average,
    );
    return Uint8List.fromList(
      img.encodeJpg(redimensionado, quality: ImageService.kQuality),
    );
  } catch (_) {
    return bytes;
  }
}

class ImageService {
  static const int kMaxBytes = 5 * 1024 * 1024;
  static const Set<String> kExtensoesPermitidas = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };
  static const int kMaxWidth = 1600;
  static const int kQuality = 85;
  static const int kAvatarMax = 512;

  final ImagePicker _picker;
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  String _extFromName(String name) {
    final idx = name.lastIndexOf('.');
    if (idx == -1) return '';
    return name.substring(idx + 1).toLowerCase();
  }

  String _mimeFromExt(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<ProfileImageResult?> _pick(
    BuildContext? context, {
    required ImageSource source,
    required String label,
    bool avatar = true,
  }) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: kMaxWidth.toDouble(),
        imageQuality: kQuality,
      );
      if (file == null) return null;
      final ext = _extFromName(file.name);
      final mimeFromExt = _mimeFromExt(ext);
      final mimePick = file.mimeType;
      final resolvedMime = (mimePick != null && mimePick.isNotEmpty)
          ? mimePick
          : mimeFromExt;

      Uint8List bytes = await file.readAsBytes();

      final preValidacao = ProfileAvatarHelper.validateBytes(
        bytes,
        path: file.name,
        mime: resolvedMime,
      );
      if (!preValidacao.valid) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                '$label: ${preValidacao.errorMessage ?? 'Arquivo inválido.'}',
              ),
            ),
          );
        }
        return null;
      }

      final max = avatar ? kAvatarMax : kMaxWidth;
      bytes = _resizeIfNeededSync(bytes, max);
      img.Image? decodificada;
      try {
        decodificada = img.decodeImage(bytes);
      } catch (_) {
        decodificada = null;
      }
      HapticFeedback.selectionClick();
      return ProfileImageResult(
        bytes: bytes,
        mimeType: resolvedMime,
        fileName: file.name,
        width: decodificada?.width ?? preValidacao.width ?? 0,
        height: decodificada?.height ?? preValidacao.height ?? 0,
      );
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Falha ao carregar $label: ${e.toString()}'),
          ),
        );
      }
      return null;
    }
  }

  Future<ProfileImageResult?> pickAvatarGaleria(BuildContext? context) => _pick(
    context,
    source: ImageSource.gallery,
    label: 'Foto de perfil',
    avatar: true,
  );

  Future<ProfileImageResult?> pickAvatarCamera(BuildContext? context) => _pick(
    context,
    source: ImageSource.camera,
    label: 'Foto de perfil',
    avatar: true,
  );

  Future<void> showAvatarPicker(
    BuildContext context, {
    required void Function(ProfileImageResult) onSelecionada,
  }) async {
    HapticFeedback.lightImpact();
    final escolha = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Alterar foto de perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _OptionFoto(
                      key: const ValueKey('avatar-opcao-galeria'),
                      icon: Icons.photo_library_outlined,
                      label: 'Galeria',
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    ),
                    _OptionFoto(
                      key: const ValueKey('avatar-opcao-camera'),
                      icon: Icons.photo_camera_outlined,
                      label: 'Câmera',
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (escolha == null || !context.mounted) return;
    final res = escolha == ImageSource.camera
        ? await pickAvatarCamera(context)
        : await pickAvatarGaleria(context);
    if (res != null && context.mounted) onSelecionada(res);
  }
}

class _OptionFoto extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionFoto({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: cs.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
