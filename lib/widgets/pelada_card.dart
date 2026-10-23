import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/enums.dart';
import '../models/pelada.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../screens/login_screen.dart';
import '../screens/participants_screen.dart';
import 'package:provider/provider.dart';

class PeladaCard extends StatelessWidget {
  final Pelada pelada;
  final VoidCallback? onTap;
  final bool highlighted;

  const PeladaCard({
    super.key,
    required this.pelada,
    this.onTap,
    this.highlighted = false,
  });

  Future<void> _confirmarParticipacao(
    BuildContext context,
    DataService dataService,
  ) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final bloqueado = dataService.isUsuarioBloqueadoParaPelada(
      peladaId: pelada.id,
      usuarioId: user.id,
    );
    if (bloqueado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta pelada não está disponível para você.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final participacao = await dataService.registrarParticipacao(
      peladaId: pelada.id,
      usuarioId: user.id,
      usuarioNome: user.nomeCompleto,
      usuarioApelido: user.apelido,
      usuarioIdade: user.idade,
      usuarioPosicaoPrincipal: user.posicaoPrincipal,
      usuarioFotoUrl: user.fotoUrl,
      status: StatusParticipacao.confirmada,
    );
    if (!context.mounted) return;

    if (participacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dataService.errorMessage ??
                'Não foi possível confirmar sua participação.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParticipantsScreen(peladaId: pelada.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dataService = Provider.of<DataService>(context, listen: false);
    final isDark = theme.brightness == Brightness.dark;

    final dateFmt = DateFormat('EEE, d/MM', 'pt_BR');
    final hora =
        '${pelada.horaInicio.hour.toString().padLeft(2, '0')}:${pelada.horaInicio.minute.toString().padLeft(2, '0')}';

    final progresso = pelada.progressoQuorum;
    final quorumCor = pelada.temQuorum
        ? AppColors.success
        : (progresso > 0.6 ? AppColors.warning : theme.colorScheme.error);

    final taxa = pelada.taxa > 0
        ? NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
          ).format(pelada.taxa)
        : 'GRATUITO';
    final taxaCor = pelada.taxa > 0 ? AppColors.secondary : AppColors.success;

    final statusColor = switch (pelada.status) {
      StatusPelada.ativa => AppColors.success,
      StatusPelada.suspensa => AppColors.warning,
      StatusPelada.bloqueada => AppColors.danger,
      StatusPelada.cancelada => AppColors.graphite3,
    };
    final chuteiraLabel = pelada.tiposChuteiraPermitidos.isNotEmpty
        ? (pelada.tiposChuteiraPermitidos.length == 1
              ? pelada.tiposChuteiraPermitidos.first.label
              : 'Várias chuteiras')
        : pelada.tipoChuteira.label;

    final bairro = pelada.bairro.trim();
    final cidadeEstado = pelada.estado.isNotEmpty
        ? '${pelada.cidade} - ${pelada.estado}'
        : pelada.cidade;

    return Consumer<DataService>(
      builder: (context, ds, _) {
        final fav = ds.isFavorito(pelada.id);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlphaSafe(
                alpha: isDark ? 0.55 : 0.72,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlphaSafe(alpha: 0.26)
                    : Colors.black.withAlphaSafe(alpha: 0.07),
                blurRadius: 18,
                spreadRadius: -5,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          foregroundDecoration: highlighted
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary, width: 3),
                )
              : null,
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Builder(
                          builder: (ctx) {
                            PeladaCapaFoto? escolhida;
                            if (pelada.fotoArena?.hasValidBytes == true) {
                              escolhida = pelada.fotoArena;
                            } else if (pelada.fotosCapa.isNotEmpty &&
                                pelada.fotosCapa.first.hasValidBytes) {
                              escolhida = pelada.fotosCapa.first;
                            } else if (pelada.fotoGalera?.hasValidBytes ==
                                true) {
                              escolhida = pelada.fotoGalera;
                            } else if (pelada.fotoBraseao?.hasValidBytes ==
                                true) {
                              escolhida = pelada.fotoBraseao;
                            }
                            if (escolhida == null) {
                              return Container(color: primary);
                            }
                            return Image.memory(
                              escolhida.bytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Container(color: primary),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withAlphaSafe(alpha: 0.46),
                                Colors.black.withAlphaSafe(alpha: 0.06),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pelada.nome,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlphaSafe(
                                        alpha: 0.82,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withAlphaSafe(
                                          alpha: 0.30,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      pelada.status.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _topChip(
                                    icon: Icons.calendar_month_outlined,
                                    text: dateFmt.format(pelada.dataInicio),
                                  ),
                                  const SizedBox(width: 8),
                                  _topChip(
                                    icon: Icons.schedule_outlined,
                                    text: hora,
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () =>
                                        dataService.toggleFavorito(pelada.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlphaSafe(
                                          alpha: 0.50,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        fav ? Icons.star : Icons.star_border,
                                        color: fav
                                            ? Colors.white
                                            : Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Builder(
                      builder: (context) {
                        final bool isClaro = !isDark;
                        final Color mascFundoClaro = Colors.white.withAlphaSafe(
                          alpha: 0.90,
                        );
                        final Color femFundoClaro = Colors.white.withAlphaSafe(
                          alpha: 0.90,
                        );
                        final Color mascBordaClaro = const Color(
                          0xFF90CAF9,
                        ).withAlphaSafe(alpha: 0.85);
                        final Color femBordaClaro = const Color(
                          0xFFF8BBD0,
                        ).withAlphaSafe(alpha: 0.90);
                        const Color mascFundoEscuro = Color(0xFFE3F2FD);
                        const Color femFundoEscuro = Color(0xFFFCE4EC);
                        const Color mascBordaEscuro = Color(0xFF90CAF9);
                        const Color femBordaEscuro = Color(0xFFF8BBD0);
                        final Color generoFundo;
                        final Color generoBorda;
                        final Color generoTexto;
                        if (pelada.categoriaGenero == CategoriaGenero.masc) {
                          generoFundo = isClaro
                              ? mascFundoClaro
                              : mascFundoEscuro;
                          generoBorda = isClaro
                              ? mascBordaClaro
                              : mascBordaEscuro;
                          generoTexto = const Color(0xFF0D47A1);
                        } else {
                          generoFundo = isClaro
                              ? femFundoClaro
                              : femFundoEscuro;
                          generoBorda = isClaro
                              ? femBordaClaro
                              : femBordaEscuro;
                          generoTexto = const Color(0xFF880E4F);
                        }
                        return Column(
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
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cidadeEstado,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (bairro.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          bairro,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: theme.hintColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (pelada.localArena
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          pelada.localArena.trim(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
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
                                        color: generoFundo,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: generoBorda,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            pelada.categoriaGenero ==
                                                    CategoriaGenero.masc
                                                ? Icons.male
                                                : Icons.female,
                                            size: 14,
                                            color: generoTexto,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            pelada.categoriaGenero.label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11.5,
                                              letterSpacing: 0.3,
                                              color: generoTexto,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: taxaCor.withAlphaSafe(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        taxa,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: taxaCor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 14,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${pelada.participantesConfirmados}/${pelada.quorumMaximoEfetivo}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: quorumCor,
                                                ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            pelada.temQuorum
                                                ? '• Quórum atingido'
                                                : 'confirmados',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: progresso,
                                          minHeight: 6,
                                          backgroundColor:
                                              theme.colorScheme.outlineVariant,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                quorumCor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppColors.warning,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      pelada.avaliacaoMedia > 0
                                          ? pelada.avaliacaoMedia
                                                .toStringAsFixed(1)
                                          : '—',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
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
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _chip(
                                  theme,
                                  pelada.modalidade.label,
                                  Icons.sports_soccer,
                                  primary,
                                ),
                                _chip(
                                  theme,
                                  chuteiraLabel,
                                  Icons.sports_soccer,
                                  AppColors.secondary,
                                ),
                                _chip(
                                  theme,
                                  pelada.categoria.label,
                                  Icons.group_outlined,
                                  AppColors.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _confirmarParticipacao(
                                  context,
                                  dataService,
                                ),
                                icon: const Icon(Icons.sports_soccer, size: 19),
                                label: const Text('Bora, eu vou!'),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 11,
                                  ),
                                  foregroundColor: primary,
                                  backgroundColor: primary.withAlphaSafe(
                                    alpha: 0.12,
                                  ),
                                  side: BorderSide(
                                    color: primary.withAlphaSafe(alpha: 0.28),
                                  ),
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _chip(ThemeData theme, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlphaSafe(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlphaSafe(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
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
        color: Colors.black.withAlphaSafe(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlphaSafe(alpha: 0.22)),
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
