import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/campo_arena.dart';
import '../services/data_service.dart';
import 'campo_detail_screen.dart';
import 'campo_arena_filter_screen.dart';
import 'home_screen.dart';

/// Tela dedicada aos "CAMPOS E ARENAS FAVORITADOS" pelo usuário autenticado.
/// Usa o Set<String> `favoritos` do [DataService] (compartilhado com a Home)
/// para filtrar dinamicamente apenas os [CampoArena] cujo `id` está presente
/// na lista de favoritos do usuário.
///
/// Implementa:
/// - Carregamento dinâmico (reativo via Consumer)
/// - Estado vazio amigável (sem campos favoritos)
/// - Responsividade Grid/Lista semelhante à tela CamposArenasScreen
/// - Navegação de clique para detalhes do campo.
class CamposArenasFavoritosScreen extends StatefulWidget {
  const CamposArenasFavoritosScreen({super.key});

  @override
  State<CamposArenasFavoritosScreen> createState() =>
      _CamposArenasFavoritosScreenState();
}

class _CamposArenasFavoritosScreenState
    extends State<CamposArenasFavoritosScreen> {
  final ScrollController _scrollController = ScrollController();
  CampoArenaFilter _filtroCampos = const CampoArenaFilter();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
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
        title: const Text('Campos e Arenas Favoritos'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          Semantics(
            button: true,
            label: _filtroCampos.activeFiltersCount > 0
                ? 'Abrir filtros. ${_filtroCampos.activeFiltersCount} filtros ativos'
                : 'Abrir filtros',
            child: Tooltip(
              message: _filtroCampos.activeFiltersCount > 0
                  ? 'Filtros (${_filtroCampos.activeFiltersCount} ativos)'
                  : 'Filtrar favoritos',
              child: IconButton(
                onPressed: () async {
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
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Não foi possível abrir filtros: $error'),
                      ),
                    );
                  }
                },
                icon: _filtroCampos.activeFiltersCount > 0
                    ? Badge(
                        label: Text(
                          _filtroCampos.activeFiltersCount.toString(),
                        ),
                        child: const Icon(Icons.filter_list_alt),
                      )
                    : const Icon(Icons.filter_list_outlined),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Consumer<DataService>(
          builder: (context, data, _) {
            // Usa o getter tipado camposFavoritos do DataService,
            // que já filtra corretamente pelo namespace "campo:"
            // (evita colisão com favoritos de peladas ou juízes).
            final lista = data.camposFavoritos
                .where(_filtroCampos.matches)
                .toList(growable: false);

            if (data.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (lista.isEmpty) {
              return _filtroCampos.activeFiltersCount > 0
                  ? _buildSemResultados(theme)
                  : _buildVazio(context, theme);
            }

            return RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.lightImpact();
                try {
                  await data.carregarCamposArenas();
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Não foi possível atualizar os favoritos.'),
                    ),
                  );
                }
              },
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 360,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 340 / 380,
                ),
                itemCount: lista.length,
                itemBuilder: (ctx, idx) =>
                    _buildCard(ctx, lista[idx], data, theme, isDark),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVazio(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border_rounded,
              size: 80,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : theme.primaryColor.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum campo ou arena favoritado ainda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Volte para a tela de Campos e Arenas e toque na estrelinha '
              'para salvar seus espaços esportivos preferidos.',
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

  Widget _buildSemResultados(ThemeData theme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum favorito corresponde aos filtros',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(
              () => _filtroCampos = const CampoArenaFilter(),
            ),
            icon: const Icon(Icons.clear_all_rounded),
            label: const Text('Limpar filtros'),
          ),
        ],
      ),
    ),
  );

  Widget _buildCard(
    BuildContext context,
    CampoArena c,
    DataService data,
    ThemeData theme,
    bool isDark,
  ) {
    final favorito = data.isCampoFavorito(c.id);
    final destaque = theme.colorScheme.primary;
    final ruaNum = c.rua.trim().isNotEmpty && c.numero.trim().isNotEmpty
        ? '${c.rua}, ${c.numero}'
        : (c.rua.trim().isNotEmpty ? c.rua : c.numero);
    final partesEndereco = <String>[];
    if (ruaNum.trim().isNotEmpty) partesEndereco.add(ruaNum.trim());
    if (c.bairro.trim().isNotEmpty) partesEndereco.add(c.bairro.trim());
    final cidadeUf = c.estado.trim().isNotEmpty
        ? '${c.cidade} - ${c.estado}'
        : c.cidade;
    if (cidadeUf.trim().isNotEmpty) partesEndereco.add(cidadeUf.trim());
    final enderecoStr = partesEndereco.join(' · ');

    return GestureDetector(
      onTap: () async {
        try {
          unawaited(HapticFeedback.lightImpact());
          await Navigator.of(
            context,
          ).push(_rotaAnimada((_) => CampoDetailScreen(campo: c)));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Não foi possível abrir o campo: $e'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: c.fotos.isNotEmpty
                        ? Builder(
                      builder: (_) {
                        final capa = c.fotoCapa;
                        if (capa != null && capa.hasValidBytes) {
                          return Image.memory(
                            capa.bytes,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              child: Icon(
                                Icons.stadium_rounded,
                                size: 54,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        }
                        final f = c.fotos.first;
                        if (f.url != null && f.url!.trim().isNotEmpty) {
                          return Image.network(
                            f.url!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              child: Icon(
                                Icons.stadium_rounded,
                                size: 54,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        }
                        return Container(
                          color: isDark
                              ? AppColors.grafiteDarkBg
                              : Colors.grey[200],
                          child: Icon(
                            Icons.stadium_rounded,
                            size: 54,
                            color: isDark
                                ? Colors.white70
                                : Colors.black.withValues(alpha: 0.45),
                          ),
                        );
                      },
                    )
                        : Container(
                      color: isDark
                          ? AppColors.grafiteDarkBg
                          : Colors.grey[200],
                      child: Icon(
                        Icons.stadium_rounded,
                        size: 54,
                        color: isDark
                            ? Colors.white70
                            : Colors.black.withValues(alpha: 0.45),
                      ),
                        ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _shareAction(context, c),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Semantics(
                          button: true,
                          toggled: favorito,
                          label: favorito
                              ? 'Remover campo dos favoritos'
                              : 'Adicionar campo aos favoritos',
                          hint:
                              'Toque duas vezes para ${favorito ? 'remover dos' : 'adicionar aos'} favoritos',
                          child: Tooltip(
                            message: favorito
                                ? 'Remover dos favoritos'
                                : 'Favoritar campo',
                            preferBelow: false,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                try {
                                  await data.toggleCampoFavorito(c.id);
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
                                      ? const Color(0xFFFF805F)
                                      : (isDark
                                            ? Colors.white60
                                            : Colors.black.withValues(
                                                alpha: 0.45,
                                              )),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      enderecoStr.isEmpty
                          ? 'Localização não disponível'
                          : enderecoStr,
                      maxLines: 2,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${c.quantidadePorLinha}x${c.quantidadePorLinha}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.tipoGrama.label.toUpperCase(),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoFaixa(
                            'MEDIDAS',
                            c.larguraMetros != null && c.profundidadeMetros != null
                                ? '${_formatarMedida(c.larguraMetros!)} × ${_formatarMedida(c.profundidadeMetros!)} m'
                                : 'Não informado',
                            destaque,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _infoFaixa(
                            'ÁREA TOTAL',
                            c.areaM2 != null
                                ? '${_formatarMedida(c.areaM2!)} m²'
                                : 'Não informada',
                            const Color(0xFFFF805F),
                            alinhamentoDireita: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _infoFaixa(
                      'DEPENDÊNCIAS',
                      c.dependencias.isEmpty ? 'Não informado' : c.dependenciasLabel,
                      const Color(0xFF416579),
                      larguraTotal: true,
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

  String _formatarMedida(double valor) => valor % 1 == 0
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

  Widget _infoFaixa(
    String titulo,
    String valor,
    Color cor, {
    bool alinhamentoDireita = false,
    bool larguraTotal = false,
  }) {
    return Align(
      alignment: larguraTotal
          ? Alignment.centerLeft
          : (alinhamentoDireita ? Alignment.centerRight : Alignment.centerLeft),
      child: Container(
        width: larguraTotal ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: cor,
        child: Text(
          '$titulo  $valor',
          maxLines: larguraTotal ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _shareAction(BuildContext context, CampoArena campo) => Material(
    color: Colors.black.withValues(alpha: 0.58),
    borderRadius: BorderRadius.circular(10),
    child: IconButton(
      tooltip: 'Compartilhar campo ${campo.nome}',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      iconSize: 18,
      color: Colors.white,
      icon: const Icon(Icons.share_outlined),
      onPressed: () async {
        unawaited(HapticFeedback.selectionClick());
        final renderObject = context.findRenderObject();
        final origin = renderObject is RenderBox && renderObject.hasSize
            ? renderObject.localToGlobal(Offset.zero) & renderObject.size
            : null;
        try {
          await SharePlus.instance.share(
            ShareParams(
              title: campo.nome,
              text: [
                campo.nome,
                if (campo.enderecoCompleto.isNotEmpty)
                  'Endereço: ${campo.enderecoCompleto}',
                'Tamanho: ${campo.quantidadePorLinha}x${campo.quantidadePorLinha}',
                'Piso: ${campo.tipoGrama.label}',
                if (campo.areaM2 != null)
                  'Área total: ${_formatarMedida(campo.areaM2!)} m²',
                'Conheça no aplicativo Peladeiros SA: https://peladeiros.app',
              ].join('\n'),
              sharePositionOrigin: origin,
            ),
          );
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Não foi possível compartilhar o campo: $error'),
            ),
          );
        }
      },
    ),
  );
}
