import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peladeiros_sa/models/campo_arena.dart';
import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/models/juiz.dart';
import 'package:peladeiros_sa/models/pelada.dart';
import 'package:peladeiros_sa/models/pelada_filter.dart';
import 'package:peladeiros_sa/models/participation.dart';
import 'package:peladeiros_sa/models/user_profile.dart';
import 'package:peladeiros_sa/screens/participants_screen.dart';
import 'package:peladeiros_sa/services/auth_service.dart';
import 'package:peladeiros_sa/services/data_service.dart';
import 'package:provider/provider.dart';
import '../../utils/test_helpers.dart';

class _SmartFakeDataService implements DataService {
  final List<Pelada> _peladas;
  final List<Participation> _participations;
  final Set<String> _favoritos;
  final bool _loading = false;
  String? _error;
  _SmartFakeDataService({
    List<Pelada>? peladas,
    List<Participation>? participations,
    Set<String>? favoritos,
  }) : _peladas = List<Pelada>.from(peladas ?? const <Pelada>[]),
       _participations = List<Participation>.from(
         participations ?? const <Participation>[],
       ),
       _favoritos = Set<String>.from(favoritos ?? const <String>{});

  @override
  bool get isLoading => _loading;
  @override
  String? get errorMessage => _error;
  @override
  Set<String> get favoritos => Set.unmodifiable(_favoritos);
  @override
  bool get temFavoritos => _favoritos.isNotEmpty;
  @override
  List<Pelada> get peladas => List.unmodifiable(_peladas);
  @override
  List<Pelada> get favoritas => const <Pelada>[];
  @override
  List<Pelada> get filteredPeladas => const <Pelada>[];
  @override
  List<CampoArena> get camposArenas => const <CampoArena>[];
  @override
  List<CampoArena> get camposFavoritos => const <CampoArena>[];
  @override
  List<Juiz> get juizes => const <Juiz>[];
  @override
  List<Juiz> get juizesFavoritos => const <Juiz>[];
  @override
  PeladaFilter get currentFilter => kEmptyFilter;
  @override
  String? get searchQuery => null;
  @override
  String? get favoritosError => null;
  @override
  bool get hasListeners => false;
  @override
  Stream<PeladaStatusChange> get statusChanges =>
      const Stream<PeladaStatusChange>.empty();
  @override
  int? get quantidadeJuizesFavoritos => null;
  @override
  bool? get temJuizesFavoritos => null;

  @override
  UserProfile? getUserProfile(String usuarioId) => null;

  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  void dispose() {}
  @override
  void notifyListeners() {}
  @override
  Future<void> carregarFavoritos() async {}
  @override
  Future<void> carregarPeladas({
    bool forceRefresh = false,
    bool listenRealtime = true,
    String? estado,
    String? cidade,
    String? usuarioId,
  }) async {}
  @override
  Future<void> carregarCamposArenas({bool forceRefresh = false}) async {}
  @override
  Future<List<Juiz>> carregarJuizes({bool forceRefresh = false}) async => [];
  @override
  void clearCache() {}
  @override
  void clearError(String field) {}
  @override
  void clearFilter() {}
  @override
  void ensurePeladasRealtime({required String usuarioId}) {}

  @override
  Pelada? findPelada(String id) => getPeladaById(id);

