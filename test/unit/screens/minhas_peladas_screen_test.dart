import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/models/pelada.dart';
import 'package:peladeiros_sa/models/user_profile.dart';
import 'package:peladeiros_sa/screens/home_screen.dart';
import 'package:peladeiros_sa/screens/minhas_peladas_screen.dart';
import '../../utils/test_helpers.dart';

UserProfile _buildUsuarioLogado({String id = 'org-u1'}) => UserProfile(
  id: id,
  primeiroNome: 'Organizador',
  sobrenome: 'Das Peladas',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Pelada _buildMinhaPelada({required String id, required String donoId}) =>
    Pelada(
      id: id,
      nome: 'Minha Pelada $id',
      organizadorId: donoId,
      organizadorNome: 'Organizador Das Peladas',
      contato: '(11) 99999-0000',
      dataInicio: DateTime.now().add(const Duration(days: 5)),
      dataFim: DateTime.now().add(const Duration(days: 5, hours: 2)),
      horaInicio: const TimeOfDay(hour: 20, minute: 0),
      horaFim: const TimeOfDay(hour: 22, minute: 0),
      taxa: 15.0,
      modalidade: Modalidade.futebolCampo,
      tipoGrama: TipoGrama.natural,
      tipoChuteira: TipoChuteira.trava,
      categoria: CategoriaPelada.livreAdulto,
      categoriaGenero: CategoriaGenero.masc,
      corColeteIndex: 0,
      endereco: 'Rua das Flores, 789',
      localArena: 'Arena do Bairro',
      estado: 'SP',
      cidade: 'São Paulo',
      bairro: 'Centro',
      status: StatusPelada.ativa,
      quorumMinimo: 10,
      quorumMaximo: 22,
      participantesConfirmados: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

class _HomeDummyPage extends StatelessWidget {
  const _HomeDummyPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MinhasPeladasScreen()),
            );
          },
          child: const Text('Ir para Minhas Peladas'),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAuthService authLogado;
  late UserProfile usuario;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    usuario = _buildUsuarioLogado();
    authLogado = FakeAuthService(authenticated: true, user: usuario);
  });

  group('MinhasPeladasScreen · AppBar - Botão VOLTAR', () {
    testWidgets(
      '1. AppBar mostra ícone seta voltar (arrow_back_rounded) e NÃO mostra ícone menu/gaveta',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.binding.platformDispatcher.clearAllTestValues();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final obs = TestNavigatorObserver();
        final donoId = usuario.id;
        final minhaPelada = _buildMinhaPelada(id: 'm1', donoId: donoId);
        final fakeData = FakeDataService(peladasList: <Pelada>[minhaPelada]);
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authLogado,
            data: fakeData,
            observer: obs,
            child: const MinhasPeladasScreen(),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(
          find.byIcon(Icons.arrow_back_rounded),
          findsOneWidget,
          reason:
              'AppBar deve exibir ícone arrow_back_rounded substituindo o menu hambúrguer',
        );
        expect(
          find.byIcon(Icons.menu),
          findsNothing,
          reason: 'Ícone de menu hambúrguer (Icons.menu) NÃO deve existir',
        );
        expect(
          find.byTooltip('Open navigation menu'),
          findsNothing,
          reason:
              'Tooltip padrão "Open navigation menu" NÃO deve estar presente',
        );
      },
    );

    testWidgets('2. Tooltip "Voltar" e Semantics estão no botão leading', (
      tester,
    ) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final donoId = usuario.id;
      final minhaPelada = _buildMinhaPelada(id: 'm2', donoId: donoId);
      final fakeData = FakeDataService(peladasList: <Pelada>[minhaPelada]);
      await tester.pumpWidget(
        buildTestAppShell(
          auth: authLogado,
          data: fakeData,
          child: const MinhasPeladasScreen(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final backIconBtn = find.byIcon(Icons.arrow_back_rounded);
      expect(backIconBtn, findsOneWidget);

      final tooltipAncestor = find.ancestor(
        of: backIconBtn,
        matching: find.byType(Tooltip),
      );
      expect(
        tooltipAncestor,
        findsWidgets,
        reason: 'Botão voltar deve estar envolvido em Tooltip',
      );
      final tt = tester.widgetList<Tooltip>(tooltipAncestor).first;
      expect(
        tt.message?.toLowerCase() ?? '',
        contains('voltar'),
        reason: 'Tooltip deve conter a palavra "Voltar"',
      );
    });

    testWidgets(
      '3. Clique no VOLTAR → navega para HomeScreen (pushAndRemoveUntil até Home)',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.binding.platformDispatcher.clearAllTestValues();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final obs = TestNavigatorObserver();
        final donoId = usuario.id;
        final minhaPelada = _buildMinhaPelada(id: 'm3', donoId: donoId);
        final fakeData = FakeDataService(peladasList: <Pelada>[minhaPelada]);
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authLogado,
            data: fakeData,
            observer: obs,
            child: const _HomeDummyPage(),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.text('Ir para Minhas Peladas'), findsOneWidget);
        await tester.tap(find.text('Ir para Minhas Peladas'));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.byType(MinhasPeladasScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);

        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle(const Duration(milliseconds: 900));

        expect(
          find.byType(HomeScreen),
          findsOneWidget,
          reason:
              'Após clicar em Voltar, HomeScreen deve ser a nova raiz da navegação',
        );
        expect(
          find.byType(MinhasPeladasScreen),
          findsNothing,
          reason: 'MinhasPeladasScreen deve sair da árvore após voltar',
        );
        expect(
          find.byType(_HomeDummyPage),
          findsNothing,
          reason: 'Página intermediária também é limpa (pushAndRemoveUntil)',
        );
      },
    );

    testWidgets('4. Tamanho mínimo 44x44 do botão (hit target WCAG)', (
      tester,
    ) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final donoId = usuario.id;
      final minhaPelada = _buildMinhaPelada(id: 'm4', donoId: donoId);
      final fakeData = FakeDataService(peladasList: <Pelada>[minhaPelada]);
      await tester.pumpWidget(
        buildTestAppShell(
          auth: authLogado,
          data: fakeData,
          child: const MinhasPeladasScreen(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final backIcon = find.byIcon(Icons.arrow_back_rounded);
        expect(backIcon, findsOneWidget);
        final iconBtnFinder = find.ancestor(
          of: backIcon,
          matching: find.byType(IconButton),
        );
        expect(iconBtnFinder, findsOneWidget);
        final iconBtn = tester.widget<IconButton>(iconBtnFinder.first);
        final estilo = iconBtn.style;
        final minSize = estilo?.minimumSize?.resolve(<WidgetState>{});
        expect(
          (minSize?.width ?? 0) >= 44,
          isTrue,
          reason:
              'IconButton.style minimumSize largura deve ser >= 44 (padrão WCAG). Encontrado: ${minSize?.width}',
        );
        expect(
          (minSize?.height ?? 0) >= 44,
          isTrue,
          reason:
              'IconButton.style minimumSize altura deve ser >= 44 (padrão WCAG). Encontrado: ${minSize?.height}',
        );
        final rect = tester.getRect(iconBtnFinder.first);
        expect(
          rect.width >= 44 || (minSize?.width ?? 0) >= 44,
          isTrue,
          reason:
              'Hit target do botão voltar deve ser >= 44 (WCAG). RenderBox=${rect.width}x${rect.height}, style=$minSize',
        );
    });
  });

  group('MinhasPeladasScreen · AppBar - Padrão de Cores do Tema', () {
    testWidgets(
      '5. backgroundColor usa scheme.surface e foregroundColor scheme.onSurface',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.binding.platformDispatcher.clearAllTestValues();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final customTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
        );
        final donoId = usuario.id;
        final minhaPelada = _buildMinhaPelada(id: 'm5', donoId: donoId);
        final fakeData = FakeDataService(peladasList: <Pelada>[minhaPelada]);
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authLogado,
            data: fakeData,
            theme: customTheme,
            child: const MinhasPeladasScreen(),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        final appBar = tester.widget<AppBar>(find.byType(AppBar).first);
        final scheme = customTheme.colorScheme;
        expect(
          appBar.backgroundColor,
          scheme.surface,
          reason: 'AppBar.backgroundColor deve ser scheme.surface',
        );
        expect(
          appBar.foregroundColor,
          scheme.onSurface,
          reason: 'AppBar.foregroundColor deve ser scheme.onSurface',
        );
        expect(
          appBar.elevation,
          0,
          reason: 'AppBar.elevation deve ser zero para seguir padrão do tema',
        );
      },
    );

    testWidgets(
      '6. Título AppBar "Minhas Peladas" usa fontSize 20, fontWeight 800, cor onSurface',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.binding.platformDispatcher.clearAllTestValues();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final customTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.pink,
            brightness: Brightness.dark,
          ),
        );
        final donoId = usuario.id;
        final minhaPelada = _buildMinhaPelada(id: 'm6', donoId: donoId);
        final fakeData = FakeDataService(peladasList: <Pelada>[minhaPelada]);
        await tester.pumpWidget(
          buildTestAppShell(
            auth: authLogado,
            data: fakeData,
            theme: customTheme,
            child: const MinhasPeladasScreen(),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        final tituloFinder = find.text('Minhas Peladas');
        expect(tituloFinder, findsOneWidget);
        final appBar = tester.widget<AppBar>(find.byType(AppBar).first);
        final titleStyle = appBar.titleTextStyle;
        expect(
          titleStyle?.fontSize,
          20,
          reason: 'AppBar.titleTextStyle.fontSize deve ser 20',
        );
        expect(
          titleStyle?.fontWeight,
          FontWeight.w800,
          reason: 'AppBar.titleTextStyle.fontWeight deve ser w800',
        );
        expect(
          titleStyle?.color,
          customTheme.colorScheme.onSurface,
          reason: 'AppBar.titleTextStyle.color deve ser scheme.onSurface',
        );
        final tituloWidget = tester.widget<Text>(tituloFinder.first);
        expect(
          tituloWidget.data,
          'Minhas Peladas',
          reason: 'Texto do título deve ser "Minhas Peladas"',
        );
      },
    );
  });

  group('MinhasPeladasScreen · AppBar - Ação + (Nova Pelada)', () {
    testWidgets('7. Ação add_circle_outline ainda existe na AppBar', (
      tester,
    ) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.binding.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final donoId = usuario.id;
      final minhaPelada = _buildMinhaPelada(id: 'm7', donoId: donoId);
      final fakeData = FakeDataService(peladasList: <Pelada>[minhaPelada]);
      final obs = TestNavigatorObserver();
      await tester.pumpWidget(
        buildTestAppShell(
          auth: authLogado,
          data: fakeData,
          observer: obs,
          child: const MinhasPeladasScreen(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(
        find.byIcon(Icons.add_circle_outline),
        findsOneWidget,
        reason: 'Ação "Nova Pelada" deve continuar presente na AppBar',
      );
      final tooltipBtn = find.byTooltip('Nova Pelada');
      expect(tooltipBtn, findsOneWidget);
    });
  });
}
