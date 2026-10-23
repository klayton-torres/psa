import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../utils/profile_avatar_helper.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient? _client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  static const String demoUserEmail = 'demo@peladeiros.app';
  static const String demoUserPassword = 'demo123';

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;
  bool _isDemoMode = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get requiresSupabaseSession => _client != null;
  bool get hasSupabaseSession =>
      !_isDemoMode && _client?.auth.currentSession != null;
  bool get isDemoMode => _isDemoMode;
  bool get initialized => _initialized;

  static SupabaseClient? _resolveClient() {
    if (!AppConstants.hasSupabaseConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  AuthService({SupabaseClient? client}) : _client = client ?? _resolveClient() {
    _init();
  }

  void forceInitialized() {
    if (_initialized) return;
    _initialized = true;
    notifyListeners();
  }

  static String _extractPrimeiroNome(
    Map<String, dynamic> metadata,
    String fallback,
  ) {
    final raw =
        metadata['primeiro_nome'] ?? metadata['first_name'] ?? metadata['name'];
    if (raw == null) return fallback;
    final parts = raw.toString().trim().split(' ');
    if (parts.isEmpty || parts.first.trim().isEmpty) return fallback;
    return parts.first.trim();
  }

  static String _extractSobrenome(Map<String, dynamic> metadata) {
    final rawSobrenome = metadata['sobrenome'];
    if (rawSobrenome != null && rawSobrenome.toString().trim().isNotEmpty) {
      return rawSobrenome.toString().trim();
    }
    final rawNome = metadata['name'];
    if (rawNome == null) return '';
    final parts = rawNome.toString().trim().split(' ');
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ').trim();
  }

  static String? _extractString(
    Map<String, dynamic> metadata,
    List<String> keys,
  ) {
    for (final k in keys) {
      final v = metadata[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  Future<void> _init() async {
    const kQueryTimeout = Duration(seconds: 10);
    final client = _client;
    if (client == null) {
      _initialized = true;
      notifyListeners();
      return;
    }
    try {
      final session = client.auth.currentSession;
      if (session != null) {
        try {
          await _syncUserFromAuth(session.user).timeout(kQueryTimeout);
        } on TimeoutException {
          debugPrint(
            '[Auth] _syncUserFromAuth excedeu timeout ${kQueryTimeout.inSeconds}s. '
            'Avançando sem perfil do servidor.',
          );
        } catch (e, st) {
          _logError(action: '_syncUserFromAuth', error: e, stackTrace: st);
        }
      }
      client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;
        if (event == AuthChangeEvent.signedOut ||
            (event == AuthChangeEvent.tokenRefreshed && session == null)) {
          _currentUser = null;
          _isDemoMode = false;
          notifyListeners();
        } else if (session != null &&
            (event == AuthChangeEvent.signedIn ||
                event == AuthChangeEvent.tokenRefreshed ||
                event == AuthChangeEvent.passwordRecovery ||
                event == AuthChangeEvent.userUpdated)) {
          try {
            await _syncUserFromAuth(session.user);
          } catch (_) {}
        }
      });
    } on TimeoutException {
      debugPrint(
        '[Auth] _init geral excedeu timeout. Avançando para modo parcial.',
      );
    } catch (e, st) {
      _logError(action: '_init', error: e, stackTrace: st);
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _syncUserFromAuth(User user) async {
    _isDemoMode = false;
    const kProfileTimeout = Duration(seconds: 9);
    try {
      final client = _client;
      final metadata = user.userMetadata ?? <String, dynamic>{};

      UserProfile? fromTable;
      if (client != null) {
        try {
          final res = await client
              .from('user_profiles')
              .select()
              .eq('auth_uid', user.id)
              .maybeSingle()
              .timeout(kProfileTimeout);
          if (res != null) {
            fromTable = UserProfile.fromMap(Map<String, dynamic>.from(res));
          }
        } on TimeoutException {
          debugPrint(
            '[Auth] consulta user_profiles excedeu timeout. '
            'Usando dados locais do auth.',
          );
          fromTable = null;
        } catch (_) {
          fromTable = null;
        }
      }

      if (fromTable != null) {
        _currentUser = fromTable.copyWith(
          email: fromTable.email ?? user.email,
          fotoUrl:
              fromTable.fotoUrl ??
              _extractString(metadata, const ['avatar_url', 'picture']),
          authUid: user.id,
        );
      } else {
        final String createdRaw = user.createdAt;
        _currentUser = UserProfile(
          id: user.id,
          authUid: user.id,
          primeiroNome: _extractPrimeiroNome(metadata, 'Usuário'),
          sobrenome: _extractSobrenome(metadata),
          apelido: _extractString(metadata, const ['apelido']),
          email: user.email,
          fotoUrl: _extractString(metadata, const ['avatar_url', 'picture']),
          createdAt: (createdRaw.isNotEmpty)
              ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
              : DateTime.now(),
          updatedAt: DateTime.now(),
          modalidadesPraticadas: const [],
          marcasChuteiraFavoritas: const [],
        );
      }
    } catch (e, st) {
      _logError(action: '_syncUserFromAuth', error: e, stackTrace: st);
      final userMeta = user.userMetadata ?? <String, dynamic>{};
      _currentUser = UserProfile(
        id: user.id,
        authUid: user.id,
        primeiroNome: _extractPrimeiroNome(userMeta, 'Usuário'),
        sobrenome: _extractSobrenome(userMeta),
        apelido: _extractString(userMeta, const ['apelido']),
        email: user.email,
        fotoUrl: _extractString(userMeta, const ['avatar_url', 'picture']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        modalidadesPraticadas: const [],
        marcasChuteiraFavoritas: const [],
      );
    }
    notifyListeners();
  }

  Future<void> _upsertProfile(UserProfile profile) async {
    final client = _client;
    if (client == null) return;
    try {
      final map = profile.toMap();
      map['updated_at'] = DateTime.now().toIso8601String();
      await client.from('user_profiles').upsert(map, onConflict: 'auth_uid');
    } catch (e, st) {
      _logError(action: '_upsertProfile', error: e, stackTrace: st);
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _logError({
    required String action,
    required Object error,
    StackTrace? stackTrace,
  }) {
    debugPrint('[Auth][$action] ${error.runtimeType}: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  Future<bool> signInWithEmail(String email, String senha) async {
    setLoading(true);
    try {
      final emailNorm = email.trim().toLowerCase();
      final senhaNorm = senha.trim();

      if (emailNorm == demoUserEmail && senhaNorm == demoUserPassword) {
        _isDemoMode = true;
        _currentUser = UserProfile(
          id: 'demo-user-0001',
          authUid: 'demo-user-0001',
          primeiroNome: 'Usuário',
          sobrenome: 'Demo',
          apelido: 'Demo',
          email: demoUserEmail,
          telefone: '(11) 90000-0000',
          dataNascimento: DateTime(1995, 6, 15),
          fotoUrl: null,
          modalidadePraticada: Modalidade.society,
          modalidadesPraticadas: const [
            Modalidade.society,
            Modalidade.futebolCampo,
          ],
          pontuacaoChuteira: 41.0,
          altura: 1.78,
          peso: 78.0,
          marcasChuteiraFavoritas: const ['Nike', 'Adidas', 'Puma'],
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          updatedAt: DateTime.now(),
          estado: 'SP',
          cidade: 'São Paulo',
        );
        setLoading(false);
        return true;
      }

      if (_client == null) {
        _errorMessage =
            'Modo demo: Supabase não configurado. Use $demoUserEmail / $demoUserPassword';
        setLoading(false);
        return false;
      }

      final response = await _client.auth.signInWithPassword(
        email: emailNorm,
        password: senhaNorm,
      );
      final user = response.user;
      if (user == null) {
        _errorMessage = 'Usuário não encontrado';
        setLoading(false);
        return false;
      }
      await _syncUserFromAuth(user);
      setLoading(false);
      return true;
    } on AuthException catch (e) {
      _logError(action: 'signInWithEmail', error: e);
      if (e.message.toLowerCase().contains('invalid credentials') ||
          e.message.toLowerCase().contains('invalid login') ||
          e.statusCode == '400') {
        _errorMessage = 'E-mail ou senha incorretos.';
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
        _errorMessage =
            'E-mail não confirmado. Verifique sua caixa de entrada.';
      } else {
        _errorMessage = e.message;
      }
      setLoading(false);
      return false;
    } catch (e, st) {
      _logError(action: 'signInWithEmail', error: e, stackTrace: st);
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Failed host lookup') ||
          msg.contains('Connection refused') ||
          msg.contains('HandshakeException')) {
        _errorMessage = 'Sem conexão com o servidor. Verifique sua internet.';
      } else {
        _errorMessage = 'Erro ao entrar. Tente novamente.';
      }
      setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String senha,
    required String primeiroNome,
    required String sobrenome,
    String? apelido,
    String? telefone,
    DateTime? dataNascimento,
  }) async {
    setLoading(true);
    try {
      if (_client == null) {
        _errorMessage =
            'Modo demo: cadastro desabilitado. Use o usuário de demonstração.';
        setLoading(false);
        return false;
      }

      final emailNorm = email.trim().toLowerCase();
      final response = await _client.auth.signUp(
        email: emailNorm,
        password: senha.trim(),
        data: {
          'primeiro_nome': primeiroNome.trim(),
          'sobrenome': sobrenome.trim(),
          'apelido': apelido?.trim(),
          'telefone': telefone?.trim(),
          'data_nascimento': dataNascimento?.toIso8601String(),
        },
      );
      final user = response.user;
      if (user == null) {
        _errorMessage = response.session == null
            ? 'Cadastro enviado! Confirme seu e-mail para ativar a conta.'
            : 'Erro ao criar conta. Tente novamente.';
        setLoading(false);
        return response.session != null;
      }
      if (response.session == null) {
        _currentUser = null;
        _isDemoMode = false;
        _errorMessage =
            'Confirme seu e-mail e entre com sua conta antes de publicar cadastros.';
        setLoading(false);
        return false;
      }

      final profile = UserProfile(
        id: user.id,
        authUid: user.id,
        primeiroNome: primeiroNome.trim(),
        sobrenome: sobrenome.trim(),
        apelido: apelido?.trim().isEmpty == true ? null : apelido?.trim(),
        dataNascimento: dataNascimento,
        telefone: telefone?.trim().isEmpty == true ? null : telefone?.trim(),
        email: emailNorm,
        fotoUrl: _extractString(
          user.userMetadata ?? <String, dynamic>{},
          const ['avatar_url', 'picture'],
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        modalidadesPraticadas: const [],
        marcasChuteiraFavoritas: const [],
      );
      _currentUser = profile;
      _isDemoMode = false;
      await _upsertProfile(profile);
      setLoading(false);
      return true;
    } on AuthException catch (e) {
      _logError(action: 'signUpWithEmail', error: e);
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists') ||
          e.statusCode == '409' ||
          e.message.toLowerCase().contains('unique')) {
        _errorMessage = 'Este e-mail já está cadastrado. Faça login.';
      } else if (e.message.toLowerCase().contains('weak password') ||
          e.message.toLowerCase().contains('password')) {
        _errorMessage = 'Senha fraca. Use pelo menos 6 caracteres.';
      } else {
        _errorMessage = e.message;
      }
      setLoading(false);
      return false;
    } catch (e, st) {
      _logError(action: 'signUpWithEmail', error: e, stackTrace: st);
      _errorMessage = 'Erro ao cadastrar. Tente novamente.';
      setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    setLoading(true);
    try {
      if (_client == null) {
        _errorMessage = 'Modo demo: login com Google desabilitado.';
        setLoading(false);
        return false;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setLoading(false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        _errorMessage = 'Falha ao obter credenciais do Google';
        setLoading(false);
        return false;
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = response.user;
      if (user == null) {
        setLoading(false);
        return false;
      }
      await _syncUserFromAuth(user);
      setLoading(false);
      return true;
    } on AuthException catch (e) {
      _logError(action: 'signInWithGoogle', error: e);
      _errorMessage = e.message;
      setLoading(false);
      return false;
    } catch (e, st) {
      _logError(action: 'signInWithGoogle', error: e, stackTrace: st);
      _errorMessage = 'Erro ao entrar com Google. Tente novamente.';
      setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    setLoading(true);
    try {
      final emailNorm = email.trim().toLowerCase();
      final emailError = validateEmail(emailNorm);
      if (emailError != null) {
        _errorMessage = emailError;
        setLoading(false);
        return false;
      }
      if (_client == null) {
        _errorMessage = 'Modo demo: recuperação de senha indisponível.';
        setLoading(false);
        return false;
      }
      await _client.auth.resetPasswordForEmail(emailNorm);
      setLoading(false);
      return true;
    } on AuthException catch (e) {
      _logError(action: 'sendPasswordResetEmail', error: e);
      _errorMessage = e.message;
      setLoading(false);
      return false;
    } catch (e, st) {
      _logError(action: 'sendPasswordResetEmail', error: e, stackTrace: st);
      _errorMessage = 'Erro ao enviar e-mail de recuperação.';
      setLoading(false);
      return false;
    }
  }

  Future<bool> updatePassword(String novaSenha) async {
    setLoading(true);
    try {
      final senhaError = validateSenha(novaSenha);
      if (senhaError != null) {
        _errorMessage = senhaError;
        setLoading(false);
        return false;
      }
      if (_client == null) {
        _errorMessage = 'Modo demo: operação indisponível.';
        setLoading(false);
        return false;
      }
      await _client.auth.updateUser(UserAttributes(password: novaSenha));
      setLoading(false);
      return true;
    } on AuthException catch (e) {
      _logError(action: 'updatePassword', error: e);
      _errorMessage = e.message;
      setLoading(false);
      return false;
    } catch (e, st) {
      _logError(action: 'updatePassword', error: e, stackTrace: st);
      _errorMessage = 'Erro ao atualizar senha.';
      setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    setLoading(true);
    try {
      if (_client != null) {
        try {
          await _client.auth.signOut();
        } catch (e) {
          _logError(action: 'signOut_supabase', error: e);
        }
      }
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      _currentUser = null;
      _isDemoMode = false;
    } catch (e) {
      _logError(action: 'signOut', error: e);
      _errorMessage = 'Erro ao sair: ${e.toString()}';
    } finally {
      setLoading(false);
    }
  }

  void mockLoginDemo() {
    _isDemoMode = true;
    _currentUser = UserProfile(
      id: 'demo-user-002',
      authUid: 'demo-user-002',
      primeiroNome: 'João',
      sobrenome: 'Peladeiro',
      apelido: 'Jão',
      email: 'joao@peladeiros.com',
      telefone: '(11) 98765-4321',
      dataNascimento: DateTime(1992, 5, 15),
      fotoUrl: null,
      modalidadePraticada: Modalidade.society,
      modalidadesPraticadas: const [
        Modalidade.society,
        Modalidade.futebolCampo,
      ],
      pontuacaoChuteira: 42,
      altura: 1.78,
      peso: 78.5,
      marcasChuteiraFavoritas: const ['Nike', 'Adidas', 'Puma'],
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
      estado: 'SP',
      cidade: 'São Paulo',
    );
    notifyListeners();
  }

  Future<void> updateUser(UserProfile updatedProfile) async {
    _currentUser = updatedProfile.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    await _upsertProfile(_currentUser!);
  }

  Future<String> updateProfileAvatar({
    required Uint8List croppedJpegBytes,
    required Uint8List? thumbnailJpegBytes,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception(
        'Você precisa estar logado para atualizar a foto de perfil.',
      );
    }

    String publicUrl;

    if (_client != null && AppConstants.hasSupabaseConfigured) {
      final storage = _client.storage;
      const bucket = 'profile-avatars';
      bool bucketReady = false;
      try {
        await storage.getBucket(bucket);
        bucketReady = true;
      } catch (_) {
        try {
          await storage.createBucket(
            bucket,
            const BucketOptions(public: true, fileSizeLimit: '10MB'),
          );
          bucketReady = true;
        } catch (e) {
          _logError(action: 'create_bucket_profile_avatars', error: e);
          bucketReady = false;
        }
      }

      final mainPath = ProfileAvatarHelper.avatarStoragePath(user.id);
      final thumbPath = ProfileAvatarHelper.avatarStoragePath(
        user.id,
        thumb: true,
      );
      bool uploadOk = false;
      if (bucketReady) {
        try {
          await storage.from(bucket).uploadBinary(mainPath, croppedJpegBytes);
          uploadOk = true;
          if (thumbnailJpegBytes != null) {
            try {
              await storage
                  .from(bucket)
                  .uploadBinary(thumbPath, thumbnailJpegBytes);
            } catch (_) {}
          }
        } catch (e) {
          _logError(action: 'upload_profile_avatar_storage', error: e);
          uploadOk = false;
        }
      }

      if (uploadOk) {
        try {
          publicUrl = storage.from(bucket).getPublicUrl(mainPath);
        } catch (_) {
          publicUrl = ProfileAvatarHelper.buildDataUrl(croppedJpegBytes);
        }
      } else {
        publicUrl = ProfileAvatarHelper.buildDataUrl(croppedJpegBytes);
      }
    } else {
      publicUrl = ProfileAvatarHelper.buildDataUrl(croppedJpegBytes);
    }

    _currentUser = user.copyWith(fotoUrl: publicUrl, updatedAt: DateTime.now());
    notifyListeners();
    await _upsertProfile(_currentUser!);
    return publicUrl;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu e-mail';
    final regex = RegExp(r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'E-mail inválido';
    return null;
  }

  String? validateSenha(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha';
    if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
    return null;
  }

  String? validateNome(String? value, {String campo = 'Nome'}) {
    if (value == null || value.trim().isEmpty) return 'Informe o $campo';
    if (value.trim().length < 2) return '$campo muito curto';
    return null;
  }

  String? validateCpf(String? value) {
    if (value == null || value.isEmpty) return 'CPF é obrigatório';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'CPF incompleto';
    return null;
  }

  String? validateTelefone(String? value) {
    if (value == null || value.isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty && digits.length < 10) return 'Telefone inválido';
    return null;
  }

  String? validateDataNascimento(DateTime? value) {
    if (value == null) return null;
    if (value.isAfter(DateTime.now())) {
      return 'Data inválida';
    }
    final idade = DateTime.now().year - value.year;
    if (idade > 120) return 'Verifique a data informada';
    return null;
  }
}
