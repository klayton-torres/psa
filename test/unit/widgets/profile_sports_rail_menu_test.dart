import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/models/pelada_filter.dart';
import 'package:peladeiros_sa/screens/campos_arenas_screen.dart';
import 'package:peladeiros_sa/screens/home_screen.dart';
import 'package:peladeiros_sa/screens/juizes_screen.dart';
import 'package:peladeiros_sa/services/auth_service.dart';
import 'package:peladeiros_sa/services/data_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR');
  });

  Future<(AuthService, DataService)> pumpHome(WidgetTester tester) async {
    final auth = AuthService();
    auth.mockLoginDemo();
    final data = DataService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<DataService>.value(value: data),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return (auth, data);
  }

  Future<void> selectTrailButton(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(const ValueKey<String>('trail-btn-main')));
    await tester.pumpAndSettle();

    final button = find.byKey(ValueKey<String>('trail-btn-$id'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
  }

  testWidgets('Vôlei abre Home filtrada somente por Vôlei', (tester) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (auth, data) = await pumpHome(tester);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);
    data
      ..setFilter(
        const PeladaFilter(
          cidade: 'Campinas',
          modalidades: {Modalidade.basquete},
        ),
      )
      ..setSearch('busca antiga');

    await selectTrailButton(tester, 'volei');

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(data.currentFilter.modalidades, const {Modalidade.voley});
    expect(data.currentFilter.cidade, isNull);
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).modalidadesIniciais,
      const {Modalidade.voley},
    );
  });

  testWidgets('Basquete abre Home filtrada somente por Basquete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (auth, data) = await pumpHome(tester);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);

    await selectTrailButton(tester, 'basquete');

    expect(data.currentFilter.modalidades, const {Modalidade.basquete});
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).modalidadesIniciais,
      const {Modalidade.basquete},
    );
  });

  testWidgets('Vários exclui futebol, Vôlei e Basquete', (tester) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (auth, data) = await pumpHome(tester);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);

    await selectTrailButton(tester, 'varios');

    final modalidades = data.currentFilter.modalidades;
    expect(modalidades, {Modalidade.futevolei, Modalidade.outros});
    expect(
      modalidades.intersection(const {
        Modalidade.futebolCampo,
        Modalidade.futebolRua,
        Modalidade.futsal,
        Modalidade.society,
        Modalidade.areia,
        Modalidade.praia,
        Modalidade.voley,
        Modalidade.basquete,
      }),
      isEmpty,
    );
  });

  testWidgets('Peladas abre Home e limpa filtros e busca', (tester) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (auth, data) = await pumpHome(tester);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);
    data
      ..setFilter(const PeladaFilter(cidade: 'Campinas'))
      ..setSearch('busca antiga');

    await selectTrailButton(tester, 'peladas');

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(data.currentFilter.isEmpty, isTrue);
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).modalidadesIniciais,
      isNull,
    );
  });

  testWidgets('Campos abre a tela Campos e Arenas', (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (auth, data) = await pumpHome(tester);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);

    await selectTrailButton(tester, 'arena');

    expect(find.byType(CamposArenasScreen), findsOneWidget);
  });

  testWidgets('Juízes abre a tela Juízes', (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (auth, data) = await pumpHome(tester);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);

    await selectTrailButton(tester, 'juizes');

    expect(find.byType(JuizesScreen), findsOneWidget);
  });

  testWidgets('Trail Menu permanece ancorado ao botão principal da barra', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (auth, data) = await pumpHome(tester);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);

    final navButton = find.byKey(const ValueKey<String>('trail-btn-main'));
    expect(navButton, findsOneWidget);
    expect(tester.getCenter(navButton).dx, closeTo(210, 1));
    await tester.tap(navButton);
    await tester.pumpAndSettle();

    final volei = find.byKey(const ValueKey<String>('trail-btn-volei'));
    expect(volei, findsOneWidget);
    expect(tester.getCenter(volei).dx, closeTo(210, 1));
  });
}
