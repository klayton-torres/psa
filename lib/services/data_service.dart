import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import 'demo_cover_images.dart';
import '../models/enums.dart';
import '../models/pelada.dart';
import '../models/campo_arena.dart';
import '../models/juiz.dart';
import '../models/goleiro.dart';
import '../models/pelada_filter.dart';
import '../models/participation.dart';
import '../models/user_profile.dart';

class PeladaStatusChange {
  final String peladaId;
  final String peladaNome;
  final String organizadorId;
  final StatusPelada oldStatus;
  final StatusPelada newStatus;
  final String? motivo;
  final DateTime at;

  const PeladaStatusChange({
    required this.peladaId,
    required this.peladaNome,
    required this.organizadorId,
    required this.oldStatus,
    required this.newStatus,
    required this.motivo,
    required this.at,
  });
}

class PeladaBloqueioUsuario {
  final String id;
  final String peladaId;
  final String usuarioId;
  final String usuarioNome;
  final String organizadorId;
  final String? motivo;
  final DateTime bloqueadoEm;
  final bool ativo;

  const PeladaBloqueioUsuario({
    required this.id,
    required this.peladaId,
    required this.usuarioId,
    required this.usuarioNome,
    required this.organizadorId,
    this.motivo,
    required this.bloqueadoEm,
    this.ativo = true,
  });

  PeladaBloqueioUsuario copyWith({
    String? id,
    String? peladaId,
    String? usuarioId,
    String? usuarioNome,
    String? organizadorId,
    String? motivo,
    DateTime? bloqueadoEm,
    bool? ativo,
  }) {
    return PeladaBloqueioUsuario(
      id: id ?? this.id,
      peladaId: peladaId ?? this.peladaId,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      organizadorId: organizadorId ?? this.organizadorId,
      motivo: motivo ?? this.motivo,
      bloqueadoEm: bloqueadoEm ?? this.bloqueadoEm,
      ativo: ativo ?? this.ativo,
    );
  }
}

class DataService with ChangeNotifier {
  // ============================================================
  // NAMESPACE — Prefixos usados no Set<String> _favoritos para
  // evitar colisões de ID entre entidades de tipos diferentes.
  // Formato armazenado:   "tipo:uuid-do-item"
  // Exemplos:             "pelada:abc-123", "campo:xyz", "juiz:777"
  // ============================================================
  static const String _kPrefixPelada = 'pelada:';
  static const String _kPrefixCampo = 'campo:';
  static const String _kPrefixJuiz = 'juiz:';
  static const String _kPrefixGoleiro = 'goleiro:';
  static const String _kStorageKey = 'psa_favoritos_v1';
  static const String _kPeladasLocaisStorageKey = 'psa_peladas_locais_v1';

  final SupabaseClient? _client;
  final Uuid _uuid = const Uuid();
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  final List<Pelada> _peladas = [];
  final List<Participation> _participations = [];
  final List<PeladaBloqueioUsuario> _bloqueios = [];
  final List<CampoArena> _camposArenas = [];
  final List<Juiz> _juizes = [];
  final Set<String> _juizesSomenteLocais = {};
  int _juizesRevision = 0;
  final List<Goleiro> _goleiros = [];
  final Set<String> _peladasSomenteLocais = {};
  final Set<String> _favoritos = {};
  final Map<String, UserProfile> _userProfiles = {};
  final StreamController<PeladaStatusChange> _statusChangesController =
      StreamController<PeladaStatusChange>.broadcast();
  RealtimeChannel? _peladasChannel;
  String? _realtimeUserId;
  bool _isLoading = false;
  int _peladasLoadGeneration = 0;
  String? _errorMessage;
  String? _favoritosError;
  late final Future<void> _peladasLocaisProntas;