  @override
  Pelada? getPeladaById(String id) {
    for (final p in _peladas) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  List<Participation> getParticipationsByPelada(String peladaId) {
    return _participations
        .where((p) => p.peladaId == peladaId)
        .toList(growable: false);
  }

  @override
  List<PeladaBloqueioUsuario> getBloqueiosPelada(String peladaId) =>
      const <PeladaBloqueioUsuario>[];

  @override
  Participation? getParticipacaoUsuario(String peladaId, String usuarioId) {
    for (final p in _participations) {
      if (p.peladaId == peladaId && p.usuarioId == usuarioId) return p;
    }
    return null;
  }

  @override
  PeladaBloqueioUsuario? getBloqueioUsuario({
    required String peladaId,
    required String usuarioId,
  }) => null;

  @override
  Future<Participation?> registrarParticipacao({
    required String peladaId,
    required String usuarioId,
    required String usuarioNome,
    String? usuarioApelido,
    PosicaoAtleta? usuarioPosicaoPrincipal,
    String? usuarioFotoUrl,
    required StatusParticipacao status,
    MotivoAusencia? motivoAusencia,
    String? observacao,
  }) async {
    final idx = _participations.indexWhere(
      (p) => p.peladaId == peladaId && p.usuarioId == usuarioId,
    );
    final now = DateTime.now();
    final Participation p;
    if (idx != -1) {
      p = _participations[idx].copyWith(
        usuarioNome: usuarioNome,
        usuarioApelido: usuarioApelido,
        usuarioPosicaoPrincipal: usuarioPosicaoPrincipal,
        usuarioFotoUrl: usuarioFotoUrl,
        status: status,
        motivoAusencia: motivoAusencia,
        observacao: observacao,
        updatedAt: now,
      );
      _participations[idx] = p;
    } else {
      p = Participation(
        id: 'p_${now.millisecondsSinceEpoch}_${_participations.length}',
        peladaId: peladaId,
        usuarioId: usuarioId,
        usuarioNome: usuarioNome,
        usuarioApelido: usuarioApelido,
        usuarioPosicaoPrincipal: usuarioPosicaoPrincipal,
        usuarioFotoUrl: usuarioFotoUrl,
        status: status,
        motivoAusencia: motivoAusencia,
        observacao: observacao,
        createdAt: now,
        updatedAt: now,
      );
      _participations.add(p);
    }
    final peladaIdx = _peladas.indexWhere((p) => p.id == peladaId);
    if (peladaIdx != -1) {
      final confirmados = _participations
          .where(
            (x) =>
                x.peladaId == peladaId &&
                x.status == StatusParticipacao.confirmada,
          )
          .length;
      _peladas[peladaIdx] = _peladas[peladaIdx].copyWith(
        participantesConfirmados: confirmados,
      );
    }
    return p;
  }

  @override
  Future<bool> removerParticipacao({
    required String peladaId,
    required String participationId,
    required String usuarioId,
  }) async {
    final before = _participations.length;
    _participations.removeWhere((p) => p.id == participationId);
    if (before != _participations.length) {
      final peladaIdx = _peladas.indexWhere((p) => p.id == peladaId);
      if (peladaIdx != -1) {
        final confirmados = _participations
            .where(
              (x) =>
                  x.peladaId == peladaId &&
                  x.status == StatusParticipacao.confirmada,
            )
            .length;
        _peladas[peladaIdx] = _peladas[peladaIdx].copyWith(
          participantesConfirmados: confirmados,
        );
      }
      return true;
    }
    return false;
  }

  @override
  Future<Pelada?> atualizarPelada(Pelada atualizada) async {
    final idx = _peladas.indexWhere((p) => p.id == atualizada.id);
    if (idx == -1) return null;
    _peladas[idx] = atualizada.copyWith(updatedAt: DateTime.now());
    return _peladas[idx];
  }

  @override
  Future<PeladaBloqueioUsuario?> bloquearUsuario({
    required String peladaId,
    required String usuarioId,
    required String usuarioNome,
    required String organizadorId,
    String? motivo,
  }) async => null;
  @override
  Future<bool> desbloquearUsuario({
    required String peladaId,
    required String usuarioId,
  }) async => true;
  @override
  Future<bool> avaliarPelada({
    required String peladaId,
    required String usuarioId,
    required int nota,
    String? comentario,
  }) async => true;
  @override
  Future<CampoArena?> atualizarCampoArena(CampoArena atualizado) async => null;
  @override
  Future<Juiz?> atualizarJuiz(Juiz atualizado) async => null;
  @override
  Future<CampoArena?> cadastrarCampoArena(CampoArena novo) async => null;
  @override
  Future<Pelada?> cadastrarPelada(Pelada novaPelada) async => null;
  @override
  Future<int?> cadastrarPeladasRecorrentes(Pelada template) async => 0;
  @override
  Future<bool> excluirCampoArena({
    required String campoArenaId,
    required String usuarioId,
  }) async => true;
  @override
  Future<bool> excluirJuiz({
    required String juizId,
    required String usuarioId,
  }) async => true;
  @override
  CampoArena? getCampoArenaById(String id) => null;
  @override
  List<CampoArena> getCamposArenasDoUsuario(String usuarioId) =>
      const <CampoArena>[];
  @override
  Juiz? getJuizById(String id) => null;
  @override
  Juiz? getJuizByIdLocal(String juizId) => null;
  @override
  bool isCampoFavorito(String id) => false;
  @override
  bool isFavorito(String id) => false;
  @override
  bool isJuizFavorito(String id) => false;
  @override
  bool isUsuarioBloqueadoParaPelada({
    required String peladaId,
    required String usuarioId,
  }) => false;
  @override
  List<Pelada> pesquisarPeladas(String query) => const <Pelada>[];
  @override
  Future<void> salvarPelada(Pelada p) async {}
  @override
  Future<bool> salvarCampoArena(CampoArena c) async => true;
  @override
  Future<bool> salvarJuiz(Juiz j) async => true;
  @override
  void setFilter(PeladaFilter value) {}
  @override
  void setSearch(String? query) {}
  @override
  void startPeladasRealtime() {}
  @override
  void stopPeladasRealtime() {}
  @override
  Future<void> toggleCampoFavorito(String campoId) async {}
  @override
  Future<void> toggleFavorito(String peladaId) async {}
  @override
  Future<void> toggleJuizFavorito(String juizId) async {}
  @override
  Future<bool> excluirPelada({
    required String peladaId,
    required String usuarioId,
  }) async => false;
}

Pelada _buildPelada({
  String id = 'pelada-teste-1',
  String organizadorId = 'org-user-1',
  int quorumMin = 10,
  int quorumMax = 22,
  int confirmados = 0,
}) {
  return Pelada(
    id: id,
    nome: 'Pelada Teste E2E',
    organizadorId: organizadorId,
    organizadorNome: 'Dono Organização',
    contato: '(11) 99999-0000',
    dataInicio: DateTime.now().add(const Duration(days: 2)),
    dataFim: DateTime.now().add(const Duration(days: 2, hours: 2)),
    horaInicio: const TimeOfDay(hour: 20, minute: 0),
    horaFim: const TimeOfDay(hour: 22, minute: 0),
    taxa: 20.0,
    modalidade: Modalidade.futebolCampo,
    tipoGrama: TipoGrama.natural,
    tipoChuteira: TipoChuteira.trava,
    categoria: CategoriaPelada.livreAdulto,
    categoriaGenero: CategoriaGenero.masc,
    corColeteIndex: 0,
    endereco: 'Rua Teste, 123',
    localArena: 'Arena Centro',
    estado: 'SP',
    cidade: 'São Paulo',
    bairro: 'Centro',
    status: StatusPelada.ativa,
    quorumMinimo: quorumMin,
    quorumMaximo: quorumMax,
    participantesConfirmados: confirmados,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

UserProfile _organizadorUser({String id = 'org-user-1'}) => UserProfile(
  id: id,
  primeiroNome: 'Donosão',
  sobrenome: 'Futebol',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

UserProfile _visitanteUser({String id = 'visit-user-1'}) => UserProfile(
  id: id,
  primeiroNome: 'Torcedor',
  sobrenome: 'Neutro',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

class _DummyFirstPage extends StatelessWidget {
  final String peladaId;
  const _DummyFirstPage({required this.peladaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ParticipantsScreen(peladaId: peladaId),
              ),
            );
          },
          child: const Text('Ir para Gerenciar Participantes'),
        ),
      ),
    );
  }
}

