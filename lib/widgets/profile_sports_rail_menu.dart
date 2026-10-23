import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/pelada_filter.dart';
import '../services/data_service.dart';
import '../screens/home_screen.dart';
import '../screens/campos_arenas_screen.dart';
import '../screens/juizes_screen.dart';
import '../screens/goleiros_screen.dart';
import '../screens/mapa_screen.dart';

class ProfileSportsRailMenu extends StatefulWidget {
  final double buttonDiameter;
  final double verticalSpacing;
  final Duration staggerDelay;
  final double labelColumnWidth;
  final double labelGutter;
  final EdgeInsets labelOffsetAdjust;
  final double navBarHeight;
  final double minHorizontalPadding;
  final double minItemAdjacentGap;
  final double centerVerticalAtTopEdgeOffsetAdjust;

  final String? activeButtonId;

  const ProfileSportsRailMenu({
    super.key,
    this.buttonDiameter = 56,
    this.verticalSpacing = 6,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.labelColumnWidth = 92,
    this.labelGutter = 10,
    this.labelOffsetAdjust = const EdgeInsets.only(right: 4),
    required this.navBarHeight,
    this.minHorizontalPadding = 8,
    this.minItemAdjacentGap = 8,
    this.centerVerticalAtTopEdgeOffsetAdjust = 0,
    required int notchDockedOffset,
    this.activeButtonId,
  });

  @override
  State<ProfileSportsRailMenu> createState() => _ProfileSportsRailMenuState();
}

