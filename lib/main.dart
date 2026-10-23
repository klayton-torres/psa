import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_preferences_service.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';

const _kBootstrapTimeout = Duration(seconds: 8);

Future<AppPreferencesService> _bootstrapPreferences() async {
  final prefs = AppPreferencesService();
  try {
    await prefs.init().timeout(_kBootstrapTimeout);
    return prefs;
  } on TimeoutException {
    debugPrint(
      '[Bootstrap] prefs.init() excedeu tempo limite '
      '(${_kBootstrapTimeout.inSeconds}s). Iniciando com padrões.',
    );
  } catch (e, st) {
    debugPrint('[Bootstrap] prefs.init() falhou (usando padrões): $e');
    debugPrintStack(label: 'Prefs init stack', stackTrace: st);
  }
  return prefs;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const _BootstrapLoadingScreen());
  try {
    const splashMinDuration = Duration(seconds: 5);
    final splashTimer = Future<void>.delayed(splashMinDuration);

    Future<void> initFuture;
    if (AppConstants.hasSupabaseConfigured) {
      initFuture = () async {
        try {
          await Supabase.initialize(
            url: AppConstants.supabaseUrl,
            publishableKey: AppConstants.supabaseAnonKey,
            debug: false,
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Supabase init falhou (modo demo/local): $e');
        }
      }();
    } else {
      debugPrint(
        'Modo demo ativado: Supabase não configurado. '
        'Defina SUPABASE_URL e SUPABASE_ANON_KEY para habilitar integração.',
      );
      initFuture = Future.value();
    }

    final prefsFuture = _bootstrapPreferences();

    await Future.wait([splashTimer, initFuture, prefsFuture]);
    final prefs = await prefsFuture;
    runApp(PeladeirosApp(prefs: prefs));
  } catch (e, st) {
    debugPrint('[Bootstrap] ERRO CRÍTICO (iniciando com fallback): $e');
    debugPrintStack(label: 'Bootstrap stack', stackTrace: st);
    final fallbackPrefs = AppPreferencesService();
    runApp(PeladeirosApp(prefs: fallbackPrefs));
  }
}

class PeladeirosApp extends StatelessWidget {
  final AppPreferencesService prefs;
  const PeladeirosApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppPreferencesService>.value(value: prefs),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<DataService>(create: (_) => DataService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final scale = themeProvider.textScaleFactor;
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: themeProvider.currentTheme,
              builder: (context, child) => LayoutBuilder(
                builder: (context, constraints) {
                  final theme = themeProvider.currentTheme;
                  final canvas = theme.canvasColor;
                  final largura = constraints.maxWidth;
                  final larguraApp = kIsWeb
                      ? largura.clamp(0.0, 1360.0).toDouble()
                      : largura;
                  final webComMargem = kIsWeb && largura > larguraApp;
                  return ColoredBox(
                    color: canvas,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.575,
                          colors: [
                            Colors.transparent,
                            theme.colorScheme.primary.withValues(
                              alpha: themeProvider.isDarkMode ? 0.20 : 0.14,
                            ),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: larguraApp,
                          height: constraints.maxHeight,
                          decoration: BoxDecoration(
                            border: webComMargem
                                ? Border.symmetric(
                                    vertical: BorderSide(
                                      color: theme.dividerColor.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  )
                                : null,
                            boxShadow: webComMargem
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: themeProvider.isDarkMode
                                            ? 0.20
                                            : 0.045,
                                      ),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Theme(
                            data: theme.copyWith(
                              scaffoldBackgroundColor: Colors.transparent,
                            ),
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              home: const AuthGate(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
              locale: const Locale('pt', 'BR'),
            ),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _authTimeout;
  bool _authTimedOut = false;
  static const _kAuthTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _authTimeout = Timer(_kAuthTimeout, () {
      if (mounted) {
        setState(() => _authTimedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _authTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.initialized) {
      _authTimeout?.cancel();
      return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                CircularProgressIndicator(color: theme.colorScheme.primary),
                const SizedBox(height: 18),
                Text(
                  _authTimedOut
                      ? 'Está demorando mais que o esperado...'
                      : 'Carregando dados do aplicativo...',
                  textAlign: TextAlign.center,
                ),
                if (_authTimedOut) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Verifique sua conexão ou continue utilizando o modo off-line.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () {
                          final svc = context.read<AuthService>();
                          svc.forceInitialized();
                          svc.setLoading(false);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          });
                        },
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Continuar'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00BFA6), Color(0xFF00897B), Color(0xFF00695C)],
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer, size: 92, color: Colors.white),
                  SizedBox(height: 24),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sempre há uma Pelada perto de você!',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3.5,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Inicializando...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