  List<Pelada> get peladas => List.unmodifiable(_peladas);
  List<CampoArena> get camposArenas => List.unmodifiable(_camposArenas);
  List<Juiz> get juizes => List.unmodifiable(_juizes);
  List<Goleiro> get goleiros => List.unmodifiable(_goleiros);
  Set<String> get favoritos => Set.unmodifiable(_favoritos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get favoritosError => _favoritosError;
  PeladaFilter get currentFilter => _currentFilter;
  bool get temFavoritos => _favoritos.isNotEmpty;

  UserProfile? getUserProfile(String usuarioId) => _userProfiles[usuarioId];

  Future<UserProfile?> carregarPerfilUsuario(String usuarioId) async {
    final cached = _userProfiles[usuarioId];
    if (cached != null) return cached;

    final client = _client;
    if (client == null || usuarioId.trim().isEmpty) return null;

    try {
      var row = await client
          .from('user_profiles')
          .select()
          .eq('id', usuarioId)
          .maybeSingle();
      row ??= await client
          .from('user_profiles')
          .select()
          .eq('auth_uid', usuarioId)
          .maybeSingle();
      if (row == null) return null;

      final profile = UserProfile.fromMap(Map<String, dynamic>.from(row));
      _userProfiles[profile.id] = profile;
      final authUid = profile.authUid;
      if (authUid != null && authUid.isNotEmpty) {
        _userProfiles[authUid] = profile;
      }
      return profile;
    } catch (e) {
      debugPrint('[Data] Falha ao carregar perfil $usuarioId: $e');
      return null;
    }
  }

  // ============================================================
  // Getters de Favoritos Tipados (já filtrados por namespace)
  // ============================================================
  List<Pelada> get favoritas => _peladas
      .where((p) => _favoritos.contains('$_kPrefixPelada${p.id}'))
      .toList();

  List<CampoArena> get camposFavoritos => _camposArenas
      .where((c) => _favoritos.contains('$_kPrefixCampo${c.id}'))
      .toList();

  List<Juiz> get juizesFavoritos => _juizes
      .where((j) => _favoritos.contains('$_kPrefixJuiz${j.id}'))
      .toList();

  List<Goleiro> get goleirosFavoritos => _goleiros
      .where((g) => _favoritos.contains('$_kPrefixGoleiro${g.id}'))
      .toList();

  int get quantidadePeladasFavoritas => _contarFavoritos(_kPrefixPelada);
  int get quantidadeCamposFavoritos => _contarFavoritos(_kPrefixCampo);
  int get quantidadeJuizesFavoritos => _contarFavoritos(_kPrefixJuiz);
  int get quantidadeGoleirosFavoritos => _contarFavoritos(_kPrefixGoleiro);

  bool get temPeladasFavoritas => quantidadePeladasFavoritas > 0;
  bool get temCamposFavoritos => quantidadeCamposFavoritos > 0;
  bool get temJuizesFavoritos => quantidadeJuizesFavoritos > 0;
  bool get temGoleirosFavoritos => quantidadeGoleirosFavoritos > 0;

  int _contarFavoritos(String prefixo) =>
      _favoritos.where((favorito) => favorito.startsWith(prefixo)).length;

  Stream<PeladaStatusChange> get statusChanges =>
      _statusChangesController.stream;

  bool peladaSalvaSomenteNesteDispositivo(String peladaId) =>
      _peladasSomenteLocais.contains(peladaId);

  Future<void> _carregarPeladasLocais() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registros = prefs.getStringList(_kPeladasLocaisStorageKey) ?? [];
      for (final registro in registros) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(registro) as Map);
          final pelada = Pelada.fromMap(map);
          if (pelada.id.isEmpty) continue;
          _peladasSomenteLocais.add(pelada.id);
          final index = _peladas.indexWhere((item) => item.id == pelada.id);
          if (index == -1) {
            _peladas.add(pelada);
          } else {
            _peladas[index] = pelada;
          }
        } catch (_) {
          // Ignora apenas um registro local inválido e mantém os demais.
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Falha ao carregar peladas locais: $e';
      notifyListeners();
    }
  }

  Future<void> _persistirPeladasLocais() async {
    final porId = {
      for (final pelada in _peladas)
        if (_peladasSomenteLocais.contains(pelada.id)) pelada.id: pelada,
    };
    _peladasSomenteLocais.removeWhere((id) => !porId.containsKey(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kPeladasLocaisStorageKey,
      porId.values.map((pelada) {
        final map = pelada.toMap()..remove('organizador_cpf');
        return jsonEncode(map);
      }).toList(),
    );
  }

  Future<Pelada> _salvarPeladaSomenteLocal(Pelada pelada) async {
    final index = _peladas.indexWhere((item) => item.id == pelada.id);
    if (index == -1) {
      _peladas.insert(0, pelada);
    } else {
      _peladas[index] = pelada;
    }
    _peladasSomenteLocais.add(pelada.id);
    await _persistirPeladasLocais();
    return pelada;
  }

  PeladaFilter _currentFilter = const PeladaFilter();
  String? _searchQuery;

  static SupabaseClient? _resolveClient() {
    if (!AppConstants.hasSupabaseConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient? _clientForPelada(Pelada pelada) =>
      _client != null && _uuidPattern.hasMatch(pelada.organizadorId)
      ? _client
      : null;

  DataService({SupabaseClient? client}) : _client = client ?? _resolveClient() {
    _loadMockPeladas();
    _loadMockCamposArenas();
    _loadMockJuizes();
    _peladasLocaisProntas = _carregarPeladasLocais();
    if (_client != null) {
      unawaited(carregarPeladas());
      unawaited(carregarGoleiros());
      unawaited(carregarJuizes());
    }
    // Carrega favoritos já persistidos no SharedPreferences.
    unawaited(_carregarFavoritosPersistidos());
  }

  // ============================================================
  // Persistência Local de Favoritos (SharedPreferences)
  // Garante que o estado se mantenha após hot restart / login
  // em múltiplos dispositivos (nível local por dispositivo).
  // ============================================================
  Future<void> _carregarFavoritosPersistidos() async {
    try {
      _favoritosError = null;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kStorageKey);
      if (raw != null && raw.isNotEmpty) {
        _favoritos
          ..clear()
          ..addAll(raw);
      }
      notifyListeners();
    } catch (e) {
      _favoritosError = 'Falha ao carregar favoritos: $e';
      notifyListeners();
    }
  }

  Future<void> _persistirFavoritos() async {
    try {
      _favoritosError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _kStorageKey,
        _favoritos.toList(growable: false),
      );
    } catch (e) {
      _favoritosError = 'Falha ao salvar favoritos: $e';
      rethrow;
    }
  }

  @override
  void dispose() {
    _peladasChannel?.unsubscribe();
    _statusChangesController.close();
    super.dispose();
  }

  void ensurePeladasRealtime({required String usuarioId}) {
    if (_realtimeUserId == usuarioId && _peladasChannel != null) return;
    if (_client == null) return;
    if (!_uuidPattern.hasMatch(usuarioId)) {
      _peladasChannel?.unsubscribe();
      _peladasChannel = null;
      _realtimeUserId = null;
      return;
    }

    _realtimeUserId = usuarioId;
    _peladasChannel?.unsubscribe();
    _peladasChannel = _client.channel('public:peladas:$usuarioId');

    _peladasChannel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'peladas',
        callback: (payload) {
          final inserted = Pelada.fromMap(
            Map<String, dynamic>.from(payload.newRecord),
          );
          _peladas.removeWhere((p) => p.id == inserted.id);
          _peladas.insert(0, inserted);
          notifyListeners();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'peladas',
        callback: (payload) {
          final newRecord = payload.newRecord;
          final map = Map<String, dynamic>.from(newRecord);
          final updated = Pelada.fromMap(map);

          final idx = _peladas.indexWhere((p) => p.id == updated.id);
          final old = idx != -1 ? _peladas[idx] : null;

          if (idx != -1) {
            _peladas[idx] = updated;
          } else {
            _peladas.insert(0, updated);
          }

          if (old != null) {
            _maybeEmitStatusChange(old: old, updated: updated);
          }

          notifyListeners();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'peladas',
        callback: (payload) {
          final oldRecord = payload.oldRecord;
          final map = Map<String, dynamic>.from(oldRecord);
          final peladaId = map['id']?.toString();
          if (peladaId == null || peladaId.isEmpty) return;

          _peladas.removeWhere((p) => p.id == peladaId);
          _favoritos.remove('$_kPrefixPelada$peladaId');
          _participations.removeWhere((p) => p.peladaId == peladaId);
          notifyListeners();
        },
      )
      ..subscribe();
  }

  void stopPeladasRealtime() {
    _peladasChannel?.unsubscribe();
    _peladasChannel = null;
    _realtimeUserId = null;
  }

  void _maybeEmitStatusChange({required Pelada old, required Pelada updated}) {
    if (old.status == updated.status) return;
    if (updated.status != StatusPelada.suspensa &&
        updated.status != StatusPelada.bloqueada &&
        updated.status != StatusPelada.cancelada) {
      return;
    }

    _statusChangesController.add(
      PeladaStatusChange(
        peladaId: updated.id,
        peladaNome: updated.nome,
        organizadorId: updated.organizadorId,
        oldStatus: old.status,
        newStatus: updated.status,
        motivo: updated.statusMotivo,
        at: DateTime.now(),
      ),
    );
  }

  bool _validarDatasPelada(Pelada p) {
    final inicio = DateTime(
      p.dataInicio.year,
      p.dataInicio.month,
      p.dataInicio.day,
    );
    final fim = DateTime(p.dataFim.year, p.dataFim.month, p.dataFim.day);
    if (fim.isBefore(inicio)) {
      _errorMessage = 'A data fim não pode ser anterior à data inicial';
      return false;
    }
    final limite = inicio.add(const Duration(days: 90));
    if (fim.isAfter(limite)) {
      _errorMessage =
          'A data fim não pode ultrapassar 90 dias consecutivos após a data inicial';
      return false;
    }
    return true;
  }

  List<Pelada> get filteredPeladas {
    var result = _peladas.toList();
    final f = _currentFilter;
    final now = DateTime.now();
    result = result.where((p) {
      final fim = DateTime(
        p.dataFim.year,
        p.dataFim.month,
        p.dataFim.day,
        p.horaFim.hour,
        p.horaFim.minute,
      );
      if (!fim.isBefore(now)) return true;
      final withinRetention = now.difference(fim) <= const Duration(days: 15);
      return f.mostrarPassadas && withinRetention;
    }).toList();

    if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
      final q = _searchQuery!.trim().toLowerCase();
      result = result.where((p) {
        return p.nome.toLowerCase().contains(q) ||
            p.cidade.toLowerCase().contains(q) ||
            p.organizadorNome.toLowerCase().contains(q) ||
            p.endereco.toLowerCase().contains(q) ||
            p.bairro.toLowerCase().contains(q) ||
            p.localArena.toLowerCase().contains(q);
      }).toList();
    }

    if (f.estado != null) {
      result = result.where((p) => p.estado == f.estado).toList();
    }
    if (f.cidade != null) {
      result = result
          .where((p) => p.cidade.toLowerCase() == f.cidade!.toLowerCase())
          .toList();
    }
    if (f.bairro != null) {
      result = result
          .where((p) => p.bairro.toLowerCase() == f.bairro!.toLowerCase())
          .toList();
    }
    if (f.localArena != null) {
      final q = f.localArena!.trim().toLowerCase();
      result = result
          .where((p) => p.localArena.toLowerCase().contains(q))
          .toList();
    }
    if (f.dataInicio != null) {
      result = result
          .where((p) => !p.dataInicio.isBefore(f.dataInicio!))
          .toList();
    }
    if (f.dataFim != null) {
      result = result.where((p) => !p.dataFim.isAfter(f.dataFim!)).toList();
    }
    if (f.horarioInicio != null) {
      result = result.where((p) {
        final t = p.horaInicio.hour * 60 + p.horaInicio.minute;
        final f1 = f.horarioInicio!.hour * 60 + f.horarioInicio!.minute;
        return t >= f1;
      }).toList();
    }
    if (f.horarioFim != null) {
      result = result.where((p) {
        final t = p.horaFim.hour * 60 + p.horaFim.minute;
        final f1 = f.horarioFim!.hour * 60 + f.horarioFim!.minute;
        return t <= f1;
      }).toList();
    }
    if (f.faixaEtaria != null) {
      result = result.where((p) => p.categoria == f.faixaEtaria).toList();
    }
    if (f.tipoCampo != null) {
      result = result.where((p) => p.tipoGrama == f.tipoCampo).toList();
    }
    if (f.tiposChuteira.isNotEmpty) {
      result = result.where((p) {
        if (f.tiposChuteira.contains(p.tipoChuteira)) return true;
        final permitidos = p.tiposChuteiraPermitidos;
        if (permitidos.isEmpty) return false;
        return permitidos.any(f.tiposChuteira.contains);
      }).toList();
    }
    if (f.modalidades.isNotEmpty) {
      result = result
          .where((p) => f.modalidades.contains(p.modalidade))
          .toList();
    }
    if (f.categoriasGenero.isNotEmpty) {
      result = result
          .where((p) => f.categoriasGenero.contains(p.categoriaGenero))
          .toList();
    }
    if (f.diasSemana.isNotEmpty) {
      result = result.where((p) {
        final wd = p.dataInicio.weekday;
        final brWeekday = wd == DateTime.sunday ? 1 : wd + 1;
        return f.diasSemana.contains(brWeekday);
      }).toList();
    }
    if (f.apenasAtivas == true) {
      result = result.where((p) => p.status == StatusPelada.ativa).toList();
    }
    if (f.apenasComVagas == true) {
      result = result.where((p) => p.temVagas).toList();
    }

    result.sort((a, b) {
      final aDate = DateTime(
        a.dataInicio.year,
        a.dataInicio.month,
        a.dataInicio.day,
        a.horaInicio.hour,
        a.horaInicio.minute,
      );
      final bDate = DateTime(
        b.dataInicio.year,
        b.dataInicio.month,
        b.dataInicio.day,
        b.horaInicio.hour,
        b.horaInicio.minute,
      );
      return aDate.compareTo(bDate);
    });

    return result;
  }

  void setFilter(PeladaFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void clearFilter() {
    _currentFilter = const PeladaFilter();
    notifyListeners();
  }

  void setSearch(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  Pelada? getPeladaById(String id) {
    try {
      return _peladas.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // Favoritos de PELADAS (mantidos 100% compatíveis com chamadas
  // antigas que só passavam o ID da pelada: automaticamente
  // adicionamos o namespace "pelada:" internamente).
  // ============================================================
  Future<void> toggleFavorito(String peladaId) async {
    final chave = '$_kPrefixPelada$peladaId';
    try {
      _favoritosError = null;
      if (_favoritos.contains(chave)) {
        _favoritos.remove(chave);
      } else {
        _favoritos.add(chave);
      }
      notifyListeners();
      await _persistirFavoritos();
    } catch (e) {
      // Mantém o estado em memória mesmo se persistir falhar.
      notifyListeners();
      rethrow;
    }
  }

  bool isFavorito(String peladaId) {
    return _favoritos.contains('$_kPrefixPelada$peladaId');
  }

  // ============================================================
  // Favoritos de CAMPOS E ARENAS
  // ============================================================
  Future<void> toggleCampoFavorito(String campoId) async {
    final chave = '$_kPrefixCampo$campoId';
    try {
      _favoritosError = null;
      if (_favoritos.contains(chave)) {
        _favoritos.remove(chave);
      } else {
        _favoritos.add(chave);
      }
      notifyListeners();
      await _persistirFavoritos();
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  bool isCampoFavorito(String campoId) {
    return _favoritos.contains('$_kPrefixCampo$campoId');
  }

  // ============================================================
  // Favoritos de JUÍZES
  // ============================================================
  Future<void> toggleJuizFavorito(String juizId) async {
    final chave = '$_kPrefixJuiz$juizId';
    try {
      _favoritosError = null;
      if (_favoritos.contains(chave)) {
        _favoritos.remove(chave);
      } else {
        _favoritos.add(chave);
      }
      notifyListeners();
      await _persistirFavoritos();
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  bool isJuizFavorito(String juizId) {
    return _favoritos.contains('$_kPrefixJuiz$juizId');
  }

  Future<void> toggleGoleiroFavorito(String goleiroId) async {
    final chave = '$_kPrefixGoleiro$goleiroId';
    try {
      _favoritosError = null;
      if (_favoritos.contains(chave)) {
        _favoritos.remove(chave);
      } else {
        _favoritos.add(chave);
      }
      notifyListeners();
      await _persistirFavoritos();
    } catch (_) {
      notifyListeners();
      rethrow;
    }
  }

  bool isGoleiroFavorito(String goleiroId) =>
      _favoritos.contains('$_kPrefixGoleiro$goleiroId');

  Goleiro? getGoleiroById(String id) {
    try {
      return _goleiros.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> carregarGoleiros() async {
    if (_client == null) return;
    try {
      final rows = await _client
          .from('goleiros')
          .select()
          .order('created_at', ascending: false);
      final carregados = (rows as List)
          .map((row) => Goleiro.fromMap(Map<String, dynamic>.from(row)))
          .toList();
      final goleirosLocais = _goleiros
          .where((g) => !_uuidPattern.hasMatch(g.proprietarioId ?? ''))
          .toList();
      _goleiros
        ..clear()
        ..addAll(carregados)
        ..addAll(
          goleirosLocais.where(
            (local) => !carregados.any((remoto) => remoto.id == local.id),
          ),
        );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar goleiros: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> carregarJuizes() async {
    if (_client == null) return;
    final revisionAtStart = _juizesRevision;
    try {
      final rows = await _client
          .from('juizes')
          .select()
          .order('created_at', ascending: false);
      final carregados = (rows as List)
          .map((row) => Juiz.fromMap(Map<String, dynamic>.from(row)))
          .toList();
      // A carga pode ter começado antes de uma publicação. Nesse caso, não
      // deixa uma resposta antiga apagar a alteração local recém-confirmada.
      if (revisionAtStart != _juizesRevision) return;
      final carregadosIds = carregados.map((juiz) => juiz.id).toSet();
      final locais = _juizes
          .where(
            (juiz) =>
                _juizesSomenteLocais.contains(juiz.id) &&
                !carregadosIds.contains(juiz.id),
          )
          .toList(growable: false);
      _juizes
        ..clear()
        ..addAll(carregados)
        ..addAll(locais);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar juízes: ${e.toString()}';
      notifyListeners();
    }
  }

  Juiz? getJuizById(String id) {
    try {
      return _juizes.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> carregarPeladas({
    String? usuarioId,
    String? estado,
    String? cidade,
  }) async {
    final generation = ++_peladasLoadGeneration;
    _isLoading = true;
    notifyListeners();
    try {
      await _peladasLocaisProntas;
      final userId = usuarioId ?? _client?.auth.currentUser?.id;
      final idValido = userId == null || _uuidPattern.hasMatch(userId);
      if (_client != null && idValido) {
        final rows = await _client
            .from('peladas')
            .select()
            .order('data_inicio');
        final peladasDb = (rows as List)
            .map((row) => Pelada.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();

        if (userId != null && userId.isNotEmpty) {
          try {
            final privateRows = await _client
                .from('peladas_private')
                .select('pelada_id, organizador_cpf')
                .eq('organizador_id', userId);
            final cpfs = <String, String>{
              for (final row in privateRows as List)
                row['pelada_id'].toString(): row['organizador_cpf'].toString(),
            };
            for (var i = 0; i < peladasDb.length; i++) {
              final cpf = cpfs[peladasDb[i].id];
              if (cpf != null)
                peladasDb[i] = peladasDb[i].copyWith(organizadorCpf: cpf);
            }
          } catch (_) {
            // CPF é privado e não impede a exibição dos eventos públicos.
          }
        }

        final locaisDoUsuario = _peladas.where(
          (pelada) =>
              _peladasSomenteLocais.contains(pelada.id) &&
              (userId == null || pelada.organizadorId == userId),
        );
        for (final local in locaisDoUsuario) {
          if (!peladasDb.any((pelada) => pelada.id == local.id)) {
            peladasDb.add(local);
          }
        }

        if (generation == _peladasLoadGeneration) {
          _peladas
            ..clear()
            ..addAll(peladasDb);
        }
      } else if (_client != null && !idValido) {
        // IDs de sessões demonstrativas não existem no Supabase. Preserve
        // os registros locais dessa sessão em vez de limpar a lista.
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (generation != _peladasLoadGeneration) return;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (generation != _peladasLoadGeneration) return;
      _errorMessage = 'Erro ao carregar peladas: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Pelada?> cadastrarPelada(Pelada novaPelada) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (novaPelada.fotosCapa.length > 2) {
        _errorMessage = 'Limite de 2 fotos de capa por pelada';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      if (!_validarDatasPelada(novaPelada)) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      final peladaComId = novaPelada.copyWith(
        id: novaPelada.id.isEmpty ? _uuid.v4() : novaPelada.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final client = _clientForPelada(peladaComId);
      if (client != null) {
        final payload = peladaComId.toMap()..remove('organizador_cpf');
        final row = await client
            .from('peladas')
            .insert(payload)
            .select()
            .single();
        final saved = Pelada.fromMap(Map<String, dynamic>.from(row));
        final cpf = peladaComId.organizadorCpf;
        if (cpf != null && cpf.trim().isNotEmpty) {
          await client.from('peladas_private').upsert({
            'pelada_id': saved.id,
            'organizador_id': saved.organizadorId,
            'organizador_cpf': cpf.trim(),
          }, onConflict: 'pelada_id');
        }
        _peladas.insert(0, saved.copyWith(organizadorCpf: cpf));
        _isLoading = false;
        notifyListeners();
        return saved.copyWith(organizadorCpf: cpf);
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await _salvarPeladaSomenteLocal(peladaComId);
      _isLoading = false;
      notifyListeners();
      return peladaComId;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar pelada: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<int?> cadastrarPeladasRecorrentes(Pelada template) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (template.fotosCapa.length > 2) {
        _errorMessage = 'Limite de 2 fotos de capa por pelada';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      if (!_validarDatasPelada(template)) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      final diasSemana = template.recorrenciaDiasSemana.toSet();
      if (diasSemana.isEmpty) {
        _errorMessage = 'Selecione ao menos um dia da semana para repetir';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final start = DateTime(
        template.dataInicio.year,
        template.dataInicio.month,
        template.dataInicio.day,
      );
      final end = DateTime(
        template.dataFim.year,
        template.dataFim.month,
        template.dataFim.day,
      );

      final List<DateTime> ocorrencias = [];
      var cursor = start;
      while (!cursor.isAfter(end)) {
        if (diasSemana.contains(cursor.weekday)) {
          ocorrencias.add(cursor);
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      if (ocorrencias.isEmpty) {
        _errorMessage =
            'Nenhuma sessão encontrada no período para os dias selecionados';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      await Future.delayed(const Duration(milliseconds: 900));

      final grupoId = _uuid.v4();
      for (final d in ocorrencias.reversed) {
        final peladaComId = template.copyWith(
          id: _uuid.v4(),
          dataInicio: d,
          dataFim: d,
          recorrenciaGrupoId: grupoId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final salvo = await cadastrarPelada(peladaComId);
        if (salvo == null)
          throw Exception(_errorMessage ?? 'Erro ao salvar evento recorrente');
      }

      _isLoading = false;
      notifyListeners();
      return ocorrencias.length;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar pelada: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Pelada?> atualizarPelada(Pelada atualizada) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (atualizada.fotosCapa.length > 2) {
        _errorMessage = 'Limite de 2 fotos de capa por pelada';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      if (!_validarDatasPelada(atualizada)) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      final idx = _peladas.indexWhere((p) => p.id == atualizada.id);
      final client = _clientForPelada(atualizada);
      if (client != null) {
        final payload = atualizada.copyWith(updatedAt: DateTime.now()).toMap()
          ..remove('organizador_cpf');
        final row = await client
            .from('peladas')
            .update(payload)
            .eq('id', atualizada.id)
            .select()
            .maybeSingle();
        if (row == null)
          throw Exception(
            'Pelada não encontrada ou sem permissão para editar.',
          );
        final saved = Pelada.fromMap(Map<String, dynamic>.from(row));
        if (_peladasSomenteLocais.remove(saved.id)) {
          try {
            await _persistirPeladasLocais();
          } catch (_) {
            // A limpeza do cache local não invalida a gravação remota.
          }
        }
        final cpf = atualizada.organizadorCpf;
        if (cpf != null && cpf.trim().isNotEmpty) {
          await client.from('peladas_private').upsert({
            'pelada_id': saved.id,
            'organizador_id': saved.organizadorId,
            'organizador_cpf': cpf.trim(),
          }, onConflict: 'pelada_id');
        }
        final old = idx != -1 ? _peladas[idx] : saved;
        if (idx != -1) {
          _peladas[idx] = saved.copyWith(organizadorCpf: cpf);
        } else {
          _peladas.insert(0, saved.copyWith(organizadorCpf: cpf));
        }
        _maybeEmitStatusChange(old: old, updated: saved);
        _isLoading = false;
        notifyListeners();
        return saved.copyWith(organizadorCpf: cpf);
      }
      await Future.delayed(const Duration(milliseconds: 300));
      if (idx != -1) {
        final old = _peladas[idx];
        final saved = atualizada.copyWith(updatedAt: DateTime.now());
        await _salvarPeladaSomenteLocal(saved);
        _maybeEmitStatusChange(old: old, updated: saved);
      }
      _isLoading = false;
      notifyListeners();
      return idx != -1 ? _peladas[idx] : null;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar pelada: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> excluirPelada({
    required String peladaId,
    required String usuarioId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pelada = getPeladaById(peladaId);
      if (pelada == null) {
        _errorMessage = 'Pelada não encontrada';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (pelada.organizadorId != usuarioId) {
        _errorMessage = 'Você não tem permissão para excluir esta pelada';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final client = _clientForPelada(pelada);
      if (client != null) {
        await client.from('peladas').delete().eq('id', peladaId);
      }

      _peladas.removeWhere((p) => p.id == peladaId);
      final eraSomenteLocal = _peladasSomenteLocais.remove(peladaId);
      _favoritos.remove('$_kPrefixPelada$peladaId');
      _participations.removeWhere((p) => p.peladaId == peladaId);
      if (eraSomenteLocal) await _persistirPeladasLocais();
      _isLoading = false;
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao excluir pelada: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Participation> getParticipationsByPelada(String peladaId) {
    final raw = _participations.where((p) => p.peladaId == peladaId);
    if (_userProfiles.isEmpty) return raw.toList();
    return raw.map((p) {
      final profile = _userProfiles[p.usuarioId];
      if (profile == null) return p;
      final apelidoAtual = p.usuarioApelido;
      final posAtual = p.usuarioPosicaoPrincipal;
      final novoApelido =
          (apelidoAtual != null && apelidoAtual.trim().isNotEmpty)
          ? apelidoAtual
          : (profile.apelido != null && profile.apelido!.trim().isNotEmpty
                ? profile.apelido!
                : apelidoAtual);
      final novaPosicao = posAtual ?? profile.posicaoPrincipal;
      if (novoApelido == apelidoAtual && novaPosicao == posAtual) return p;
      return p.copyWith(
        usuarioApelido: novoApelido,
        usuarioPosicaoPrincipal: novaPosicao,
      );
    }).toList();
  }

  List<CampoArena> getCamposArenasDoUsuario(String usuarioId) {
    return _camposArenas.where((c) => c.proprietarioId == usuarioId).toList();
  }

  CampoArena? getCampoArenaById(String id) {
    try {
      return _camposArenas.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<CampoArena?> cadastrarCampoArena(CampoArena novo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (novo.nome.trim().isEmpty) {
        _errorMessage = 'Nome do campo é obrigatório';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      if (novo.responsavelNome.trim().isEmpty) {
        _errorMessage = 'Responsável pelo estabelecimento é obrigatório';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      if (novo.estado.trim().isEmpty || novo.cidade.trim().isEmpty) {
        _errorMessage = 'Estado e cidade são obrigatórios';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      await Future.delayed(const Duration(milliseconds: 600));
      final agora = DateTime.now();
      final comId = novo.copyWith(
        id: novo.id.isEmpty ? _uuid.v4() : novo.id,
        createdAt: novo.createdAt.toIso8601String().startsWith('0000')
            ? agora
            : novo.createdAt,
        updatedAt: agora,
      );
      if (_client != null) {
        try {
          await _client.from('campos_arenas').insert(comId.toMap());
        } catch (_) {
          // tabela pode ainda não existir, segue em modo local
        }
      }
      _camposArenas.insert(0, comId);
      _isLoading = false;
      notifyListeners();
      return comId;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar campo: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<CampoArena?> atualizarCampoArena(CampoArena atualizado) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final agora = DateTime.now();
      final salvo = atualizado.copyWith(updatedAt: agora);
      final idx = _camposArenas.indexWhere((c) => c.id == salvo.id);
      if (idx == -1) {
        _camposArenas.insert(0, salvo);
      } else {
        _camposArenas[idx] = salvo;
      }
      if (_client != null) {
        try {
          await _client
              .from('campos_arenas')
              .update(salvo.toMap())
              .eq('id', salvo.id);
        } catch (_) {
          // tabela pode não existir, segue em modo local
        }
      }
      _isLoading = false;
      notifyListeners();
      return salvo;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar campo: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> excluirCampoArena({
    required String campoArenaId,
    required String usuarioId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final c = getCampoArenaById(campoArenaId);
      if (c == null) {
        _errorMessage = 'Campo não encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (c.proprietarioId != null && c.proprietarioId != usuarioId) {
        _errorMessage = 'Você não tem permissão para excluir este campo';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      if (_client != null) {
        try {
          await _client.from('campos_arenas').delete().eq('id', campoArenaId);
        } catch (_) {
          // tabela pode não existir, segue em modo local
        }
      }
      _camposArenas.removeWhere((x) => x.id == campoArenaId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir campo: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Juiz? getJuizByIdLocal(String juizId) {
    try {
      return _juizes.firstWhere((j) => j.id == juizId);
    } catch (_) {
      return null;
    }
  }

  Goleiro? getGoleiroByIdLocal(String goleiroId) => getGoleiroById(goleiroId);

  Future<Goleiro?> atualizarGoleiro(Goleiro atualizado) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      var salvo = atualizado.copyWith(updatedAt: DateTime.now());
      final idx = _goleiros.indexWhere((g) => g.id == salvo.id);
      var persistirNoBanco = false;
      if (_client != null &&
          idx == -1 &&
          _uuidPattern.hasMatch(salvo.proprietarioId ?? '')) {
        final authUid = _client.auth.currentUser?.id;
        if (authUid != null && _uuidPattern.hasMatch(authUid)) {
          final perfil = await _client
              .from('user_profiles')
              .select('id')
              .eq('auth_uid', authUid)
              .maybeSingle();
          final perfilId = perfil?['id']?.toString();
          if (perfilId != null && _uuidPattern.hasMatch(perfilId)) {
            salvo = salvo.copyWith(proprietarioId: perfilId);
            persistirNoBanco = true;
          }
        }
      } else if (_client != null && idx != -1) {
        final authUid = _client.auth.currentUser?.id;
        persistirNoBanco =
            authUid != null &&
            _uuidPattern.hasMatch(authUid) &&
            _uuidPattern.hasMatch(salvo.proprietarioId ?? '');
      }
      if (idx == -1) {
        _goleiros.insert(0, salvo);
      } else {
        _goleiros[idx] = salvo;
      }
      if (persistirNoBanco) {
        final client = _client;
        if (client == null) {
          throw StateError('Cliente Supabase indisponível para salvar goleiro.');
        }
        try {
          if (idx == -1) {
            await client.from('goleiros').insert(salvo.toMap());
          } else {
            await client
                .from('goleiros')
                .update(salvo.toMap())
                .eq('id', salvo.id);
          }
        } catch (e) {
          _errorMessage = 'Erro ao salvar goleiro no banco: ${e.toString()}';
          _goleiros.removeWhere((g) => g.id == salvo.id);
          if (idx != -1) _goleiros.insert(idx, atualizado);
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }
      _isLoading = false;
      notifyListeners();
      return salvo;
    } catch (e) {
      _errorMessage = 'Erro ao salvar goleiro: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> excluirGoleiro({
    required String goleiroId,
    required String usuarioId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final goleiro = getGoleiroById(goleiroId);
      if (goleiro == null) {
        _errorMessage = 'Goleiro não encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (goleiro.proprietarioId != null &&
          goleiro.proprietarioId != usuarioId) {
        _errorMessage = 'Você não tem permissão para excluir este goleiro';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (_client != null) {
        try {
          await _client.from('goleiros').delete().eq('id', goleiroId);
        } catch (e) {
          _errorMessage = 'Erro ao excluir goleiro do banco: ${e.toString()}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      _goleiros.removeWhere((g) => g.id == goleiroId);
      _favoritos.remove('$_kPrefixGoleiro$goleiroId');
      await _persistirFavoritos();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir goleiro: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Juiz?> atualizarJuiz(
    Juiz atualizado, {
    bool salvarLocalmente = false,
    UserProfile? proprietario,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final agora = DateTime.now();
      var salvo = atualizado.copyWith(updatedAt: agora);
      final idx = _juizes.indexWhere((j) => j.id == salvo.id);
      if (_client != null && !salvarLocalmente) {
        final client = _client!;
        if (idx == -1) {
          final authUid = client.auth.currentUser?.id;
          if (authUid == null || !_uuidPattern.hasMatch(authUid)) {
            throw StateError(
              'A sessão Supabase expirou. Entre novamente para publicar o juiz.',
            );
          }
          final perfil = await client
              .from('user_profiles')
              .select('id')
              .eq('auth_uid', authUid)
              .maybeSingle();
          var perfilId = perfil?['id']?.toString();
          if (perfilId == null && proprietario != null) {
            final nome = proprietario.primeiroNome.trim();
            final perfilCriado = await client
                .from('user_profiles')
                .upsert({
                  'auth_uid': authUid,
                  'primeiro_nome': nome.isEmpty ? 'Usuário' : nome,
                  'sobrenome': proprietario.sobrenome.trim(),
                  'apelido': proprietario.apelido,
                  'email': proprietario.email,
                  'created_at': proprietario.createdAt.toIso8601String(),
                  'updated_at': agora.toIso8601String(),
                }, onConflict: 'auth_uid')
                .select('id')
                .single();
            perfilId = perfilCriado['id']?.toString();
          }
          if (perfilId == null || !_uuidPattern.hasMatch(perfilId)) {
            throw StateError(
              'Não foi possível localizar o perfil do usuário para publicar o juiz.',
            );
          }
          salvo = salvo.copyWith(proprietarioId: perfilId);
          await client
              .from('juizes')
              .insert(salvo.toMap())
              .select('id')
              .single();
        } else {
          final atualizadoNoBanco = await client
              .from('juizes')
              .update(salvo.toMap())
              .eq('id', salvo.id)
              .select('id')
              .maybeSingle();
          if (atualizadoNoBanco == null) {
            throw StateError(
              'O juiz não foi encontrado ou você não tem permissão para atualizá-lo.',
            );
          }
        }
      }
      if (idx == -1) {
        _juizes.insert(0, salvo);
      } else {
        _juizes[idx] = salvo;
      }
      if (salvarLocalmente) {
        _juizesSomenteLocais.add(salvo.id);
      } else {
        _juizesSomenteLocais.remove(salvo.id);
      }
      _juizesRevision++;
      _isLoading = false;
      notifyListeners();
      return salvo;
    } catch (e) {
      _errorMessage = 'Erro ao salvar juiz: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> excluirJuiz({
    required String juizId,
    required String usuarioId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final j = getJuizById(juizId);
      if (j == null) {
        _errorMessage = 'Juiz não encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (j.proprietarioId != null && j.proprietarioId != usuarioId) {
        _errorMessage = 'Você não tem permissão para excluir este juiz';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      if (_client != null) {
        try {
          await _client.from('juizes').delete().eq('id', juizId);
        } catch (_) {
          // tabela pode não existir, segue em modo local
        }
      }
      _juizes.removeWhere((x) => x.id == juizId);
      _juizesSomenteLocais.remove(juizId);
      _juizesRevision++;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir juiz: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Participation? getParticipacaoUsuario(String peladaId, String usuarioId) {
    try {
      return _participations.firstWhere(
        (p) => p.peladaId == peladaId && p.usuarioId == usuarioId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<Participation?> registrarParticipacao({
    required String peladaId,
    required String usuarioId,
    required String usuarioNome,
    String? usuarioApelido,
    int? usuarioIdade,
    PosicaoAtleta? usuarioPosicaoPrincipal,
    String? usuarioFotoUrl,
    required StatusParticipacao status,
    MotivoAusencia? motivoAusencia,
    String? observacao,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 400));

      final idx = _participations.indexWhere(
        (p) => p.peladaId == peladaId && p.usuarioId == usuarioId,
      );

      Participation participacao;
      if (idx != -1) {
        participacao = _participations[idx].copyWith(
          usuarioNome: usuarioNome,
          usuarioApelido: usuarioApelido,
          usuarioIdade: usuarioIdade,
          usuarioPosicaoPrincipal: usuarioPosicaoPrincipal,
          usuarioFotoUrl: usuarioFotoUrl,
          status: status,
          motivoAusencia: motivoAusencia,
          observacao: observacao,
          updatedAt: DateTime.now(),
        );
        _participations[idx] = participacao;
      } else {
        participacao = Participation(
          id: _uuid.v4(),
          peladaId: peladaId,
          usuarioId: usuarioId,
          usuarioNome: usuarioNome,
          usuarioApelido: usuarioApelido,
          usuarioIdade: usuarioIdade,
          usuarioPosicaoPrincipal: usuarioPosicaoPrincipal,
          usuarioFotoUrl: usuarioFotoUrl,
          status: status,
          motivoAusencia: motivoAusencia,
          observacao: observacao,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _participations.add(participacao);
      }

      final peladaIdx = _peladas.indexWhere((p) => p.id == peladaId);
      if (peladaIdx != -1) {
        final confirmados = _participations
            .where(
              (p) =>
                  p.peladaId == peladaId &&
                  p.status == StatusParticipacao.confirmada,
            )
            .length;
        _peladas[peladaIdx] = _peladas[peladaIdx].copyWith(
          participantesConfirmados: confirmados,
        );
      }

      _isLoading = false;
      notifyListeners();
      return participacao;
    } catch (e) {
      _errorMessage = 'Erro ao registrar participação: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> atualizarPagamentoParticipacao({
    required String peladaId,
    required String usuarioId,
    required String? formaPagamento,
    required double valorPago,
  }) async {
    final idx = _participations.indexWhere(
      (p) => p.peladaId == peladaId && p.usuarioId == usuarioId,
    );
    if (idx == -1) {
      _errorMessage = 'Participante não encontrado.';
      return false;
    }
    _participations[idx] = _participations[idx].copyWith(
      formaPagamento: formaPagamento,
      clearFormaPagamento: formaPagamento == null,
      valorPago: valorPago,
      updatedAt: DateTime.now(),
    );
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> avaliarPelada({
    required String peladaId,
    required String usuarioId,
    required int nota,
    String? comentario,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 5));
      final idx = _participations.indexWhere(
        (p) => p.peladaId == peladaId && p.usuarioId == usuarioId,
      );
      if (idx != -1) {
        _participations[idx] = _participations[idx].copyWith(
          notaAvaliacao: nota,
          comentarioAvaliacao: comentario,
          dataAvaliacao: DateTime.now(),
        );
      }

      final peladaIdx = _peladas.indexWhere((p) => p.id == peladaId);
      if (peladaIdx != -1) {
        final avaliacoes = _participations
            .where((p) => p.peladaId == peladaId && p.notaAvaliacao != null)
            .toList();
        if (avaliacoes.isNotEmpty) {
          final media =
              avaliacoes.map((e) => e.notaAvaliacao!).reduce((a, b) => a + b) /
              avaliacoes.length;
          _peladas[peladaIdx] = _peladas[peladaIdx].copyWith(
            avaliacaoMedia: double.parse(media.toStringAsFixed(1)),
            totalAvaliacoes: avaliacoes.length,
          );
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao avaliar: ${e.toString()}';
      return false;
    }
  }

  bool isUsuarioBloqueadoParaPelada({
    required String peladaId,
    required String usuarioId,
  }) {
    try {
      return _bloqueios.any(
        (b) =>
            b.peladaId == peladaId &&
            b.usuarioId == usuarioId &&
            b.ativo == true,
      );
    } catch (_) {
      return false;
    }
  }

  PeladaBloqueioUsuario? getBloqueioUsuario({
    required String peladaId,
    required String usuarioId,
  }) {
    try {
      return _bloqueios.firstWhere(
        (b) =>
            b.peladaId == peladaId &&
            b.usuarioId == usuarioId &&
            b.ativo == true,
      );
    } catch (_) {
      return null;
    }
  }

  List<PeladaBloqueioUsuario> getBloqueiosPelada(String peladaId) {
    return _bloqueios.where((b) => b.peladaId == peladaId).toList();
  }

  Future<PeladaBloqueioUsuario?> bloquearUsuario({
    required String peladaId,
    required String usuarioId,
    required String usuarioNome,
    required String organizadorId,
    String? motivo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final existenteIdx = _bloqueios.indexWhere(
        (b) => b.peladaId == peladaId && b.usuarioId == usuarioId,
      );

      final novo = PeladaBloqueioUsuario(
        id: existenteIdx != -1 ? _bloqueios[existenteIdx].id : _uuid.v4(),
        peladaId: peladaId,
        usuarioId: usuarioId,
        usuarioNome: usuarioNome,
        organizadorId: organizadorId,
        motivo: motivo,
        bloqueadoEm: DateTime.now(),
        ativo: true,
      );

      if (existenteIdx != -1) {
        _bloqueios[existenteIdx] = novo;
      } else {
        _bloqueios.add(novo);
      }

      final partIdx = _participations.indexWhere(
        (p) => p.peladaId == peladaId && p.usuarioId == usuarioId,
      );
      if (partIdx != -1) {
        _participations[partIdx] = _participations[partIdx].copyWith(
          status: StatusParticipacao.naoIrei,
          motivoAusencia: MotivoAusencia.outros,
          observacao: motivo ?? 'Bloqueado pelo organizador',
          updatedAt: DateTime.now(),
        );
        _atualizarQuorum(peladaId);
      }

      _isLoading = false;
      notifyListeners();
      return novo;
    } catch (e) {
      _errorMessage = 'Falha ao bloquear usuário: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> desbloquearUsuario({
    required String peladaId,
    required String usuarioId,
  }) async {
    try {
      final idx = _bloqueios.indexWhere(
        (b) => b.peladaId == peladaId && b.usuarioId == usuarioId,
      );
      if (idx == -1) return false;
      _bloqueios[idx] = _bloqueios[idx].copyWith(ativo: false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Falha ao desbloquear: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removerParticipacao({
    required String peladaId,
    required String participationId,
    required String usuarioId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 250));
      final antes = _participations.length;
      _participations.removeWhere(
        (p) => p.peladaId == peladaId && p.id == participationId,
      );
      if (_participations.length == antes) {
        _errorMessage =
            'Participação não encontrada. Talvez o usuário já tenha saído da pelada.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _atualizarQuorum(peladaId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Falha ao remover participação: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _atualizarQuorum(String peladaId) {
    final peladaIdx = _peladas.indexWhere((p) => p.id == peladaId);
    if (peladaIdx == -1) return;
    final confirmados = _participations
        .where(
          (p) =>
              p.peladaId == peladaId &&
              p.status == StatusParticipacao.confirmada,
        )
        .length;
    _peladas[peladaIdx] = _peladas[peladaIdx].copyWith(
      participantesConfirmados: confirmados,
    );
  }

  void _loadMockPeladas() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    PeladaCapaFoto fotoPlaceholder() {
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      );
      return PeladaCapaFoto.fromBytes(bytes: bytes, mimeType: 'image/png');
    }

    final List<Pelada> listaMock = [
      Pelada(
        id: 'p1',
        nome: 'Pelada da Vovó - Quartas',
        organizadorId: 'org1',
        organizadorNome: 'Carlos Alberto',
        organizadorCpf: '123.456.789-00',
        contato: '(11) 91234-5678',
        dataInicio: hoje.add(const Duration(days: 1)),
        dataFim: hoje.add(const Duration(days: 1)),
        horaInicio: const TimeOfDay(hour: 20, minute: 0),
        horaFim: const TimeOfDay(hour: 22, minute: 0),
        taxa: 20.0,
        modalidade: Modalidade.society,
        tipoGrama: TipoGrama.sintetica,
        tipoChuteira: TipoChuteira.society,
        categoria: CategoriaPelada.livreAdulto,
        categoriaGenero: CategoriaGenero.masc,
        corColeteIndex: 5,
        endereco: 'Av. Paulista, 1500',
        localArena: 'Arena Jardins',
        estado: 'SP',
        cidade: 'São Paulo',
        bairro: 'Jardins',
        latitude: -23.5632,
        longitude: -46.6543,
        status: StatusPelada.ativa,
        quorumMinimo: 14,
        quorumMaximo: 14,
        participantesConfirmados: 10,
        avaliacaoMedia: 4.7,
        totalAvaliacoes: 18,
        descricao:
            'Pelada tradicional, sempre organizada, com bola e coletes inclusos.',
        fotoBraseao: fotoPlaceholder(),
        fotoArena: fotoPlaceholder(),
        fotoGalera: fotoPlaceholder(),
        createdAt: agora.subtract(const Duration(days: 30)),
        updatedAt: agora.subtract(const Duration(days: 2)),
      ),
      Pelada(
        id: 'p2',
        nome: 'Racha dos Amigos',
        organizadorId: 'org2',
        organizadorNome: 'Marcos Silva',
        organizadorCpf: '234.567.890-11',
        contato: '(11) 92345-6789',
        dataInicio: hoje.add(const Duration(days: 2)),
        dataFim: hoje.add(const Duration(days: 2)),
        horaInicio: const TimeOfDay(hour: 19, minute: 0),
        horaFim: const TimeOfDay(hour: 21, minute: 0),
        taxa: 15.0,
        modalidade: Modalidade.futsal,
        tipoGrama: TipoGrama.quadra,
        tipoChuteira: TipoChuteira.tenis,
        categoria: CategoriaPelada.acima35,
        categoriaGenero: CategoriaGenero.masc,
        corColeteIndex: 6,
        endereco: 'Rua Augusta, 2000',
        localArena: 'Quadra Augusta',
        estado: 'SP',
        cidade: 'São Paulo',
        bairro: 'Consolação',
        latitude: -23.5510,
        longitude: -46.6636,
        status: StatusPelada.ativa,
        quorumMinimo: 10,
        quorumMaximo: 10,
        participantesConfirmados: 9,
        avaliacaoMedia: 4.3,
        totalAvaliacoes: 7,
        descricao: 'Racha leve, descontração e diversão garantida.',
        fotoBraseao: fotoPlaceholder(),
        fotoArena: fotoPlaceholder(),
        fotoGalera: fotoPlaceholder(),
        createdAt: agora.subtract(const Duration(days: 20)),
        updatedAt: agora.subtract(const Duration(days: 1)),
      ),
      Pelada(
        id: 'p3',
        nome: 'Futebol do Clube do Sábado',
        organizadorId: 'org3',
        organizadorNome: 'Ricardo Gomes',
        organizadorCpf: '345.678.901-22',
        contato: '(21) 93456-7890',
        dataInicio: hoje.add(const Duration(days: 4)),
        dataFim: hoje.add(const Duration(days: 4)),
        horaInicio: const TimeOfDay(hour: 8, minute: 0),
        horaFim: const TimeOfDay(hour: 10, minute: 0),
        taxa: 30.0,
        modalidade: Modalidade.futebolCampo,
        tipoGrama: TipoGrama.natural,
        tipoChuteira: TipoChuteira.trava,
        categoria: CategoriaPelada.livreAdulto,
        categoriaGenero: CategoriaGenero.masc,
        corColeteIndex: 0,
        endereco: 'Av. Atlântica, 500',
        localArena: 'Clube Copacabana',
        estado: 'RJ',
        cidade: 'Rio de Janeiro',
        bairro: 'Copacabana',
        latitude: -22.9711,
        longitude: -43.1822,
        status: StatusPelada.ativa,
        quorumMinimo: 22,
        quorumMaximo: 22,
        participantesConfirmados: 22,
        avaliacaoMedia: 4.9,
        totalAvaliacoes: 45,
        descricao: 'Futebol de campo em gramado impecável, com arbitragem.',
        fotoBraseao: fotoPlaceholder(),
        fotoArena: fotoPlaceholder(),
        fotoGalera: fotoPlaceholder(),
        createdAt: agora.subtract(const Duration(days: 60)),
        updatedAt: agora.subtract(const Duration(hours: 12)),
      ),
      Pelada(
        id: 'p4',
        nome: 'Pelada Sub-20 de Terça',
        organizadorId: 'org4',
        organizadorNome: 'Lucas Pereira',
        organizadorCpf: '456.789.012-33',
        contato: '(31) 94567-8901',
        dataInicio: hoje.add(const Duration(days: 0)),
        dataFim: hoje.add(const Duration(days: 0)),
        horaInicio: const TimeOfDay(hour: 21, minute: 30),
        horaFim: const TimeOfDay(hour: 23, minute: 0),
        taxa: 18.0,
        modalidade: Modalidade.society,
        tipoGrama: TipoGrama.sintetica,
        tipoChuteira: TipoChuteira.society,
        categoria: CategoriaPelada.sub20,
        categoriaGenero: CategoriaGenero.masc,
        corColeteIndex: 3,
        endereco: 'Rua da Bahia, 1200',
        localArena: 'Arena BH Centro',
        estado: 'MG',
        cidade: 'Belo Horizonte',
        bairro: 'Centro',
        latitude: -19.9208,
        longitude: -43.9378,
        status: StatusPelada.ativa,
        quorumMinimo: 12,
        quorumMaximo: 12,
        participantesConfirmados: 7,
        avaliacaoMedia: 4.1,
        totalAvaliacoes: 5,
        descricao: 'Galera nova, energia alta! Bora jogar?',
        fotoBraseao: fotoPlaceholder(),
        fotoArena: fotoPlaceholder(),
        fotoGalera: fotoPlaceholder(),
        createdAt: agora.subtract(const Duration(days: 7)),
        updatedAt: agora.subtract(const Duration(hours: 3)),
      ),
      Pelada(
        id: 'p5',
        nome: 'Areia do Forte - Domingo',
        organizadorId: 'org5',
        organizadorNome: 'Felipe Costa',
        organizadorCpf: '567.890.123-44',
        contato: '(71) 95678-9012',
        dataInicio: hoje.add(const Duration(days: 5)),
        dataFim: hoje.add(const Duration(days: 5)),
        horaInicio: const TimeOfDay(hour: 16, minute: 0),
        horaFim: const TimeOfDay(hour: 18, minute: 0),
        taxa: 25.0,
        modalidade: Modalidade.areia,
        tipoGrama: TipoGrama.areia,
        tipoChuteira: TipoChuteira.descalco,
        categoria: CategoriaPelada.livreAdulto,
        categoriaGenero: CategoriaGenero.masc,
        corColeteIndex: 10,
        endereco: 'Praia do Forte',
        localArena: 'Areia do Forte',
        estado: 'BA',
        cidade: 'Salvador',
        bairro: 'Orla',
        latitude: -12.5797,
        longitude: -38.0100,
        status: StatusPelada.ativa,
        quorumMinimo: 10,
        quorumMaximo: 10,
        participantesConfirmados: 8,
        avaliacaoMedia: 4.8,
        totalAvaliacoes: 32,
        descricao: 'Futebol de areia ao pôr do sol. Experiência imperdível!',
        fotoBraseao: fotoPlaceholder(),
        fotoArena: fotoPlaceholder(),
        fotoGalera: fotoPlaceholder(),
        createdAt: agora.subtract(const Duration(days: 45)),
        updatedAt: agora.subtract(const Duration(days: 3)),
      ),
      Pelada(
        id: 'p6',
        nome: 'Veteranos Acima de 50',
        organizadorId: 'org6',
        organizadorNome: 'Antônio Rocha',
        organizadorCpf: '678.901.234-55',
        contato: '(11) 96789-0123',
        dataInicio: hoje.add(const Duration(days: 6)),
        dataFim: hoje.add(const Duration(days: 6)),
        horaInicio: const TimeOfDay(hour: 9, minute: 0),
        horaFim: const TimeOfDay(hour: 11, minute: 0),
        taxa: 12.0,
        modalidade: Modalidade.society,
        tipoGrama: TipoGrama.sintetica,
        tipoChuteira: TipoChuteira.society,
        categoria: CategoriaPelada.acima50,
        categoriaGenero: CategoriaGenero.masc,
        corColeteIndex: 4,
        endereco: 'Alameda Santos, 300',
        localArena: 'Clube dos Veteranos',
        estado: 'SP',
        cidade: 'São Paulo',
        bairro: 'Jardim Paulista',
        latitude: -23.5689,
        longitude: -46.6490,
        status: StatusPelada.ativa,
        quorumMinimo: 12,
        quorumMaximo: 12,
        participantesConfirmados: 12,
        avaliacaoMedia: 4.5,
        totalAvaliacoes: 14,
        descricao: 'Jogo calmo, sem contato, muita história e companheirismo.',
        fotoBraseao: fotoPlaceholder(),
        fotoArena: fotoPlaceholder(),
        fotoGalera: fotoPlaceholder(),
        createdAt: agora.subtract(const Duration(days: 90)),
        updatedAt: agora.subtract(const Duration(hours: 36)),
      ),
    ];
    _peladas.addAll(listaMock);
    notifyListeners();
    _applyDemoCovers();
  }

  void _loadMockCamposArenas() {
    final agora = DateTime.now();
    final List<CampoArena> lista = [
      CampoArena(
        id: 'c1',
        nome: 'Arena Verde Gramado',
        responsavelNome: 'João Gomes',
        contato: '(11) 99876-5432',
        estado: 'SP',
        cidade: 'São Paulo',
        bairro: 'Pinheiros',
        rua: 'Av. Brigadeiro Luís Antônio',
        numero: '2500',
        cep: '01.317-000',
        proprietarioId: null,
        quantidadePorLinha: 7,
        tipoGrama: TipoGrama.sintetica,
        calcadosPermitidos: {TipoChuteira.society, TipoChuteira.livre},
        dependencias: {
          DependenciaCampo.estacionamento,
          DependenciaCampo.vestiario,
          DependenciaCampo.chuveiros,
          DependenciaCampo.bar,
        },
        itensOpcionais: {ItemOpcionalCampo.bola, ItemOpcionalCampo.coletes},
        createdAt: agora.subtract(const Duration(days: 30)),
        updatedAt: agora.subtract(const Duration(days: 2)),
      ),
      CampoArena(
        id: 'c2',
        nome: 'Campo do Zé - Centro',
        responsavelNome: 'José Carlos',
        contato: '(21) 98888-1111',
        estado: 'RJ',
        cidade: 'Rio de Janeiro',
        bairro: 'Copacabana',
        rua: 'Rua das Laranjeiras',
        numero: '500',
        cep: '22.030-000',
        proprietarioId: null,
        quantidadePorLinha: 5,
        tipoGrama: TipoGrama.natural,
        calcadosPermitidos: {
          TipoChuteira.trava,
          TipoChuteira.society,
          TipoChuteira.livre,
        },
        dependencias: {
          DependenciaCampo.arquibancada,
          DependenciaCampo.estacionamento,
          DependenciaCampo.bebedouros,
          DependenciaCampo.lanchonete,
        },
        itensOpcionais: {
          ItemOpcionalCampo.bola,
          ItemOpcionalCampo.apito,
          ItemOpcionalCampo.cartoes,
        },
        createdAt: agora.subtract(const Duration(days: 15)),
        updatedAt: agora.subtract(const Duration(days: 1)),
      ),
      CampoArena(
        id: 'c3',
        nome: 'FutArena Society 7',
        responsavelNome: 'Marcos André',
        contato: '(31) 97777-2222',
        estado: 'MG',
        cidade: 'Belo Horizonte',
        bairro: 'Savassi',
        rua: 'Rua Pernambuco',
        numero: '800',
        cep: '30.130-150',
        proprietarioId: null,
        quantidadePorLinha: 7,
        tipoGrama: TipoGrama.sintetica,
        calcadosPermitidos: {TipoChuteira.society, TipoChuteira.tenis},
        dependencias: {
          DependenciaCampo.estacionamento,
          DependenciaCampo.vestiario,
          DependenciaCampo.chuveiros,
          DependenciaCampo.banheiros,
          DependenciaCampo.salaoFestaseEventos,
          DependenciaCampo.restaurante,
          DependenciaCampo.alugaParaEventos,
        },
        itensOpcionais: {
          ItemOpcionalCampo.aguaMineral,
          ItemOpcionalCampo.coletes,
          ItemOpcionalCampo.bola,
          ItemOpcionalCampo.apito,
          ItemOpcionalCampo.cartoes,
        },
        createdAt: agora.subtract(const Duration(days: 8)),
        updatedAt: agora,
      ),
    ];
    _camposArenas.addAll(lista);
    notifyListeners();
  }

  void _loadMockJuizes() {
    final agora = DateTime.now();
    final List<Juiz> lista = [
      Juiz(
        id: 'j1',
        nome: 'Carlos',
        sobrenome: 'Silva Pereira',
        apelido: 'Carlão',
        dataNascimento: DateTime(1985, 3, 12),
        telefone: '(11) 98765-4321',
        cep: '04.512-000',
        uf: 'SP',
        cidade: 'São Paulo',
        bairro: 'Saúde',
        createdAt: agora.subtract(const Duration(days: 45)),
        updatedAt: agora.subtract(const Duration(days: 3)),
      ),
      Juiz(
        id: 'j2',
        nome: 'Márcia',
        sobrenome: 'Costa Souza',
        apelido: 'Marci',
        dataNascimento: DateTime(1992, 7, 21),
        telefone: '(21) 99988-7766',
        cep: '20.530-000',
        uf: 'RJ',
        cidade: 'Rio de Janeiro',
        bairro: 'Tijuca',
        createdAt: agora.subtract(const Duration(days: 22)),
        updatedAt: agora.subtract(const Duration(days: 1)),
      ),
      Juiz(
        id: 'j3',
        nome: 'Roberto',
        sobrenome: 'Lima',
        apelido: 'Betinho',
        dataNascimento: DateTime(1978, 11, 5),
        telefone: '(31) 91234-5678',
        cep: '30.140-001',
        uf: 'MG',
        cidade: 'Belo Horizonte',
        bairro: 'Savassi',
        createdAt: agora.subtract(const Duration(days: 60)),
        updatedAt: agora.subtract(const Duration(days: 10)),
      ),
    ];
    _juizes.addAll(lista);
    notifyListeners();
  }

  Future<void> _applyDemoCovers() async {
    final covers = await DemoCoverImages.loadAll();
    if (covers.isEmpty) return;

    const demoIds = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'];
    for (var i = 0; i < demoIds.length; i++) {
      final peladaIdx = _peladas.indexWhere((p) => p.id == demoIds[i]);
      if (peladaIdx == -1) continue;
      final cover = covers[i % covers.length];
      final galeraIdx = (i + 2) % covers.length;
      final brasaoIdx = (i + 4) % covers.length;
      _peladas[peladaIdx] = _peladas[peladaIdx].copyWith(
        fotosCapa: [cover],
        fotoArena: cover,
        fotoGalera: covers[galeraIdx],
        fotoBraseao: covers[brasaoIdx],
      );
    }
    notifyListeners();
  }

  Future<void> carregarCamposArenas() async {
    if (_client == null) return;
    try {
      final rows = await _client
          .from('campos_arenas')
          .select()
          .order('created_at', ascending: false);
      final camposDb = (rows as List)
          .map(
            (row) => CampoArena.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

      // Preserve records already available locally if the database response
      // does not include them (for example, while running in offline mode).
      for (final local in _camposArenas) {
        if (!camposDb.any((campo) => campo.id == local.id)) {
          camposDb.add(local);
        }
      }
      _camposArenas
        ..clear()
        ..addAll(camposDb);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar campos e arenas: ${e.toString()}';
      notifyListeners();
    }
  }
}
