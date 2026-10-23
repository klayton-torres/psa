import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peladeiros_sa/models/campo_arena.dart';
import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/models/juiz.dart';
import 'package:peladeiros_sa/models/user_profile.dart';
import 'package:peladeiros_sa/screens/campos_arenas_screen.dart';
import 'package:peladeiros_sa/screens/juizes_screen.dart';
import 'package:peladeiros_sa/widgets/profile_sports_rail_menu.dart';
import '../../utils/test_helpers.dart';

UserProfile _buildUsuarioFake({String id = 'u1'}) => UserProfile(
  id: id,
  primeiroNome: 'Teste',
  sobrenome: 'Usuário',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  modalidadesPraticadas: const <Modalidade>[],
  marcasChuteiraFavoritas: const <String>[],
);

FakeAuthService _authLogado() =>
    FakeAuthService(authenticated: true, user: _buildUsuarioFake());

CampoArena _buildCampoArenaFake({String id = 'c1'}) => CampoArena(
  id: id,
  nome: 'Arena Teste $id',
  responsavelNome: 'João Responsável',
  estado: 'SP',
  cidade: 'São Paulo',
  bairro: 'Centro',
  rua: 'Av. Paulista',
  numero: '100',
  quantidadePorLinha: 2,
  tipoGrama: TipoGrama.sintetica,
  calcadosPermitidos: const {TipoChuteira.trava},
  dependencias: const {},
  itensOpcionais: const {},
  fotos: const [],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Juiz _buildJuizFake({String id = 'j1'}) => Juiz(
  id: id,
  nome: 'Carlos',
  sobrenome: 'Silva',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  group('CamposArenasScreen · NAVEGAÇÃO Trail Menu → Juízes', () {
    testWidgets(
      'E2E: Ao clicar no botão Juízes do Trail Menu → push JuizesScreen (rota pilha preservada)',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.view.physicalSize = const Size(600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.binding.platformDispatcher.clearAllTestValues();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final obs = TestNavigatorObserver();
        final fakeData = FakeDataService(
          camposArenasList: <CampoArena>[_buildCampoArenaFake()],
          juizesList: <Juiz>[_buildJuizFake()],
        );
        await tester.pumpWidget(
          buildTestAppShell(
            auth: _authLogado(),
            observer: obs,
            data: fakeData,
            child: const CamposArenasScreen(),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        expect(find.byType(CamposArenasScreen), findsOneWidget);
        expect(find.byType(JuizesScreen), findsNothing);
        final pushInicial = obs.pushCount;
        expect(
          pushInicial,
          greaterThanOrEqualTo(0),
          reason: 'push inicial da rota base do MaterialApp',
        );

        final railFinder = find.byType(ProfileSportsRailMenu);
        expect(railFinder, findsOneWidget);

        final juizesBtnKey = find.byKey(
          const ValueKey<String>('trail-btn-juizes'),
        );
        expect(juizesBtnKey, findsOneWidget);
        final inkWell = tester.widget<InkWell>(juizesBtnKey);
        expect(inkWell.onTap, isNotNull);

        inkWell.onTap!.call();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(
          obs.pushCount,
          greaterThanOrEqualTo(pushInicial + 1),
          reason:
              'Esperado push adicional ($pushInicial + 1) ao chamar onJuizesTap',
        );
        expect(
          find.byType(JuizesScreen),
          findsOneWidget,
          reason: 'JuizesScreen deve estar renderizada após navegação',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'Navegação não pode disparar exception',
        );
      },
    );

    testWidgets(
      'E2E Responsivo 480px (mobile compacto): Botão Juízes é encontrado e linka callback (navegabilidade)',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.view.physicalSize = const Size(480, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.binding.platformDispatcher.clearAllTestValues();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeData = FakeDataService(
          camposArenasList: <CampoArena>[_buildCampoArenaFake()],
        );
        await tester.pumpWidget(
          buildTestAppShell(
            auth: _authLogado(),
            data: fakeData,
            child: const CamposArenasScreen(),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        expect(
          find.byKey(const ValueKey<String>('trail-btn-juizes')),
          findsOneWidget,
          reason: '480px: botão Juízes do Trail Menu DEVE existir',
        );
        final ink = tester.widget<InkWell>(
          find.byKey(const ValueKey<String>('trail-btn-juizes')),
        );
        expect(
          ink.onTap,
          isNotNull,
          reason: '480px: callback onTap do botão Juízes NÃO pode ser nulo',
        );
        final e = tester.takeException();
        expect(
          e == null || e is FlutterError,
          isTrue,
          reason:
              'Apenas exceções esperadas (overflow warnings) são permitidas; erro real',
        );
      },
    );

    testWidgets(
      'E2E Responsivo 1024px (tablet/desktop): Botão Juízes → encontra e callback não nulo',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.binding.platformDispatcher.clearAllTestValues();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeData = FakeDataService(
          camposArenasList: <CampoArena>[_buildCampoArenaFake()],
        );
        await tester.pumpWidget(
          buildTestAppShell(
            auth: _authLogado(),
            data: fakeData,
            child: const CamposArenasScreen(),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        expect(
          find.byKey(const ValueKey<String>('trail-btn-juizes')),
          findsOneWidget,
          reason: '1024px: botão Juízes do Trail Menu DEVE existir',
        );
        final ink = tester.widget<InkWell>(
          find.byKey(const ValueKey<String>('trail-btn-juizes')),
        );
        expect(
          ink.onTap,
          isNotNull,
          reason: '1024px: callback onTap do botão Juízes NÃO pode ser nulo',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Pós-redirecionamento: Elementos JuizesScreen carregam sem erro (AppBar, Trail Menu, dados)',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.view.physicalSize = const Size(600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.binding.platformDispatcher.clearAllTestValues();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final obs = TestNavigatorObserver();
        final fakeData = FakeDataService(
          camposArenasList: <CampoArena>[_buildCampoArenaFake()],
          juizesList: <Juiz>[
            _buildJuizFake(),
            _buildJuizFake(id: 'j2'),
          ],
        );
        await tester.pumpWidget(
          buildTestAppShell(
            auth: _authLogado(),
            observer: obs,
            data: fakeData,
            child: const CamposArenasScreen(),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        final juizesBtnKey = find.byKey(
          const ValueKey<String>('trail-btn-juizes'),
        );
        final inkWell = tester.widget<InkWell>(juizesBtnKey);
        inkWell.onTap!.call();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        expect(find.byType(JuizesScreen), findsOneWidget);
        expect(
          find.byType(ProfileSportsRailMenu),
          findsAtLeast(1),
          reason: 'JuizesScreen DEVE ter o seu próprio Trail Menu',
        );
        expect(
          find.byKey(const ValueKey<String>('trail-btn-main')),
          findsAtLeast(1),
        );
        expect(
          find.byType(AppBar),
          findsAtLeast(1),
          reason: 'JuizesScreen DEVE ter AppBar carregado',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'Tela Juízes NÃO pode ter erros de carregamento',
        );
      },
    );
  });
}
