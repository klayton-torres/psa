import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/minhas_peladas_screen.dart';
import '../screens/campos_arenas_screen.dart';
import '../screens/juizes_screen.dart';
import '../screens/goleiros_screen.dart';
import '../screens/mapa_screen.dart';
import '../services/app_preferences_service.dart';
import '../services/auth_service.dart';
import '../utils/profile_navigation_helper.dart';

Widget _avatarChild(String? fotoUrl, Color primary) {
  if (fotoUrl == null || fotoUrl.isEmpty) {
    return Icon(Icons.person, color: primary, size: 30);
  }
  final radius = BorderRadius.circular(30);
  if (fotoUrl.startsWith('data:')) {
    final comma = fotoUrl.indexOf(',');
    if (comma <= 0) return const Icon(Icons.broken_image_outlined);
    try {
      final bytes = Base64Decoder().convert(fotoUrl.substring(comma + 1));
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    } catch (_) {
      return Icon(Icons.person, color: primary, size: 30);
    }
  }
  return ClipRRect(
    borderRadius: radius,
    child: Image.network(
      fotoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Icon(Icons.person, color: primary, size: 30),
    ),
  );
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    final user = authService.currentUser;
    final scalePct = themeProvider.textScalePctInt;
    final canAumentar =
        themeProvider.textScaleFactor <
        AppPreferencesService.maxTextScale - 0.001;
    final canDiminuir =
        themeProvider.textScaleFactor >
        AppPreferencesService.minTextScale + 0.001;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withAlphaSafe(
                      alpha: 0.15,
                    ),
                    child: _avatarChild(
                      user?.fotoUrl,
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nomeCompleto ?? 'Visitante',
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? 'Faça login para continuar',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 8, endIndent: 8),
            const SizedBox(height: 6),
            ListTile(
              leading: Icon(
                Icons.home_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Home'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 2),
            if (user != null) ...[
              ListTile(
                leading: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Meu Perfil'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await navigateToProfile(context);
                },
              ),
              const SizedBox(height: 2),

              ListTile(
                leading: Icon(
                  Icons.event_note_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Minhas Peladas'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MinhasPeladasScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              ListTile(
                leading: Icon(
                  Icons.stadium_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Campos e Arenas'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CamposArenasScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              ListTile(
                leading: Icon(
                  Icons.sports_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Juízes'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JuizesScreen()),
                  );
                },
              ),
              const SizedBox(height: 2),
              ListTile(
                leading: Icon(
                  Icons.sports_handball_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Goleiros'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoleirosScreen()),
                  );
                },
              ),
              const SizedBox(height: 2),
              ListTile(
                leading: Icon(
                  Icons.map_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Mapa'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapaScreen()),
                  );
                },
              ),
              const SizedBox(height: 2),
            ],
            ListTile(
              leading: Icon(
                Icons.palette_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Tema de Cores'),
              subtitle: Text(themeProvider.currentThemeName),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(themeProvider.paletteColors.length, (
                  i,
                ) {
                  final isSelected = i == themeProvider.themeIndex;
                  return Semantics(
                    label: 'Tema ${themeProvider.paletteNames[i]}',
                    selected: isSelected,
                    button: true,
                    hint:
                        'Toque duas vezes para aplicar o tema ${themeProvider.paletteNames[i]}.',
                    child: GestureDetector(
                      onTap: () => themeProvider.setThemeIndex(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: themeProvider.paletteColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? themeProvider.paletteColors[i]
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: themeProvider.paletteColors[i]
                                        .withAlphaSafe(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Semantics(
              toggled: themeProvider.isDarkMode,
              label: 'Modo Escuro',
              hint: 'Alternar entre os modos claro e escuro.',
              button: true,
              child: SwitchListTile(
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Modo Escuro'),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Ativado' : 'Desativado',
                ),
                value: themeProvider.isDarkMode,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onChanged: (_) => themeProvider.toggleDarkMode(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.text_fields_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tamanho da Fonte',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlphaSafe(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$scalePct%',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Diminuir fonte',
                      hint:
                          'Diminui o tamanho da fonte em 10%. '
                          'Mínimo 80%.',
                      button: true,
                      enabled: canDiminuir,
                      child: _TextScaleButton(
                        icon: Icons.remove,
                        label: 'Diminuir',
                        isEnabled: canDiminuir,
                        onPressed: themeProvider.diminuirFonte,
                        color: theme.colorScheme.onSurfaceVariant,
                        bg: theme.colorScheme.surfaceContainerHigh,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: 'Aumentar fonte',
                      hint:
                          'Aumenta o tamanho da fonte em 10%. '
                          'Máximo 120%.',
                      button: true,
                      enabled: canAumentar,
                      child: _TextScaleButton(
                        icon: Icons.add,
                        label: 'Aumentar',
                        isEnabled: canAumentar,
                        onPressed: themeProvider.aumentarFonte,
                        color: theme.colorScheme.primary,
                        bg: theme.colorScheme.primary.withAlphaSafe(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(indent: 8, endIndent: 8),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Sobre o App'),
              subtitle: const Text('Peladeiros S/A v1.0.0'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 4),
            if (user != null)
              ListTile(
                leading: const Icon(
                  Icons.logout_outlined,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Sair da Conta',
                  style: TextStyle(color: AppColors.danger),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => _confirmarLogout(context, authService),
              )
            else
              ListTile(
                leading: Icon(
                  Icons.login_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Entrar / Cadastrar',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmarLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da Conta?'),
        content: const Text('Tem certeza que deseja desconectar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _TextScaleButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final Future<bool> Function() onPressed;
  final Color color;
  final Color bg;

  const _TextScaleButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onPressed,
    required this.color,
    required this.bg,
  });

  @override
  State<_TextScaleButton> createState() => _TextScaleButtonState();
}

class _TextScaleButtonState extends State<_TextScaleButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: OutlinedButton.icon(
        icon: _loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              )
            : Icon(widget.icon, size: 18, color: widget.color),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            widget.label,
            style: TextStyle(color: widget.color, fontWeight: FontWeight.w800),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: widget.bg,
          disabledBackgroundColor: widget.bg.withAlphaSafe(alpha: 0.4),
          foregroundColor: widget.color,
          side: BorderSide(
            color: widget.color.withAlphaSafe(alpha: 0.55),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        ),
        onPressed: (widget.isEnabled && !_loading)
            ? () async {
                if (_loading) return;
                setState(() => _loading = true);
                try {
                  await widget.onPressed();
                  await HapticFeedback.lightImpact();
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              }
            : null,
      ),
    );
  }
}
