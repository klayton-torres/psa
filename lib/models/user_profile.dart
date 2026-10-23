import 'enums.dart';

class UserProfile {
  final String id;
  final String? authUid;
  final String primeiroNome;
  final String sobrenome;
  final String? apelido;
  final DateTime? dataNascimento;
  final String? telefone;
  final String? telefoneEmergencia;
  final String? email;
  final String? fotoUrl;
  final Modalidade? modalidadePraticada;
  final List<Modalidade> modalidadesPraticadas;
  final PosicaoAtleta? posicaoPrincipal;
  final PosicaoAtleta? posicaoAlternativa;
  final double pontuacaoChuteira;
  final double? altura;
  final double? peso;
  final List<String> marcasChuteiraFavoritas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? estado;
  final String? cidade;
  final double? latitude;
  final double? longitude;

  const UserProfile({
    required this.id,
    this.authUid,
    required this.primeiroNome,
    required this.sobrenome,
    this.apelido,
    this.dataNascimento,
    this.telefone,
    this.telefoneEmergencia,
    this.email,
    this.fotoUrl,
    this.modalidadePraticada,
    this.modalidadesPraticadas = const [],
    this.posicaoPrincipal,
    this.posicaoAlternativa,
    this.pontuacaoChuteira = 0.0,
    this.altura,
    this.peso,
    this.marcasChuteiraFavoritas = const [],
    required this.createdAt,
    required this.updatedAt,
    this.estado,
    this.cidade,
    this.latitude,
    this.longitude,
  });

  String get nomeCompleto => '$primeiroNome $sobrenome'.trim();

  int? get idade {
    if (dataNascimento == null) return null;
    final hoje = DateTime.now();
    int anos = hoje.year - dataNascimento!.year;
    if (hoje.month < dataNascimento!.month ||
        (hoje.month == dataNascimento!.month && hoje.day < dataNascimento!.day)) {
      anos--;
    }
    return anos;
  }

  UserProfile copyWith({
    String? id,
    String? authUid,
    String? primeiroNome,
    String? sobrenome,
    String? apelido,
    DateTime? dataNascimento,
    String? telefone,
    String? telefoneEmergencia,
    String? email,
    String? fotoUrl,
    Modalidade? modalidadePraticada,
    List<Modalidade>? modalidadesPraticadas,
    PosicaoAtleta? posicaoPrincipal,
    PosicaoAtleta? posicaoAlternativa,
    double? pontuacaoChuteira,
    double? altura,
    double? peso,
    List<String>? marcasChuteiraFavoritas,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? estado,
    String? cidade,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      primeiroNome: primeiroNome ?? this.primeiroNome,
      sobrenome: sobrenome ?? this.sobrenome,
      apelido: apelido ?? this.apelido,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      telefone: telefone ?? this.telefone,
      telefoneEmergencia: telefoneEmergencia ?? this.telefoneEmergencia,
      email: email ?? this.email,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      modalidadePraticada: modalidadePraticada ?? this.modalidadePraticada,
      modalidadesPraticadas:
          modalidadesPraticadas ?? List.of(this.modalidadesPraticadas),
      posicaoPrincipal: posicaoPrincipal ?? this.posicaoPrincipal,
      posicaoAlternativa: posicaoAlternativa ?? this.posicaoAlternativa,
      pontuacaoChuteira: pontuacaoChuteira ?? this.pontuacaoChuteira,
      altura: altura ?? this.altura,
      peso: peso ?? this.peso,
      marcasChuteiraFavoritas: marcasChuteiraFavoritas ?? this.marcasChuteiraFavoritas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estado: estado ?? this.estado,
      cidade: cidade ?? this.cidade,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_uid': authUid,
      'primeiro_nome': primeiroNome,
      'sobrenome': sobrenome,
      'apelido': apelido,
      'data_nascimento': dataNascimento?.toIso8601String(),
      'telefone': telefone,
      'telefone_emergencia': telefoneEmergencia,
      'email': email,
      'foto_url': fotoUrl,
      'modalidade_praticada': modalidadePraticada?.name,
      'modalidades_praticadas': modalidadesPraticadas.map((e) => e.name).toList(),
      'posicao_principal': posicaoPrincipal?.name,
      'posicao_alternativa': posicaoAlternativa?.name,
      'pontuacao_chuteira': pontuacaoChuteira,
      'altura': altura,
      'peso': peso,
      'marcas_chuteira_favoritas': marcasChuteiraFavoritas,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'estado': estado,
      'cidade': cidade,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final modalidades = ((map['modalidades_praticadas'] as List?) ?? const [])
        .map((e) => Modalidade.fromString(e as String?))
        .toList();
    return UserProfile(
      id: map['id'] as String,
      authUid: map['auth_uid'] as String?,
      primeiroNome: map['primeiro_nome'] as String? ?? '',
      sobrenome: map['sobrenome'] as String? ?? '',
      apelido: map['apelido'] as String?,
      dataNascimento: map['data_nascimento'] != null
          ? DateTime.tryParse(map['data_nascimento'] as String)
          : null,
      telefone: map['telefone'] as String?,
      telefoneEmergencia: map['telefone_emergencia'] as String?,
      email: map['email'] as String?,
      fotoUrl: map['foto_url'] as String?,
      modalidadePraticada: map['modalidade_praticada'] != null
          ? Modalidade.fromString(map['modalidade_praticada'] as String?)
          : null,
      modalidadesPraticadas: modalidades.isNotEmpty
          ? modalidades
          : (map['modalidade_praticada'] != null
              ? [Modalidade.fromString(map['modalidade_praticada'] as String?)]
              : const []),
      posicaoPrincipal:
          PosicaoAtleta.fromString(map['posicao_principal'] as String?),
      posicaoAlternativa:
          PosicaoAtleta.fromString(map['posicao_alternativa'] as String?),
      pontuacaoChuteira: (map['pontuacao_chuteira'] as num?)?.toDouble() ?? 0.0,
      altura: (map['altura'] as num?)?.toDouble(),
      peso: (map['peso'] as num?)?.toDouble(),
      marcasChuteiraFavoritas: List<String>.from(map['marcas_chuteira_favoritas'] as List? ?? []),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      estado: map['estado'] as String?,
      cidade: map['cidade'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
