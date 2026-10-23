import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/enums.dart';
import '../models/pelada.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/pelada_card.dart';
import '../widgets/profile_sports_rail_menu.dart';
import 'cadastro_pelada_screen.dart';
import 'pelada_detail_screen.dart';
import 'filters_screen.dart';
import 'pelada_list_view_screen.dart';
import 'campos_arenas_screen.dart';
import '../utils/profile_navigation_helper.dart';

class HomeScreen extends StatefulWidget {
  final Set<Modalidade>? modalidadesIniciais;
  final int initialTab;

  const HomeScreen({super.key, this.modalidadesIniciais, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  bool _pesquisaGrid = true;
  final _searchCtrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _filtroInicialAplicado = false;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
    _searchCtrl.addListener(() {
      Provider.of<DataService>(
        context,
        listen: false,
      ).setSearch(_searchCtrl.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filtroInicialAplicado && mounted) {
      final modalidades = widget.modalidadesIniciais;
      if (modalidades != null && modalidades.isNotEmpty) {
        final data = context.read<DataService>();
        final atual = data.currentFilter;
        if (atual.modalidades.isEmpty ||
            atual.modalidades.length != modalidades.length ||
            !atual.modalidades.containsAll(modalidades)) {
          data.setFilter(
            atual.copyWith(modalidades: modalidades, clearModalidades: false),
          );
        }
      }
      _filtroInicialAplicado = true;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  // HELPERS DE NAVEGAÇÃO TRAIL MENU (Requisitos 1-6)
  // =========================================================================
  static const Set<Modalidade> _modalidadesVolei = {Modalidade.voley};
  static const Set<Modalidade> _modalidadesBasquete = {Modalidade.basquete};
  static const Set<Modalidade> _modalidadesVarios = {
    Modalidade.futevolei,
    Modalidade.outros,
  };

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

  void _trailIrHome({Set<Modalidade>? modalidades}) {
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    try {
      Navigator.of(context).pushAndRemoveUntil(
        _rotaAnimada((ctx) => HomeScreen(modalidadesIniciais: modalidades)),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível navegar para Home: $e'),
        ),
      );
    }
  }

  void _trailNavegarPara(
    Widget tela,
    String nomeDestino, {
    bool removerAtePrimeira = false,
  }) {
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    try {
      if (removerAtePrimeira) {
        Navigator.of(
          context,
        ).pushAndRemoveUntil(_rotaAnimada((ctx) => tela), (r) => r.isFirst);
      } else {
        Navigator.of(context).push(_rotaAnimada((ctx) => tela));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível abrir $nomeDestino: $e'),
        ),
      );
    }
  }

  void _trailLimparFiltrosIrPesquisa() => _trailIrHome(modalidades: null);

  void _trailAplicarFiltroModalidade(Set<Modalidade> modalidades) =>
      _trailIrHome(modalidades: modalidades);

  void _trailAbrirTela(Widget tela, String nomeTela) =>
      _trailNavegarPara(tela, nomeTela);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<DataService>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    List<Widget> telas = [
      _buildPesquisa(context, data, theme),
      _buildFavoritos(context, data, theme),
      _buildPesquisa(context, data, theme),
      // Índice 3 (PERFIL) — reservado para futuras configurações.
      // Mantenho o widget vazio para manter selectedIndex válido,
      // porém onTabSelected desativa completamente a navegação.
      const SizedBox.shrink(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        leading: Builder(
          builder: (ctx) {
            // ==================================================================
            // Item 1: Tela "Peladas Favoritos" → substituir botão MENU por VOLTAR
            // Quando _tabIndex == 1 (aba Favoritos), o leading não abre mais
            // o Drawer; em vez disso, navega de volta para a HOME (aba 0 =
            // pesquisa de peladas, que é a tela principal). Semântica e UX
            // seguem o padrão PSA (Tooltip, Semantics, HapticFeedback,
            // IconButton 48x48 = tamanho de toque adequado).
            // ==================================================================
            if (_tabIndex == 1) {
              return Semantics(
                button: true,
                label: 'Voltar para a tela inicial de peladas',
                hint: 'Toque duas vezes para retornar a home',
                child: IconButton(
                  tooltip: 'Voltar',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() => _tabIndex = 0);
                  },
                ),
              );
            }
            return Semantics(
              button: true,
              label: 'Abrir menu do aplicativo',
              hint: 'Toque duas vezes para abrir o menu lateral',
              child: IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_outlined),
                tooltip: 'Menu',
              ),
            );
          },
        ),
        actions: [
          Semantics(
            button: true,
            label: data.currentFilter.activeFiltersCount > 0
                ? 'Abrir filtros. ${data.currentFilter.activeFiltersCount} filtros ativos'
                : 'Abrir filtros',
            hint: 'Toque duas vezes para abrir a tela de filtros',
            child: Tooltip(
              message: data.currentFilter.activeFiltersCount > 0
                  ? 'Filtros (${data.currentFilter.activeFiltersCount} ativos)'
                  : 'Filtros',
              preferBelow: false,
              child: data.currentFilter.activeFiltersCount > 0
                  ? Badge(
                      label: Text(
                        data.currentFilter.activeFiltersCount.toString(),
                      ),
                      child: IconButton(
                        onPressed: () {
                          unawaited(HapticFeedback.selectionClick());
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FiltersScreen(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Não foi possível abrir filtros: $e',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.filter_list_alt,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: () {
                        unawaited(HapticFeedback.selectionClick());
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FiltersScreen(),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Não foi possível abrir filtros: $e',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.filter_list_outlined,
                        color: Colors.white70,
                      ),
                    ),
            ),
          ),
          if (_tabIndex == 0)
            IconButton(
              onPressed: () => setState(() => _pesquisaGrid = !_pesquisaGrid),
              icon: Icon(
                _pesquisaGrid
                    ? Icons.view_list_outlined
                    : Icons.grid_view_outlined,
              ),
              tooltip: _pesquisaGrid ? 'Exibir em lista' : 'Exibir em grade',
            ),
          const SizedBox(width: 4),
        ],
        bottom: _tabIndex == 0 || _tabIndex == 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(43.2),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 2.4),
                  child: Transform.translate(
                    offset: const Offset(0, -5.6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 40.8,
                        child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlphaSafe(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 0,
                            ),
                            border: InputBorder.none,
                            prefixIconConstraints: const BoxConstraints(
                              minHeight: 40.8,
                              minWidth: 40.8,
                            ),
                            hintText: 'Buscar por nome, cidade, local...',
                            hintStyle: TextStyle(
                              color: Colors.white.withAlphaSafe(alpha: 0.75),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () => _searchCtrl.clear(),
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(40.8, 40.8),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: IndexedStack(index: _tabIndex, children: telas),
      floatingActionButton: null,
      floatingActionButtonLocation: null,
      bottomNavigationBar: Builder(
        builder: (context) {
          Widget? centerMenu;
          if (auth.isAuthenticated) {
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
              activeButtonId: 'peladas',
              navBarHeight: CustomBottomNavBar.barHeight,
            );
          }
          return CustomBottomNavBar(
            selectedIndex: _tabIndex,
            customCenterMenu: centerMenu ?? const SizedBox.shrink(),
            onTabSelected: (i) async {
              if (i == 0) {
                final a = context.read<AuthService>();
                if (a.isAuthenticated) {
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CadastroPeladaScreen(),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Não foi possível abrir cadastro: $e'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Faça login para cadastrar uma pelada.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              if (i == 1) {
                if (_tabIndex == 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Você já está na tela de Favoritos.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                unawaited(HapticFeedback.selectionClick());
                setState(() => _tabIndex = 1);
                return;
              }
              if (i == 2) {
                try {
                  unawaited(HapticFeedback.selectionClick());
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CamposArenasScreen(),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Não foi possível abrir Campos: $e'),
                    ),
                  );
                }
                return;
              }
              if (i == 3) {
                await navigateToProfile(context);
                return;
              }
            },
            showFavoritesBadge: data.temPeladasFavoritas,
            favoritesBadgeCount: data.quantidadePeladasFavoritas,
            tipoFavoritoBadge: TipoFavoritoBadge.peladas,
          );
        },
      ),
    );
  }

  Widget _buildPesquisa(
    BuildContext context,
    DataService data,
    ThemeData theme,
  ) {
    final lista = data.filteredPeladas;
    if (data.isLoading && lista.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_soccer, size: 72, color: theme.hintColor),
              const SizedBox(height: 18),
              Text(
                'Nenhuma pelada encontrada',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Tente ajustar os filtros ou busque por outra cidade.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor),
              ),
            ],
          ),
        ),
      );
    }
    if (_pesquisaGrid) {
      final width = MediaQuery.of(context).size.width;
      final tema = Theme.of(context);
      final brightnessClara = tema.brightness == Brightness.light;
      final crossAxisCount = width >= 1100 ? 5 : (width >= 800 ? 4 : 3);
      final EdgeInsets gridPadding = width >= 800
          ? const EdgeInsets.fromLTRB(3, 3, 3, 100)
          : const EdgeInsets.fromLTRB(4, 4, 4, 100);
      final double crossSpacing = width >= 800 ? 3 : 2;
      final double mainSpacing = width >= 800 ? 3 : 2;
      final double cardRadius = width >= 800 ? 10 : 8;
      final double childAspectRatio = width >= 1100
          ? 0.93
          : (width >= 800 ? 0.91 : 0.89);

      return GridView.builder(
        padding: gridPadding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossSpacing,
          mainAxisSpacing: mainSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: lista.length,
        itemBuilder: (context, i) {
          final p = lista[i];
          final bairro = p.bairro.trim();
          final localArena = p.localArena.trim();
          final cidadeEstado =
              '${p.cidade}${p.estado.isNotEmpty ? ' - ${p.estado}' : ''}';
          final isMobile = crossAxisCount == 3;
          final isDesktop = crossAxisCount == 5;
          final double baseCidadeFont = isDesktop
              ? 12.5
              : (isMobile ? 11 : 11.8);
          final double baseBairroFont = isDesktop ? 11 : (isMobile ? 10 : 10.5);
          final double baseLocalFont = isDesktop ? 10.5 : (isMobile ? 9.5 : 10);
          final double baseChipFont = isDesktop ? 10 : (isMobile ? 9 : 9.5);
          final double baseHoraFont = isDesktop ? 9.5 : (isMobile ? 8.5 : 9);
          final double chipPaddingH = isDesktop ? 6 : (isMobile ? 5 : 5.5);
          final double chipPaddingV = isDesktop ? 2.5 : (isMobile ? 2 : 2.25);
          final scaler = MediaQuery.textScalerOf(context);
          final double cidadeFontSize = scaler
              .scale(baseCidadeFont)
              .clamp(8.0, 13.5);
          final double bairroFontSize = scaler
              .scale(baseBairroFont)
              .clamp(7.5, 11.5);
          final double localFontSize = scaler
              .scale(baseLocalFont)
              .clamp(7.0, 11.0);
          final double chipFontSize = scaler
              .scale(baseChipFont)
              .clamp(7.5, 10.5);
          final double horaFontSize = scaler
              .scale(baseHoraFont)
              .clamp(7.0, 10.0);
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PeladaListViewScreen(initialPeladaId: p.id),
              ),
            ),
            borderRadius: BorderRadius.circular(cardRadius),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cardRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _GradeFundoImagem(pelada: p),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withAlphaSafe(alpha: 0.06),
                              Colors.black.withAlphaSafe(alpha: 0.36),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                p.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: cidadeFontSize,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Semantics(
                              label: 'Pelada ${p.categoriaGenero.label}',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: brightnessClara
                                      ? Colors.white.withAlphaSafe(alpha: 0.87)
                                      : Colors.black.withAlphaSafe(alpha: 0.38),
                                  shape: BoxShape.circle,
                                  boxShadow: brightnessClara
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  p.categoriaGenero == CategoriaGenero.masc
                                      ? Icons.male
                                      : Icons.female,
                                  color:
                                      p.categoriaGenero == CategoriaGenero.masc
                                      ? (brightnessClara
                                            ? const Color(0xFF1565C0)
                                            : Colors.blue.shade700)
                                      : (brightnessClara
                                            ? const Color(0xFFC2185B)
                                            : Colors.pink.shade400),
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ClipRect(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: chipPaddingH,
                                        vertical: chipPaddingV,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlphaSafe(
                                          alpha: 0.36,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'd/MM',
                                          'pt_BR',
                                        ).format(p.dataInicio),
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: chipFontSize,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ClipRect(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: chipPaddingH,
                                        vertical: chipPaddingV,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withAlphaSafe(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${p.horaInicio.hour.toString().padLeft(2, '0')}:${p.horaInicio.minute.toString().padLeft(2, '0')}',
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: horaFontSize,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Consumer<DataService>(
                      builder: (_, ds, _) {
                        final fav = ds.isFavorito(p.id);
                        return GestureDetector(
                          onTap: () => ds.toggleFavorito(p.id),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlphaSafe(alpha: 0.38),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              fav ? Icons.star : Icons.star_border,
                              color: fav ? Colors.white : Colors.white70,
                              size: 15,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 30,
                    bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              p.temQuorum
                                  ? Icons.check_circle
                                  : Icons.hourglass_bottom,
                              size: 13,
                              color: p.temQuorum
                                  ? AppColors.success
                                  : Colors.white.withAlphaSafe(alpha: 0.88),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cidadeEstado,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlphaSafe(alpha: 0.94),
                            fontWeight: FontWeight.w800,
                            fontSize: cidadeFontSize,
                            height: 1.1,
                          ),
                        ),
                        if (bairro.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            bairro,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withAlphaSafe(alpha: 0.82),
                              fontWeight: FontWeight.w600,
                              fontSize: bairroFontSize,
                              height: 1.1,
                            ),
                          ),
                        ],
                        if (localArena.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            localArena,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.secondary.withAlphaSafe(
                                alpha: 0.95,
                              ),
                              fontWeight: FontWeight.w700,
                              fontSize: localFontSize,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return RefreshIndicator(
      onRefresh: () => data.carregarPeladas(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 100),
        itemCount: lista.length,
        itemBuilder: (ctx, i) {
          final p = lista[i];
          return PeladaCard(
            pelada: p,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PeladaDetailScreen(peladaId: p.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoritos(
    BuildContext context,
    DataService data,
    ThemeData theme,
  ) {
    final lista = data.favoritas;
    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border, size: 72, color: theme.hintColor),
              const SizedBox(height: 18),
              Text(
                'Nenhuma pelada favoritada',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Toque na estrela em um card para salvar aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 100),
      itemCount: lista.length,
      itemBuilder: (ctx, i) {
        final p = lista[i];
        return PeladaCard(
          pelada: p,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PeladaDetailScreen(peladaId: p.id),
            ),
          ),
        );
      },
    );
  }
}

class _GradeFundoImagem extends StatelessWidget {
  final Pelada pelada;

  const _GradeFundoImagem({required this.pelada});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fallbackPadrao = Container(
      width: double.infinity,
      height: double.infinity,
      color: primary,
      child: Center(
        child: Icon(
          Icons.sports_soccer,
          color: Colors.white.withAlphaSafe(alpha: 0.72),
          size: 36,
        ),
      ),
    );

    PeladaCapaFoto? escolhida;
    if (pelada.fotoGalera?.hasValidBytes == true) {
      escolhida = pelada.fotoGalera;
    } else if (pelada.fotoArena?.hasValidBytes == true) {
      escolhida = pelada.fotoArena;
    } else if (pelada.fotosCapa.isNotEmpty &&
        pelada.fotosCapa.first.hasValidBytes) {
      escolhida = pelada.fotosCapa.first;
    } else if (pelada.fotoBraseao?.hasValidBytes == true) {
      escolhida = pelada.fotoBraseao;
    }

    if (escolhida == null) return fallbackPadrao;

    return Image.memory(
      escolhida.bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallbackPadrao,
    );
  }
}

class _PeladaSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final data = Provider.of<DataService>(context, listen: false);
    data.setSearch(query);
    return Consumer<DataService>(
      builder: (ctx, d, _) {
        final lista = d.filteredPeladas;
        if (lista.isEmpty) {
          return const Center(child: Text('Nenhum resultado'));
        }
        return ListView.builder(
          itemCount: lista.length,
          itemBuilder: (c, i) => PeladaCard(
            pelada: lista[i],
            onTap: () {
              close(context, lista[i].id);
              Navigator.push(
                c,
                MaterialPageRoute(
                  builder: (_) => PeladaDetailScreen(peladaId: lista[i].id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Busque por nome, cidade ou local'));
    }
    return buildResults(context);
  }
}
