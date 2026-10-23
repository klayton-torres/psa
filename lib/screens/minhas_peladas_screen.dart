import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:peladeiros_sa/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/enums.dart';
import '../models/pelada.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/profile_sports_rail_menu.dart';
import 'cadastro_pelada_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'pelada_detail_screen.dart';
import 'participants_screen.dart';
import 'campos_arenas_screen.dart';
import '../utils/profile_navigation_helper.dart';

class MinhasPeladasScreen extends StatefulWidget {
  const MinhasPeladasScreen({super.key});

  @override
  State<MinhasPeladasScreen> createState() => _MinhasPeladasScreenState();
}

class _MinhasPeladasScreenState extends State<MinhasPeladasScreen> {
  StreamSubscription<PeladaStatusChange>? _statusSub;
  String? _listeningUserId;

  Key? get _scaffoldKey => null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      _statusSub?.cancel();
      _statusSub = null;
      _listeningUserId = null;
      return;
    }
    if (_listeningUserId == user.id) return;

    final data = Provider.of<DataService>(context, listen: false);
    data.ensurePeladasRealtime(usuarioId: user.id);
    unawaited(data.carregarPeladas(usuarioId: user.id));
    _statusSub?.cancel();
    _listeningUserId = user.id;
    _statusSub = data.statusChanges.listen((event) {
      if (!mounted) return;
      if (event.organizadorId != user.id) return;
      final motivo = (event.motivo != null && event.motivo!.trim().isNotEmpty)
          ? '\nMotivo: ${event.motivo!.trim()}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status atualizado: ${event.peladaNome} → ${event.newStatus.label}$motivo',
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _confirmarExclusao(
    BuildContext context, {
    required DataService data,
    required String usuarioId,
    required String peladaId,
    required String peladaNome,
  }) async {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        var loading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Excluir pelada?'),
              content: Text(
                'Tem certeza que deseja excluir "$peladaNome"?\n\nEssa ação não pode ser desfeita.',
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
                          setState(() => loading = true);
                          final success = await data.excluirPelada(
                            peladaId: peladaId,
                            usuarioId: usuarioId,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context, success);
                        },
                  icon: loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: errorColor,
                          ),
                        )
                      : Icon(Icons.delete_outline, color: errorColor),
                  label: Text(
                    loading ? 'Excluindo...' : 'Excluir',
                    style: TextStyle(color: errorColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pelada excluída com sucesso.')),
      );
    } else if (ok == false && data.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(data.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<DataService>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Peladas'),
          centerTitle: true,
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          surfaceTintColor: theme.appBarTheme.surfaceTintColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 72, color: theme.hintColor),
                const SizedBox(height: 16),
                Text(
                  'Faça login para continuar',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Essa área é exclusiva para organizadores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.login_outlined),
                  label: const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final minhas =
        data.peladas.where((p) => p.organizadorId == user.id).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final dateFull = DateFormat('dd/MM/yyyy', 'pt_BR');

    final scheme = theme.colorScheme;
    final appBarPlusColor =
        theme.appBarTheme.actionsIconTheme?.color ??
        theme.appBarTheme.iconTheme?.color ??
        theme.appBarTheme.foregroundColor ??
        (theme.useMaterial3 ? scheme.onSurface : scheme.onPrimary);
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Minhas Peladas'),
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        surfaceTintColor: theme.appBarTheme.surfaceTintColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle:
            theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.appBarTheme.foregroundColor,
              fontSize: 20,
            ) ??
            TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.appBarTheme.foregroundColor,
              fontSize: 20,
            ),
        iconTheme: theme.appBarTheme.iconTheme,
        actionsIconTheme: theme.appBarTheme.actionsIconTheme,
        leading: Semantics(
          label: 'Voltar para tela inicial',
          button: true,
          hint: 'Retorna para a tela Home',
          child: Tooltip(
            message: 'Voltar',
            preferBelow: false,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: theme.appBarTheme.foregroundColor,
                size: 24,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                unawaited(HapticFeedback.selectionClick());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (r) => false,
                );
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CadastroPeladaScreen()),
            ),
            icon: Icon(Icons.add_circle_outline, color: appBarPlusColor),
            tooltip: 'Nova Pelada',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: minhas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_soccer, size: 72, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'Você ainda não cadastrou peladas',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie sua primeira pelada para começar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.hintColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CadastroPeladaScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova Pelada'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 110),
              itemCount: minhas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = minhas[i];
                PeladaCapaFoto? escolhida;
                if (p.fotoGalera?.hasValidBytes == true) {
                  escolhida = p.fotoGalera;
                } else if (p.fotoArena?.hasValidBytes == true) {
                  escolhida = p.fotoArena;
                } else if (p.fotosCapa.isNotEmpty &&
                    p.fotosCapa.first.hasValidBytes) {
                  escolhida = p.fotosCapa.first;
                } else if (p.fotoBraseao?.hasValidBytes == true) {
                  escolhida = p.fotoBraseao;
                }
                final hasPhoto = escolhida != null;
                final statusColor = switch (p.status) {
                  StatusPelada.ativa => theme.colorScheme.primary,
                  StatusPelada.suspensa => Colors.orange,
                  StatusPelada.bloqueada => theme.colorScheme.error,
                  StatusPelada.cancelada => theme.hintColor,
                };
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PeladaDetailScreen(peladaId: p.id),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 64,
                                  width: 64,
                                  child: hasPhoto
                                      ? Image.memory(
                                          escolhida.bytes,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: primary,
                                            child: Icon(
                                              Icons.sports_soccer,
                                              color: Colors.white.withAlphaSafe(
                                                alpha: 0.85,
                                              ),
                                              size: 28,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: primary,
                                          child: Icon(
                                            Icons.sports_soccer,
                                            color: Colors.white.withAlphaSafe(
                                              alpha: 0.85,
                                            ),
                                            size: 28,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nome,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${p.cidade} - ${p.estado}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: theme.hintColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${dateFull.format(p.dataInicio)} • ${p.horaInicio.hour.toString().padLeft(2, '0')}:${p.horaInicio.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _confirmarExclusao(
                                      context,
                                      data: data,
                                      usuarioId: user.id,
                                      peladaId: p.id,
                                      peladaNome: p.nome,
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Excluir',
                                    color: theme.colorScheme.error,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  IconButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CadastroPeladaScreen(pelada: p),
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Editar',
                                    color: AppColors.secondary,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlphaSafe(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    p.status.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'Clonar pelada',
                                  child: Tooltip(
                                    message: 'Clonar pelada',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          unawaited(
                                            HapticFeedback.selectionClick(),
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CadastroPeladaScreen(
                                                    pelada: p,
                                                    isClone: true,
                                                  ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary
                                                .withAlphaSafe(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: AppColors.secondary
                                                  .withAlphaSafe(alpha: 0.38),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.content_copy_outlined,
                                                color: AppColors.secondary,
                                                size: 14,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                'Clonar',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.secondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'Gerenciar participantes',
                                  child: Tooltip(
                                    message: 'Gerenciar participantes',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          unawaited(
                                            HapticFeedback.selectionClick(),
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ParticipantsScreen(
                                                    peladaId: p.id,
                                                  ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: scheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: scheme.onPrimaryContainer
                                                  .withAlphaSafe(alpha: 0.35),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.people_alt_outlined,
                                                color:
                                                    scheme.onPrimaryContainer,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Gerenciar',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      scheme.onPrimaryContainer,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
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
                  ),
                );
              },
            ),
      floatingActionButton: null,
      floatingActionButtonLocation: null,
      bottomNavigationBar: Builder(
        builder: (context) {
          final auth = context.watch<AuthService>();
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
            selectedIndex: -1,
            customCenterMenu: centerMenu ?? const SizedBox.shrink(),
            onTabSelected: (i) async {
              switch (i) {
                case 0:
                  final a = context.read<AuthService>();
                  if (a.isAuthenticated) {
                    try {
                      unawaited(HapticFeedback.selectionClick());
                      Navigator.push(
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
                  break;
                case 1:
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(initialTab: 1),
                      ),
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
                  break;
                case 2:
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.push(
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
                  break;
                case 3:
                  await navigateToProfile(context);
                  break;
              }
            },
            tipoFavoritoBadge: TipoFavoritoBadge.peladas,
          );
        },
      ),
    );
  }
}
