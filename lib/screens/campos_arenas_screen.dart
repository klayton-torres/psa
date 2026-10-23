import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peladeiros_sa/screens/campos_arenas_favoritos_screen.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/campo_arena.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/profile_sports_rail_menu.dart';
import 'cadastro_campo_arena_screen.dart';
import 'campo_detail_screen.dart';
import 'campo_arena_filter_screen.dart';
import 'home_screen.dart';
import 'juizes_screen.dart';
import '../utils/profile_navigation_helper.dart';

class CamposArenasScreen extends StatefulWidget {
  final String? focoCampoId;
  final CampoArena? focoCampo;

  const CamposArenasScreen({super.key, this.focoCampoId, this.focoCampo});

  @override
  State<CamposArenasScreen> createState() => _CamposArenasScreenState();
}

class _CamposArenasScreenState extends State<CamposArenasScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _navIndex = 0;
  bool _isGridMode = true;
  bool _headerVisible = true;
  Timer? _headerAutoHideTimer;
  final ScrollController _scrollController = ScrollController();
  String? _focoDestacado;
  CampoArenaFilter _filtroCampos = const CampoArenaFilter();
  Timer? _timerRemoveDestaque;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _headerAutoHideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _headerVisible = false;
          });
        }
      });
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        _realizarFocoCampo();
      });
    });
  }

  @override
  void dispose() {
    _headerAutoHideTimer?.cancel();
    _timerRemoveDestaque?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _realizarFocoCampo() {
    final id = widget.focoCampo?.id ?? widget.focoCampoId;
    if (id == null || id.isEmpty) return;
    final ctxKey = GlobalObjectKey('campo_card_$id');
    final targetCtx = ctxKey.currentContext;
    if (targetCtx == null) {
      Future<void>.delayed(const Duration(milliseconds: 240), () {
        if (!mounted) return;
        _realizarFocoCampo();
      });
      return;
    }
    setState(() {
      _focoDestacado = id;
    });
    _timerRemoveDestaque?.cancel();
    _timerRemoveDestaque = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _focoDestacado = null;
        });
      }
    });
    try {
      final rb = targetCtx.findRenderObject();
      if (rb is RenderObject) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Scrollable.ensureVisible(
            targetCtx,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            alignment: 0.35,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
        });
      }
    } catch (_) {}
  }

  void _alternarModoGrade() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _isGridMode = !_isGridMode;
    });
  }

  // ============================================================
  // HELPERS DE NAVEGAÇÃO E AÇÕES DO TRAIL MENU
  // Obs: Todos os 6 botões chamam esses métodos, canalizados
  // pelos callbacks onPeladasTap..onJuizesTap do ProfileSportsRailMenu
  // (inserido no notch central da CustomBottomNavBar).
  // ============================================================

  static PageRouteBuilder<T> _rotaAnimada<T>(
    WidgetBuilder builder, {
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (ctx, anim, sec) => builder(ctx),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (ctx, anim, sec, child) {
        final fade = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: anim, curve: curve));
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: curve));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  /// Navega para a HomeScreen aplicando modalidades iniciais.
  /// Usa `pushAndRemoveUntil(route.isFirst)` para evitar empilhar
  /// múltiplas instâncias da Home (boa prática UX).
  Future<void> _navegarParaHomeComModalidades(
    Set<Modalidade>? modalidades, {
    required String erroMensagem,
  }) async {
    try {
      unawaited(HapticFeedback.lightImpact());
      await Navigator.of(context).pushAndRemoveUntil(
        _rotaAnimada((_) => HomeScreen(modalidadesIniciais: modalidades)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$erroMensagem: $e'),
        ),
      );
    }
  }

  /// Navega para a tela Juízes (push normal, mantém Campos e Arenas
  /// na pilha para permitir voltar facilmente).
  Future<void> _navegarParaJuizes() async {
    try {
      unawaited(HapticFeedback.lightImpact());
      await Navigator.of(
        context,
      ).push(_rotaAnimada((_) => const JuizesScreen()));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível abrir Juízes: $e'),
        ),
      );
    }
  }

  /// Ação do botão CAMPOS: como a tela atual já é Campos e Arenas,
  /// evita duplicação na pilha e recarrega/atualiza os dados:
  /// - Scrolla para o topo
  /// - Simula um refresh da listagem
  /// - SnackBar amigável confirmando a atualização
  Future<void> _atualizarTelaCamposArenas() async {
    try {
      unawaited(HapticFeedback.mediumImpact());
      // Scroll para o topo da listagem
      try {
        if (_scrollController.hasClients) {
          await _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      } catch (_) {}
      if (!mounted) return;
      // Força rebuild do provider atualizando os listeners
      // (garante que dados em camposArenas sejam re-exibidos)
      final data = context.read<DataService>();
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      data.notifyListeners();
      if (!mounted) return;
      setState(() {
        // Trigger para exibir foco visual temporário de atualização
        _focoDestacado = '__refresh__';
      });
      _timerRemoveDestaque?.cancel();
      _timerRemoveDestaque = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _focoDestacado = null);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Lista de Campos e Arenas atualizada com sucesso!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível atualizar Campos: $e'),
        ),
      );
    }
  }

  /// Navegação do botão CAMPOS: direciona para a própria tela "Campos e
  /// Arenas" (rota ATUAL), MANTENDO o contexto atual e o estado global
  /// (providers DataService e AuthService são singletons globais, então
  /// nenhum dado é perdido e nenhum recarregamento de singleton ocorre).
  /// Usa `pushReplacement` para:
  ///  - Evitar duplicação na pilha de rotas (mantém apenas uma instância)
  ///  - Forçar a reconstrução do state da tela (com o mesmo contexto)
  ///  - Executar novamente `initState` / didChangeDependencies apenas no
  ///    widget da tela (refresh leve e controlado da listagem de campos).
  /// Tudo com tratamento de erro e SnackBar amigável.
  Future<void> _navegarParaCamposArenas() async {
    try {
      unawaited(HapticFeedback.lightImpact());
      await Navigator.of(
        context,
      ).pushReplacement(_rotaAnimada((_) => const CamposArenasScreen()));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível abrir Campos: $e'),
        ),
      );
    }
  }

  /// Conjunto de modalidades classificadas como "PELADAS" (todas as
  /// variações de futebol): campo, rua, futsal, society, areia,
  /// praia e futevôlei.
  static const Set<Modalidade> _modalidadesPeladas = {
    Modalidade.futebolCampo,
    Modalidade.futebolRua,
    Modalidade.futsal,
    Modalidade.society,
    Modalidade.areia,
    Modalidade.praia,
    Modalidade.futevolei,
  };

  /// Modalidades excluídas no filtro "VÁRIOS" (as 3 categorias
  /// específicas: futebol em geral, vôlei e basquete).
  /// A lógica: exibir tudo EXCETO as 3 categorias principais.
  static final Set<Modalidade> _modalidadesVarios = {
    ...Modalidade.values,
  }..removeAll({..._modalidadesPeladas, Modalidade.voley, Modalidade.basquete});

  Future<void> _onCadastrarCampoTap(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    final a = context.read<AuthService>();
    final theme = Theme.of(context);
    if (!a.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.colorScheme.error,
          content: const Text(
            'Faça login ou cadastre-se antes de cadastrar campos.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    try {
      final navigator = Navigator.of(context);
      final r = await navigator.push<CampoArena?>(
        MaterialPageRoute(builder: (_) => const CadastroCampoArenaScreen()),
      );
      if (!mounted) return;
      if (r != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
            content: Text('Campo "${r.nome}" cadastrado com sucesso!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível abrir cadastro: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final onSurface = theme.colorScheme.onSurfaceVariant;
    final auth = context.watch<AuthService>();
    final data = context.watch<DataService>();
    final user = auth.currentUser;
    final todosCampos = data.camposArenas
        .where(_filtroCampos.matches)
        .toList(growable: false);
    final usuarioTemLogin = user != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        leading: Semantics(
          button: true,
          label: 'Voltar para a tela inicial',
          hint: 'Toque duas vezes para retornar a home',
          child: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.selectionClick();
              try {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (r) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Não foi possível voltar: $e'),
                  ),
                );
              }
            },
          ),
        ),
        title: Semantics(
          header: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              'Campos e Arenas',
              style: TextStyle(fontWeight: FontWeight.w800, color: onPrimary),
            ),
          ),
        ),
        titleSpacing: 0,
        actions: [
          Consumer<DataService>(
            builder: (_, data, _) {
              final active = _filtroCampos.activeFiltersCount > 0;
              Future<void> onTap() async {
                unawaited(HapticFeedback.selectionClick());
                try {
                  final filtro = await Navigator.push<CampoArenaFilter>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CampoArenaFilterScreen(
                        initialFilter: _filtroCampos,
                      ),
                    ),
                  );
                  if (filtro != null && mounted) {
                    setState(() => _filtroCampos = filtro);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Não foi possível abrir filtros: $e'),
                    ),
                  );
                }
              }

              final btnTransparente = IconButton(
                onPressed: onTap,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: theme.appBarTheme.foregroundColor,
                  disabledForegroundColor: theme.appBarTheme.foregroundColor
                      ?.withValues(alpha: 0.38),
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  highlightColor: theme.appBarTheme.foregroundColor?.withValues(
                    alpha: 0.10,
                  ),
                  splashFactory: InkSparkle.splashFactory,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(38, 38),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
                icon: Icon(
                  active ? Icons.filter_list_alt : Icons.filter_list_outlined,
                  size: 20,
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Semantics(
                  button: true,
                  label: active
                      ? 'Abrir filtros. ${_filtroCampos.activeFiltersCount} filtros ativos'
                      : 'Abrir filtros',
                  hint: 'Toque duas vezes para abrir a tela de filtros',
                  child: Tooltip(
                    message: active
                        ? 'Filtros (${_filtroCampos.activeFiltersCount} ativos)'
                        : 'Filtros',
                    preferBelow: false,
                    child: active
                        ? Badge(
                            label: Text(
                              _filtroCampos.activeFiltersCount.toString(),
                            ),
                            child: btnTransparente,
                          )
                        : btnTransparente,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Semantics(
              button: true,
              toggled: _isGridMode,
              label: _isGridMode
                  ? 'Alternar para modo lista detalhada'
                  : 'Alternar para modo grade compacta',
              hint: 'Toque duas vezes para alternar a exibição',
              child: Tooltip(
                message: _isGridMode ? 'Exibir em lista' : 'Exibir em grade',
                preferBelow: false,
                child: IconButton(
                  onPressed: _alternarModoGrade,
                  icon: Icon(
                    _isGridMode
                        ? Icons.view_list_outlined
                        : Icons.grid_view_outlined,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final maxContentWidth = isWide && _isGridMode
                ? 780.0
                : double.infinity;
            final horizontalPad = _isGridMode
                ? (isWide ? 28.0 : 18.0)
                : (isWide ? 12.0 : 6.0);
            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                padding: EdgeInsets.only(
                  left: horizontalPad,
                  right: horizontalPad,
                  bottom: 24,
                ),
                child: CustomScrollView(
                  clipBehavior: Clip.none,
                  slivers: [
                    SliverToBoxAdapter(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 420),
                        reverseDuration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOut,
                          opacity: _headerVisible ? 1.0 : 0.0,
                          alwaysIncludeSemantics: false,
                          child: _headerVisible
                              ? Padding(
                                  key: const ValueKey<String>('header_on'),
                                  padding: const EdgeInsets.only(top: 16),
                                  child: _buildHeader(
                                    context,
                                    isWide: isWide,
                                    userLoggedIn: usuarioTemLogin,
                                    primary: primary,
                                    textTheme: textTheme,
                                    total: todosCampos.length,
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey<String>('header_off'),
                                ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              size: 18,
                              color: onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TODOS OS CAMPOS',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.6,
                                color: onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${todosCampos.length} ${todosCampos.length == 1 ? 'cadastrado' : 'cadastrados'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (todosCampos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_soccer_outlined,
                              size: 54,
                              color: primary.withValues(alpha: 0.65),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Nenhum campo ou arena cadastrado ainda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              usuarioTemLogin
                                  ? 'Toque em "Campo/Arena" na barra inferior para cadastrar!'
                                  : 'Faça login para cadastrar seu campo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurface.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 340),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  alignment: Alignment.topCenter,
                                  child: child,
                                ),
                              ),
                          child: _isGridMode
                              ? LayoutBuilder(
                                  key: const ValueKey<String>('grid_layout'),
                                  builder: (ctx, gridConstraints) {
                                    final mq = MediaQuery.of(ctx);
                                    final screenH = mq.size.height;
                                    final w = gridConstraints.maxWidth;
                                    final crossAxisCount = w >= 1100
                                        ? 4
                                        : (w >= 760 ? 3 : 2);
                                    const nCardsColunaViewport = 3;
                                    const espacamento = 6.0;
                                    const appBarH = kToolbarHeight;
                                    final paddingTop = mq.padding.top;
                                    final paddingBottom = mq.padding.bottom;
                                    const navBarH = kBottomNavigationBarHeight;
                                    final headerH = _headerVisible
                                        ? 92 + 16
                                        : 0;
                                    const titulosH = 42;
                                    const paddingsH = 24 + 24 + 12 + 10 + 24;
                                    final totalGapVerticalViewport =
                                        espacamento *
                                        (nCardsColunaViewport - 1);
                                    final alturaLiquidaViewport =
                                        screenH -
                                        appBarH -
                                        paddingTop -
                                        paddingBottom -
                                        navBarH -
                                        headerH -
                                        titulosH -
                                        paddingsH -
                                        totalGapVerticalViewport;
                                    final larguraCard =
                                        (w -
                                            espacamento *
                                                (crossAxisCount - 1)) /
                                        crossAxisCount;
                                    final alturaCardOriginal = larguraCard;
                                    final alturaCardAlvo40Pct =
                                        alturaCardOriginal * 1.40;
                                    final alturaCardPorViewport =
                                        alturaLiquidaViewport > 0
                                        ? alturaLiquidaViewport /
                                              nCardsColunaViewport
                                        : 140.0;
                                    final minAlvoBase =
                                        (alturaCardAlvo40Pct * 0.85).clamp(
                                          90.0,
                                          double.infinity,
                                        );
                                    final maxAlvoBase = alturaCardAlvo40Pct
                                        .clamp(110.0, 360.0);
                                    final minClamp = minAlvoBase <= maxAlvoBase
                                        ? minAlvoBase
                                        : maxAlvoBase;
                                    final maxClamp = maxAlvoBase;
                                    final alturaCard = alturaCardPorViewport > 0
                                        ? alturaCardPorViewport
                                              .clamp(minClamp, maxClamp)
                                              .toDouble()
                                        : alturaCardAlvo40Pct
                                              .clamp(110.0, 360.0)
                                              .toDouble();
                                    final aspect = (larguraCard / alturaCard)
                                        .clamp(0.55, 1.05);
                                    return GridView.builder(
                                      key: const PageStorageKey<String>(
                                        'campos_arenas_grid',
                                      ),
                                      clipBehavior: Clip.none,
                                      controller: _scrollController,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: espacamento,
                                            crossAxisSpacing: espacamento,
                                            childAspectRatio: aspect,
                                          ),
                                      itemCount: todosCampos.length,
                                      itemBuilder: (ctx, i) {
                                        final campo = todosCampos[i];
                                        final isOwner =
                                            usuarioTemLogin &&
                                            campo.proprietarioId != null &&
                                            campo.proprietarioId == user.id;
                                        final isHighlighted =
                                            _focoDestacado != null &&
                                            _focoDestacado == campo.id;
                                        return KeyedSubtree(
                                          key: GlobalObjectKey(
                                            'campo_card_${campo.id}',
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 360,
                                            ),
                                            curve: Curves.easeOut,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: isHighlighted
                                                  ? [
                                                      BoxShadow(
                                                        color: primary
                                                            .withValues(
                                                              alpha: 0.55,
                                                            ),
                                                        blurRadius: 14,
                                                        spreadRadius: 2.2,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                              border: Border.all(
                                                color: isHighlighted
                                                    ? primary
                                                    : Colors.transparent,
                                                width: isHighlighted ? 3 : 0,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    isHighlighted ? 13 : 16,
                                                  ),
                                              child: _CampoGridCard(
                                                campo: campo,
                                                isOwner: isOwner,
                                                highlighted: isHighlighted,
                                                onDelete: () =>
                                                    _confirmarExclusao(
                                                      context: context,
                                                      data: data,
                                                      auth: auth,
                                                      campo: campo,
                                                    ),
                                                onEdit: () => _editarCampo(
                                                  context: context,
                                                  campo: campo,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                )
                              : Column(
                                  key: const ValueKey<String>('list_layout'),
                                  children: [
                                    for (
                                      int i = 0;
                                      i < todosCampos.length;
                                      i++
                                    ) ...[
                                      Builder(
                                        builder: (ctx) {
                                          final campo = todosCampos[i];
                                          final isOwner =
                                              usuarioTemLogin &&
                                              campo.proprietarioId != null &&
                                              campo.proprietarioId == user.id;
                                          final isHighlighted =
                                              _focoDestacado != null &&
                                              _focoDestacado == campo.id;
                                          return KeyedSubtree(
                                            key: GlobalObjectKey(
                                              'campo_card_${campo.id}',
                                            ),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 360,
                                              ),
                                              curve: Curves.easeOut,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                boxShadow: isHighlighted
                                                    ? [
                                                        BoxShadow(
                                                          color: primary
                                                              .withValues(
                                                                alpha: 0.45,
                                                              ),
                                                          blurRadius: 16,
                                                          spreadRadius: 2,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                                border: Border.all(
                                                  color: isHighlighted
                                                      ? primary
                                                      : Colors.transparent,
                                                  width: isHighlighted ? 3 : 0,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isHighlighted ? 15 : 18,
                                                    ),
                                                child: _CampoCard(
                                                  campo: campo,
                                                  isOwner: isOwner,
                                                  highlighted: isHighlighted,
                                                  onDelete: () =>
                                                      _confirmarExclusao(
                                                        context: context,
                                                        data: data,
                                                        auth: auth,
                                                        campo: campo,
                                                      ),
                                                  onEdit: () => _editarCampo(
                                                    context: context,
                                                    campo: campo,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      if (i != todosCampos.length - 1)
                                        const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          Widget? centerMenu;
          if (usuarioTemLogin) {
            const buttonDiameter = CustomBottomNavBar.fabDiameter;
            const labelColumnWidth = 92.0;
            const labelGutter = 10.0;
            centerMenu = ProfileSportsRailMenu(
              buttonDiameter: buttonDiameter,
              verticalSpacing: 6,
              labelColumnWidth: labelColumnWidth,
              labelGutter: labelGutter,
              labelOffsetAdjust: const EdgeInsets.only(right: 6),
              notchDockedOffset: 0,
              activeButtonId: 'arena',
              navBarHeight: CustomBottomNavBar.barHeight,
            );
          }
          return CustomBottomNavBar(
            selectedIndex: _navIndex,
            customCenterMenu: centerMenu ?? const SizedBox.shrink(),
            useCadastrarCampoNoIndiceZero: true,
            indiceZeroIcon: Icons.stadium_outlined,
            indiceZeroSelectedIcon: Icons.stadium,
            indiceZeroLabel: 'Campos',
            indiceZeroUsaIconeSimples: false,
            sobrescreverIndiceUm: true,
            indiceUmIcon: Icons.star_border,
            indiceUmSelectedIcon: Icons.star,
            indiceUmLabel: 'Favoritos',
            indiceUmUsaIconeSimples: true,
            indiceUmUsaBadgeFavoritos: true,
            sobrescreverIndiceDois: true,
            indiceDoisIcon: Icons.sports_soccer_outlined,
            indiceDoisSelectedIcon: Icons.sports_soccer,
            indiceDoisLabel: 'Peladas',
            indiceDoisUsaIconeSimples: true,
            onTabSelected: (idx) async {
              switch (idx) {
                case 0:
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    await _onCadastrarCampoTap(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Não foi possível abrir cadastro de campo: $e',
                        ),
                      ),
                    );
                  }
                  return;
                case 1:
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CamposArenasFavoritosScreen(),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Não foi possível abrir favoritos: $e'),
                      ),
                    );
                  }
                  return;
                case 2:
                  // ============================================================
                  // BOTÃO "PELADAS" (barra inferior, índice 2 = ícone bola de
                  // futebol) — Item 2 da solicitação: redireciona DIRETAMENTE
                  // para a HOME (pushAndRemoveUntil), independente da tela.
                  // ============================================================
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (r) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Não foi possível navegar: $e'),
                      ),
                    );
                  }
                  return;
                case 3:
                  await navigateToProfile(context);
                  return;
              }
            },
            tipoFavoritoBadge: TipoFavoritoBadge.campos,
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool isWide,
    required bool userLoggedIn,
    required Color primary,
    required TextTheme textTheme,
    required int total,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.18),
            primary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.30), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.stadium_outlined, color: primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encontre o campo perfeito para sua pelada!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isWide ? 18 : 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userLoggedIn
                          ? '$total campos e arenas disponíveis. Cadastre o seu também!'
                          : '$total campos e arenas disponíveis na plataforma.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNovoCampoSquare(
    BuildContext context, {
    required Color primary,
    required TextTheme textTheme,
    required bool userLoggedIn,
  }) {
    final theme = Theme.of(context);
    final disabled = !userLoggedIn;
    final onPrimary = theme.colorScheme.onPrimary;
    return Center(
      child: Semantics(
        button: true,
        label: 'Cadastrar novo campo ou arena',
        hint: disabled
            ? 'Você precisa estar logado para cadastrar'
            : 'Toque duas vezes para abrir o formulário',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: disabled
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: theme.colorScheme.error,
                        content: const Text(
                          'Faça login ou cadastre-se antes de cadastrar campos.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                : () async {
                    unawaited(HapticFeedback.selectionClick());
                    final navigator = Navigator.of(context);
                    final r = await navigator.push<CampoArena?>(
                      MaterialPageRoute(
                        builder: (_) => const CadastroCampoArenaScreen(),
                      ),
                    );
                    if (!mounted) return;
                    if (r != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green[700],
                          content: Text(
                            'Campo "${r.nome}" cadastrado com sucesso!',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: disabled
                      ? [
                          theme.colorScheme.surface.withValues(alpha: 0.96),
                          theme.colorScheme.surface.withValues(alpha: 0.92),
                        ]
                      : [
                          primary,
                          HSLColor.fromColor(primary)
                              .withLightness(
                                (HSLColor.fromColor(
                                  primary,
                                ).lightness).clamp(0.42, 0.62),
                              )
                              .toColor(),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (disabled ? primary : primary).withValues(
                      alpha: 0.22,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: disabled
                      ? primary.withValues(alpha: 0.36)
                      : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.stadium_rounded,
                      color: disabled
                          ? primary.withValues(alpha: 0.80)
                          : onPrimary,
                      size: 76,
                    ),
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: disabled
                              ? primary.withValues(alpha: 0.88)
                              : onPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 26,
                          color: disabled ? Colors.white : primary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Text(
                        'CADASTRAR\nCAMPO / ARENA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          height: 1.25,
                          color: disabled
                              ? primary.withValues(alpha: 0.92)
                              : onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editarCampo({
    required BuildContext context,
    required CampoArena campo,
  }) async {
    unawaited(HapticFeedback.selectionClick());
    final navigator = Navigator.of(context);
    final r = await navigator.push<CampoArena?>(
      MaterialPageRoute(
        builder: (_) => CadastroCampoArenaScreen(campoArena: campo),
      ),
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (r != null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          content: Text('Campo "${r.nome}" atualizado com sucesso!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmarExclusao({
    required BuildContext context,
    required DataService data,
    required AuthService auth,
    required CampoArena campo,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = auth.currentUser;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        var loading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Excluir campo?'),
              content: Text(
                'Tem certeza que deseja excluir "${campo.nome}"?\n\nEssa ação não pode ser desfeita.',
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.tonalIcon(
                  onPressed: loading
                      ? null
                      : () async {
                          setDialogState(() => loading = true);
                          final usuarioId = user?.id ?? '';
                          final ok = await data.excluirCampoArena(
                            campoArenaId: campo.id,
                            usuarioId: usuarioId,
                          );
                          if (context.mounted) {
                            Navigator.pop(context, ok);
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.14),
                    foregroundColor: AppColors.danger,
                  ),
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Excluir'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          content: const Text('Campo removido com sucesso.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (ok == false && data.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(data.errorMessage!),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _CampoCard extends StatelessWidget {
  final CampoArena campo;
  final bool isOwner;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool highlighted;

  const _CampoCard({
    required this.campo,
    required this.isOwner,
    required this.onDelete,
    required this.onEdit,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final hintColor = theme.hintColor;
    final isDark = theme.brightness == Brightness.dark;
    final contato = (campo.contato ?? '').trim();
    final bairro = campo.bairro.trim();
    final cidadeEstado = campo.estado.isNotEmpty
        ? '${campo.cidade} - ${campo.estado}'
        : campo.cidade;
    final chuteiraLabel = campo.calcadosPermitidos.isNotEmpty
        ? (campo.calcadosPermitidos.length == 1
              ? campo.calcadosPermitidos.first.label
              : 'Vários calçados')
        : 'Calçado não informado';
    String formatarMedida(double? valor) {
      if (valor == null) return '—';
      if ((valor - valor.truncateToDouble()).abs() < 0.005) {
        return valor.toStringAsFixed(0);
      }
      return valor
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.48)
                : Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.09),
            blurRadius: 8,
            spreadRadius: -3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: 'Card do campo ${campo.nome}',
        hint: 'Toque duas vezes para abrir os detalhes do campo',
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CampoDetailScreen(campo: campo),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 156,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Builder(
                        builder: (_) {
                          final capa = campo.fotoCapa;
                          if (capa != null && capa.hasValidBytes) {
                            return Image.memory(
                              capa.bytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Container(color: primary),
                            );
                          }
                          return Container(color: primary);
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.46),
                              Colors.black.withValues(alpha: 0.06),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    campo.nome,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black38,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Consumer<DataService>(
                                      builder: (_, data, _) {
                                        final fav = data.isCampoFavorito(
                                          campo.id,
                                        );
                                        return Semantics(
                                          button: true,
                                          toggled: fav,
                                          label: fav
                                              ? 'Remover campo dos favoritos'
                                              : 'Adicionar campo aos favoritos',
                                          hint:
                                              'Toque duas vezes para ${fav ? 'remover dos' : 'adicionar aos'} favoritos',
                                          child: Tooltip(
                                            message: fav
                                                ? 'Remover dos favoritos'
                                                : 'Favoritar campo',
                                            preferBelow: false,
                                            child: Material(
                                              color: Colors.black.withValues(
                                                alpha: 0.42,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                onTap: () async {
                                                  unawaited(
                                                    HapticFeedback.selectionClick(),
                                                  );
                                                  try {
                                                    await data
                                                        .toggleCampoFavorito(
                                                          campo.id,
                                                        );
                                                  } catch (e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        content: Text(
                                                          'Não foi possível atualizar favorito: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    5,
                                                  ),
                                                  child: Icon(
                                                    fav
                                                        ? Icons.star_rounded
                                                        : Icons
                                                              .star_border_rounded,
                                                    size: 16,
                                                    color: fav
                                                        ? AppColors
                                                              .secondaryColor
                                                        : Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    Semantics(
                                      button: true,
                                      label: 'Compartilhar campo ${campo.nome}',
                                      child: Tooltip(
                                        message: 'Compartilhar campo',
                                        preferBelow: false,
                                        child: Material(
                                          color: Colors.black.withValues(
                                            alpha: 0.42,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () => unawaited(
                                              HapticFeedback.selectionClick(),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Icon(
                                                Icons.share_outlined,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _topChip(
                                  icon: Icons.groups_2_outlined,
                                  text:
                                      '${campo.quantidadePorLinha}x${campo.quantidadePorLinha}',
                                ),
                                const SizedBox(width: 8),
                                _topChip(
                                  icon: Icons.grass_outlined,
                                  text: campo.tipoGrama.label,
                                ),
                                const Spacer(),
                                const SizedBox(width: 38),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (campo.fotos.isNotEmpty)
                        Positioned(
                          right: 8,
                          bottom: 10,
                          child: Tooltip(
                            message: campo.fotos.length == 1
                                ? 'Ver imagem do campo'
                                : 'Ver ${campo.fotos.length} imagens do campo',
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.42),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                campo.fotos.length == 1
                                    ? Icons.photo_library_rounded
                                    : Icons.photo_album_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: hintColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cidadeEstado,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (bairro.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    bairro,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: hintColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (campo.rua.trim().isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    '${campo.rua.trim()}${campo.numero.trim().isNotEmpty ? ', ${campo.numero.trim()}' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'Capac. Público ${campo.capacidadePublico ?? '—'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                    letterSpacing: 0.3,
                                    color: primary,
                                  ),
                                ),
                              ),
                              if (campo.larguraMetros != null &&
                                  campo.profundidadeMetros != null) ...[
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${formatarMedida(campo.larguraMetros)} x ${formatarMedida(campo.profundidadeMetros)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                      letterSpacing: 0.3,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                              if (campo.areaM2 != null) ...[
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.square_foot_rounded,
                                        color: AppColors.info,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${formatarMedida(campo.areaM2)} m²',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: hintColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              campo.responsavelNome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (contato.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                contato,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _chipCampoCard(
                                  theme,
                                  chuteiraLabel,
                                  Icons.sports_soccer,
                                  primary,
                                ),
                                if (campo.dependencias.isNotEmpty)
                                  _chipCampoCard(
                                    theme,
                                    campo.dependenciasLabel,
                                    Icons.other_houses_outlined,
                                    AppColors.secondary,
                                    maxWidth: 220,
                                  ),
                                if (campo.itensOpcionais.isNotEmpty)
                                  _chipCampoCard(
                                    theme,
                                    campo.itensOpcionaisLabel,
                                    Icons.checklist_rtl_rounded,
                                    AppColors.info,
                                    maxWidth: 220,
                                  ),
                              ],
                            ),
                          ),
                          if (isOwner) ...[
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  button: true,
                                  label: 'Editar campo ${campo.nome}',
                                  child: Tooltip(
                                    message: 'Editar campo',
                                    preferBelow: false,
                                    child: Material(
                                      color: AppColors.info.withValues(
                                        alpha: 0.90,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: onEdit,
                                        child: const Padding(
                                          padding: EdgeInsets.all(7),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Semantics(
                                  button: true,
                                  label: 'Excluir campo ${campo.nome}',
                                  child: Tooltip(
                                    message: 'Excluir campo',
                                    preferBelow: false,
                                    child: Material(
                                      color: AppColors.danger.withValues(
                                        alpha: 0.90,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: onDelete,
                                        child: const Padding(
                                          padding: EdgeInsets.all(7),
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipCampoCard(
    ThemeData theme,
    String label,
    IconData icon,
    Color color, {
    double maxWidth = 180,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

double _isWideAspect(int crossAxisCount, double w) {
  if (crossAxisCount <= 1) {
    return w >= 640 ? 3.2 : 2.9;
  }
  if (crossAxisCount == 2) {
    if (w >= 900) return 0.54;
    if (w >= 720) return 0.52;
    if (w >= 560) return 0.47;
    return 0.45;
  }
  return 0.43;
}

class _CampoGridCard extends StatelessWidget {
  final CampoArena campo;
  final bool isOwner;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool highlighted;

  const _CampoGridCard({
    required this.campo,
    required this.isOwner,
    required this.onDelete,
    required this.onEdit,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final contato = (campo.contato ?? '').trim();
    final bairro = campo.bairro.trim();
    final cidadeUf = [
      campo.cidade.trim(),
      campo.estado.trim().toUpperCase(),
    ].where((parte) => parte.isNotEmpty).join(' - ');
    final temEstacionamento = campo.dependencias.contains(
      DependenciaCampo.estacionamento,
    );
    final temBola = campo.itensOpcionais.contains(ItemOpcionalCampo.bola);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.16),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Semantics(
            button: true,
            label: 'Card do campo ${campo.nome}',
            hint: 'Toque duas vezes para abrir os detalhes do campo',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CampoDetailScreen(campo: campo),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Builder(
                        builder: (_) {
                          final capa = campo.fotoCapa;
                          if (capa != null && capa.hasValidBytes) {
                            return Image.memory(
                              capa.bytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _campoPlaceholder(primary: primary),
                            );
                          }
                          return _campoPlaceholder(primary: primary);
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.80),
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.84),
                            ],
                            stops: const [0.0, 0.30, 0.66, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 46,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 125;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                campo.nome,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: compact ? 11 : 13,
                                  height: 1.12,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                children: [
                                  _topInfo(
                                    icon: Icons.groups_2_outlined,
                                    text:
                                        '${campo.quantidadePorLinha} X ${campo.quantidadePorLinha}',
                                    compact: compact,
                                  ),
                                  _topInfo(
                                    icon: Icons.grass_outlined,
                                    text: campo.tipoGrama.label,
                                    compact: compact,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer<DataService>(
                            builder: (_, data, _) {
                              final fav = data.isCampoFavorito(campo.id);
                              return Tooltip(
                                message: fav
                                    ? 'Remover dos favoritos'
                                    : 'Favoritar campo',
                                preferBelow: false,
                                child: _actionTile(
                                  icon: fav
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: fav
                                      ? AppColors.secondaryColor ?? Colors.amber
                                      : Colors.white,
                                  label: fav
                                      ? 'Remover campo dos favoritos'
                                      : 'Adicionar campo aos favoritos',
                                  onTap: () async {
                                    unawaited(HapticFeedback.selectionClick());
                                    try {
                                      await data.toggleCampoFavorito(campo.id);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'Não foi possível atualizar favorito: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          if (temEstacionamento) ...[
                            const SizedBox(height: 5),
                            Tooltip(
                              message: 'Estacionamento disponível',
                              preferBelow: false,
                              child: _actionTile(
                                icon: Icons.directions_car_outlined,
                                color: Colors.white,
                                label: 'Estacionamento disponível',
                              ),
                            ),
                          ],
                          if (temBola) ...[
                            const SizedBox(height: 5),
                            Tooltip(
                              message: 'Bola disponível',
                              preferBelow: false,
                              child: _actionTile(
                                icon: Icons.sports_soccer_outlined,
                                color: Colors.white,
                                label: 'Bola disponível',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: isOwner ? 46 : 8,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final fonte = constraints.maxWidth < 100 ? 8.5 : 10.5;
                          final estilo = TextStyle(
                            color: Colors.white,
                            fontSize: fonte,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _footerLine(
                                icon: Icons.phone_in_talk_outlined,
                                text: contato.isEmpty
                                    ? 'Telefone não informado'
                                    : contato,
                                style: estilo,
                              ),
                              _footerLine(
                                text: bairro.isEmpty
                                    ? 'Bairro não informado'
                                    : bairro,
                                style: estilo.copyWith(
                                  color: Colors.white.withValues(alpha: 0.90),
                                ),
                              ),
                              _footerLine(
                                text: cidadeUf.isEmpty ? '—' : cidadeUf,
                                style: estilo.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (isOwner)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionTile(
                              icon: Icons.edit_outlined,
                              color: Colors.white,
                              label: 'Editar campo ${campo.nome}',
                              background: AppColors.info.withValues(
                                alpha: 0.92,
                              ),
                              onTap: onEdit,
                            ),
                            const SizedBox(height: 5),
                            _actionTile(
                              icon: Icons.delete_outline_rounded,
                              color: Colors.white,
                              label: 'Excluir campo ${campo.nome}',
                              background: AppColors.danger.withValues(
                                alpha: 0.90,
                              ),
                              onTap: onDelete,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String label,
    VoidCallback? onTap,
    Color? background,
  }) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: background ?? Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }

  Widget _topInfo({
    required IconData icon,
    required String text,
    required bool compact,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 10 : 12, color: Colors.white),
        const SizedBox(width: 3),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.90),
            fontSize: compact ? 8.5 : 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _footerLine({
    IconData? icon,
    required String text,
    required TextStyle style,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoPlaceholder({required Color primary}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.90),
            primary.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.stadium_rounded,
          color: Colors.white.withValues(alpha: 0.85),
          size: 54,
        ),
      ),
    );
  }
}
