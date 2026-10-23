import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:peladeiros_sa/core/theme/theme_provider.dart';
import 'package:peladeiros_sa/models/campo_arena.dart';
import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/models/juiz.dart';
import 'package:peladeiros_sa/models/pelada.dart';
import 'package:peladeiros_sa/models/pelada_filter.dart';
import 'package:peladeiros_sa/models/participation.dart';
import 'package:peladeiros_sa/models/user_profile.dart';
import 'package:peladeiros_sa/services/auth_service.dart';
import 'package:peladeiros_sa/services/data_service.dart';
import 'package:provider/provider.dart';

class FakeAuthService implements AuthService {
  final bool authenticated;
  final bool loading;
  final UserProfile? user;
  FakeAuthService({this.authenticated = true, this.loading = false, this.user});

  @override
  bool get isAuthenticated => authenticated;
  @override
  bool get isLoading => loading;
  @override
  UserProfile? get currentUser => user;
  @override
  String? get errorMessage => null;
  @override
  bool get initialized => true;
  @override
  bool get hasListeners => false;

  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  void dispose() {}
  @override
  void notifyListeners() {}
  @override
  void clearError() {}
  @override
  void forceInitialized() {}
  @override
  void mockLoginDemo() {}
  @override
  void setLoading(bool value) {}

  @override
  Future<bool> sendPasswordResetEmail(String email) async => false;
  @override
  Future<bool> signInWithEmail(String email, String senha) async => false;
  @override
  Future<bool> signInWithGoogle() async => authenticated;
  @override
  Future<void> signOut() async {}
  @override
  Future<bool> signUpWithEmail({
    required String email,
    required String senha,
    required String primeiroNome,
    required String sobrenome,
    String? apelido,
    DateTime? dataNascimento,
    String? telefone,
    String? cpf,
    Uint8List? foto,
  }) async {
    return false;
  }

  @override
  Future<bool> updatePassword(String novaSenha) async => false;
  @override
  Future<void> updateUser(UserProfile updatedProfile) async {}

  @override
  String? validateCpf(String? value) => null;
  @override
  String? validateDataNascimento(DateTime? value) => null;
  @override
  String? validateEmail(String? value) => null;
  @override
  String? validateNome(String? value, {String campo = 'Nome'}) => null;
  @override
  String? validateSenha(String? value) => null;
  @override
  String? validateTelefone(String? value) => null;

  @override
  Future<String> updateProfileAvatar({
    required Uint8List croppedJpegBytes,
    required Uint8List? thumbnailJpegBytes,
  }) async {
    return 'avatar_mock_url_${croppedJpegBytes.lengthInBytes}';
  }
}

class FakeDataService implements DataService {
  final List<Pelada> peladasList;
  final List<CampoArena> camposArenasList;
  final List<CampoArena> camposFavoritosList;
  final List<Juiz> juizesList;
  final List<Juiz> juizesFavoritosList;
  final Set<String> favoritosSet;
  final PeladaFilter filter;
  final bool loading;
  FakeDataService({
    this.peladasList = const <Pelada>[],
    this.camposArenasList = const <CampoArena>[],
    this.camposFavoritosList = const <CampoArena>[],
    this.juizesList = const <Juiz>[],
    this.juizesFavoritosList = const <Juiz>[],
    this.favoritosSet = const <String>{},
    this.filter = kEmptyFilter,
    this.loading = false,
  });

