import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/campo_arena.dart';
import '../models/pelada.dart';
import '../services/data_service.dart';
import '../services/location_service.dart';
import '../widgets/horarios_disponiveis_table.dart';

class CampoDetailScreen extends StatelessWidget {
  final CampoArena campo;

  const CampoDetailScreen({super.key, required this.campo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final hintColor = theme.hintColor;
    final dateFmt = DateFormat('d/MM/yyyy \'às\' HH:mm');
    final temContato =
        campo.contato != null && campo.contato!.trim().isNotEmpty;
    final temLatLon =
        campo.latitude != null &&
        campo.longitude != null &&
        (campo.latitude != 0 || campo.longitude != 0);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            centerTitle: true,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: Text(
              campo.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(
                    builder: (_) {
                      final capa = campo.fotoCapa;
                      if (capa != null && capa.hasValidBytes) {
                        return Image.memory(
                          capa.bytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
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
                        );
                      }
                      return Container(
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
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.38),
                          Colors.black.withValues(alpha: 0.18),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 72, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                              ),
                            ),
                            child: const Icon(
                              Icons.stadium_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 15,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  campo.responsavelNome,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
                                  '${campo.cidade} - ${campo.estado}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Consumer<DataService>(
                      builder: (context, data, _) {
                        final favorito = data.isCampoFavorito(campo.id);
                        return Semantics(
                          button: true,
                          toggled: favorito,
                          label: favorito
                              ? 'Remover campo dos favoritos'
                              : 'Adicionar campo aos favoritos',
                          child: Tooltip(
                            message: favorito
                                ? 'Remover dos favoritos'
                                : 'Adicionar aos favoritos',
                            child: IconButton.filled(
                              onPressed: () async {
                                unawaited(HapticFeedback.selectionClick());
                                try {
                                  await data.toggleCampoFavorito(campo.id);
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
                              tooltip: favorito
                                  ? 'Remover dos favoritos'
                                  : 'Adicionar aos favoritos',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.48,
                                ),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(48, 48),
                              ),
                              icon: Icon(
                                favorito
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: favorito
                                    ? AppColors.secondaryColor
                                    : Colors.white,
                                size: 25,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  unawaited(HapticFeedback.selectionClick());
                },
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Compartilhar',
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
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
                            'Informações Principais',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dados essenciais do campo e do seu responsável.',
                            style: TextStyle(color: hintColor),
                          ),
                          const SizedBox(height: 12),
                          _infoBlock(
                            context,
                            icon: Icons.person_outline_rounded,
                            label: 'RESPONSÁVEL',
                            value: campo.responsavelNome,
                            primary: primary,
                          ),
                          if (temContato) ...[
                            const SizedBox(height: 10),
                            _infoBlock(
                              context,
                              icon: Icons.phone_in_talk_outlined,
                              label: 'CONTATO',
                              value: campo.contato!.trim(),
                              primary: primary,
                              action: Semantics(
                                button: true,
                                label: 'Ligar para ${campo.contato!.trim()}',
                                child: Tooltip(
                                  message: 'Ligar',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        unawaited(
                                          HapticFeedback.selectionClick(),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.phone_in_talk_outlined,
                                              size: 14,
                                              color: primary,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'LIGAR',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.6,
                                                color: primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap:
                          temLatLon || campo.enderecoCompleto.trim().isNotEmpty
                          ? () async {
                              unawaited(HapticFeedback.selectionClick());
                              final coords = await _resolverCoordenadasCampo(
                                campo,
                              );
                              if (!context.mounted) return;
                              await _abrirModalMapa(
                                context,
                                coords: coords,
                                endereco: campo.enderecoCompleto,
                                bairro: campo.bairro,
                                cidade: campo.cidade,
                                estado: campo.estado,
                              );
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 22,
                                  color: primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Localização',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                if (temLatLon ||
                                    campo.enderecoCompleto
                                        .trim()
                                        .isNotEmpty) ...[
                                  Icon(
                                    Icons.open_in_new_outlined,
                                    size: 18,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Abrir no Maps',
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withAlphaSafe(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primary.withAlphaSafe(alpha: 0.28),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_city_outlined,
                                    color: primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${campo.cidade} / ${campo.estado}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (campo.enderecoCompleto.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: hintColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      campo.enderecoCompleto,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/images/mapfundo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                  color: scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
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
                                  'Informações Técnicas',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _cardTecnicaResumo(
                                  context,
                                  icon: Icons.grass_rounded,
                                  label: 'Tipo de Grama / Piso',
                                  values: [campo.tipoGrama.label],
                                  primary: primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: _cardTecnicaResumo(
                                  context,
                                  icon: Icons.straighten_rounded,
                                  label: 'Medidas',
                                  values: [
                                    if (campo.larguraMetros != null &&
                                        campo.profundidadeMetros != null)
                                      '${_formatarMedida(campo.larguraMetros!)}x${_formatarMedida(campo.profundidadeMetros!)}'
                                    else
                                      '—',
                                    campo.areaM2 == null
                                        ? '—'
                                        : '${_formatarMedida(campo.areaM2!)}m²',
                                  ],
                                  primary: primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: _cardTecnicaResumo(
                                  context,
                                  icon: Icons.sports_mma_outlined,
                                  label: 'Quant. na Linha',
                                  values: [
                                    '${campo.quantidadePorLinha}x${campo.quantidadePorLinha}',
                                  ],
                                  primary: primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: _cardTecnicaResumo(
                                  context,
                                  icon: Icons.groups_2_outlined,
                                  label: 'Capac. de Público',
                                  values: [
                                    campo.capacidadePublico == null
                                        ? '—'
                                        : '${campo.capacidadePublico}',
                                  ],
                                  primary: primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _chipsSection(
                            context,
                            icon: Icons.sports_soccer_outlined,
                            label: 'CALÇADOS PERMITIDOS',
                            items: campo.calcadosPermitidos
                                .map((e) => e.label)
                                .toList(),
                            emptyLabel: 'Nenhum informado',
                            primary: primary,
                            onSurface: onSurface,
                            onSurfaceVariant: onSurfaceVariant,
                          ),
                          const SizedBox(height: 14),
                          _chipsSection(
                            context,
                            icon: Icons.other_houses_outlined,
                            label: 'DEPENDÊNCIAS',
                            items: campo.dependencias
                                .map((e) => e.label)
                                .toList(),
                            emptyLabel: 'Nenhuma selecionada',
                            primary: primary,
                            onSurface: onSurface,
                            onSurfaceVariant: onSurfaceVariant,
                          ),
                          const SizedBox(height: 14),
                          _chipsSection(
                            context,
                            icon: Icons.checklist_rtl_rounded,
                            label: 'CORTESIAS',
                            items: campo.itensOpcionais
                                .map((e) => e.label)
                                .toList(),
                            emptyLabel: 'Nenhum selecionado',
                            primary: primary,
                            onSurface: onSurface,
                            onSurfaceVariant: onSurfaceVariant,
                          ),
                          const SizedBox(height: 14),
                          _chipsSection(
                            context,
                            icon: Icons.price_check_outlined,
                            label: 'OPCIONAIS (CONSULTAR TAXAS)',
                            items: campo.opcionaisConsultarTaxas
                                .map((e) => e.label)
                                .toList(),
                            emptyLabel: 'Nenhum selecionado',
                            primary: primary,
                            onSurface: onSurface,
                            onSurfaceVariant: onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildAlbumFotos(
                    context,
                    primary: primary,
                    scheme: scheme,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.70),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                color: primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Horários disponíveis',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Consulte a disponibilidade com o responsável.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          HorariosDisponiveisTable(
                            horariosSelecionados: campo.horariosDisponiveis,
                            mostrarAviso: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.70),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_available_outlined,
                                color: onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Registro',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _tecnicaBlock(
                                  context,
                                  icon: Icons.event_available_outlined,
                                  label: 'CADASTRADO EM',
                                  value: dateFmt.format(
                                    campo.createdAt.toLocal(),
                                  ),
                                  primary: primary,
                                  stackVertically: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _tecnicaBlock(
                                  context,
                                  icon: Icons.update_outlined,
                                  label: 'ATUALIZADO EM',
                                  value: dateFmt.format(
                                    campo.updatedAt.toLocal(),
                                  ),
                                  primary: primary,
                                  stackVertically: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Semantics(
                          button: true,
                          label: 'Voltar para a lista de campos',
                          child: Tooltip(
                            message: 'Voltar',
                            child: OutlinedButton(
                              onPressed: () {
                                unawaited(HapticFeedback.selectionClick());
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(51.2),
                                padding: EdgeInsets.zero,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: Semantics(
                          button: true,
                          label: 'Como chegar ao campo ${campo.nome}',
                          child: Tooltip(
                            message: 'Abrir localização',
                            child: FilledButton.icon(
                              onPressed:
                                  (temLatLon ||
                                      campo.enderecoCompleto.trim().isNotEmpty)
                                  ? () async {
                                      unawaited(
                                        HapticFeedback.selectionClick(),
                                      );
                                      final coords =
                                          await _resolverCoordenadasCampo(
                                            campo,
                                          );
                                      if (!context.mounted) return;
                                      if (coords == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                              'Não foi possível localizar as coordenadas deste endereço.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final ok =
                                          await LocationService.abrirGoogleMaps(
                                            coords,
                                          );
                                      if (!ok && context.mounted) {
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
                              icon: const Icon(
                                Icons.directions_outlined,
                                size: 20,
                              ),
                              label: const Text(
                                'COMO CHEGAR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(51.2),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                backgroundColor: primary,
                                foregroundColor: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color primary,
    Widget? action,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final vazio = value.trim().isEmpty;
    return Semantics(
      label: '$label: ${vazio ? 'não informado' : value}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w900,
                      color: onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vazio ? '—' : value,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: vazio
                          ? onSurfaceVariant.withValues(alpha: 0.70)
                          : onSurface,
                      height: 1.2,
                    ),
                  ),
                  if (action != null) ...[const SizedBox(height: 6), action],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tecnicaBlock(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subLabel,
    required Color primary,
    bool stackVertically = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final vazio = value.trim().isEmpty;

    final iconWidget = Container(
      width: stackVertically ? 40 : 32,
      height: stackVertically ? 40 : 32,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(stackVertically ? 12 : 10),
      ),
      child: Icon(icon, size: stackVertically ? 20 : 17, color: primary),
    );

    final textosWidget = Column(
      crossAxisAlignment: stackVertically
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: stackVertically ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w900,
            color: onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          vazio ? '—' : value,
          textAlign: stackVertically ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: vazio ? onSurfaceVariant.withValues(alpha: 0.70) : onSurface,
            height: 1.2,
          ),
        ),
        if (subLabel != null) ...[
          const SizedBox(height: 3),
          Text(
            subLabel,
            textAlign: stackVertically ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ],
      ],
    );

    Widget filho;
    if (stackVertically) {
      filho = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 10),
          Flexible(child: textosWidget),
        ],
      );
    } else {
      filho = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(width: 10),
          Expanded(child: textosWidget),
        ],
      );
    }

    return Semantics(
      label: '$label: ${vazio ? 'não informado' : value}',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          12,
          stackVertically ? 16 : 12,
          12,
          stackVertically ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary.withValues(alpha: 0.24),
            width: 1.0,
          ),
        ),
        child: filho,
      ),
    );
  }

  Widget _cardTecnicaResumo(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<String> values,
    required Color primary,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: ${values.join(', ')}',
      child: Container(
        height: 158,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(3, 10, 3, 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.28)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 23, color: primary),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 34,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            for (var i = 0; i < values.length; i++) ...[
              if (i > 0) const SizedBox(height: 2),
              Text(
                values[i],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: i == 0 ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontSize: i == 0 ? 12.5 : 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatarMedida(double valor) =>
      NumberFormat('0.##', 'pt_BR').format(valor);

  Widget _chipsSection(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<String> items,
    required String emptyLabel,
    required Color primary,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: ${items.isEmpty ? emptyLabel : items.join(', ')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w900,
                  color: onSurfaceVariant.withValues(alpha: 0.90),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: Text(
                emptyLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (e) => Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.90),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              e,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumFotos(
    BuildContext context, {
    required Color primary,
    required ColorScheme scheme,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    final fotos = campo.fotos.where((f) => f.hasValidBytes).toList();
    if (fotos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label:
          'Álbum de fotos do campo. ${fotos.length} foto(s) disponível(eis).',
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: primary.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library_outlined, size: 20, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fotos do Campo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${fotos.length} ${fotos.length == 1 ? 'foto' : 'fotos'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final crossCount = fotos.length == 1 ? 1 : 3;
                  final espacamento = 10.0;
                  final larguraTotal = constraints.maxWidth;
                  final larguraFoto =
                      (larguraTotal - espacamento * (crossCount - 1)) /
                      crossCount;
                  final alturaFoto = fotos.length == 1
                      ? larguraFoto * 0.56
                      : larguraFoto;
                  return Wrap(
                    spacing: espacamento,
                    runSpacing: espacamento,
                    children: [
                      for (int i = 0; i < fotos.length; i++)
                        Builder(
                          builder: (ctx) {
                            final foto = fotos[i];
                            final ehCapa =
                                campo.fotoCapa != null &&
                                foto.base64Data == campo.fotoCapa!.base64Data;
                            return SizedBox(
                              width: larguraFoto,
                              height: alturaFoto,
                              child: _buildFotoAlbumItem(
                                context,
                                foto: foto,
                                index: i,
                                isCapa: ehCapa,
                                primary: primary,
                                scheme: scheme,
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFotoAlbumItem(
    BuildContext context, {
    required PeladaCapaFoto foto,
    required int index,
    required bool isCapa,
    required Color primary,
    required ColorScheme scheme,
  }) {
    return Semantics(
      button: true,
      label:
          'Foto ${index + 1}. ${isCapa ? 'Foto de capa do campo. ' : ''}Toque para ampliar.',
      child: Tooltip(
        message: isCapa ? 'Foto de capa (amplicar)' : 'Amplicar foto',
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              _abrirFotoAmpliada(context, foto: foto, index: index);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCapa
                          ? primary
                          : scheme.outlineVariant.withValues(alpha: 0.80),
                      width: isCapa ? 2.0 : 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    foto.bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
                if (isCapa)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera_front_rounded,
                            size: 12,
                            color: scheme.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CAPA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: scheme.onPrimary,
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
    );
  }

  Future<void> _abrirFotoAmpliada(
    BuildContext context, {
    required PeladaCapaFoto foto,
    required int index,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (ctxDialog) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            label: 'Foto ${index + 1} ampliada',
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              ctxDialog,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.zoom_out_map_rounded,
                            size: 16,
                            color: Theme.of(ctxDialog).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Foto ${index + 1}',
                            style: Theme.of(ctxDialog).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Fechar foto ampliada',
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
                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(ctxDialog).dividerColor,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Image.memory(
                          foto.bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Container(
                            width: double.infinity,
                            height: 250,
                            color: Theme.of(
                              ctxDialog,
                            ).colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 42,
                                    color: Theme.of(ctxDialog).hintColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Não foi possível carregar a imagem.',
                                    style: TextStyle(
                                      color: Theme.of(ctxDialog).hintColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }
}

Future<Coordenadas?> _resolverCoordenadasCampo(CampoArena campo) async {
  final latitude = campo.latitude;
  final longitude = campo.longitude;
  if (latitude != null &&
      longitude != null &&
      (latitude != 0 || longitude != 0)) {
    return Coordenadas(latitude, longitude);
  }

  if (campo.enderecoCompleto.trim().isEmpty) return null;
  try {
    return await LocationService.geocodificarEndereco(
      endereco: campo.rua,
      numero: campo.numero,
      bairro: campo.bairro,
      cidade: campo.cidade,
      estado: campo.estado,
      localArena: campo.nome,
      cep: campo.cep,
    );
  } catch (_) {
    return null;
  }
}

Future<void> _abrirModalMapa(
  BuildContext context, {
  required Coordenadas? coords,
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
          label: 'Modal com o mapa da localização do campo',
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: primario.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: primario,
                        ),
                      ),
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
                      child: Image.asset(
                        'assets/images/mapfundo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.expand(),
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
                          label: 'Abrir coordenadas no Google Maps',
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
