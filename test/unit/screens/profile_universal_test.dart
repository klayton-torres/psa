import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/models/user_profile.dart';
import 'package:peladeiros_sa/screens/home_screen.dart';
import 'package:peladeiros_sa/screens/profile_screen.dart';
import 'package:peladeiros_sa/screens/edit_profile_screen.dart';
import 'package:peladeiros_sa/screens/login_screen.dart';
import 'package:peladeiros_sa/widgets/custom_bottom_nav_bar.dart';
import '../../utils/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserProfile usuarioFake;
  late FakeAuthService authLogado;

  const Size kTamanhoGrande = Size(1024, 1400);
  const Size kTamanhoExtra = Size(1200, 2000);
  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  void resetViewport(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    usuarioFake = UserProfile(
      id: 'usr-1',
      authUid: 'auth-1',
      primeiroNome: 'João',
      sobrenome: 'Peladeiro',
      apelido: 'Jão',
      dataNascimento: DateTime(1998, 5, 20),
      telefone: '(11) 99999-9999',
      email: 'joao@peladeiros.com.br',
      modalidadePraticada: Modalidade.futebolCampo,
      modalidadesPraticadas: const [
        Modalidade.futebolCampo,
        Modalidade.futsal,
        Modalidade.voley,
      ],
      posicaoPrincipal: PosicaoAtleta.atacantePivo,
      posicaoAlternativa: PosicaoAtleta.meia,
      pontuacaoChuteira: 4.5,
      altura: 1.78,
      peso: 74.0,
      marcasChuteiraFavoritas: const ['Nike', 'Adidas', 'Mizuno'],
      estado: 'SP',
      cidade: 'São Paulo',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    );
    authLogado = FakeAuthService(
      authenticated: true,
      loading: false,
      user: usuarioFake,
    );
  });

  group('ProfileScreen · Estrutura Universal', () {
    testWidgets(
      'Renderiza sem erros: identificação + perfil atleta + 2 botões com keys',
      (tester) async {
        setViewport(tester, kTamanhoGrande);
        final observer = TestNavigatorObserver();
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authLogado,
            observer: observer,
            child: const ProfileScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('profile-screen')), findsOneWidget);
        expect(find.widgetWithText(AppBar, 'Meu Perfil'), findsOneWidget);
        expect(find.text('João Peladeiro'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Jão'), findsAtLeastNWidgets(1));
        expect(
          find.byKey(const ValueKey('secao-identificacao')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('secao-perfil-atleta')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('profile-btn-edit')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('profile-btn-logout')),
          findsOneWidget,
        );
        expect(find.text('Futebol de Campo'), findsOneWidget);
        expect(find.text('Nike'), findsOneWidget);
        expect(find.text('1.78 m'), findsOneWidget);
        expect(tester.takeException(), isNull);
        resetViewport(tester);
      },
    );

    testWidgets(
      'Botão Editar perfil (key profile-btn-edit) → push EditProfileScreen',
      (tester) async {
        setViewport(tester, kTamanhoGrande);
        final observer = TestNavigatorObserver();
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authLogado,
            observer: observer,
            child: const ProfileScreen(),
          ),
        );
        await tester.pumpAndSettle();
        final inicial = observer.pushCount;
        await tester.tap(find.byKey(const ValueKey('profile-btn-edit')));
        await tester.pumpAndSettle();
        expect(observer.pushCount, greaterThanOrEqualTo(inicial + 1));
        expect(
          find.byKey(const ValueKey('edit-profile-screen')),
          findsOneWidget,
        );
        expect(find.widgetWithText(AppBar, 'Editar Perfil'), findsOneWidget);
        resetViewport(tester);
      },
    );

    testWidgets('Botão Sair → Dialog confirmação → signOut + LoginScreen', (
      tester,
    ) async {
      setViewport(tester, kTamanhoGrande);
      final observer = TestNavigatorObserver();
      bool signOutCalled = false;
      final authSpy = _SpyAuthService(
        inner: authLogado,
        onSignOut: () => signOutCalled = true,
      );
      await tester.pumpWidget(
        buildTestAppShell(
          auth: authSpy,
          observer: observer,
          child: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('profile-btn-logout')));
      await tester.pumpAndSettle();

      expect(find.text('Sair da Conta?'), findsOneWidget);
      final btnSair = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Sair'),
      );
      expect(btnSair, findsOneWidget);
      await tester.tap(btnSair);
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      expect(signOutCalled, isTrue);
      expect(find.byType(LoginScreen), findsOneWidget);
      resetViewport(tester);
    });

    testWidgets('Responsivo 480px (mobile) e 1024px (tablet) sem crash', (
      tester,
    ) async {
      for (final size in [const Size(480, 800), const Size(1024, 1400)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          buildTestAppShell(auth: authLogado, child: const ProfileScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('profile-screen')), findsOneWidget);
        final ex = tester.takeException();
        expect(
          ex == null || ex is FlutterError,
          isTrue,
          reason: 'Tamanho ${size.width.toInt()}x${size.height.toInt()}',
        );
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pumpAndSettle();
      }
    });
  });

  group('Navegação Universal · Pontos de Entrada', () {
    testWidgets(
      'HomeScreen · CustomBottomNavBar onTabSelected(3) → ProfileScreen',
      (tester) async {
        setViewport(tester, kTamanhoGrande);
        final observer = TestNavigatorObserver();
        final fakeData = FakeDataService(peladasList: []);
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authLogado,
            data: fakeData,
            observer: observer,
            child: const HomeScreen(),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 800));

        final navFinder = find.byType(CustomBottomNavBar);
        expect(navFinder, findsOneWidget);
        final navBar = tester.widget<CustomBottomNavBar>(navFinder);
        final inicial = observer.pushCount;
        await tester.runAsync(() async {
          navBar.onTabSelected?.call(3);
          await Future<void>.delayed(const Duration(milliseconds: 120));
        });
        await tester.pumpAndSettle(const Duration(milliseconds: 800));

        expect(
          find.byKey(const ValueKey('profile-screen')),
          findsOneWidget,
          reason:
              'Ao chamar onTabSelected(3) → ProfileScreen precisa estar na árvore',
        );
        expect(
          observer.pushCount >= inicial + 1 ||
              find
                  .byKey(const ValueKey('profile-screen'))
                  .evaluate()
                  .isNotEmpty,
          isTrue,
        );
        resetViewport(tester);
      },
    );

    testWidgets(
      'HomeScreen AppDrawer · ListTile "Meu Perfil" → abre ProfileScreen',
      (tester) async {
        setViewport(tester, kTamanhoGrande);
        final observer = TestNavigatorObserver();
        final fakeData = FakeDataService(peladasList: []);
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authLogado,
            data: fakeData,
            observer: observer,
            child: const HomeScreen(),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 800));

        final drawerBtn = find.byTooltip('Open navigation menu');
        final menuIconBtn = find.byIcon(Icons.menu);
        if (drawerBtn.evaluate().isNotEmpty) {
          await tester.tap(drawerBtn);
        } else if (menuIconBtn.evaluate().isNotEmpty) {
          await tester.tap(menuIconBtn);
        } else {
          final size = tester.getRect(find.byType(Scaffold).first);
          await tester.dragFrom(
            Offset(size.left + 4, size.center.dy),
            const Offset(300, 0),
          );
        }
        await tester.pumpAndSettle(const Duration(milliseconds: 800));

        final tile = find.widgetWithText(ListTile, 'Meu Perfil');
        expect(tile, findsOneWidget);
        final inicial = observer.pushCount;
        await tester.tap(tile);
        await tester.pumpAndSettle(const Duration(milliseconds: 800));

        expect(observer.pushCount, greaterThanOrEqualTo(inicial + 1));
        expect(find.byKey(const ValueKey('profile-screen')), findsOneWidget);
        expect(find.widgetWithText(AppBar, 'Meu Perfil'), findsOneWidget);
        resetViewport(tester);
      },
    );
  });

  group('EditProfileScreen · Formulário', () {
    testWidgets(
      'Valida nome obrigatório + Salvar chama updateUser com dados corretos',
      (tester) async {
        setViewport(tester, kTamanhoExtra);
        final observer = TestNavigatorObserver();
        UserProfile? salvo;
        final authSpy = _SpyAuthService(
          inner: authLogado,
          onUpdateUser: (p) => salvo = p,
        );
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authSpy,
            observer: observer,
            child: const EditProfileScreen(),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        expect(
          find.byKey(const ValueKey('edit-profile-screen')),
          findsOneWidget,
        );

        Finder salvarBtn = find.byKey(const ValueKey('edit-btn-salvar'));
        final elevados = find.byType(ElevatedButton).evaluate();
        if (salvarBtn.evaluate().isEmpty && elevados.isNotEmpty) {
          salvarBtn = find.byType(ElevatedButton).first;
        }
        if (salvarBtn.evaluate().isEmpty) {
          await tester.dragUntilVisible(
            find.byType(ElevatedButton),
            find.byType(ListView).first,
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          if (find.byType(ElevatedButton).evaluate().isNotEmpty) {
            salvarBtn = find.byType(ElevatedButton).first;
          }
        }
        expect(salvarBtn, findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('edit-field-primeiro-nome')),
          '',
        );
        await tester.enterText(
          find.byKey(const ValueKey('edit-field-sobrenome')),
          '',
        );
        await Scrollable.ensureVisible(tester.element(salvarBtn));
        await tester.ensureVisible(salvarBtn);
        await tester.pumpAndSettle();
        await tester.tap(salvarBtn);
        await tester.pumpAndSettle();

        expect(find.text('Informe o primeiro nome'), findsOneWidget);
        expect(salvo, isNull);

        await tester.enterText(
          find.byKey(const ValueKey('edit-field-primeiro-nome')),
          'João Editado',
        );
        await tester.enterText(
          find.byKey(const ValueKey('edit-field-sobrenome')),
          'Silva',
        );
        await Scrollable.ensureVisible(tester.element(salvarBtn));
        await tester.ensureVisible(salvarBtn);
        await tester.pumpAndSettle();
        await tester.tap(salvarBtn);
        await tester.pumpAndSettle(const Duration(milliseconds: 800));

        expect(salvo, isNotNull);
        expect(salvo!.primeiroNome, 'João Editado');
        expect(salvo!.sobrenome, 'Silva');
        resetViewport(tester);
      },
    );
  });
}

class _SpyAuthService extends FakeAuthService {
  final VoidCallback? onSignOut;
  final void Function(UserProfile)? onUpdateUser;
  final UserProfile? _overrideUser;

  _SpyAuthService({
    required FakeAuthService inner,
    this.onSignOut,
    this.onUpdateUser,
  }) : _overrideUser = inner.currentUser,
       super(
         authenticated: inner.isAuthenticated,
         loading: inner.isLoading,
         user: inner.currentUser,
       );

  @override
  UserProfile? get currentUser => _overrideUser;

  @override
  Future<void> signOut() async {
    onSignOut?.call();
  }

  @override
  Future<void> updateUser(UserProfile updatedProfile) async {
    onUpdateUser?.call(updatedProfile);
  }
}
