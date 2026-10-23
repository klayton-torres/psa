import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/enums.dart';
import '../models/goleiro.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/profile_sports_rail_menu.dart';
import 'cadastro_goleiro_screen.dart';
import 'campos_arenas_screen.dart';
import 'home_screen.dart';
import 'goleiros_screen.dart';
import '../utils/profile_navigation_helper.dart';

class GoleirosFavoritosScreen extends StatefulWidget {
  const GoleirosFavoritosScreen({super.key});

  @override
  State<GoleirosFavoritosScreen> createState() =>
      _GoleirosFavoritosScreenState();
}

class _GoleirosFavoritosScreenState extends State<GoleirosFavoritosScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Modalidades classificadas como "PELADAS": futebol em todas as
  /// suas variantes (campo, rua, futsal, society, areia, praia e
  /// futevôlei). Usado para montar o conjunto "VÁRIOS" por exclusão.
  static const Set<Modalidade> _modalidadesPeladas = {
    Modalidade.futebolCampo,
    Modalidade.futebolRua,
    Modalidade.futsal,
    Modalidade.society,
    Modalidade.areia,
    Modalidade.praia,
  };
  static const Set<Modalidade> _modalidadesVolei = {Modalidade.voley};
  static const Set<Modalidade> _modalidadesBasquete = {Modalidade.basquete};

  /// Filtro do botão "VÁRIOS": exibe tudo EXCETO as 3 categorias
  /// principais: futebol em geral (_modalidadesPeladas), vôlei e
  /// basquete. Calculado dinamicamente a partir de Modalidade.values
  /// para incluir automaticamente quaisquer modalidades adicionadas
  /// no futuro ao enum.
  static final Set<Modalidade> _modalidadesVarios =
      Set<Modalidade>.from(Modalidade.values)..removeAll({
        ..._modalidadesPeladas,
        ..._modalidadesVolei,
        ..._modalidadesBasquete,
      });

  /// Constrói uma rota animada (fade + slide vertical) com duração
  /// de 280ms (< 1s), consistente com as demais telas.
  static PageRouteBuilder<T> _rotaAnimada<T>(
    WidgetBuilder builder,
  ) => PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, sec) => builder(ctx),
    transitionsBuilder: (ctx, anim, sec, child) => FadeTransition(
      opacity: Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );

  /// Verifica permissão mínima para acessar a tela de Goleiros.
  /// Regra atual: usuário deve estar autenticado.
  bool _usuarioPodeAcessarGoleiros() {
    final auth = context.read<AuthService>();
    return auth.isAuthenticated;
  }

  /// Constrói tela de erro de permissão amigável com ícone, mensagem
  /// e CTA "Voltar".
  Widget _buildTelaErroPermissao({required String funcionalidade}) {
    final theme = Theme.of(context);
    final sch = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso Negado'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_outlined,
                size: 96,
                color: sch.error.withValues(alpha: 0.70),
              ),
              const SizedBox(height: 20),
              Text(
                'Você não tem permissão para acessar $funcionalidade.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Entre em contato com o administrador ou verifique seu plano de assinatura.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_outlined),
                label: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Navega para a Home aplicando filtro de modalidades.
  ///
  /// - [modalidades] = null → botão PELADAS (sem filtros)
  /// - [modalidades] = {voley} / {basquete} → botões VÔLEI / BASQUETE
  /// - Usa `pushAndRemoveUntil((r) => false)` substitui toda a pilha,
  ///   evitando múltiplas instâncias da Home.
  /// - Filtro é aplicado via [HomeScreen.modalidadesIniciais] antes
  ///   da renderização, sem carregar dados de modalidades desnecessárias.
  void _navegarParaHomeComModalidades(
    Set<Modalidade>? modalidades, {
    required String erroMensagem,
  }) {
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    try {
      Navigator.of(context).pushAndRemoveUntil(
        _rotaAnimada((_) => HomeScreen(modalidadesIniciais: modalidades)),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final sch = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: sch.error,
          content: Text(
            '$erroMensagem: $e',
            style: TextStyle(color: sch.onError),
          ),
        ),
      );
    }
  }

  /// Abre a tela Campos e Arenas (limpando a pilha até a primeira
  /// rota para evitar múltiplas instâncias).
  void _navegarParaCamposArenas() {
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    try {
      Navigator.of(context).pushAndRemoveUntil(
        _rotaAnimada((_) => const CamposArenasScreen()),
        (r) => r.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      final sch = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: sch.error,
          content: Text(
            'Não foi possível abrir Campos e Arenas: $e',
            style: TextStyle(color: sch.onError),
          ),
        ),
      );
    }
  }

  /// Ação do botão GOLEIROS com validação de permissão.
  /// Se o usuário não tiver permissão, exibe tela de erro em vez de
  /// abrir a lista de goleiros.
  void _navegarParaGoleiros() {
    if (!mounted) return;
    if (!_usuarioPodeAcessarGoleiros()) {
      unawaited(HapticFeedback.lightImpact());
      try {
        Navigator.of(context).push(
          _rotaAnimada(
            (_) => _buildTelaErroPermissao(funcionalidade: 'Goleiros'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        final sch = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: sch.error,
            content: Text(
              'Não foi possível verificar permissões: $e',
              style: TextStyle(color: sch.onError),
            ),
          ),
        );
      }
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    try {
      Navigator.of(context).pushAndRemoveUntil(
        _rotaAnimada((_) => const GoleirosScreen()),
        (r) => r.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      final sch = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: sch.error,
          content: Text(
            'Não foi possível abrir Goleiros: $e',
            style: TextStyle(color: sch.onError),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Semantics(
          button: true,
          label: 'Voltar para a tela inicial',
          hint: 'Toque duas vezes para retornar a home',
          child: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              try {
                Navigator.of(context).pushAndRemoveUntil(
                  _rotaAnimada((_) => const HomeScreen()),
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
        title: const Text('Goleiros Favoritos'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<DataService>(
          builder: (context, data, _) {
            final lista = data.goleirosFavoritos;

            if (data.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (lista.isEmpty) {
              return _buildEmpty(context, theme, isDark);
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final crossCount = w >= 900
                    ? 4
                    : (w >= 720 ? 3 : (w >= 520 ? 2 : 1));
                final cardRatio = w >= 900
                    ? 0.92
                    : (w >= 720 ? 0.90 : (w >= 560 ? 0.85 : 0.95));
                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    childAspectRatio: cardRatio,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemCount: lista.length,
                  itemBuilder: (_, i) =>
                      _buildCard(context, lista[i], data, theme, isDark),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Consumer2<AuthService, DataService>(
        builder: (context, auth, data, _) {
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
              activeButtonId: 'goleiros',
              navBarHeight: CustomBottomNavBar.barHeight,
            );
          }
          return CustomBottomNavBar(
            selectedIndex: 1,
            customCenterMenu: centerMenu ?? const SizedBox.shrink(),
            useCadastrarCampoNoIndiceZero: true,
            tipoFavoritoBadge: TipoFavoritoBadge.goleiros,
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
                    unawaited(HapticFeedback.lightImpact());
                    Navigator.of(context).pushAndRemoveUntil(
                      _rotaAnimada((_) => const HomeScreen()),
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
                case 1:
                  if (ModalRoute.of(context)?.settings.name ==
                      runtimeType.toString()) {
                    unawaited(HapticFeedback.selectionClick());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Você já está na tela de Goleiros Favoritos.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  try {
                    unawaited(HapticFeedback.lightImpact());
                    Navigator.of(context).pushReplacement(
                      _rotaAnimada((_) => const GoleirosFavoritosScreen()),
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
                  try {
                    unawaited(HapticFeedback.lightImpact());
                    Navigator.of(context).pushAndRemoveUntil(
                      _rotaAnimada((_) => const HomeScreen()),
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
            showFavoritesBadge: data.temGoleirosFavoritos,
            favoritesBadgeCount: data.quantidadeGoleirosFavoritos,
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : theme.primaryColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.20)
                      : theme.primaryColor.withValues(alpha: 0.30),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.gpp_good_outlined,
                size: 48,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.70)
                    : theme.primaryColor.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Nenhum goleiro favoritado ainda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Volte para a tela de Goleiros e toque na estrelinha '
              'para salvar seus goleiros preferidos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    Goleiro j,
    DataService data,
    ThemeData theme,
    bool isDark,
  ) {
    final favorito = data.isGoleiroFavorito(j.id);
    final DateFormat df = DateFormat('dd/MM/yyyy', 'pt_BR');
    final foto = j.foto;
    final endereco = j.enderecoCurto;
    final primary = theme.colorScheme.primary;
    final nivelGoleiro = j.situacaoFederativa?.trim();
    final cachePorPartida = j.taxaArbitragem == null
        ? 'Não informado'
        : NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
          ).format(j.taxaArbitragem);
    final modalidades = j.modalidades.isEmpty
        ? 'Não informadas'
        : j.modalidades.join(', ');

    Widget valorDestacado(
      String valor, {
      required Color fundo,
      required Color texto,
      int maxLines = 1,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          valor,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: texto,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        try {
          await HapticFeedback.selectionClick();
          final a = context.read<AuthService>();
          if (!a.isAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: theme.colorScheme.error,
                content: const Text('Faça login para editar goleiros.'),
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
          final navigator = Navigator.of(context);
          await navigator.push<Goleiro?>(
            MaterialPageRoute(
              builder: (_) => CadastroGoleiroScreen(goleiro: j),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Não foi possível abrir o goleiro: $e'),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.grafiteDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Builder(
                    builder: (_) {
                      if (foto != null && foto.hasValidBytes) {
                        return Image.memory(
                          foto.bytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black.withValues(alpha: 0.45),
                            ),
                          ),
                        );
                      }
                      if (foto?.url != null && foto!.url!.trim().isNotEmpty) {
                        return Image.network(
                          foto.url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black.withValues(alpha: 0.45),
                            ),
                          ),
                        );
                      }
                      return Container(
                        color: isDark
                            ? AppColors.grafiteDarkBg
                            : primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: isDark ? Colors.white70 : primary,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        j.nomeExibicao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        endereco.isEmpty
                            ? 'Localização não disponível'
                            : endereco,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (j.dataNascimento != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                df.format(j.dataNascimento!),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          if (j.telefone != null &&
                              j.telefone!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                j.telefone!,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: valorDestacado(
                                nivelGoleiro == null || nivelGoleiro.isEmpty
                                    ? 'Não informado'
                                    : nivelGoleiro,
                                fundo: theme.colorScheme.primary,
                                texto: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: valorDestacado(
                                cachePorPartida,
                                fundo: theme.colorScheme.secondary,
                                texto: theme.colorScheme.onSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: valorDestacado(
                          modalidades,
                          fundo: theme.colorScheme.tertiary,
                          texto: theme.colorScheme.onTertiary,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Semantics(
                button: true,
                toggled: favorito,
                label: favorito
                    ? 'Remover goleiro dos favoritos'
                    : 'Adicionar goleiro aos favoritos',
                hint:
                    'Toque duas vezes para ${favorito ? 'remover dos' : 'adicionar aos'} favoritos',
                child: Tooltip(
                  message: favorito
                      ? 'Remover dos favoritos'
                      : 'Favoritar goleiro',
                  preferBelow: false,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        try {
                          await data.toggleGoleiroFavorito(j.id);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Não foi possível atualizar favorito: $e',
                              ),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          favorito
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: favorito
                              ? AppColors.secondaryColor
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