class _ProfileSportsRailMenuState extends State<ProfileSportsRailMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final OverlayPortalController _overlayController;
  bool _aberto = false;

  // Vôlei e basquete permanecem na lista original, mas ficam ocultos durante
  // esta fase. Para reativá-los, remova seus IDs deste conjunto.
  static const Set<String> _idsModalidadesOcultas = {'volei', 'basquete'};
  static const int _totalOpcoes = 6;
  static const double _minButtonTouchArea = 44;

  Duration get _duracaoAbertura => Duration(
    milliseconds: _totalOpcoes * widget.staggerDelay.inMilliseconds + 260,
  );

  double get _passoColuna {
    final toqueMin = _minButtonTouchArea.clamp(
      0.0,
      widget.buttonDiameter * 1.1,
    );
    final base = widget.buttonDiameter + widget.verticalSpacing;
    if (base < toqueMin + widget.verticalSpacing) {
      return toqueMin + widget.verticalSpacing;
    }
    return base;
  }

  double get _alturaTotalOpcoes {
    return _totalOpcoes * widget.buttonDiameter +
        (_totalOpcoes - 1) * widget.verticalSpacing;
  }

  double get _alturaTotalAberta {
    return widget.buttonDiameter + widget.verticalSpacing + _alturaTotalOpcoes;
  }

  @override
  void initState() {
    super.initState();
    _overlayController = OverlayPortalController(debugLabel: 'trail-menu');
    _ctrl = AnimationController(
      vsync: this,
      duration: _duracaoAbertura,
      reverseDuration: Duration(
        milliseconds: (_duracaoAbertura.inMilliseconds / 1.7).round(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _overlayController.show();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navegarParaTela(BuildContext ctx, String opcaoId) async {
    unawaited(HapticFeedback.selectionClick());
    final nav = Navigator.of(ctx);
    final messenger = ScaffoldMessenger.of(ctx);
    final data = ctx.read<DataService>();
    _fecharMenu();
    final delayMs = (_duracaoAbertura.inMilliseconds / 1.7).round() + 20;
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    if (!mounted) return;

    Widget destination;
    String rotuloErro;
    Set<Modalidade>? modalidades;
    switch (opcaoId) {
      case 'arena':
        destination = const CamposArenasScreen();
        rotuloErro = 'Campos e Arenas';
        break;
      case 'juizes':
        destination = const JuizesScreen();
        rotuloErro = 'Juízes';
        break;
      case 'goleiros':
        destination = const GoleirosScreen();
        rotuloErro = 'Goleiros';
        break;
      case 'mapa':
        destination = const MapaScreen();
        rotuloErro = 'Mapa';
        break;
      case 'volei':
        modalidades = const {Modalidade.voley};
        destination = const HomeScreen(modalidadesIniciais: {Modalidade.voley});
        rotuloErro = 'eventos de vôlei';
        break;
      case 'basquete':
        modalidades = const {Modalidade.basquete};
        destination = const HomeScreen(
          modalidadesIniciais: {Modalidade.basquete},
        );
        rotuloErro = 'eventos de basquete';
        break;
      case 'varios':
        modalidades = Set<Modalidade>.from(Modalidade.values)
          ..removeAll(const {
            Modalidade.futebolCampo,
            Modalidade.futebolRua,
            Modalidade.futsal,
            Modalidade.society,
            Modalidade.areia,
            Modalidade.praia,
            Modalidade.voley,
            Modalidade.basquete,
          });
        destination = HomeScreen(modalidadesIniciais: modalidades);
        rotuloErro = 'eventos de outras modalidades';
        break;
      case 'peladas':
      default:
        destination = const HomeScreen();
        rotuloErro = 'Home';
    }

    if (destination is HomeScreen) {
      data.setSearch(null);
      if (modalidades == null) {
        data.clearFilter();
      } else {
        data.setFilter(PeladaFilter(modalidades: modalidades));
      }
    }

    try {
      if (destination is HomeScreen) {
        await nav.pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 260),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            pageBuilder: (_, anim, sec) => FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              ),
              child: destination,
            ),
          ),
          (r) => false,
        );
      } else {
        await nav.push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 260),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            pageBuilder: (_, anim, sec) => FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              ),
              child: destination,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível navegar para $rotuloErro: $e'),
        ),
      );
    }
  }

  void _alternarMenu() {
    unawaited(HapticFeedback.mediumImpact());
    if (_aberto) {
      _fecharMenu();
    } else {
      setState(() {
        _aberto = true;
      });
      unawaited(_ctrl.forward());
    }
  }

  void _fecharMenu() {
    if (!_aberto) return;
    setState(() {
      _aberto = false;
    });
    unawaited(_ctrl.reverse());
  }

  List<_BotaoEsportivo> _opcoes() => const [
    _BotaoEsportivo(
      id: 'peladas',
      nome: 'PELADAS',
      icone: Icons.sports_soccer_rounded,
      cores: [Color(0xFFFFFFFF), Color(0xFFDCDCDC)],
      corIcone: Colors.black,
      bordaCor: Colors.black,
      bordaLargura: 2.4,
      ocultarNome: false,
    ),
    _BotaoEsportivo(
      id: 'volei',
      nome: 'VÔLEI',
      icone: Icons.sports_volleyball_rounded,
      cores: [Color(0xFFFFDB4D), Color(0xFF0C4DA2)],
      corIcone: Color(0xFF10316B),
      bordaCor: Color(0xFF0A2E63),
      bordaLargura: 2.0,
      ocultarNome: false,
    ),
    _BotaoEsportivo(
      id: 'basquete',
      nome: 'BASQUETE',
      icone: Icons.sports_basketball_rounded,
      cores: [Color(0xFFFF8A3D), Color(0xFFC94807)],
      corIcone: Color(0xFF3B1400),
      bordaCor: Color(0xFF4A1700),
      bordaLargura: 2.0,
      ocultarNome: false,
    ),
    _BotaoEsportivo(
      id: 'varios',
      nome: 'VÁRIOS',
      icone: Icons.sports_tennis_rounded,
      cores: [Color(0xFFD4EF5A), Color(0xFF7EA600)],
      corIcone: Colors.white,
      bordaCor: Color(0xFF2E4300),
      bordaLargura: 2.0,
      ocultarNome: false,
    ),
    _BotaoEsportivo(
      id: 'arena',
      nome: 'CAMPOS',
      icone: Icons.stadium_rounded,
      cores: [Color(0xFF85E673), Color(0xFF00793B)],
      corIcone: Color(0xFF07160E),
      bordaCor: Color(0xFF004024),
      bordaLargura: 2.0,
      ocultarNome: false,
    ),
    _BotaoEsportivo(
      id: 'juizes',
      nome: 'JUÍZES',
      icone: Icons.sports_rounded,
      cores: [Color(0xFFF0F0F0), Color(0xFF9A9A9A)],
      corIcone: Colors.black,
      bordaCor: Color(0xFF2A2A2A),
      bordaLargura: 2.4,
      ocultarNome: false,
      iconeFallbackApito: Icons.sports_outlined,
    ),
    _BotaoEsportivo(
      id: 'goleiros',
      nome: 'GOLEIROS',
      icone: Icons.sports_handball_outlined,
      cores: [Color(0xFF00BFA5), Color(0xFF00796B)],
      corIcone: Colors.white,
      bordaCor: Color(0xFF004D40),
      bordaLargura: 2.4,
      ocultarNome: false,
    ),
    _BotaoEsportivo(
      id: 'mapa',
      nome: 'MAPA',
      icone: Icons.map_outlined,
      cores: [Color(0xFFFFE082), Color(0xFFF9A825)],
      corIcone: Color(0xFF3E2723),
      bordaCor: Color(0xFF8D5A00),
      bordaLargura: 2.2,
      ocultarNome: false,
    ),
  ];

  List<_BotaoEsportivo> get _opcoesVisiveis => _opcoes()
      .where((opcao) => !_idsModalidadesOcultas.contains(opcao.id))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final menuHeight =
        widget.navBarHeight + mq.padding.bottom + _alturaTotalAberta;
    final localFabCenterY =
        menuHeight -
        mq.padding.bottom -
        widget.centerVerticalAtTopEdgeOffsetAdjust -
        widget.buttonDiameter / 2;
    return SizedBox(
      width: widget.buttonDiameter,
      height: widget.buttonDiameter,
      child: OverlayPortal.overlayChildLayoutBuilder(
        controller: _overlayController,
        overlayChildBuilder: (overlayContext, layoutInfo) {
          final buttonCenter = MatrixUtils.transformPoint(
            layoutInfo.childPaintTransform,
            Offset(widget.buttonDiameter / 2, widget.buttonDiameter / 2),
          );
          final stageTop = buttonCenter.dy - localFabCenterY;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _ctrl.value <= 0.02,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _fecharMenu,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: stageTop,
                height: menuHeight,
                child: _buildMenuStage(overlayContext),
              ),
            ],
          );
        },
        child: Transform.translate(
          offset: Offset(
            0,
            -(mq.padding.bottom + widget.centerVerticalAtTopEdgeOffsetAdjust),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildMenuStage(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final paddingBottom = mq.padding.bottom;
    final containerHeight =
        widget.navBarHeight + paddingBottom + _alturaTotalAberta;

    return SizedBox(
      width: screenWidth,
      height: containerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerXRelativo = constraints.maxWidth / 2;
          final xLeftOpcoes =
              centerXRelativo -
              widget.buttonDiameter / 2 -
              (widget.labelGutter + widget.labelColumnWidth);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              _construirBotaoPrincipal(theme, centerXRelativo, paddingBottom),
              for (int i = 0; i < _opcoesVisiveis.length; i++)
                _construirOpcaoAnimada(
                  i,
                  _opcoesVisiveis[i],
                  centerXRelativo,
                  paddingBottom,
                  xLeftOpcoes,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirOpcaoAnimada(
    int i,
    _BotaoEsportivo opcao,
    double centerXRelativo,
    double paddingBottom,
    double xLeftOpcoes,
  ) {
    final start = i / (_totalOpcoes + 0.5);
    final end = (i + 1.45) / (_totalOpcoes + 0.8);
    final anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
      reverseCurve: Interval(start.clamp(0.0, 1.0), 1.0, curve: Curves.easeIn),
    );

    final distanciaCentros = (i + 1) * _passoColuna;
    final dyDestino = -(distanciaCentros);

    final leftColuna = xLeftOpcoes < widget.minHorizontalPadding
        ? widget.minHorizontalPadding.toDouble()
        : xLeftOpcoes;

    final larguraColuna =
        centerXRelativo + (widget.buttonDiameter / 2) - leftColuna;

    final bottomAncoragem =
        paddingBottom + widget.centerVerticalAtTopEdgeOffsetAdjust;

    final ativo = opcao.id == widget.activeButtonId;

    return AnimatedBuilder(
      animation: anim,
      builder: (ctx, _) {
        final t = anim.value;
        final opacidade = t.clamp(0.0, 1.0);
        final scaleBase = 0.35 + 0.65 * t;
        final scale = ativo ? scaleBase * 1.08 : scaleBase;
        final translateY = dyDestino * t;

        final centroXLocal = centerXRelativo - leftColuna;
        final leftBotao = centroXLocal - (widget.buttonDiameter / 2);

        final leftLabel = 0.0;
        // A coluna do rótulo termina exatamente onde começa o botão. Isso
        // impede que textos longos invadam a imagem (caso de VÁRIOS).
        final rightLabel = widget.buttonDiameter;
        final theme = Theme.of(ctx);
        final primary = theme.colorScheme.primary;
        final primaryHsl = HSLColor.fromColor(primary);
        final labelBackground = primaryHsl
            .withLightness(
              (primaryHsl.lightness - (ativo ? 0.10 : 0.18))
                  .clamp(0.18, 0.42)
                  .toDouble(),
            )
            .toColor();

        return Positioned(
          left: leftColuna,
          bottom: bottomAncoragem - translateY,
          width: larguraColuna,
          height: widget.buttonDiameter,
          child: IgnorePointer(
            ignoring: opacidade < 0.05,
            child: Opacity(
              opacity: opacidade,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (ativo)
                    Positioned(
                      left: leftBotao - 5,
                      top: -5,
                      width: widget.buttonDiameter + 10,
                      height: widget.buttonDiameter + 10,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primary, width: 2.6),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.30),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: leftLabel,
                    right: rightLabel,
                    top: 0,
                    bottom: 0,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: widget.labelOffsetAdjust.left,
                        top: widget.labelOffsetAdjust.top,
                        bottom: widget.labelOffsetAdjust.bottom,
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: () {
                          if (opcao.ocultarNome) {
                            return const SizedBox.shrink();
                          }
                          const novoFontSize = 14.0;
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomRight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(6),
                                  ),
                                ),
                                splashFactory: InkRipple.splashFactory,
                                splashColor: primary.withValues(alpha: 0.18),
                                highlightColor: primary.withValues(alpha: 0.08),
                                onTap: () => _navegarParaTela(ctx, opcao.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: labelBackground,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    opcao.nome,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: novoFontSize,
                                      fontWeight: ativo
                                          ? FontWeight.w900
                                          : FontWeight.w800,
                                      letterSpacing: 0.35,
                                      height: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: leftBotao,
                    top: 0,
                    width: widget.buttonDiameter,
                    height: widget.buttonDiameter,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: _BotaoCircular(
                        tamanho: widget.buttonDiameter,
                        opcao: opcao,
                        onTap: () => _navegarParaTela(ctx, opcao.id),
                        ativo: ativo,
                        corPrimaria: primary,
                      ),
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

  Positioned _construirBotaoPrincipal(
    ThemeData theme,
    double centerXRelativo,
    double paddingBottom,
  ) {
    final halfDiameter = widget.buttonDiameter / 2;
    final bottomPos =
        paddingBottom + widget.centerVerticalAtTopEdgeOffsetAdjust;

    return Positioned(
      left: centerXRelativo - halfDiameter,
      bottom: bottomPos,
      width: widget.buttonDiameter,
      height: widget.buttonDiameter,
      child: _conteudoBotaoPrincipal(theme),
    );
  }

  Widget _conteudoBotaoPrincipal(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final gradBase = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primary,
        HSLColor.fromColor(primary)
            .withLightness(
              (HSLColor.fromColor(primary).lightness - 0.18).clamp(0.0, 1.0),
            )
            .toColor(),
      ],
    );

    return SizedBox(
      width: widget.buttonDiameter,
      height: widget.buttonDiameter,
      child: Semantics(
        button: true,
        label: _aberto ? 'Fechar menu de esportes' : 'Abrir menu de esportes',
        hint: 'Toque duas vezes para alternar',
        child: Tooltip(
          message: _aberto ? 'Fechar menu' : 'Menu de esportes',
          preferBelow: false,
          verticalOffset: widget.buttonDiameter / 2,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradBase,
                border: Border.all(
                  color: _aberto
                      ? primary.withValues(alpha: 0.92)
                      : Colors.black,
                  width: 2.4,
                ),
              ),
              child: ClipOval(
                child: InkWell(
                  key: const ValueKey<String>('trail-btn-main'),
                  customBorder: const CircleBorder(),
                  splashFactory: InkRipple.splashFactory,
                  splashColor: Colors.white.withValues(alpha: 0.18),
                  highlightColor: Colors.white.withValues(alpha: 0.12),
                  onTap: _alternarMenu,
                  child: Padding(
                    padding: EdgeInsets.all(widget.buttonDiameter * 0.15),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        color: onPrimary,
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

class _BotaoEsportivo {
  final String id;
  final String nome;
  final IconData icone;
  final List<Color> cores;
  final Color corIcone;
  final Color bordaCor;
  final double bordaLargura;
  final bool ocultarNome;
  final IconData? iconeFallbackApito;

  const _BotaoEsportivo({
    required this.id,
    required this.nome,
    required this.icone,
    required this.cores,
    required this.corIcone,
    required this.bordaCor,
    required this.bordaLargura,
    this.ocultarNome = false,
    this.iconeFallbackApito,
  });
}

class _BotaoCircular extends StatelessWidget {
  final double tamanho;
  final _BotaoEsportivo opcao;
  final VoidCallback? onTap;
  final bool ativo;
  final Color? corPrimaria;

  const _BotaoCircular({
    required this.tamanho,
    required this.opcao,
    required this.onTap,
    this.ativo = false,
    this.corPrimaria,
  });

  @override
  Widget build(BuildContext context) {
    final gradiente = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: opcao.cores,
    );
    final desabilitado = onTap == null;
    final bordaCor = ativo && corPrimaria != null
        ? corPrimaria!
        : desabilitado
        ? opcao.bordaCor.withValues(alpha: 0.4)
        : opcao.bordaCor;
    final bordaLargura = ativo ? opcao.bordaLargura + 0.6 : opcao.bordaLargura;
    final sombraAlpha = desabilitado
        ? 0.12
        : ativo
        ? 0.38
        : 0.28;
    final sombraBlur = desabilitado
        ? 5.0
        : ativo
        ? 16.0
        : 11.0;
    final nome = opcao.nome.isEmpty ? 'Juízes' : opcao.nome;
    final tamanhoMin = tamanho < 32 ? 32.0 : tamanho;

    return Semantics(
      button: !desabilitado,
      label: ativo ? '$nome. Seção atual' : '$nome. Menu perfil',
      enabled: !desabilitado,
      excludeSemantics: true,
      onTap: desabilitado ? null : onTap,
      onTapHint: 'Abrir $nome',
      child: Tooltip(
        message: nome,
        preferBelow: false,
        verticalOffset: tamanhoMin / 2,
        child: Material(
          type: MaterialType.circle,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: Container(
            key: ValueKey<String>('trail-btn-${opcao.id}'),
            width: tamanhoMin,
            height: tamanhoMin,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradiente,
              border: Border.all(color: bordaCor, width: bordaLargura),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: sombraAlpha),
                  blurRadius: sombraBlur,
                  spreadRadius: -1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildCorpoInterno(
              context,
              desabilitado: desabilitado,
              fallback: opcao.iconeFallbackApito ?? opcao.icone,
              onAssetTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorpoInterno(
    BuildContext context, {
    required bool desabilitado,
    required IconData fallback,
    required VoidCallback? onAssetTap,
  }) {
    String? assetPath;
    String altText;
    switch (opcao.id) {
      case 'peladas':
        assetPath = 'lib/img/1pelada.png';
        altText = 'Peladas — bola de futebol';
        break;
      case 'volei':
        assetPath = 'lib/img/2volei.png';
        altText = 'Vôlei — bola de vôlei';
        break;
      case 'basquete':
        assetPath = 'lib/img/3basquete.png';
        altText = 'Basquete — bola de basquete';
        break;
      case 'varios':
        assetPath = 'lib/img/4varios.png';
        altText = 'Vários esportes — bola de tênis e outras modalidades';
        break;
      case 'arena':
        assetPath = 'lib/img/5campos.png';
        altText = 'Campos e arenas esportivas — estádio';
        break;
      case 'juizes':
        assetPath = 'lib/img/6juizes.png';
        altText = 'Juízes e arbitragem — apito';
        break;
      case 'goleiros':
        assetPath = 'lib/img/7goleiros.png';
        altText = 'Goleiros — luva de goleiro';
        break;
      case 'mapa':
        assetPath = 'lib/img/8map.png';
        altText = 'Mapa';
        break;
      default:
        assetPath = null;
        altText = opcao.nome.isEmpty ? 'Juízes' : opcao.nome;
    }

    if (assetPath != null) {
      final ehPeladas = opcao.id == 'peladas';
      final cursor = desabilitado
          ? MouseCursor.defer
          : SystemMouseCursors.click;
      return _BotaoAssetComHover(
        cursor: cursor,
        habilitarHover: !desabilitado,
        destacarPeladas: ativo || ehPeladas,
        onTap: onAssetTap,
        assetPath: assetPath,
        altText: altText,
        fallbackIcon: fallback,
        fallbackColor: desabilitado
            ? opcao.corIcone.withValues(alpha: 0.5)
            : ativo && corPrimaria != null
            ? corPrimaria!
            : opcao.corIcone,
        fallbackSize: tamanho * 0.65,
      );
    }
    return Semantics(
      label: altText,
      button: true,
      child: Icon(fallback, size: tamanho * 0.65, color: opcao.corIcone),
    );
  }
}

class _BotaoAssetComHover extends StatefulWidget {
  final MouseCursor cursor;
  final bool habilitarHover;
  final bool destacarPeladas;
  final VoidCallback? onTap;
  final String assetPath;
  final String altText;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double fallbackSize;

  const _BotaoAssetComHover({
    required this.cursor,
    required this.habilitarHover,
    required this.destacarPeladas,
    required this.onTap,
    required this.assetPath,
    required this.altText,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.fallbackSize,
  });

  @override
  State<_BotaoAssetComHover> createState() => _BotaoAssetComHoverState();
}

class _BotaoAssetComHoverState extends State<_BotaoAssetComHover> {
  bool _hover = false;
  bool _assetOk = true;

  @override
  Widget build(BuildContext context) {
    final semHover = !widget.habilitarHover;
    final escala = semHover
        ? 1.0
        : _hover
        ? widget.destacarPeladas
              ? 1.08
              : 1.04
        : 1.0;
    final opacidade = semHover
        ? 1.0
        : _hover
        ? widget.destacarPeladas
              ? 1.0
              : 0.92
        : 1.0;
    final brilho = (semHover || !_hover)
        ? null
        : widget.destacarPeladas
        ? ColorFilter.mode(
            Colors.white.withValues(alpha: 0.10),
            BlendMode.lighten,
          )
        : null;

    Widget clickableLayer;
    if (_assetOk) {
      clickableLayer = ClipOval(
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.circle,
          color: Colors.transparent,
          child: Ink.image(
            image: AssetImage(widget.assetPath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            onImageError: (_, _) {
              if (!mounted) return;
              setState(() => _assetOk = false);
            },
            child: InkWell(
              customBorder: const CircleBorder(),
              splashFactory: InkRipple.splashFactory,
              splashColor: Colors.white.withValues(alpha: 0.24),
              highlightColor: Colors.white.withValues(alpha: 0.12),
              onTap: widget.onTap,
              enableFeedback: widget.habilitarHover,
              canRequestFocus: widget.habilitarHover,
              mouseCursor: widget.cursor,
              excludeFromSemantics: true,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    } else {
      clickableLayer = ClipOval(
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.circle,
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashFactory: InkRipple.splashFactory,
            splashColor: Colors.white.withValues(alpha: 0.24),
            highlightColor: Colors.white.withValues(alpha: 0.12),
            onTap: widget.onTap,
            enableFeedback: widget.habilitarHover,
            canRequestFocus: widget.habilitarHover,
            mouseCursor: widget.cursor,
            excludeFromSemantics: true,
            child: Center(
              child: Icon(
                widget.fallbackIcon,
                color: widget.fallbackColor,
                size: widget.fallbackSize,
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        if (semHover) return;
        setState(() => _hover = true);
      },
      onExit: (_) {
        if (semHover) return;
        setState(() => _hover = false);
      },
      child: SizedBox.expand(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          scale: escala,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            opacity: opacidade,
            child: brilho == null
                ? clickableLayer
                : ColorFiltered(colorFilter: brilho, child: clickableLayer),
          ),
        ),
      ),
    );
  }
}
