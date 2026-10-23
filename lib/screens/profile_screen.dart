import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/app_preferences_service.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../utils/profile_avatar_helper.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _carregando = false;
  String? _erro;
  Uint8List? _avatarBytes;
  final ImageService _imageService = ImageService();

  Uint8List? get cacheAvatar2 => null;

  Future<void> _alterarAvatar(UserProfile user) async {
    try {
      await _imageService.showAvatarPicker(
        context,
        onSelecionada: (res) async {
          try {
            final auth = context.read<AuthService>();
            final cropped = ProfileAvatarHelper.cropSquare(res.bytes);
            await auth.updateProfileAvatar(
              croppedJpegBytes: cropped,
              thumbnailJpegBytes: ProfileAvatarHelper.generateThumbnail(
                cropped,
              ),
            );
            if (mounted) setState(() => _avatarBytes = cropped);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Foto de perfil atualizada!'),
                ),
              );
            }
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Erro ao salvar foto: $e'),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Erro ao selecionar foto: $e'),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthService>();
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false,
          );
        }
      });
    }
  }

  Future<void> _carregarPerfil() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final auth = context.read<AuthService>();
      if (auth.currentUser == null) {
        throw Exception('Sessão expirou. Faça login novamente.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Erro ao carregar perfil: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final prefs = context.watch<AppPreferencesService>();
    final Uint8List? cacheAvatar;
    if (user?.id.trim().isNotEmpty == true) {
      var newVariable = prefs.getAvatarCache(user!.id.trim());
      var newVariable2 = newVariable;
      // cacheAvatar = newVariable2;
    } else {
      cacheAvatar = null;
    }
    final scheme = theme.colorScheme;

    //   var cacheAvatar4 = cacheAvatar;
    //   var cacheAvatar3 = cacheAvatar4;
    //   var cacheAvatar2 = cacheAvatar3;
    return Scaffold(
      key: const ValueKey('profile-screen'),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Voltar',
              )
            : null,
        title: Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.15),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        surfaceTintColor: theme.appBarTheme.surfaceTintColor,
      ),
      body: RefreshIndicator(
        onRefresh: _carregarPerfil,
        color: scheme.primary,
        child: _carregando && user == null
            ? Center(child: CircularProgressIndicator(color: scheme.primary))
            : user == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Nenhum usuário logado.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                children: [
                  _HeaderIdentificacao(
                    key: const ValueKey('profile-avatar-button'),
                    user: user,
                    avatarBytes: _avatarBytes,
                    cacheAvatarBytes: cacheAvatar2,
                    onAlterarAvatar: () => _alterarAvatar(user),
                  ),
                  const SizedBox(height: 20),
                  _SecaoIdentificacao(user: user),
                  const SizedBox(height: 24),
                  _SecaoPerfilAtleta(user: user),
                  const SizedBox(height: 28),
                  _BotoesAcao(
                    onEditar: _editarPerfil,
                    onVoltar: _voltarParaHome,
                    onSair: () => _confirmarLogout(context, auth),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Aviso: $_erro',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _editarPerfil() async {
    try {
      unawaited(HapticFeedback.selectionClick());
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível abrir edição: $e'),
        ),
      );
    }
  }

  void _voltarParaHome() {
    unawaited(HapticFeedback.selectionClick());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _confirmarLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da Conta?'),
        content: const Text('Tem certeza que deseja desconectar sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          Builder(
            builder: (ctxDialog) {
              final dialogScheme = Theme.of(ctxDialog).colorScheme;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dialogScheme.error,
                  foregroundColor: dialogScheme.onError,
                ),
                onPressed: () async {
                  try {
                    Navigator.pop(ctx);
                    unawaited(HapticFeedback.lightImpact());
                    await auth.signOut();
                    if (ctx.mounted) {
                      Navigator.of(ctx).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false,
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Erro ao sair: $e'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sair'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderIdentificacao extends StatelessWidget {
  final UserProfile user;
  final Uint8List? avatarBytes;
  final Uint8List? cacheAvatarBytes;
  final VoidCallback onAlterarAvatar;
  const _HeaderIdentificacao({
    super.key,
    required this.user,
    required this.onAlterarAvatar,
    this.avatarBytes,
    this.cacheAvatarBytes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iniciais =
        '${user.primeiroNome.isNotEmpty ? user.primeiroNome[0] : ''}'
                '${user.sobrenome.isNotEmpty ? user.sobrenome[0] : ''}'
            .toUpperCase();
    final temUrl =
        user.fotoUrl != null &&
        user.fotoUrl!.trim().isNotEmpty &&
        !user.fotoUrl!.trim().startsWith('memory:');
    return Semantics(
      label: 'Alterar foto de perfil',
      button: true,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(60),
            onTap: onAlterarAvatar,
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: scheme.surface, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (avatarBytes != null)
                            Image.memory(
                              avatarBytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _IniciaisBadge(iniciais: iniciais),
                            )
                          else if (temUrl)
                            Image.network(
                              user.fotoUrl!,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) {
                                if (cacheAvatarBytes != null) {
                                  return Image.memory(
                                    cacheAvatarBytes!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _IniciaisBadge(iniciais: iniciais),
                                  );
                                }
                                return _IniciaisBadge(iniciais: iniciais);
                              },
                            )
                          else if (cacheAvatarBytes != null)
                            Image.memory(
                              cacheAvatarBytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _IniciaisBadge(iniciais: iniciais),
                            )
                          else
                            _IniciaisBadge(iniciais: iniciais),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.24),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: scheme.onPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.nomeCompleto.isEmpty ? 'Usuário' : user.nomeCompleto,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if ((user.apelido ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '“${user.apelido}”',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IniciaisBadge extends StatelessWidget {
  final String iniciais;
  const _IniciaisBadge({required this.iniciais});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        iniciais.isEmpty ? 'U' : iniciais,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SecaoIdentificacao extends StatelessWidget {
  final UserProfile user;
  const _SecaoIdentificacao({required this.user});

  @override
  Widget build(BuildContext context) {
    return _SecaoCard(
      key: const ValueKey('secao-identificacao'),
      title: 'Identificação',
      icon: Icons.badge_outlined,
      children: [
        _InfoLinha(
          rotulo: 'Nome',
          valor: user.nomeCompleto.isEmpty
              ? 'Não informado'
              : user.nomeCompleto,
        ),
        _InfoLinha(
          rotulo: 'Apelido',
          valor: (user.apelido ?? '').isEmpty ? '—' : user.apelido!,
        ),
        _InfoLinha(
          rotulo: 'Nascimento',
          valor: user.dataNascimento == null
              ? '—'
              : '${user.dataNascimento!.day.toString().padLeft(2, '0')}/'
                    '${user.dataNascimento!.month.toString().padLeft(2, '0')}/'
                    '${user.dataNascimento!.year}'
                    '${user.idade != null ? '  ·  ${user.idade} anos' : ''}',
        ),
        _InfoLinha(
          rotulo: 'Telefone',
          valor: (user.telefone ?? '').isEmpty ? '—' : user.telefone!,
        ),
        _InfoLinha(
          rotulo: 'E-mail',
          valor: (user.email ?? '').isEmpty ? '—' : user.email!,
        ),
        if ((user.cidade ?? '').isNotEmpty || (user.estado ?? '').isNotEmpty)
          _InfoLinha(
            rotulo: 'Localização',
            valor: [
              user.cidade,
              user.estado,
            ].where((e) => (e ?? '').isNotEmpty).join(' / '),
          ),
      ],
    );
  }
}

class _SecaoPerfilAtleta extends StatelessWidget {
  final UserProfile user;
  const _SecaoPerfilAtleta({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    return _SecaoCard(
      key: const ValueKey('secao-perfil-atleta'),
      title: 'Perfil do Atleta',
      icon: Icons.sports_soccer_outlined,
      children: [
        if (user.modalidadesPraticadas.isNotEmpty) ...[
          _InfoLinha(
            rotulo: 'Modalidades',
            valor: user.modalidadesPraticadas.map((e) => e.label).join(' · '),
          ),
        ],
        if (user.posicaoPrincipal != null) ...[
          const SizedBox(height: 4),
          _InfoLinha(
            rotulo: 'Posição',
            valor:
                [
                  user.posicaoPrincipal?.label,
                  user.posicaoAlternativa?.label,
                ].where((e) => (e ?? '').isNotEmpty).join('  ·  ').isEmpty
                ? '—'
                : [
                    user.posicaoPrincipal?.label,
                    user.posicaoAlternativa?.label,
                  ].where((e) => (e ?? '').isNotEmpty).join('  ·  '),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  'Chuteira',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (ctx) {
                        final pts = user.pontuacaoChuteira;
                        const double kMinPts = 30.0;
                        const double kMaxPts = 45.0;
                        const double kCmPorPonto = 0.66;
                        if (pts < kMinPts || pts > kMaxPts) {
                          return Text(
                            'Tamanho não informado',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        final cm = pts * kCmPorPonto;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${pts.toInt()}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'pts',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '≈ ${cm.toStringAsFixed(2)} cm',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: onSurface,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tamanho da chuteira (BR)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _InfoMiniCard(
                rotulo: 'Altura',
                valor: '${(user.altura ?? 0).toStringAsFixed(2)} m',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoMiniCard(
                rotulo: 'Peso',
                valor: '${(user.peso ?? 0).toStringAsFixed(1)} kg',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoMiniCard(
                rotulo: 'IMC',
                valor:
                    (user.altura != null &&
                        user.peso != null &&
                        user.altura! > 0)
                    ? (user.peso! / (user.altura! * user.altura!))
                          .toStringAsFixed(1)
                    : '—',
              ),
            ),
          ],
        ),
        if (user.marcasChuteiraFavoritas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Marcas de chuteira favoritas',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: user.marcasChuteiraFavoritas
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      m,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _BotoesAcao extends StatelessWidget {
  final Future<void> Function() onEditar;
  final VoidCallback onVoltar;
  final VoidCallback onSair;
  const _BotoesAcao({
    required this.onEditar,
    required this.onVoltar,
    required this.onSair,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const ValueKey('profile-btn-edit'),
            onPressed: onEditar,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              'Editar perfil',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('profile-btn-voltar-home'),
                onPressed: onVoltar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('profile-btn-logout'),
                onPressed: onSair,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.logout_outlined),
                label: Text(
                  'Sair da conta',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecaoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SecaoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final String rotulo;
  final String valor;
  const _InfoLinha({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              rotulo,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMiniCard extends StatelessWidget {
  final String rotulo;
  final String valor;
  const _InfoMiniCard({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvaliacaoEstrelas extends StatelessWidget {
  final double pontuacao;
  const _AvaliacaoEstrelas({required this.pontuacao});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starIndex = (i + 1).toDouble();
        IconData icon;
        if (pontuacao >= starIndex) {
          icon = Icons.star_rounded;
        } else if (pontuacao >= starIndex - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: 22, color: scheme.tertiary);
      }),
    );
  }
}
