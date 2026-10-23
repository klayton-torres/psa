import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enums.dart';

enum MenuAcaoNavegacao {
  homeFutebol,
  homeVolei,
  homeBasquete,
  homeDiversos,
  camposArenas,
  juizes,
  goleiros,
}

class AnimatedSportsMenu extends StatefulWidget {
  final VoidCallback? onFutebolPressed;
  final VoidCallback? onVoleiPressed;
  final VoidCallback? onBasquetePressed;
  final VoidCallback? onDiversosPressed;
  final VoidCallback? onCamposArenasPressed;
  final VoidCallback? onJuizesPressed;
  final VoidCallback? onGoleirosPressed;
  final VoidCallback? onFechado;
  final double? mainButtonSize;
  final double optionDiameter;
  final double verticalSpacing;
  final Duration itemDelay;

  const AnimatedSportsMenu({
    super.key,
    this.onFutebolPressed,
    this.onVoleiPressed,
    this.onBasquetePressed,
    this.onDiversosPressed,
    this.onCamposArenasPressed,
    this.onJuizesPressed,
    this.onGoleirosPressed,
    this.onFechado,
    this.mainButtonSize,
    this.optionDiameter = 52,
    this.verticalSpacing = 12,
    this.itemDelay = const Duration(milliseconds: 55),
  });

  static Set<Modalidade> get modalidadesFutebol => const {
    Modalidade.futebolCampo,
    Modalidade.futebolRua,
    Modalidade.futsal,
    Modalidade.society,
    Modalidade.areia,
    Modalidade.praia,
  };

  static const Set<Modalidade> modalidadesVolei = {Modalidade.voley};
  static const Set<Modalidade> modalidadesBasquete = {Modalidade.basquete};

  static Set<Modalidade> get modalidadesDiversos => {
    Modalidade.futevolei,
    Modalidade.outros,
  };

  @override
  State<AnimatedSportsMenu> createState() => _AnimatedSportsMenuState();
}