  @override
  bool get isLoading => loading;
  @override
  Set<String> get favoritos => Set<String>.unmodifiable(favoritosSet);
  @override
  bool get temFavoritos => favoritosSet.isNotEmpty;
  @override
  List<Pelada> get peladas => List<Pelada>.unmodifiable(peladasList);
  @override
  List<Pelada> get favoritas => const <Pelada>[];
  @override
  List<Pelada> get filteredPeladas => const <Pelada>[];
  @override
  List<CampoArena> get camposArenas =>
      List<CampoArena>.unmodifiable(camposArenasList);
  @override
  List<CampoArena> get camposFavoritos =>
      List<CampoArena>.unmodifiable(camposFavoritosList);
  @override
  List<Juiz> get juizes => List<Juiz>.unmodifiable(juizesList);
  @override
  List<Juiz> get juizesFavoritos =>
      List<Juiz>.unmodifiable(juizesFavoritosList);
  @override
  PeladaFilter get currentFilter => filter;
  @override
  String? get searchQuery => null;
  @override
  String? get favoritosError => null;
  @override
  String? get errorMessage => null;
  @override
  bool get hasListeners => false;
  @override
  Stream<PeladaStatusChange> get statusChanges =>
      const Stream<PeladaStatusChange>.empty();

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
  Future<List<Juiz>> carregarJuizes({bool forceRefresh = false}) async =>
      juizesList;
  @override
  void clearCache() {}
  @override
  void clearError(String field) {}
  @override
  void clearFilter() {}
  @override
  void ensurePeladasRealtime({required String usuarioId}) {}
  @override
  Pelada? findPelada(String id) {
    for (final p in peladasList) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<CampoArena?> atualizarCampoArena(CampoArena atualizado) async => null;
  @override
  Future<Juiz?> atualizarJuiz(Juiz atualizado) async => null;
  @override
  Future<Pelada?> atualizarPelada(Pelada atualizada) async => null;
  @override
  Future<bool> avaliarPelada({
    required String peladaId,
    required String usuarioId,
    required int nota,
    String? comentario,
  }) async {
    return true;
  }

  @override
  Future<PeladaBloqueioUsuario?> bloquearUsuario({
    required String peladaId,
    required String usuarioId,
    required String usuarioNome,
    required String organizadorId,
    String? motivo,
  }) async {
    return null;
  }

  @override
  Future<CampoArena?> cadastrarCampoArena(CampoArena novo) async => null;
  @override
  Future<Pelada?> cadastrarPelada(Pelada novaPelada) async => null;
  @override
  Future<int?> cadastrarPeladasRecorrentes(Pelada template) async => 0;
  @override
  Future<bool> desbloquearUsuario({
    required String peladaId,
    required String usuarioId,
  }) async {
    return true;
  }

  @override
  Future<bool> excluirCampoArena({
    required String campoArenaId,
    required String usuarioId,
  }) async {
    return true;
  }

  @override
  Future<bool> excluirJuiz({
    required String juizId,
    required String usuarioId,
  }) async {
    return true;
  }

  @override
  PeladaBloqueioUsuario? getBloqueioUsuario({
    required String peladaId,
    required String usuarioId,
  }) {
    return null;
  }

  @override
  List<PeladaBloqueioUsuario> getBloqueiosPelada(String peladaId) {
    return const <PeladaBloqueioUsuario>[];
  }

  @override
  CampoArena? getCampoArenaById(String id) {
    for (final c in camposArenasList) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  List<CampoArena> getCamposArenasDoUsuario(String usuarioId) {
    return const <CampoArena>[];
  }

  @override
  Juiz? getJuizById(String id) {
    for (final j in juizesList) {
      if (j.id == id) return j;
    }
    return null;
  }

  @override
  Juiz? getJuizByIdLocal(String juizId) {
    for (final j in juizesList) {
      if (j.id == juizId) return j;
    }
    return null;
  }

  @override
  Participation? getParticipacaoUsuario(String peladaId, String usuarioId) {
    return null;
  }

  @override
  List<Participation> getParticipationsByPelada(String peladaId) {
    return const <Participation>[];
  }

  @override
  Pelada? getPeladaById(String id) {
    for (final p in peladasList) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  bool isCampoFavorito(String id) => favoritosSet.contains('campo:$id');
  @override
  bool isFavorito(String id) => favoritosSet.contains('pelada:$id');
  @override
  bool isJuizFavorito(String id) => favoritosSet.contains('juiz:$id');

  @override
  List<Pelada> pesquisarPeladas(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return peladasList;
    return peladasList
        .where(
          (p) =>
              p.nome.toLowerCase().contains(q) ||
              (p.cidade.toLowerCase().contains(q)) ||
              (p.estado.toLowerCase().contains(q)),
        )
        .toList(growable: false);
  }

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
    return null;
  }

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
  bool isUsuarioBloqueadoParaPelada({
    required String peladaId,
    required String usuarioId,
  }) {
    return false;
  }

  @override
  Future<bool> removerParticipacao({
    required String peladaId,
    required String participationId,
    required String usuarioId,
  }) async {
    return true;
  }

  @override
  Future<bool> excluirPelada({
    required String peladaId,
    required String usuarioId,
  }) async {
    return true;
  }

  @override
  UserProfile? getUserProfile(String usuarioId) => null;

  @override
  int? get quantidadeJuizesFavoritos => juizesFavoritosList.length;

  @override
  bool? get temJuizesFavoritos => juizesFavoritosList.isNotEmpty;
}

const PeladaFilter kEmptyFilter = PeladaFilter(
  tiposChuteira: <TipoChuteira>{},
  modalidades: <Modalidade>{},
  categoriasGenero: <CategoriaGenero>{},
  diasSemana: <int>{},
  apenasAtivas: true,
);

class TestNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;
  int popCount = 0;
  int replaceCount = 0;
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    pushed.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replaceCount++;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void reset() {
    pushCount = 0;
    popCount = 0;
    replaceCount = 0;
    pushed.clear();
  }
}

Widget buildTestAppShell({
  Key? key,
  required Widget child,
  FakeAuthService? auth,
  FakeDataService? data,
  NavigatorObserver? observer,
  ThemeData? theme,
}) {
  final fakeAuth = auth ?? FakeAuthService();
  final fakeData = data ?? FakeDataService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(value: fakeAuth),
      ChangeNotifierProvider<DataService>.value(value: fakeData),
      ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
    ],
    child: MaterialApp(
      key: key,
      theme:
          theme ?? ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      debugShowCheckedModeBanner: false,
      navigatorObservers: observer != null ? [observer] : [],
      home: child,
    ),
  );
}

class _ProviderTree extends StatelessWidget {
  final Widget child;
  final AuthService auth;
  final DataService data;
  const _ProviderTree({
    required this.auth,
    required this.data,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<DataService>.value(value: data),
      ],
      child: child,
    );
  }
}
