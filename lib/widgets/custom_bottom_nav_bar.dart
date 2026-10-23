import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/enums.dart';
import '../screens/cadastro_pelada_screen.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'animated_sports_menu.dart';
import '../screens/home_screen.dart';
import '../screens/campos_arenas_screen.dart' as campos_widget;
import '../screens/juizes_screen.dart' as juizes_widget;
import '../screens/goleiros_screen.dart' as goleiros_widget;

enum TipoFavoritoBadge { peladas, campos, juizes, goleiros }

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onCadastroPeladaPressed;
  final VoidCallback? onCadastrarCampoPressed;
  final VoidCallback? onFabPressed;
  final bool showCadastroAuthGate;
  final bool showFavoritesBadge;
  final int? favoritesBadgeCount;
  final TipoFavoritoBadge tipoFavoritoBadge;
  final bool showFiltersBadge;
  final int? filtersBadgeCount;
  final bool useCadastrarCampoNoIndiceZero;
  final IconData? indiceZeroIcon;
  final IconData? indiceZeroSelectedIcon;
  final String? indiceZeroLabel;
  final bool indiceZeroUsaIconeSimples;
  final bool indiceZeroUsaBadgeFavoritos;
  final bool sobrescreverIndiceUm;
  final IconData? indiceUmIcon;
  final IconData? indiceUmSelectedIcon;
  final String? indiceUmLabel;
  final bool indiceUmUsaIconeSimples;
  final bool indiceUmUsaBadgeFavoritos;
  final VoidCallback? onIndiceUmPressed;
  final bool sobrescreverIndiceDois;
  final IconData? indiceDoisIcon;
  final IconData? indiceDoisSelectedIcon;
  final String? indiceDoisLabel;
  final bool indiceDoisUsaIconeSimples;
  final VoidCallback? onIndiceDoisPressed;
  final bool indiceDoisUsaBadgeFavoritos;
  final Widget? customCenterMenu;
  final bool showCenterHomeButton;

  const CustomBottomNavBar({
    super.key,
    this.selectedIndex = -1,
    this.onTabSelected,
    this.onCadastroPeladaPressed,
    this.onCadastrarCampoPressed,
    this.onFabPressed,
    this.showCadastroAuthGate = true,
    this.showFavoritesBadge = false,
    this.favoritesBadgeCount,
    this.showFiltersBadge = false,
    this.filtersBadgeCount,
    this.useCadastrarCampoNoIndiceZero = false,
    this.indiceZeroIcon,
    this.indiceZeroSelectedIcon,
    this.indiceZeroLabel,
    this.indiceZeroUsaIconeSimples = false,
    this.indiceZeroUsaBadgeFavoritos = false,
    this.sobrescreverIndiceUm = false,
    this.indiceUmIcon,
    this.indiceUmSelectedIcon,
    this.indiceUmLabel,
    this.indiceUmUsaIconeSimples = false,
    this.indiceUmUsaBadgeFavoritos = false,
    this.onIndiceUmPressed,
    this.sobrescreverIndiceDois = false,
    this.indiceDoisIcon,
    this.indiceDoisSelectedIcon,
    this.indiceDoisLabel,
    this.indiceDoisUsaIconeSimples = false,
    this.onIndiceDoisPressed,
    this.indiceDoisUsaBadgeFavoritos = false,
    this.customCenterMenu,
    this.showCenterHomeButton = false,
    required this.tipoFavoritoBadge,
  });

  static const double barHeight = 74.8;
  static const double barHeightCompact = 52.7;
  static const double fabDiameter = 68.4;
  static const double fabRadius = fabDiameter / 2;
  static const double fabVerticalOffset = 5.0;
  static const double notchSpacing = 6.0;
  static const double notchRadius = fabRadius + notchSpacing;
  static const Duration autoHideDelay = Duration(seconds: 5);
  static const Duration animationDuration = Duration(milliseconds: 320);

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  bool _labelsVisible = true;
  bool _autoHideArmed = false;
  Timer? _autoHideTimer;
  bool _hovering = false;

  int _favoriteCount(DataService data) {
    switch (widget.tipoFavoritoBadge) {
      case TipoFavoritoBadge.peladas:
        return data.quantidadePeladasFavoritas;
      case TipoFavoritoBadge.campos:
        return data.quantidadeCamposFavoritos;
      case TipoFavoritoBadge.juizes:
        return data.quantidadeJuizesFavoritos;
      case TipoFavoritoBadge.goleiros:
        return data.quantidadeGoleirosFavoritos;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _armarAutoHide(regardless: true);
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _armarAutoHide({bool regardless = false}) {
    if (!mounted) return;
    if (_hovering && !regardless) {
      setState(() {
        _labelsVisible = true;
      });
      return;
    }
    if (!_autoHideArmed || regardless) {
      _autoHideArmed = true;
    } else {
      _autoHideTimer?.cancel();
    }
    _autoHideTimer = Timer(CustomBottomNavBar.autoHideDelay, () {
      if (mounted && !_hovering) {
        setState(() {
          _labelsVisible = false;
        });
      }
    });
  }

  void _onNavInteraction() {
    unawaited(HapticFeedback.selectionClick());
    if (!mounted) return;
    setState(() {
      _labelsVisible = true;
    });
    _armarAutoHide();
  }

  void _onHoverStart(PointerEnterEvent _) {
    if (!mounted) return;
    setState(() {
      _hovering = true;
      _labelsVisible = true;
    });
    _autoHideTimer?.cancel();
  }

  void _onHoverExit(PointerExitEvent _) {
    if (!mounted) return;
    setState(() {
      _hovering = false;
    });
    _armarAutoHide();
  }

  bool _isSelected(int i) => widget.selectedIndex == i;

  void _irHomeComFiltroModalidades(
    BuildContext context, {
    Set<Modalidade>? modalidades,
    bool limparFiltros = false,
  }) {
    unawaited(HapticFeedback.selectionClick());
    final data = context.read<DataService>();
    final limpar = limparFiltros || modalidades == null;
    if (limpar) {
      data.clearFilter();
    } else {
      final novo = data.currentFilter.copyWith(
        modalidades: modalidades,
        clearModalidades: false,
      );
      data.setFilter(novo);
    }
    if (widget.onTabSelected != null) {
      widget.onTabSelected!.call(0);
      return;
    }
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) =>
            HomeScreen(modalidadesIniciais: limpar ? null : modalidades),
      ),
      (route) => false,
    );
  }

  void _irParaTela(BuildContext context, Widget tela) {
    unawaited(HapticFeedback.selectionClick());
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => tela),
      (route) => false,
    );
  }

  Widget _buildHomeFabButton(BuildContext context, double screenWidth) {
    const mainSize = CustomBottomNavBar.fabDiameter;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: mainSize,
      height: mainSize,
      child: Semantics(
        button: true,
        label: 'Home. Ir para a página inicial',
        hint: 'Toque duas vezes para acionar',
        child: Tooltip(
          message: 'Ir para a Home',
          preferBelow: false,
          verticalOffset: mainSize / 2,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
                border: Border.all(
                  color: scheme.primary,
                  width: 3.0,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashFactory: InkRipple.splashFactory,
                splashColor: scheme.onSurface.withValues(alpha: 0.10),
                highlightColor: scheme.onSurface.withValues(alpha: 0.08),
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  final navigator = Navigator.of(context);
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(mainSize * 0.14),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.home_rounded,
                      color: scheme.onSurface,
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

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    Widget? customIcon,
    Widget? badgeIcon,
    bool showBadge = false,
    String? badgeText,
    VoidCallback? onTap,
    required Color unselectedColor,
    required Color selectedIconColor,
    required Color selectedPillBg,
    required Color selectedLabelColor,
    required bool isDark,
  }) {
    final selected = _isSelected(index);
    final badgeTexto = badgeText ?? '';
    return Flexible(
      fit: FlexFit.tight,
      child: Semantics(
        button: true,
        label: label,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _onNavInteraction();
            if (onTap != null) {
              onTap.call();
            } else {
              widget.onTabSelected?.call(index);
            }
          },
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: CustomBottomNavBar.animationDuration,
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 22 : 10,
                    vertical: selected ? 8 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedPillBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      customIcon ??
                          badgeIcon ??
                          Icon(
                            selected ? selectedIcon : icon,
                            color: selected
                                ? selectedIconColor
                                : unselectedColor,
                            size: 26,
                          ),
                      if (showBadge)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            constraints: const BoxConstraints(minWidth: 16),
                            child: Text(
                              badgeTexto,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: CustomBottomNavBar.animationDuration,
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: AnimatedOpacity(
                    duration: CustomBottomNavBar.animationDuration,
                    curve: Curves.easeOut,
                    opacity: _labelsVisible ? 1.0 : 0.0,
                    child: _labelsVisible
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? selectedLabelColor
                                      : unselectedColor,
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final data = context.watch<DataService>();

    final navBg =
        theme.bottomNavigationBarTheme.backgroundColor ??
        (isDark ? cs.surfaceContainerHigh : cs.surfaceContainerHighest);

    final unselectedColor = cs.onPrimary.withAlphaSafe(alpha: 0.72);
    final selectedIconColor = cs.onPrimary;
    final selectedPillBg = cs.onPrimary.withAlphaSafe(
      alpha: isDark ? 0.24 : 0.16,
    );
    final selectedLabelColor = cs.onPrimary;

    Widget customIconNova(
      bool selected,
      Color selectedColor,
      Color unselectedColor,
      bool isDark,
    ) {
      final base = selected ? selectedColor : unselectedColor;
      final fg = cs.primary;
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(Icons.sports_soccer, color: base, size: 28),
          Positioned(
            right: -10,
            bottom: -8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
              child: Icon(Icons.add, color: fg, size: 12, weight: 900),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        final targetHeight = _labelsVisible
            ? CustomBottomNavBar.barHeight
            : CustomBottomNavBar.barHeightCompact;
        final totalHeight = targetHeight + safeBottom;

        late Widget bodyNavBar = AnimatedContainer(
          duration: CustomBottomNavBar.animationDuration,
          curve: Curves.easeOut,
          width: screenWidth,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomPaint(
                  size: Size(screenWidth, totalHeight),
                  painter: CurvedNotchedBarPainter(
                    fillColor: navBg,
                    notchRadius: CustomBottomNavBar.notchRadius,
                    fabDiameter: CustomBottomNavBar.fabDiameter,
                    notchCenterY: CustomBottomNavBar.fabVerticalOffset,
                    shadowColor: isDark
                        ? Colors.black.withAlphaSafe(alpha: 0.38)
                        : Colors.black.withAlphaSafe(alpha: 0.18),
                    heightFactor: targetHeight / CustomBottomNavBar.barHeight,
                  ),
                  child: AnimatedContainer(
                    duration: CustomBottomNavBar.animationDuration,
                    curve: Curves.easeOut,
                    height: totalHeight,
                    padding: EdgeInsets.only(bottom: safeBottom),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (_) {
                        _onNavInteraction();
                      },
                      child: MouseRegion(
                        onEnter: _onHoverStart,
                        onExit: _onHoverExit,
                        opaque: false,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!widget.useCadastrarCampoNoIndiceZero)
                              _buildNavItem(
                                context: context,
                                index: 0,
                                icon: Icons.home_outlined,
                                selectedIcon: Icons.home,
                                label: 'Nova',
                                isDark: isDark,
                                unselectedColor: unselectedColor,
                                selectedIconColor: selectedIconColor,
                                selectedPillBg: selectedPillBg,
                                selectedLabelColor: selectedLabelColor,
                                customIcon: customIconNova(
                                  _isSelected(0),
                                  selectedIconColor,
                                  unselectedColor,
                                  isDark,
                                ),
                                onTap: () {
                                  if (widget.onCadastroPeladaPressed != null) {
                                    widget.onCadastroPeladaPressed!.call();
                                    return;
                                  }
                                  final auth = context.read<AuthService>();
                                  if (!widget.showCadastroAuthGate ||
                                      auth.isAuthenticated) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CadastroPeladaScreen(),
                                      ),
                                    );
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Faça login para cadastrar uma pelada.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              )
                            else
                              Builder(
                                builder: (ctx) {
                                  final iconDefault = Icons.stadium_outlined;
                                  final iconSelDefault = Icons.stadium;
                                  final labelDefault = 'Campo/Arena';
                                  final icone =
                                      widget.indiceZeroIcon ?? iconDefault;
                                  final iconeSel =
                                      widget.indiceZeroSelectedIcon ??
                                      iconSelDefault;
                                  final rotulo =
                                      widget.indiceZeroLabel ?? labelDefault;
                                  final usaSimples =
                                      widget.indiceZeroUsaIconeSimples;
                                  final usaBadgeFavoritos =
                                      widget.indiceZeroUsaBadgeFavoritos;
                                  return _buildNavItem(
                                    context: ctx,
                                    index: 0,
                                    icon: icone,
                                    selectedIcon: iconeSel,
                                    label: rotulo,
                                    isDark: isDark,
                                    unselectedColor: unselectedColor,
                                    selectedIconColor: selectedIconColor,
                                    selectedPillBg: selectedPillBg,
                                    selectedLabelColor: selectedLabelColor,
                                    customIcon: usaSimples
                                        ? null
                                        : Builder(
                                            builder: (ctx2) {
                                              final selected = _isSelected(0);
                                              final base = selected
                                                  ? selectedIconColor
                                                  : unselectedColor;
                                              final fg = cs.primary;
                                              return Stack(
                                                clipBehavior: Clip.none,
                                                alignment: Alignment.center,
                                                children: [
                                                  Icon(
                                                    selected ? iconeSel : icone,
                                                    color: base,
                                                    size: 28,
                                                  ),
                                                  Positioned(
                                                    right: -10,
                                                    bottom: -8,
                                                    child: Container(
                                                      width: 16,
                                                      height: 16,
                                                      decoration: BoxDecoration(
                                                        color: base,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.add,
                                                        color: fg,
                                                        size: 12,
                                                        weight: 900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                    badgeIcon: usaBadgeFavoritos
                                        ? Icon(
                                            _isSelected(0)
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: _isSelected(0)
                                                ? selectedIconColor
                                                : unselectedColor,
                                            size: 26,
                                          )
                                        : null,
                                    showBadge: usaBadgeFavoritos
                                        ? (widget.showFavoritesBadge ||
                                              _favoriteCount(data) > 0)
                                        : false,
                                    badgeText: usaBadgeFavoritos
                                        ? (widget.favoritesBadgeCount ??
                                                  _favoriteCount(data))
                                              .toString()
                                        : null,
                                    onTap: () {
                                      if (widget.onCadastrarCampoPressed !=
                                          null) {
                                        widget.onCadastrarCampoPressed!.call();
                                        return;
                                      }
                                      if (widget.showCadastroAuthGate &&
                                          !ctx
                                              .read<AuthService>()
                                              .isAuthenticated &&
                                          !usaBadgeFavoritos &&
                                          !usaSimples) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Faça login para continuar.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }
                                      if (widget.onTabSelected != null) {
                                        widget.onTabSelected!.call(0);
                                      }
                                    },
                                  );
                                },
                              ),
                            Builder(
                              builder: (ctx) {
                                if (!widget.sobrescreverIndiceUm) {
                                  return _buildNavItem(
                                    context: ctx,
                                    index: 1,
                                    icon: Icons.star_border,
                                    selectedIcon: Icons.star,
                                    label: 'Favoritos',
                                    isDark: isDark,
                                    unselectedColor: unselectedColor,
                                    selectedIconColor: selectedIconColor,
                                    selectedPillBg: selectedPillBg,
                                    selectedLabelColor: selectedLabelColor,
                                    badgeIcon: Icon(
                                      _isSelected(1)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: _isSelected(1)
                                          ? selectedIconColor
                                          : unselectedColor,
                                      size: 26,
                                    ),
                                    showBadge:
                                        widget.showFavoritesBadge ||
                                        _favoriteCount(data) > 0,
                                    badgeText:
                                        (widget.favoritesBadgeCount ??
                                                _favoriteCount(data))
                                            .toString(),
                                  );
                                }
                                final iconDefault = Icons.star_border;
                                final iconSelDefault = Icons.star;
                                final labelDefault = 'Favoritos';
                                final icone =
                                    widget.indiceUmIcon ?? iconDefault;
                                final iconeSel =
                                    widget.indiceUmSelectedIcon ??
                                    iconSelDefault;
                                final rotulo =
                                    widget.indiceUmLabel ?? labelDefault;
                                final usaSimples =
                                    widget.indiceUmUsaIconeSimples;
                                final usaBadgeFavoritos =
                                    widget.indiceUmUsaBadgeFavoritos;
                                return _buildNavItem(
                                  context: ctx,
                                  index: 1,
                                  icon: icone,
                                  selectedIcon: iconeSel,
                                  label: rotulo,
                                  isDark: isDark,
                                  unselectedColor: unselectedColor,
                                  selectedIconColor: selectedIconColor,
                                  selectedPillBg: selectedPillBg,
                                  selectedLabelColor: selectedLabelColor,
                                  customIcon: usaSimples
                                      ? null
                                      : Builder(
                                          builder: (ctx2) {
                                            final selected = _isSelected(1);
                                            final base = selected
                                                ? selectedIconColor
                                                : unselectedColor;
                                            final fg = selected
                                                ? (isDark
                                                      ? Colors.black
                                                      : Colors.white)
                                                : (isDark
                                                      ? Colors.black87
                                                      : Colors.white);
                                            return Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  selected ? iconeSel : icone,
                                                  color: base,
                                                  size: 28,
                                                ),
                                                Positioned(
                                                  right: -10,
                                                  bottom: -8,
                                                  child: Container(
                                                    width: 16,
                                                    height: 16,
                                                    decoration: BoxDecoration(
                                                      color: base,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.add,
                                                      color: fg,
                                                      size: 12,
                                                      weight: 900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                  badgeIcon: usaBadgeFavoritos
                                      ? Icon(
                                          _isSelected(1)
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: _isSelected(1)
                                              ? selectedIconColor
                                              : unselectedColor,
                                          size: 26,
                                        )
                                      : null,
                                  showBadge: usaBadgeFavoritos
                                      ? (widget.showFavoritesBadge ||
                                            _favoriteCount(data) > 0)
                                      : false,
                                  badgeText: usaBadgeFavoritos
                                      ? (widget.favoritesBadgeCount ??
                                                _favoriteCount(data))
                                            .toString()
                                      : null,
                                  onTap: () {
                                    if (widget.onIndiceUmPressed != null) {
                                      widget.onIndiceUmPressed!.call();
                                      return;
                                    }
                                    if (widget.showCadastroAuthGate &&
                                        !ctx
                                            .read<AuthService>()
                                            .isAuthenticated &&
                                        !usaBadgeFavoritos &&
                                        !usaSimples) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Faça login para continuar.',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    if (widget.onTabSelected != null) {
                                      widget.onTabSelected!.call(1);
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(
                              width:
                                  CustomBottomNavBar.fabDiameter +
                                  CustomBottomNavBar.notchSpacing * 2,
                            ),
                            Builder(
                              builder: (ctx) {
                                if (!widget.sobrescreverIndiceDois) {
                                  return _buildNavItem(
                                    context: ctx,
                                    index: 2,
                                    icon: Icons.stadium_outlined,
                                    selectedIcon: Icons.stadium,
                                    label: 'Campos',
                                    isDark: isDark,
                                    unselectedColor: unselectedColor,
                                    selectedIconColor: selectedIconColor,
                                    selectedPillBg: selectedPillBg,
                                    selectedLabelColor: selectedLabelColor,
                                    badgeIcon: Icon(
                                      _isSelected(2)
                                          ? Icons.stadium
                                          : Icons.stadium_outlined,
                                      color: _isSelected(2)
                                          ? selectedIconColor
                                          : unselectedColor,
                                      size: 26,
                                    ),
                                  );
                                }
                                final iconDefault = Icons.stadium_outlined;
                                final iconSelDefault = Icons.stadium;
                                final labelDefault = 'Campos';
                                final icone =
                                    widget.indiceDoisIcon ?? iconDefault;
                                final iconeSel =
                                    widget.indiceDoisSelectedIcon ??
                                    iconSelDefault;
                                final rotulo =
                                    widget.indiceDoisLabel ?? labelDefault;
                                final usaSimples =
                                    widget.indiceDoisUsaIconeSimples;
                                final usaBadgeFavoritos =
                                    widget.indiceDoisUsaBadgeFavoritos;
                                return _buildNavItem(
                                  context: ctx,
                                  index: 2,
                                  icon: icone,
                                  selectedIcon: iconeSel,
                                  label: rotulo,
                                  isDark: isDark,
                                  unselectedColor: unselectedColor,
                                  selectedIconColor: selectedIconColor,
                                  selectedPillBg: selectedPillBg,
                                  selectedLabelColor: selectedLabelColor,
                                  customIcon: usaSimples
                                      ? null
                                      : Builder(
                                          builder: (ctx2) {
                                            final selected = _isSelected(2);
                                            final base = selected
                                                ? selectedIconColor
                                                : unselectedColor;
                                            final fg = selected
                                                ? (isDark
                                                      ? Colors.black
                                                      : Colors.white)
                                                : (isDark
                                                      ? Colors.black87
                                                      : Colors.white);
                                            return Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  selected ? iconeSel : icone,
                                                  color: base,
                                                  size: 28,
                                                ),
                                                Positioned(
                                                  right: -10,
                                                  bottom: -8,
                                                  child: Container(
                                                    width: 16,
                                                    height: 16,
                                                    decoration: BoxDecoration(
                                                      color: base,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.add,
                                                      color: fg,
                                                      size: 12,
                                                      weight: 900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                  badgeIcon: usaBadgeFavoritos
                                      ? Icon(
                                          _isSelected(2)
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: _isSelected(2)
                                              ? selectedIconColor
                                              : unselectedColor,
                                          size: 26,
                                        )
                                      : null,
                                  showBadge: usaBadgeFavoritos
                                      ? (widget.showFavoritesBadge ||
                                            _favoriteCount(data) > 0)
                                      : false,
                                  badgeText: usaBadgeFavoritos
                                      ? (widget.favoritesBadgeCount ??
                                                _favoriteCount(data))
                                            .toString()
                                      : null,
                                  onTap: () {
                                    if (widget.onIndiceDoisPressed != null) {
                                      widget.onIndiceDoisPressed!.call();
                                      return;
                                    }
                                    if (widget.showCadastroAuthGate &&
                                        !ctx
                                            .read<AuthService>()
                                            .isAuthenticated &&
                                        !usaBadgeFavoritos &&
                                        !usaSimples) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Faça login para continuar.',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    if (widget.onTabSelected != null) {
                                      widget.onTabSelected!.call(2);
                                    }
                                  },
                                );
                              },
                            ),
                            _buildNavItem(
                              context: context,
                              index: 3,
                              icon: Icons.person_outline,
                              selectedIcon: Icons.person,
                              label: 'Perfil',
                              isDark: isDark,
                              unselectedColor: unselectedColor,
                              selectedIconColor: selectedIconColor,
                              selectedPillBg: selectedPillBg,
                              selectedLabelColor: selectedLabelColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top:
                    -(CustomBottomNavBar.fabDiameter / 2 -
                        CustomBottomNavBar.fabVerticalOffset),
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: CustomBottomNavBar.fabDiameter,
                    height: CustomBottomNavBar.fabDiameter,
                    child: widget.showCenterHomeButton
                        ? _buildHomeFabButton(context, screenWidth)
                        : (widget.customCenterMenu != null
                              ? widget.customCenterMenu!
                              : AnimatedSportsMenu(
                                  mainButtonSize:
                                      CustomBottomNavBar.fabDiameter,
                                  onFutebolPressed: () {
                                    _onNavInteraction();
                                    if (widget.onFabPressed != null) {
                                      widget.onFabPressed!.call();
                                      return;
                                    }
                                    _irHomeComFiltroModalidades(
                                      context,
                                      limparFiltros: true,
                                    );
                                  },
                                  onVoleiPressed: () {
                                    _onNavInteraction();
                                    _irHomeComFiltroModalidades(
                                      context,
                                      modalidades:
                                          AnimatedSportsMenu.modalidadesVolei,
                                    );
                                  },
                                  onBasquetePressed: () {
                                    _onNavInteraction();
                                    _irHomeComFiltroModalidades(
                                      context,
                                      modalidades: AnimatedSportsMenu
                                          .modalidadesBasquete,
                                    );
                                  },
                                  onDiversosPressed: () {
                                    _onNavInteraction();
                                    _irHomeComFiltroModalidades(
                                      context,
                                      modalidades: AnimatedSportsMenu
                                          .modalidadesDiversos,
                                    );
                                  },
                                  onCamposArenasPressed: () {
                                    _onNavInteraction();
                                    _irParaTela(
                                      context,
                                      const campos_widget.CamposArenasScreen(),
                                    );
                                  },
                                  onJuizesPressed: () {
                                    _onNavInteraction();
                                    _irParaTela(
                                      context,
                                      const juizes_widget.JuizesScreen(),
                                    );
                                  },
                                  onGoleirosPressed: () {
                                    _onNavInteraction();
                                    _irParaTela(
                                      context,
                                      const goleiros_widget.GoleirosScreen(),
                                    );
                                  },
                                )),
                  ),
                ),
              ),
            ],
          ),
        );

        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Barra de navegação inferior',
          child: Listener(
            onPointerDown: (_) {
              _onNavInteraction();
            },
            child: MouseRegion(
              onEnter: _onHoverStart,
              onExit: _onHoverExit,
              child: bodyNavBar,
            ),
          ),
        );
      },
    );
  }
}

class CurvedNotchedBarPainter extends CustomPainter {
  final Color fillColor;
  final double notchRadius;
  final double fabDiameter;
  final double notchCenterY;
  final Color shadowColor;
  final double heightFactor;

  const CurvedNotchedBarPainter({
    required this.fillColor,
    required this.notchRadius,
    required this.fabDiameter,
    required this.notchCenterY,
    required this.shadowColor,
    this.heightFactor = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    const topY = 0.0;
    const shoulderWidth = 45.0;
    final maxNotchRadius = (centerX - shoulderWidth - 8)
        .clamp(0.0, centerX)
        .toDouble();
    final effectiveNotchRadius = notchRadius
        .clamp(0.0, maxNotchRadius)
        .toDouble();
    final notchDrop = notchCenterY.clamp(0.0, h / 2).toDouble();

    final path = Path();
    path.moveTo(0, topY);
    path.lineTo(centerX - effectiveNotchRadius - shoulderWidth, topY);
    path.cubicTo(
      centerX - effectiveNotchRadius - shoulderWidth * 0.55,
      topY,
      centerX - effectiveNotchRadius,
      topY,
      centerX - effectiveNotchRadius,
      notchDrop,
    );
    path.arcToPoint(
      Offset(centerX + effectiveNotchRadius, notchDrop),
      radius: Radius.circular(effectiveNotchRadius),
      clockwise: false,
      largeArc: false,
    );
    path.cubicTo(
      centerX + effectiveNotchRadius,
      topY,
      centerX + effectiveNotchRadius + shoulderWidth * 0.55,
      topY,
      centerX + effectiveNotchRadius + shoulderWidth,
      topY,
    );
    path.lineTo(w, topY);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.lineTo(0, topY);
    path.close();

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..style = PaintingStyle.fill;
    final shadowShift = Path()
      ..addPath(path.shift(const Offset(0, -2)), Offset.zero);
    canvas.drawPath(shadowShift, shadowPaint);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CurvedNotchedBarPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.fabDiameter != fabDiameter ||
        oldDelegate.notchCenterY != notchCenterY ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.heightFactor != heightFactor;
  }
}