Participation _buildParticipation({
  required String id,
  required String peladaId,
  required String usuarioId,
  required String nome,
  String? apelido,
  PosicaoAtleta? posicao,
  StatusParticipacao status = StatusParticipacao.confirmada,
}) {
  final now = DateTime.now().subtract(const Duration(hours: 1));
  return Participation(
    id: id,
    peladaId: peladaId,
    usuarioId: usuarioId,
    usuarioNome: nome,
    usuarioApelido: apelido,
    usuarioPosicaoPrincipal: posicao,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  Future<void> pump(
    WidgetTester tester, {
    required String peladaId,
    required UserProfile? currentUser,
    required _SmartFakeDataService data,
    TestNavigatorObserver? observer,
    bool stackParticipantsUnderneath = false,
  }) async {
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.binding.platformDispatcher.clearAllTestValues();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final auth = FakeAuthService(
      authenticated: currentUser != null,
      user: currentUser,
    );
    final obs = observer ?? TestNavigatorObserver();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<DataService>.value(value: data),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
          debugShowCheckedModeBanner: false,
          navigatorObservers: [obs],
          home: stackParticipantsUnderneath
              ? _DummyFirstPage(peladaId: peladaId)
              : ParticipantsScreen(peladaId: peladaId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (stackParticipantsUnderneath) {
      await tester.tap(find.text('Ir para Gerenciar Participantes'));
      await tester.pumpAndSettle();
    }
  }

  group('ParticipantsScreen · E2E · AppBar - Botão VOLTAR', () {
    testWidgets('1. AppBar EXIBE seta voltar e NÃO exibe ícone Menu/Gaveta', (
      tester,
    ) async {
      final data = _SmartFakeDataService(peladas: [_buildPelada()]);
      final obs = TestNavigatorObserver();
      await pump(
        tester,
        peladaId: 'pelada-teste-1',
        currentUser: _organizadorUser(),
        data: data,
        observer: obs,
      );
      expect(
        find.byIcon(Icons.arrow_back_rounded),
        findsOneWidget,
        reason: 'Deve exibir a seta para esquerda',
      );
      expect(find.byTooltip('Abrir menu de navegação'), findsNothing);
      expect(
        find.byIcon(Icons.menu),
        findsNothing,
        reason: 'Ícone de Menu/Gaveta foi substituído',
      );
    });

    testWidgets(
      '2. Clique no VOLTAR dispara Navigator.pop (preserva contexto)',
      (tester) async {
        final data = _SmartFakeDataService(peladas: [_buildPelada()]);
        final obs = TestNavigatorObserver();
        await pump(
          tester,
          peladaId: 'pelada-teste-1',
          currentUser: _organizadorUser(),
          data: data,
          observer: obs,
          stackParticipantsUnderneath: true,
        );
        expect(obs.popCount, 0);
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        expect(
          obs.popCount,
          1,
          reason: 'Clicar no voltar deve chamar pop() mantendo a pilha',
        );
      },
    );
  });

  group('ParticipantsScreen · E2E · AppBar - Botão "+ AVULSO" REMOVIDO', () {
    testWidgets(
      '3. NÃO-organizador NÃO vê botão "+ AVULSO" na AppBar (removido)',
      (tester) async {
        final data = _SmartFakeDataService(peladas: [_buildPelada()]);
        await pump(
          tester,
          peladaId: 'pelada-teste-1',
          currentUser: _visitanteUser(),
          data: data,
        );
        expect(
          find.widgetWithText(FilledButton, '+ AVULSO'),
          findsNothing,
          reason:
              'Botão "+ AVULSO" da AppBar foi REMOVIDO para todos os usuários',
        );
        expect(
          find.text('Organizador'),
          findsNothing,
          reason: 'Badge Organizador não aparece para visitante',
        );
      },
    );

    testWidgets(
      '4. ORGANIZADOR TAMBÉM NÃO vê botão "+ AVULSO" na AppBar (removido)',
      (tester) async {
        final data = _SmartFakeDataService(peladas: [_buildPelada()]);
        await pump(
          tester,
          peladaId: 'pelada-teste-1',
          currentUser: _organizadorUser(),
          data: data,
        );
        expect(
          find.widgetWithText(FilledButton, '+ AVULSO'),
          findsNothing,
          reason:
              'Botão "+ AVULSO" foi REMOVIDO da AppBar também para organizadores',
        );
        expect(find.text('ORGANIZADOR'), findsOneWidget);
      },
    );
  });

  group(
    'ParticipantsScreen · E2E · BottomNavBar - Botão "Avulso" (nova localização)',
    () {
      testWidgets('5. Botão "Avulso" RENDERIZA na barra inferior (ícone + label)', (
        tester,
      ) async {
        final data = _SmartFakeDataService(peladas: [_buildPelada()]);
        await pump(
          tester,
          peladaId: 'pelada-teste-1',
          currentUser: _organizadorUser(),
          data: data,
        );
        expect(
          find.text('Avulso'),
          findsOneWidget,
          reason:
              'Label "Avulso" deve aparecer na barra inferior (CustomBottomNavBar)',
        );
        expect(
          find.byIcon(Icons.person_add_alt_1_outlined),
          findsOneWidget,
          reason:
              'Ícone person_add_alt_1_outlined do botão Avulso na barra inferior',
        );
      });

      testWidgets(
        '6. ORGANIZADOR clica no botão Avulso → ABRE modal com 4 campos esperados',
        (tester) async {
          final data = _SmartFakeDataService(peladas: [_buildPelada()]);
          await pump(
            tester,
            peladaId: 'pelada-teste-1',
            currentUser: _organizadorUser(),
            data: data,
          );
          expect(find.byKey(const Key('avulso_nome')), findsNothing);
          expect(find.byKey(const Key('avulso_idade')), findsNothing);
          expect(find.byKey(const Key('avulso_posicao')), findsNothing);
          await tester.tap(find.text('Avulso'));
          await tester.pumpAndSettle();
          expect(
            find.text('Novo Participante Avulso'),
            findsOneWidget,
            reason: 'Título do modal',
          );
          expect(
            find.byKey(const Key('avulso_nome')),
            findsOneWidget,
            reason: 'Campo Nome *',
          );
          expect(
            find.byKey(const Key('avulso_apelido')),
            findsOneWidget,
            reason: 'Campo Apelido (opcional)',
          );
          expect(
            find.byKey(const Key('avulso_idade')),
            findsOneWidget,
            reason: 'Campo Idade *',
          );
          expect(
            find.byKey(const Key('avulso_posicao')),
            findsOneWidget,
            reason: 'Campo Posição *',
          );
          expect(
            find.widgetWithText(TextButton, 'Cancelar'),
            findsOneWidget,
            reason: 'Botão Cancelar',
          );
          expect(
            find.widgetWithText(FilledButton, 'Adicionar'),
            findsOneWidget,
            reason: 'Botão Adicionar',
          );
        },
      );

      testWidgets('7. Fechar modal via botão X (canto sup direito) → fecha', (
        tester,
      ) async {
        final data = _SmartFakeDataService(peladas: [_buildPelada()]);
        await pump(
          tester,
          peladaId: 'pelada-teste-1',
          currentUser: _organizadorUser(),
          data: data,
        );
        await tester.tap(find.text('Avulso'));
        await tester.pumpAndSettle();
        expect(find.text('Novo Participante Avulso'), findsOneWidget);
        await tester.tap(find.byTooltip('Fechar'));
        await tester.pumpAndSettle();
        expect(
          find.text('Novo Participante Avulso'),
          findsNothing,
          reason: 'Botão X fecha o modal',
        );
      });

      testWidgets('8. Fechar modal via botão Cancelar → fecha', (tester) async {
        final data = _SmartFakeDataService(peladas: [_buildPelada()]);
        await pump(
          tester,
          peladaId: 'pelada-teste-1',
          currentUser: _organizadorUser(),
          data: data,
        );
        await tester.tap(find.text('Avulso'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
        await tester.pumpAndSettle();
        expect(
          find.text('Novo Participante Avulso'),
          findsNothing,
          reason: 'Botão Cancelar fecha o modal',
        );
      });
    },
  );

  group('ParticipantsScreen · E2E · Validação Formulário Avulso', () {
    testWidgets('8. Submeter VAZIO mostra erros em campos obrigatórios', (
      tester,
    ) async {
      final data = _SmartFakeDataService(peladas: [_buildPelada()]);
      await pump(
        tester,
        peladaId: 'pelada-teste-1',
        currentUser: _organizadorUser(),
        data: data,
      );
      await tester.tap(find.text('Avulso'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Campo obrigatório.'),
        findsNWidgets(2),
        reason: 'Nome e Idade obrigatórios não preenchidos.',
      );
      expect(
        find.text('Selecione a posição principal.'),
        findsOneWidget,
        reason: 'Posição principal obrigatória não selecionada.',
      );
    });

    testWidgets('9. Valida Idade: 4 anos → erro mínimo; 95 → erro máximo', (
      tester,
    ) async {
      final data = _SmartFakeDataService(peladas: [_buildPelada()]);
      await pump(
        tester,
        peladaId: 'pelada-teste-1',
        currentUser: _organizadorUser(),
        data: data,
      );
      await tester.tap(find.text('Avulso'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('avulso_idade')), '4');
      await tester.enterText(find.byKey(const Key('avulso_nome')), 'Carlos');
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
      await tester.pumpAndSettle();
      expect(find.text('Idade mínima permitida: 5 anos.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('avulso_idade')), '95');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
      await tester.pumpAndSettle();
      expect(find.text('Idade máxima permitida: 90 anos.'), findsOneWidget);
    });

    testWidgets('10. Nome com 1 caractere → erro min 2 chars', (tester) async {
      final data = _SmartFakeDataService(peladas: [_buildPelada()]);
      await pump(
        tester,
        peladaId: 'pelada-teste-1',
        currentUser: _organizadorUser(),
        data: data,
      );
      await tester.tap(find.text('Avulso'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('avulso_nome')), 'Z');
      await tester.enterText(find.byKey(const Key('avulso_idade')), '25');
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
      await tester.pumpAndSettle();
      expect(find.text('Informe ao menos 2 caracteres.'), findsOneWidget);
    });

    testWidgets('11. Idade não-numérica bloqueada por formatter', (
      tester,
    ) async {
      final data = _SmartFakeDataService(peladas: [_buildPelada()]);
      await pump(
        tester,
        peladaId: 'pelada-teste-1',
        currentUser: _organizadorUser(),
        data: data,
      );
      await tester.tap(find.text('Avulso'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('avulso_idade')), 'abc25!@#');
      await tester.pumpAndSettle();
      final idadeField = tester.widget<TextFormField>(
        find.byKey(const Key('avulso_idade')),
      );
      final idadeVal = (idadeField.controller?.text ?? '');
      expect(
        idadeVal,
        '25',
        reason:
            'FilteringTextInputFormatter.digitsOnly deve descartar tudo que não for dígito',
      );
    });
  });

  group('ParticipantsScreen · E2E · Submissão Válida e Atualização do Quorum', () {
    testWidgets(
      '12. Dados VÁLIDOS → Participante entra em Confirmados e QUORUM atualiza (N→N+1)',
      (tester) async {
        final pelada = _buildPelada(confirmados: 3, quorumMax: 22);
        final participations = [
          _buildParticipation(
            id: 'p1',
            peladaId: pelada.id,
            usuarioId: 'u1',
            nome: 'Participante 1',
            posicao: PosicaoAtleta.zagaFixo,
          ),
          _buildParticipation(
            id: 'p2',
            peladaId: pelada.id,
            usuarioId: 'u2',
            nome: 'Participante 2',
            apelido: 'P2',
            posicao: PosicaoAtleta.lateralAla,
          ),
          _buildParticipation(
            id: 'p3',
            peladaId: pelada.id,
            usuarioId: 'u3',
            nome: 'Participante 3',
            posicao: PosicaoAtleta.meia,
          ),
        ];
        final data = _SmartFakeDataService(
          peladas: [pelada],
          participations: participations,
        );
        await pump(
          tester,
          peladaId: 'pelada-teste-1',
          currentUser: _organizadorUser(),
          data: data,
        );

        expect(
          find.text('3 confirmados • 3/22 vagas'),
          findsOneWidget,
          reason:
              'Quorum inicial = 3 (lista e Pelada.participantesConfirmados sincronizados)',
        );
        expect(
          find.text('Confirmados (3)'),
          findsOneWidget,
          reason:
              'Título da sessão mostra contagem de participantes confirmados',
        );

        await tester.tap(find.text('Avulso'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('avulso_nome')),
          'João Souza Silva',
        );
        await tester.enterText(
          find.byKey(const Key('avulso_apelido')),
          'Jão Bola',
        );
        await tester.enterText(find.byKey(const Key('avulso_idade')), '28');

        await tester.tap(find.byKey(const Key('avulso_posicao')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Atacante / Pivô').last);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(
          find.text('João Souza Silva'),
          findsOneWidget,
          reason: 'Nome do avulso aparece na lista de confirmados',
        );
        expect(
          find.text('Confirmados (4)'),
          findsOneWidget,
          reason: 'Título da sessão atualiza de 3 → 4',
        );
        final updatedPel = data.getPeladaById('pelada-teste-1');
        expect(updatedPel, isNotNull);
        expect(
          updatedPel!.participantesConfirmados,
          4,
          reason: 'Quorum passa de 3 → 4 após adição',
        );
        final participationsFinal = data.getParticipationsByPelada(
          'pelada-teste-1',
        );
        final avulso = participationsFinal.firstWhere(
          (p) => p.usuarioNome == 'João Souza Silva',
        );
        expect(
          avulso.status,
          StatusParticipacao.confirmada,
          reason: 'Status deve ser CONFIRMADA',
        );
        expect(avulso.usuarioApelido, 'Jão Bola');
        expect(avulso.usuarioPosicaoPrincipal, PosicaoAtleta.atacantePivo);
        expect(
          avulso.usuarioId.startsWith('avulso_'),
          isTrue,
          reason: 'Usuário avulso deve ter id prefixado com "avulso_"',
        );
        expect(avulso.observacao, contains('Participante avulso'));
        expect(avulso.observacao, contains('28'));
      },
    );

    testWidgets(
      '13. Adição consecutiva de 2 avulsos → quorum N → N+2, listagem duplicada',
      (tester) async {
        final pelada = _buildPelada(confirmados: 1, quorumMax: 22);
        final participations = [
          _buildParticipation(
            id: 'seed',
            peladaId: pelada.id,
            usuarioId: 'u-seed',
            nome: 'Jogador Inicial',
            posicao: PosicaoAtleta.zagaFixo,
          ),
        ];
        final data = _SmartFakeDataService(
          peladas: [pelada],
          participations: participations,
        );
        await pump(
          tester,
          peladaId: 'pelada-teste-1',
          currentUser: _organizadorUser(),
          data: data,
        );
        expect(
          data.getPeladaById('pelada-teste-1')!.participantesConfirmados,
          1,
        );

        Future<void> adicionarUm({
          required String nome,
          required String apelido,
          required int idade,
          required String posicaoLabel,
        }) async {
          await tester.tap(find.text('Avulso'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const Key('avulso_nome')), nome);
          await tester.enterText(
            find.byKey(const Key('avulso_apelido')),
            apelido,
          );
          await tester.enterText(
            find.byKey(const Key('avulso_idade')),
            idade.toString(),
          );
          await tester.tap(find.byKey(const Key('avulso_posicao')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(posicaoLabel).last);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        await adicionarUm(
          nome: 'Primeiro Jogador',
          apelido: 'Primo',
          idade: 24,
          posicaoLabel: 'Goleiro',
        );
        expect(
          data.getPeladaById('pelada-teste-1')!.participantesConfirmados,
          2,
        );

        await adicionarUm(
          nome: 'Segundo Jogador',
          apelido: 'Segudo',
          idade: 31,
          posicaoLabel: 'Meia',
        );
        expect(
          data.getPeladaById('pelada-teste-1')!.participantesConfirmados,
          3,
        );
        expect(find.text('Primeiro Jogador'), findsOneWidget);
        expect(find.text('Segundo Jogador'), findsOneWidget);
      },
    );

    testWidgets('14. QUÓRUM CHEIO → botão +AVULSO bloqueia adição com aviso', (
      tester,
    ) async {
      final pelada = _buildPelada(confirmados: 10, quorumMax: 10);
      final seed = List<Participation>.generate(
        10,
        (i) => _buildParticipation(
          id: 's$i',
          peladaId: pelada.id,
          usuarioId: 'u$i',
          nome: 'Jogador Seed $i',
        ),
      );
      final data = _SmartFakeDataService(
        peladas: [pelada],
        participations: seed,
      );
      await pump(
        tester,
        peladaId: 'pelada-teste-1',
        currentUser: _organizadorUser(),
        data: data,
      );
      await tester.tap(find.text('Avulso'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.textContaining('Quórum máximo já atingido'),
        findsOneWidget,
        reason: 'Aviso mostra quórum cheio antes de abrir formulário.',
      );
      expect(
        find.text('Novo Participante Avulso'),
        findsNothing,
        reason: 'Modal NÃO deve ser aberto',
      );
    });
  });
}