class _AnimatedSportsMenuState extends State<AnimatedSportsMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _aberto = false;

  static const int _opcoesAcima = 6;

  double get _step => widget.verticalSpacing + widget.optionDiameter;
  Duration get _duracaoAbertura => Duration(
    milliseconds: _opcoesAcima * widget.itemDelay.inMilliseconds + 250,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: _duracaoAbertura,
      reverseDuration: Duration(
        milliseconds: (_duracaoAbertura.inMilliseconds / 1.6).round(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _acionarComFechamento(VoidCallback? callback) {
    unawaited(HapticFeedback.selectionClick());
    _fecharMenu();
    Future.delayed(
      Duration(
        milliseconds: (_duracaoAbertura.inMilliseconds / 1.6).round() + 20,
      ),
      () {
        if (!mounted) return;
        callback?.call();
      },
    );
  }

  void _aoClicarFabPrincipal() {
    if (!_aberto) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _aberto = true;
      });
      _ctrl.forward();
      return;
    }
    _acionarComFechamento(widget.onFutebolPressed);
  }

  void _fecharMenu() {
    if (!_aberto) return;
    setState(() {
      _aberto = false;
    });
    unawaited(
      _ctrl.reverse().then((_) {
        if (!mounted) return;
        widget.onFechado?.call();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainSize = widget.mainButtonSize ?? 68.4;
    final alturaTotalAcima = _opcoesAcima * _step + widget.verticalSpacing;

    return SizedBox(
      width: mainSize,
      height: mainSize + alturaTotalAcima,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, _) {
              final visivel = _ctrl.value > 0.02;
              if (!visivel) return const SizedBox.shrink();
              final mq = MediaQuery.of(ctx);
              final center = mainSize / 2;
              final screenLargura = mq.size.width;
              final deslocEsq = -(screenLargura / 2) + center;
              final alturaAncoragem =
                  (mainSize / 2) - (widget.optionDiameter / 2);
              final totalAltura =
                  alturaTotalAcima +
                  alturaAncoragem +
                  widget.optionDiameter +
                  200;
              final totalLargura = screenLargura;
              return Positioned(
                left: deslocEsq,
                bottom: -(mq.padding.bottom + 120),
                width: totalLargura,
                height: totalAltura,
                child: IgnorePointer(
                  ignoring: !visivel,
                  child: Opacity(
                    opacity: Curves.easeOut
                        .transform(_ctrl.value)
                        .clamp(0.0, 1.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _fecharMenu,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              );
            },
          ),
          for (int i = 0; i < _opcoesAcima; i++) _construirOpcao(i, mainSize),
          _construirFabPrincipal(mainSize),
        ],
      ),
    );
  }

  Positioned _construirOpcao(int i, double mainSize) {
    final start = i / (_opcoesAcima + 0.5);
    final end = (i + 1.4) / (_opcoesAcima + 0.8);
    final anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
      reverseCurve: Interval(start.clamp(0.0, 1.0), 1.0, curve: Curves.easeIn),
    );
    final distanciaSubida = widget.optionDiameter / 2 + (i + 1) * _step;
    final ancora = mainSize / 2 - widget.optionDiameter / 2;
    final tuple = _opcaoVisual(i);
    return Positioned(
      bottom: ancora,
      child: AnimatedBuilder(
        animation: anim,
        builder: (ctx, _) {
          final t = anim.value;
          final dy = -(distanciaSubida * t);
          final s = 0.35 + 0.65 * t;
          final op = t.clamp(0.0, 1.0);
          return Opacity(
            opacity: op,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: s,
                alignment: Alignment.bottomCenter,
                child: _bolhaCircular(
                  onTap: tuple.$6,
                  gradient: tuple.$1,
                  icon: tuple.$2,
                  iconColor: tuple.$3,
                  borderColor: tuple.$4,
                  borderWidth: tuple.$5,
                  diameter: widget.optionDiameter,
                  semanticLabel: tuple.$7,
                  tooltip: tuple.$8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  (Gradient, IconData, Color, Color, double, VoidCallback, String, String)
  _opcaoVisual(int indiceDeBaixoParaCima) {
    switch (indiceDeBaixoParaCima) {
      case 0:
        return (
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFFFFDB4D), Color(0xFF0C4DA2)],
          ),
          Icons.sports_volleyball_rounded,
          const Color(0xFF10316B),
          const Color(0xFF0A2E63),
          1.8,
          () => _acionarComFechamento(widget.onVoleiPressed),
          'Ver eventos de vôlei',
          'Vôlei',
        );
      case 1:
        return (
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFFFF8A3D), Color(0xFFC94807)],
          ),
          Icons.sports_basketball_rounded,
          Colors.black54,
          const Color(0xFF4A1700),
          1.8,
          () => _acionarComFechamento(widget.onBasquetePressed),
          'Ver eventos de basquete',
          'Basquete',
        );
      case 2:
        return (
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFFD4EF5A), Color(0xFF7EA600)],
          ),
          Icons.sports_tennis_rounded,
          Colors.white,
          const Color(0xFF2E4300),
          1.8,
          () => _acionarComFechamento(widget.onDiversosPressed),
          'Ver eventos diversos',
          'Diversos',
        );
      case 3:
        return (
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFF85E673), Color(0xFF00793B)],
          ),
          Icons.stadium_rounded,
          Colors.black87,
          const Color(0xFF004024),
          1.8,
          () => _acionarComFechamento(widget.onCamposArenasPressed),
          'Ir para Campos e Arenas',
          'Arena',
        );
      case 4:
        return (
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFF1F2430), Color(0xFF000000)],
          ),
          Icons.sports_bar_rounded,
          Colors.white,
          const Color(0xFFFFFFFF),
          2.0,
          () => _acionarComFechamento(widget.onJuizesPressed),
          'Ir para Juízes',
          'Apito',
        );
      default:
        return (
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00BFA5), Color(0xFF00796B)],
          ),
          Icons.sports_handball_outlined,
          Colors.white,
          const Color(0xFF004D40),
          2.0,
          () => _acionarComFechamento(widget.onGoleirosPressed),
          'Ir para Goleiros',
          'Goleiro',
        );
    }
  }

  Widget _construirFabPrincipal(double mainSize) {
    final gradientFutebol = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _aberto
          ? const [Color(0xFFE6E6E6), Color(0xFFB8B8B8)]
          : const [Color(0xFFFFFFFF), Color(0xFFDEDEDE)],
    );
    return Positioned(
      bottom: 0,
      child: Semantics(
        button: true,
        label: _aberto
            ? 'Futebol. Toque para abrir home com todos os eventos'
            : 'Abrir menu de esportes',
        hint: 'Toque duas vezes para acionar',
        child: Tooltip(
          message: _aberto ? 'Todos os eventos' : 'Menu de esportes',
          preferBelow: false,
          verticalOffset: mainSize / 2,
          child: SizedBox(
            width: mainSize,
            height: mainSize,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradientFutebol,
                  border: Border.all(
                    color: Colors.black,
                    width: 3.0,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _aberto ? 0.35 : 0.22,
                      ),
                      blurRadius: _aberto ? 22 : 16,
                      spreadRadius: _aberto ? 0.5 : 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  splashFactory: InkRipple.splashFactory,
                  splashColor: Colors.black.withValues(alpha: 0.10),
                  highlightColor: Colors.white.withValues(alpha: 0.22),
                  onTap: _aoClicarFabPrincipal,
                  child: Padding(
                    padding: EdgeInsets.all(mainSize * 0.12),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateZ(_aberto ? (7 * math.pi / 180) : 0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            Icons.sports_soccer_rounded,
                            key: ValueKey<bool>(_aberto),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _bolhaCircular({
  required VoidCallback onTap,
  required Gradient gradient,
  required IconData icon,
  required Color iconColor,
  required Color borderColor,
  required double borderWidth,
  required double diameter,
  required String semanticLabel,
  required String tooltip,
}) {
  return Semantics(
    button: true,
    label: semanticLabel,
    excludeSemantics: true,
    child: Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: diameter / 2,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 12,
                  spreadRadius: -1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashFactory: InkRipple.splashFactory,
              splashColor: Colors.white.withValues(alpha: 0.22),
              highlightColor: Colors.white.withValues(alpha: 0.14),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(diameter * 0.18),
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
