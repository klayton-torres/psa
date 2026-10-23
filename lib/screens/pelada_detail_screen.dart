import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../core/constants/app_colors.dart';
import '../models/enums.dart';
import '../models/pelada.dart';
import '../models/participation.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/location_service.dart';
import '../widgets/checklist_card.dart';
import 'login_screen.dart';
import 'participants_screen.dart';

class PeladaDetailScreen extends StatefulWidget {
  final String peladaId;
  const PeladaDetailScreen({super.key, required this.peladaId});

  @override
  State<PeladaDetailScreen> createState() => _PeladaDetailScreenState();
}

class _PeladaCapaGalleryScreen extends StatefulWidget {
  final List<PeladaCapaFoto> fotos;
  final int initialIndex;

  const _PeladaCapaGalleryScreen({
    required this.fotos,
    required this.initialIndex,
  });

  @override
  State<_PeladaCapaGalleryScreen> createState() =>
      _PeladaCapaGalleryScreenState();
}

class _PeladaCapaGalleryScreenState extends State<_PeladaCapaGalleryScreen> {
  late final PageController _pageController;
  late final TransformationController _transformController;
  late int _index;
  double _currentScale = 1;

  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;
  static const double _stepScale = 0.5;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.fotos.length - 1);
    _pageController = PageController(initialPage: _index);
    _transformController = TransformationController();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.01) {
      if (mounted) {
        setState(() => _currentScale = scale);
      }
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    if (mounted) {
      setState(() => _currentScale = 1);
    }
  }

  void _zoomIn() {
    final next = (_currentScale + _stepScale).clamp(_minScale, _maxScale);
    _applyScale(next);
  }

  void _zoomOut() {
    final next = (_currentScale - _stepScale).clamp(_minScale, _maxScale);
    _applyScale(next);
  }

  void _applyScale(double scale) {
    final newTransform = Matrix4.diagonal3Values(scale, scale, 1.0);
    _transformController.value = newTransform;
    if (mounted) {
      setState(() => _currentScale = scale);
    }
  }

  void _goToPrevious() {
    if (_index > 0) {
      _resetZoom();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_index < widget.fotos.length - 1) {
      _resetZoom();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isNarrow = screenSize.shortestSide < 480;
    final hasMultiple = widget.fotos.length > 1;
    final canPrev = _index > 0;
    final canNext = _index < widget.fotos.length - 1;
    final topButtonSize = isNarrow ? 40.0 : 48.0;
    final navButtonSize = isNarrow ? 44.0 : 56.0;
    final zoomButtonSize = isNarrow ? 40.0 : 48.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.black87,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.fotos.length,
                    onPageChanged: (i) {
                      _resetZoom();
                      setState(() => _index = i);
                    },
                    itemBuilder: (context, i) {
                      return InteractiveViewer(
                        transformationController: _transformController,
                        minScale: _minScale,
                        maxScale: _maxScale,
                        panEnabled: true,
                        scaleEnabled: true,
                        clipBehavior: Clip.hardEdge,
                        child: Center(
                          child: Hero(
                            tag:
                                'capa_foto_${widget.fotos[i].base64Data.hashCode}',
                            child: Image.memory(
                              widget.fotos[i].bytes,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 72,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        Container(
                          width: topButtonSize,
                          height: topButtonSize,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            iconSize: isNarrow ? 20 : 24,
                            tooltip: 'Fechar',
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 10 : 14,
                            vertical: isNarrow ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            '${_index + 1} / ${widget.fotos.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: isNarrow ? 13 : 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasMultiple) ...[
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: isNarrow ? 6 : 12),
                            child: SizedBox(
                              width: navButtonSize,
                              height: navButtonSize,
                              child: IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: canPrev
                                      ? Colors.white24
                                      : Colors.white10,
                                  foregroundColor: canPrev
                                      ? Colors.white
                                      : Colors.white38,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: canPrev ? _goToPrevious : null,
                                icon: const Icon(Icons.chevron_left),
                                iconSize: isNarrow ? 28 : 36,
                                tooltip: 'Anterior',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: isNarrow ? 6 : 12),
                            child: SizedBox(
                              width: navButtonSize,
                              height: navButtonSize,
                              child: IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: canNext
                                      ? Colors.white24
                                      : Colors.white10,
                                  foregroundColor: canNext
                                      ? Colors.white
                                      : Colors.white38,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: canNext ? _goToNext : null,
                                icon: const Icon(Icons.chevron_right),
                                iconSize: isNarrow ? 28 : 36,
                                tooltip: 'Próximo',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isNarrow ? 12 : 20,
                        8,
                        isNarrow ? 12 : 20,
                        isNarrow ? 10 : 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ZoomIndicator(
                            scale: _currentScale,
                            width: zoomButtonSize,
                            height: zoomButtonSize,
                            narrow: isNarrow,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: zoomButtonSize,
                                height: zoomButtonSize,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withAlphaSafe(
                                      alpha: 0.15,
                                    ),
                                    foregroundColor: Colors.white,
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: _zoomOut,
                                  icon: const Icon(Icons.zoom_out),
                                  iconSize: isNarrow ? 20 : 24,
                                  tooltip: 'Diminuir zoom',
                                ),
                              ),
                              SizedBox(width: isNarrow ? 8 : 12),
                              SizedBox(
                                width: zoomButtonSize,
                                height: zoomButtonSize,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withAlphaSafe(
                                      alpha: 0.15,
                                    ),
                                    foregroundColor: Colors.white,
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: _resetZoom,
                                  icon: const Icon(Icons.crop_free_outlined),
                                  iconSize: isNarrow ? 20 : 24,
                                  tooltip: 'Tamanho original',
                                ),
                              ),
                              SizedBox(width: isNarrow ? 8 : 12),
                              SizedBox(
                                width: zoomButtonSize,
                                height: zoomButtonSize,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withAlphaSafe(
                                      alpha: 0.15,
                                    ),
                                    foregroundColor: Colors.white,
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: _zoomIn,
                                  icon: const Icon(Icons.zoom_in),
                                  iconSize: isNarrow ? 20 : 24,
                                  tooltip: 'Aumentar zoom',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (!hasMultiple)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isNarrow ? 12 : 20,
                        8,
                        isNarrow ? 12 : 20,
                        isNarrow ? 10 : 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: zoomButtonSize,
                            height: zoomButtonSize,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withAlphaSafe(
                                  alpha: 0.15,
                                ),
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                              ),
                              onPressed: _zoomOut,
                              icon: const Icon(Icons.zoom_out),
                              iconSize: isNarrow ? 20 : 24,
                              tooltip: 'Diminuir zoom',
                            ),
                          ),
                          SizedBox(width: isNarrow ? 10 : 14),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 10 : 14,
                              vertical: isNarrow ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              '${(_currentScale * 100).round()}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: isNarrow ? 12 : 14,
                              ),
                            ),
                          ),
                          SizedBox(width: isNarrow ? 10 : 14),
                          SizedBox(
                            width: zoomButtonSize,
                            height: zoomButtonSize,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withAlphaSafe(
                                  alpha: 0.15,
                                ),
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                              ),
                              onPressed: _resetZoom,
                              icon: const Icon(Icons.crop_free_outlined),
                              iconSize: isNarrow ? 20 : 24,
                              tooltip: 'Tamanho original',
                            ),
                          ),
                          SizedBox(width: isNarrow ? 10 : 14),
                          SizedBox(
                            width: zoomButtonSize,
                            height: zoomButtonSize,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withAlphaSafe(
                                  alpha: 0.15,
                                ),
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                              ),
                              onPressed: _zoomIn,
                              icon: const Icon(Icons.zoom_in),
                              iconSize: isNarrow ? 20 : 24,
                              tooltip: 'Aumentar zoom',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapaIconeSubstituto extends StatelessWidget {
  final double size;
  final Color? fallbackColor;
  const _MapaIconeSubstituto({required this.size, this.fallbackColor});

  static const mapfundoAsset = 'assets/images/mapfundo.png';

  @override
  Widget build(BuildContext context) {
    final Color fbkColor =
        fallbackColor ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          mapfundoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Icon(Icons.map_outlined, size: size, color: fbkColor),
        ),
      ),
    );
  }
}

