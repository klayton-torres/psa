import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peladeiros_sa/models/campo_arena.dart';
import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/models/juiz.dart';
import 'package:peladeiros_sa/screens/home_screen.dart';
import 'package:peladeiros_sa/screens/campos_arenas_screen.dart';
import 'package:peladeiros_sa/screens/juizes_screen.dart';
import 'package:peladeiros_sa/screens/juizes_favoritos_screen.dart';
import '../../utils/test_helpers.dart';

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

abstract class ModalidadesConstantes {
  static const Set<Modalidade> futebolVariantes = <Modalidade>{
    Modalidade.futebolCampo,
    Modalidade.futebolRua,
    Modalidade.futsal,
    Modalidade.society,
    Modalidade.areia,
    Modalidade.praia,
  };
  static const Set<Modalidade> volei = <Modalidade>{Modalidade.voley};
  static const Set<Modalidade> basquete = <Modalidade>{Modalidade.basquete};
  static Set<Modalidade> todosExcetoPrincipais() =>
      Set<Modalidade>.from(Modalidade.values)..removeAll(<Modalidade>{
        ...futebolVariantes,
        Modalidade.voley,
        Modalidade.basquete,
      });
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  group('Constantes de Modalidades Trail Menu · Correção de Subconjuntos', () {
    test('VÔLEI / BASQUETE / VÁRIOS consistentes', () {
      final varios = ModalidadesConstantes.todosExcetoPrincipais();
      expect(
        ModalidadesConstantes.volei,
        const {Modalidade.voley},
        reason: 'Vôlei deve conter APENAS Modalidade.voley',
      );
      expect(
        ModalidadesConstantes.basquete,
        const {Modalidade.basquete},
        reason: 'Basquete deve conter APENAS Modalidade.basquete',
      );
      expect(
        varios.intersection(ModalidadesConstantes.futebolVariantes),
        isEmpty,
        reason: 'VÁRIOS não deve conter NENHUMA variante de futebol',
      );
      expect(varios.contains(Modalidade.voley), isFalse);
      expect(varios.contains(Modalidade.basquete), isFalse);
      expect(
        varios.contains(Modalidade.futevolei) ||
            varios.contains(Modalidade.outros),
        isTrue,
        reason: 'VÁRIOS deve conter esportes fora do trio principal',
      );
    });

    test('VÁRIOS = Modalidade.values - futebol - vôlei - basquete', () {
      final esperado = ModalidadesConstantes.todosExcetoPrincipais();
      expect(esperado, {Modalidade.futevolei, Modalidade.outros});
      expect(esperado, isNot(contains(Modalidade.futebolCampo)));
      expect(esperado, isNot(contains(Modalidade.society)));
      expect(esperado, isNot(contains(Modalidade.voley)));
      expect(esperado, isNot(contains(Modalidade.basquete)));
    });
  });

  group('HomeScreen · Persistência de filtros via modalidadesIniciais', () {
    testWidgets('Sem filtro → widget recebe null', (tester) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        buildTestAppShell(child: const HomeScreen(modalidadesIniciais: null)),
      );
      await tester.pump();
      final HomeScreen w = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(w.modalidadesIniciais, isNull);
    });

    testWidgets('Filtro VÔLEI → widget recebe {Modalidade.voley}', (
      tester,
    ) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        buildTestAppShell(
          child: const HomeScreen(modalidadesIniciais: {Modalidade.voley}),
        ),
      );
      await tester.pump();
      final HomeScreen w = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(w.modalidadesIniciais, const {Modalidade.voley});
    });

    testWidgets('Filtro BASQUETE → widget recebe {Modalidade.basquete}', (
      tester,
    ) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        buildTestAppShell(
          child: const HomeScreen(modalidadesIniciais: {Modalidade.basquete}),
        ),
      );
      await tester.pump();
      final HomeScreen w = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(w.modalidadesIniciais, const {Modalidade.basquete});
    });

    testWidgets('Filtro VÁRIOS → widget recebe sem futebol/vôlei/basquete', (
      tester,
    ) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final varios = ModalidadesConstantes.todosExcetoPrincipais();
      await tester.pumpWidget(
        buildTestAppShell(child: HomeScreen(modalidadesIniciais: varios)),
      );
      await tester.pump();
      final HomeScreen w = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(w.modalidadesIniciais, varios);
      expect(w.modalidadesIniciais!.contains(Modalidade.voley), isFalse);
      expect(w.modalidadesIniciais!.contains(Modalidade.basquete), isFalse);
      expect(
        w.modalidadesIniciais!.intersection(
          ModalidadesConstantes.futebolVariantes,
        ),
        isEmpty,
      );
    });
  });

  group('Widgets · Renderizam sem crash (baseline integration)', () {
    testWidgets('CamposArenasScreen renderiza', (tester) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        buildTestAppShell(
          data: FakeDataService(
            camposArenasList: <CampoArena>[_buildCampoArenaFake()],
          ),
          child: const CamposArenasScreen(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('JuizesScreen renderiza', (tester) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        buildTestAppShell(
          data: FakeDataService(juizesList: <Juiz>[_buildJuizFake()]),
          child: const JuizesScreen(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('JuizesFavoritosScreen renderiza', (tester) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        buildTestAppShell(
          data: FakeDataService(
            juizesFavoritosList: <Juiz>[_buildJuizFake(id: 'jf1')],
          ),
          child: const JuizesFavoritosScreen(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });
}