Future<void> _abrirModalMapa(
  BuildContext context, {
  required Coordenadas? coords,
  required String localArena,
  required String endereco,
  required String bairro,
  required String cidade,
  required String estado,
}) async {
  unawaited(HapticFeedback.lightImpact());
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    useSafeArea: true,
    builder: (ctxDialog) {
      final theme = Theme.of(ctxDialog);
      final Color primario = theme.colorScheme.primary;
      final String linhaLocal = [
        if (localArena.trim().isNotEmpty) localArena.trim(),
        if (endereco.trim().isNotEmpty) endereco.trim(),
        if (bairro.trim().isNotEmpty) bairro.trim(),
        if (cidade.trim().isNotEmpty || estado.trim().isNotEmpty)
          [cidade.trim(), estado.trim()].where((e) => e.isNotEmpty).join(' - '),
      ].where((e) => e.isNotEmpty).join(', ');
      final bool temCoords = coords != null;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          label: 'Modal com o mapa da localização da pelada',
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      _MapaIconeSubstituto(size: 24, fallbackColor: primario),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mapa da Localização',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Fechar modal do mapa',
                        button: true,
                        child: IconButton(
                          tooltip: 'Fechar',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(ctxDialog).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                ),
                if (linhaLocal.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: theme.hintColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            linhaLocal,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              _MapaIconeSubstituto.mapfundoAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.expand(),
                            ),
                          ),
                          if (temCoords)
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withValues(
                                    alpha: 0.94,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.place_outlined,
                                      size: 16,
                                      color: primario,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${coords.latitude.toStringAsFixed(5)}, ${coords.longitude.toStringAsFixed(5)}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Semantics(
                          label:
                              'Abrir as coordenadas no aplicativo Google Maps',
                          button: true,
                          child: FilledButton.tonalIcon(
                            onPressed: temCoords
                                ? () async {
                                    final ok =
                                        await LocationService.abrirGoogleMaps(
                                          coords,
                                        );
                                    if (!ok && ctxDialog.mounted) {
                                      Navigator.of(ctxDialog).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'Não foi possível abrir o Google Maps.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.open_in_new_outlined),
                            label: const Text('Abrir no Google Maps'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

enum _MapaLoadState { loading, sucesso, falha }

class _MapaEmbedPreview extends StatefulWidget {
  final Coordenadas coords;
  const _MapaEmbedPreview({required this.coords});

  @override
  State<_MapaEmbedPreview> createState() => _MapaEmbedPreviewState();
}

class _MapaEmbedPreviewState extends State<_MapaEmbedPreview> {
  _MapaLoadState _state = _MapaLoadState.loading;
  Timer? _timerSeguranca;

  @override
  void initState() {
    super.initState();
    _verificarDisponibilidade();
    _timerSeguranca = Timer(const Duration(seconds: 10), () {
      if (mounted && _state == _MapaLoadState.loading) {
        if (kDebugMode) {
          debugPrint('[Mapa] Timer de segurança: timeout staticmap (10s)');
        }
        setState(() => _state = _MapaLoadState.falha);
      }
    });
  }

  Future<void> _verificarDisponibilidade() async {
    final lat = widget.coords.latitude;
    final lon = widget.coords.longitude;
    final q = Uri.encodeComponent('$lat,$lon');
    final uriString =
        'https://staticmap.openstreetmap.de/staticmap.php?'
        'center=$q&zoom=16&size=900x420&markers=$lat,$lon,ol-marker';
    try {
      final resp = await http
          .get(Uri.parse(uriString))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (resp.statusCode >= 200 &&
          resp.statusCode < 300 &&
          resp.bodyBytes.isNotEmpty) {
        setState(() => _state = _MapaLoadState.sucesso);
      } else {
        if (kDebugMode) {
          debugPrint('[Mapa] staticmap HTTP ${resp.statusCode} → fallback');
        }
        setState(() => _state = _MapaLoadState.falha);
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('[Mapa] staticmap timeout (8s) → fallback');
      setState(() => _state = _MapaLoadState.falha);
    } catch (e, st) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[Mapa] Erro staticmap: $e');
        debugPrintStack(stackTrace: st, label: 'Mapa staticmap');
      }
      setState(() => _state = _MapaLoadState.falha);
    }
  }

  @override
  void dispose() {
    _timerSeguranca?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.coords.latitude;
    final lon = widget.coords.longitude;
    final theme = Theme.of(context);
    final Color primario = theme.colorScheme.primary;
    final q = Uri.encodeComponent('$lat,$lon');
    final uriString =
        'https://staticmap.openstreetmap.de/staticmap.php?'
        'center=$q&zoom=16&size=900x420&markers=$lat,$lon,ol-marker';
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$q',
    );
    return Semantics(
      label: 'Mapa da localização da pelada. Toque para abrir no Google Maps.',
      button: true,
      child: Container(
        height: 220,
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: switch (_state) {
                _MapaLoadState.loading => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        Text(
                          'Carregando mapa...',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ),
                _MapaLoadState.sucesso => Image.network(
                  uriString,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, _) {
                    if (kDebugMode) {
                      debugPrint(
                        '[Mapa] Image.network errorBuilder → fallback',
                      );
                    }
                    Future.microtask(() {
                      if (mounted && _state != _MapaLoadState.falha) {
                        setState(() => _state = _MapaLoadState.falha);
                      }
                    });
                    return const SizedBox.expand();
                  },
                ),
                _MapaLoadState.falha => _MapaFallback(
                  coords: widget.coords,
                  fallbackUri: fallbackUri,
                ),
              },
            ),
            if (_state != _MapaLoadState.falha)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 46,
                            decoration: BoxDecoration(
                              color: primario,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_outlined, size: 16, color: primario),
                    const SizedBox(width: 6),
                    Text(
                      '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapaFallback extends StatelessWidget {
  final Coordenadas coords;
  final Uri fallbackUri;
  const _MapaFallback({required this.coords, required this.fallbackUri});

  static const fallbackImgUrl = _MapaIconeSubstituto.mapfundoAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget fallbackSolido = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
          ],
        ),
      ),
    );
    return Semantics(
      label: 'Mapa. Toque no card de localização para abrir no Google Maps.',
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              fallbackImgUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallbackSolido,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${coords.latitude.toStringAsFixed(5)}, ${coords.longitude.toStringAsFixed(5)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomIndicator extends StatelessWidget {
  final double scale;
  final double width;
  final double height;
  final bool narrow;

  const _ZoomIndicator({
    required this.scale,
    required this.width,
    required this.height,
    required this.narrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: Text(
        '${(scale * 100).round()}%',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: narrow ? 12 : 14,
        ),
      ),
    );
  }
}

class _PeladaDetailScreenState extends State<PeladaDetailScreen> {
  StatusParticipacao? _statusSelecionado;
  MotivoAusencia? _motivoSelecionado;
  final _obsCtrl = TextEditingController();
  final _comentarioAvaliacaoCtrl = TextEditingController();
  double _notaAvaliacao = 0;
  bool _mostrarMotivos = false;
  bool _mostrarAvaliacao = false;
  StreamSubscription<PeladaStatusChange>? _statusSub;
  final PageController _capaPageController = PageController();
  int _capaIndex = 0;

  AuthService? _maybeAuth(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<AuthService>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = _maybeAuth(context, listen: false);
      final data = Provider.of<DataService>(context, listen: false);
      final user = auth?.currentUser;
      if (user != null) {
        data.ensurePeladasRealtime(usuarioId: user.id);
        _statusSub?.cancel();
        _statusSub = data.statusChanges.listen((event) {
          if (!mounted) return;
          if (event.organizadorId != user.id) return;
          if (event.peladaId != widget.peladaId) return;

          final motivo =
              (event.motivo != null && event.motivo!.trim().isNotEmpty)
              ? ' • ${event.motivo!.trim()}'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status alterado: ${event.newStatus.label}$motivo'),
            ),
          );
        });
        final p = data.getParticipacaoUsuario(widget.peladaId, user.id);
        if (p != null) {
          setState(() {
            _statusSelecionado = p.status;
            _motivoSelecionado = p.motivoAusencia;
            _obsCtrl.text = p.observacao ?? '';
            _notaAvaliacao = (p.notaAvaliacao ?? 0).toDouble();
            _comentarioAvaliacaoCtrl.text = p.comentarioAvaliacao ?? '';
            _mostrarMotivos = p.status == StatusParticipacao.naoIrei;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _obsCtrl.dispose();
    _comentarioAvaliacaoCtrl.dispose();
    _capaPageController.dispose();
    super.dispose();
  }

  Future<void> _confirmarPresenca() async {
    final auth = _maybeAuth(context, listen: false);
    final data = Provider.of<DataService>(context, listen: false);
    final user = auth?.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    final bloqueado = data.isUsuarioBloqueadoParaPelada(
      peladaId: widget.peladaId,
      usuarioId: user.id,
    );
    if (bloqueado &&
        (_statusSelecionado == StatusParticipacao.confirmada ||
            _statusSelecionado == StatusParticipacao.tenhoDuvida)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Está pelada não está disponível para você!'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_statusSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma opção de presença')),
      );
      return;
    }
    if (_statusSelecionado == StatusParticipacao.naoIrei &&
        _motivoSelecionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um motivo')));
      return;
    }

    final res = await data.registrarParticipacao(
      peladaId: widget.peladaId,
      usuarioId: user.id,
      usuarioNome: user.nomeCompleto,
      usuarioApelido: user.apelido,
      usuarioIdade: user.idade,
      usuarioPosicaoPrincipal: user.posicaoPrincipal,
      usuarioFotoUrl: user.fotoUrl,
      status: _statusSelecionado!,
      motivoAusencia: _mostrarMotivos ? _motivoSelecionado : null,
      observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );
    if (!mounted) return;
    if (res != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Presença registrada!')));
      setState(() {});
      if (_statusSelecionado == StatusParticipacao.confirmada) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ParticipantsScreen(peladaId: widget.peladaId),
          ),
        );
      }
    }
  }

  Future<void> _avaliar() async {
    if (_notaAvaliacao < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma nota de 1 a 5 estrelas')),
      );
      return;
    }
    final auth = _maybeAuth(context, listen: false);
    final data = Provider.of<DataService>(context, listen: false);
    final user = auth?.currentUser;
    if (user == null) return;

    final ok = await data.avaliarPelada(
      peladaId: widget.peladaId,
      usuarioId: user.id,
      nota: _notaAvaliacao.round(),
      comentario: _comentarioAvaliacaoCtrl.text.trim().isEmpty
          ? null
          : _comentarioAvaliacaoCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Obrigado pela avaliação!')));
    }
  }

  List<PeladaCapaFoto> _fotosDaPelada(Pelada p) {
    final List<PeladaCapaFoto> result = [];
    if (p.fotoArena != null) result.add(p.fotoArena!);
    if (p.fotoGalera != null) result.add(p.fotoGalera!);
    if (p.fotoBraseao != null) result.add(p.fotoBraseao!);
    result.addAll(p.fotosCapa);
    return result;
  }

  void _abrirFotosCapa(int initialIndex, List<PeladaCapaFoto> fotos) {
    if (fotos.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _PeladaCapaGalleryScreen(fotos: fotos, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildCapaHeader(
    BuildContext context,
    Pelada pelada,
    DateFormat dateFmt,
  ) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 15,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${pelada.cidade} - ${pelada.estado}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 15,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFmt.format(pelada.dataInicio)} às ${pelada.horaInicio.hour.toString().padLeft(2, '0')}:${pelada.horaInicio.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final auth = _maybeAuth(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final pelada = data.getPeladaById(widget.peladaId);

    if (pelada == null) {
      return Scaffold(
        appBar: AppBar(
        ),
        body: const Center(child: Text('Pelada não encontrada.')),
      );
    }

    final dateFmt = DateFormat('EEEE, d/MM', 'pt_BR');
    final dateFull = DateFormat('d/MM/yyyy', 'pt_BR');
    final taxa = pelada.taxa > 0
        ? NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
          ).format(pelada.taxa)
        : 'Gratuito';
    final progresso = pelada.progressoQuorum;
    final quorumCor = pelada.temQuorum
        ? AppColors.success
        : (progresso > 0.6 ? AppColors.warning : AppColors.danger);
    final participacoes = data.getParticipationsByPelada(widget.peladaId);
    final confirmadas = participacoes
        .where((p) => p.status == StatusParticipacao.confirmada)
        .toList();
    final duvida = participacoes
        .where((p) => p.status == StatusParticipacao.tenhoDuvida)
        .toList();
    final naoIrao = participacoes
        .where((p) => p.status == StatusParticipacao.naoIrei)
        .toList();
    final isFav = data.isFavorito(pelada.id);

    final statusColor = switch (pelada.status) {
      StatusPelada.ativa => AppColors.success,
      StatusPelada.suspensa => AppColors.warning,
      StatusPelada.bloqueada => AppColors.danger,
      StatusPelada.cancelada => AppColors.graphite3,
    };
    final isAuthenticated = auth?.isAuthenticated == true;
    final chuteiraLabel = pelada.tiposChuteiraPermitidos.isNotEmpty
        ? (pelada.tiposChuteiraPermitidos.length == 1
              ? pelada.tiposChuteiraPermitidos.first.label
              : pelada.tiposChuteiraPermitidos.map((e) => e.label).join(', '))
        : pelada.tipoChuteira.label;
    final coleteIndices = pelada.coresColeteIndices.isNotEmpty
        ? pelada.coresColeteIndices
        : [pelada.corColeteIndex];
    final coleteLabel = coleteIndices
        .map((i) {
          if (i == 10 &&
              pelada.corColetePersonalizado != null &&
              pelada.corColetePersonalizado!.trim().isNotEmpty) {
            return pelada.corColetePersonalizado!;
          }
          if (i >= 0 && i < AppColors.vestColorNames.length) {
            return AppColors.vestColorNames[i];
          }
          return 'Personalizado';
        })
        .toSet()
        .join(', ');
    final quorumMax = pelada.quorumMaximoEfetivo;
    final faltamMin = (pelada.quorumMinimo - pelada.participantesConfirmados)
        .clamp(0, pelada.quorumMinimo);
    final vagasRestantes = (quorumMax - pelada.participantesConfirmados).clamp(
      0,
      quorumMax,
    );
    final fotosCapaCompleta = _fotosDaPelada(pelada);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            centerTitle: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              pelada.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: fotosCapaCompleta.isNotEmpty
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          _abrirFotosCapa(_capaIndex, fotosCapaCompleta),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _capaPageController,
                            itemCount: fotosCapaCompleta.length,
                            onPageChanged: (i) =>
                                setState(() => _capaIndex = i),
                            itemBuilder: (context, index) => Image.memory(
                              fotosCapaCompleta[index].bytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withAlphaSafe(alpha: 0.08),
                                  Colors.black.withAlphaSafe(alpha: 0.62),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          _buildCapaHeader(context, pelada, dateFmt),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withAlphaSafe(alpha: 0.72),
                                primary,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        _buildCapaHeader(context, pelada, dateFmt),
                      ],
                    ),
            ),
            actions: [
              IconButton(
                onPressed: () => data.toggleFavorito(pelada.id),
                tooltip: isFav ? 'Remover dos favoritos' : 'Favoritar',
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? Colors.white : null,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Compartilhar',
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: primary.withAlphaSafe(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: primary.withAlphaSafe(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirmar Presença',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAuthenticated
                                ? 'Selecione uma opção e confirme!'
                                : 'Faça login para confirmar sua presença.',
                            style: TextStyle(color: theme.hintColor),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _presencaBtn(
                                  'Bora, vou!',
                                  Icons.check_circle_outline,
                                  AppColors.success,
                                  StatusParticipacao.confirmada,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _presencaBtn(
                                  'Talvez',
                                  Icons.help_outline,
                                  AppColors.warning,
                                  StatusParticipacao.tenhoDuvida,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _presencaBtn(
                                  'Num vou!',
                                  Icons.cancel_outlined,
                                  AppColors.danger,
                                  StatusParticipacao.naoIrei,
                                ),
                              ),
                            ],
                          ),
                          if (_mostrarMotivos) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Selecione o motivo:',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: MotivoAusencia.values
                                  .map(
                                    (m) => ChoiceChip(
                                      label: Text(m.label),
                                      selected: _motivoSelecionado == m,
                                      onSelected: (_) => setState(
                                        () => _motivoSelecionado = m,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: _obsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Observação (opcional)',
                              prefixIcon: Icon(Icons.message_outlined),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(51.2),
                                    padding: EdgeInsets.zero,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  child: const Icon(Icons.arrow_back_rounded),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: _confirmarPresenca,
                                  icon: const Icon(Icons.send_outlined),
                                  label: const Text('Confirmar'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(51.2),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ParticipantsScreen(peladaId: widget.peladaId),
                      ),
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: primary.withAlphaSafe(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: primary.withAlphaSafe(alpha: 0.25),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.groups_outlined,
                                        color: primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Quórum e Participantes',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: primary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new_outlined,
                                  color: primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${pelada.participantesConfirmados}/$quorumMax',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: quorumCor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Mín: ${pelada.quorumMinimo} • Máx: $quorumMax • Vagas: $vagasRestantes',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: quorumMax > 0
                                    ? (pelada.participantesConfirmados /
                                              quorumMax)
                                          .clamp(0.0, 1.0)
                                    : 0.0,
                                minHeight: 10,
                                backgroundColor:
                                    theme.colorScheme.outlineVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  quorumCor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pelada.temQuorum
                                  ? '✅ Quórum mínimo atingido! Vai rolar jogo.'
                                  : 'Faltam $faltamMin para garantir o jogo. Toque para ver/gerenciar a Lista de participantes.',
                              style: TextStyle(
                                color: quorumCor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (confirmadas.isNotEmpty)
                              _lista(
                                confirmadas,
                                'Confirmados',
                                Icons.check_circle,
                                AppColors.success,
                              ),
                            if (duvida.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _lista(
                                duvida,
                                'Em dúvida',
                                Icons.help_outline,
                                AppColors.warning,
                              ),
                            ],
                            if (naoIrao.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _lista(
                                naoIrao,
                                'Não irão',
                                Icons.cancel_outlined,
                                AppColors.danger,
                              ),
                            ],
                            if (participacoes.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Se deixar pra última hora vai ficar de fora!',
                                  style: TextStyle(color: theme.hintColor),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (ctx) {
                      final temLatLon =
                          pelada.latitude != null && pelada.longitude != null;
                      final temEndereco =
                          (pelada.endereco.trim().isNotEmpty) ||
                          (pelada.localArena.trim().isNotEmpty) ||
                          (pelada.bairro.trim().isNotEmpty) ||
                          (pelada.cidade.trim().isNotEmpty) ||
                          (pelada.estado.trim().isNotEmpty);
                      final bool temLocalArena = pelada.localArena
                          .trim()
                          .isNotEmpty;
                      final String localArenaTexto = pelada.localArena.trim();
                      final String enderecoTexto = [
                        if (pelada.endereco.trim().isNotEmpty)
                          pelada.endereco.trim(),
                        if (pelada.bairro.trim().isNotEmpty)
                          pelada.bairro.trim(),
                        [
                          if (pelada.cidade.trim().isNotEmpty)
                            pelada.cidade.trim(),
                          if (pelada.estado.trim().isNotEmpty)
                            pelada.estado.trim(),
                        ].where((e) => e.isNotEmpty).join(' - '),
                      ].where((e) => e.isNotEmpty).join(', ');
                      final coords = temLatLon
                          ? Coordenadas(pelada.latitude!, pelada.longitude!)
                          : null;
                      final bool podeAbrir = temEndereco || temLatLon;
                      final Color primario = Theme.of(ctx).colorScheme.primary;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: podeAbrir
                              ? () async {
                                  await _abrirModalMapa(
                                    ctx,
                                    coords: temLatLon
                                        ? Coordenadas(
                                            pelada.latitude!,
                                            pelada.longitude!,
                                          )
                                        : null,
                                    localArena: pelada.localArena,
                                    endereco: pelada.endereco,
                                    bairro: pelada.bairro,
                                    cidade: pelada.cidade,
                                    estado: pelada.estado,
                                  );
                                }
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    _MapaIconeSubstituto(
                                      size: 22,
                                      fallbackColor: primario,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Localização',
                                        style: Theme.of(
                                          ctx,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    if (podeAbrir) ...[
                                      Icon(
                                        Icons.open_in_new_outlined,
                                        size: 18,
                                        color: primario,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Abrir no Maps',
                                        style: TextStyle(
                                          color: primario,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!temEndereco && !temLatLon)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    14,
                                    16,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 28,
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(ctx).dividerColor,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_off_outlined,
                                          color: Theme.of(ctx).hintColor,
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Endereço não cadastrado para esta pelada. Entre em contato com o organizador para mais informações.',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else ...[
                                if (temLocalArena)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      10,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primario.withAlphaSafe(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: primario.withAlphaSafe(
                                            alpha: 0.28,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.sports_soccer_outlined,
                                            color: primario,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              localArenaTexto,
                                              style: Theme.of(ctx)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: primario,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (enderecoTexto.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 18,
                                          color: Theme.of(ctx).hintColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            enderecoTexto,
                                            style: Theme.of(
                                              ctx,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (temLatLon && coords != null)
                                  _MapaEmbedPreview(coords: coords)
                                else
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      16,
                                    ),
                                    child: Container(
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(ctx).dividerColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.pin_drop_outlined,
                                                size: 34,
                                                color: Theme.of(ctx).hintColor,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Aguardando coordenadas...',
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    ctx,
                                                  ).hintColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'O organizador ainda não gerou a localização geográfica deste endereço.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    ctx,
                                                  ).hintColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Detalhes',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (pelada.status != StatusPelada.ativa)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withAlphaSafe(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withAlphaSafe(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: statusColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Esta pelada está ${pelada.status.label.toLowerCase()}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: statusColor,
                                          ),
                                        ),
                                        if (pelada.statusMotivo != null &&
                                            pelada.statusMotivo!
                                                .trim()
                                                .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              pelada.statusMotivo!.trim(),
                                              style: TextStyle(
                                                color: theme.hintColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (pelada.status != StatusPelada.ativa)
                            const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlphaSafe(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  pelada.status.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withAlphaSafe(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  taxa,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.warning,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pelada.avaliacaoMedia > 0
                                        ? pelada.avaliacaoMedia.toStringAsFixed(
                                            1,
                                          )
                                        : '—',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    pelada.totalAvaliacoes > 0
                                        ? '(${pelada.totalAvaliacoes})'
                                        : '',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _infoTile(
                            Icons.event_available,
                            'Data de Início',
                            dateFull.format(pelada.dataInicio),
                          ),
                          _infoTile(
                            Icons.event,
                            'Data de Fim',
                            dateFull.format(pelada.dataFim),
                          ),
                          _infoTile(
                            Icons.access_time,
                            'Horário',
                            '${pelada.horaInicio.hour.toString().padLeft(2, '0')}:${pelada.horaInicio.minute.toString().padLeft(2, '0')} às ${pelada.horaFim.hour.toString().padLeft(2, '0')}:${pelada.horaFim.minute.toString().padLeft(2, '0')}',
                          ),
                          _infoTile(
                            Icons.sports_soccer,
                            'Modalidade',
                            pelada.modalidade.label,
                          ),
                          _infoTile(
                            Icons.park,
                            'Tipo de Grama',
                            pelada.tipoGrama.label,
                          ),
                          _infoTile(
                            Icons.sports_soccer,
                            'Tipo de Chuteira',
                            chuteiraLabel,
                          ),
                          _infoTileGenero(
                            pelada.categoriaGenero == CategoriaGenero.masc
                                ? Icons.male
                                : Icons.female,
                            'Categoria',
                            pelada.categoriaGenero.label,
                            pelada.categoriaGenero,
                          ),
                          _infoTile(
                            Icons.group_outlined,
                            'Sub-Categoria',
                            pelada.categoria.label,
                          ),
                          _infoTile(
                            Icons.palette_outlined,
                            'Cor do Colete',
                            coleteLabel,
                          ),
                          const SizedBox(height: 6),
                          _infoTile(
                            Icons.person_outline,
                            'Organizador',
                            pelada.organizadorNome,
                          ),
                          _infoTile(
                            Icons.phone_outlined,
                            'Contato',
                            pelada.contato,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ChecklistCard(checklist: pelada.checklist),
                  const SizedBox(height: 10),
                  if (pelada.descricao != null && pelada.descricao!.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Descrição',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(pelada.descricao!),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Avalie esta Pelada',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => _mostrarAvaliacao = !_mostrarAvaliacao,
                                ),
                                child: Text(
                                  _mostrarAvaliacao ? 'Fechar' : 'Avaliar',
                                ),
                              ),
                            ],
                          ),
                          if (_mostrarAvaliacao || _notaAvaliacao > 0) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: RatingBar.builder(
                                initialRating: _notaAvaliacao,
                                minRating: 0,
                                maxRating: 5,
                                allowHalfRating: false,
                                itemCount: 5,
                                glow: false,
                                itemPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                itemBuilder: (_, _) => const Icon(
                                  Icons.star,
                                  color: AppColors.warning,
                                ),
                                onRatingUpdate: (v) =>
                                    setState(() => _notaAvaliacao = v),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                _notaAvaliacao > 0
                                    ? '${_notaAvaliacao.round().toString()} estrela(s)'
                                    : 'Toque para avaliar',
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _comentarioAvaliacaoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Comentário (opcional)',
                                hintText:
                                    'Sua opinião ajuda outros peladeiros...',
                                prefixIcon: Icon(Icons.rate_review_outlined),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _notaAvaliacao > 0 ? _avaliar : null,
                                child: const Text('Enviar Avaliação'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: theme.hintColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTileGenero(
    IconData icon,
    String label,
    String value,
    CategoriaGenero genero,
  ) {
    final theme = Theme.of(context);
    final cor = genero == CategoriaGenero.masc
        ? Colors.blue.shade700
        : Colors.pink.shade400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: cor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presencaBtn(
    String label,
    IconData icon,
    Color color,
    StatusParticipacao status,
  ) {
    final selected = _statusSelecionado == status;
    return GestureDetector(
      onTap: () => setState(() {
        _statusSelecionado = status;
        _mostrarMotivos = status == StatusParticipacao.naoIrei;
        if (status != StatusParticipacao.naoIrei) _motivoSelecionado = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withAlphaSafe(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : null),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista(
    List<Participation> lista,
    String titulo,
    IconData icon,
    Color cor,
  ) {
    final isConfirmados = titulo == 'Confirmados';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: cor),
            const SizedBox(width: 6),
            Text(
              '$titulo (${lista.length})',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cor,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxChipWidth = constraints.maxWidth < 320
                ? constraints.maxWidth * 0.85
                : constraints.maxWidth * 0.42;
            final chipWidth = maxChipWidth.clamp(120.0, 240.0);

            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lista.map((p) {
                final apelido = (p.usuarioApelido ?? '').trim().isEmpty
                    ? null
                    : p.usuarioApelido!.trim();
                final posAbrev = p.usuarioPosicaoPrincipal?.abreviacao;

                String chipLabel;
                if (isConfirmados) {
                  if (apelido != null && posAbrev != null) {
                    chipLabel = '$apelido - $posAbrev';
                  } else if (apelido != null) {
                    chipLabel = apelido;
                  } else if (posAbrev != null) {
                    chipLabel = '${p.usuarioNome.split(' ').first} - $posAbrev';
                  } else {
                    chipLabel = p.usuarioNome.split(' ').first;
                  }
                } else {
                  chipLabel = p.usuarioNome.split(' ').first;
                }

                String tooltipMsg;
                if (isConfirmados) {
                  final buffer = StringBuffer(p.usuarioNome);
                  if (apelido != null) buffer.write(' · "$apelido"');
                  if (p.usuarioPosicaoPrincipal != null) {
                    buffer.write(' · ${p.usuarioPosicaoPrincipal!.label}');
                  }
                  tooltipMsg = buffer.toString();
                } else {
                  tooltipMsg = p.usuarioNome;
                }

                return Tooltip(
                  message: tooltipMsg,
                  preferBelow: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: chipWidth),
                    child: Chip(
                      label: Text(
                        chipLabel,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                      avatar: const Icon(Icons.person, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
