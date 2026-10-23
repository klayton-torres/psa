import 'pelada.dart';
import 'enums.dart';

class CampoArena {
  final String id;
  final String nome;
  final String responsavelNome;
  final String? contato;
  final String estado;
  final String cidade;
  final String bairro;
  final String rua;
  final String numero;
  final String? cep;
  final double? latitude;
  final double? longitude;
  final String? proprietarioId;
  final int quantidadePorLinha;
  final TipoGrama tipoGrama;
  final Set<TipoChuteira> calcadosPermitidos;
  final Set<DependenciaCampo> dependencias;
  final Set<ItemOpcionalCampo> itensOpcionais;
  final Set<ItemOpcionalCampo> opcionaisConsultarTaxas;
  final double? larguraMetros;
  final double? profundidadeMetros;
  final int? capacidadePublico;
  final List<PeladaCapaFoto> fotos;
  final int? fotoCapaIndex;
  final Set<String> horariosDisponiveis;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CampoArena({
    required this.id,
    required this.nome,
    required this.responsavelNome,
    this.contato,
    required this.estado,
    required this.cidade,
    required this.bairro,
    required this.rua,
    required this.numero,
    this.cep,
    this.latitude,
    this.longitude,
    this.proprietarioId,
    required this.quantidadePorLinha,
    required this.tipoGrama,
    this.calcadosPermitidos = const {},
    this.dependencias = const {},
    this.itensOpcionais = const {},
    this.opcionaisConsultarTaxas = const {},
    this.larguraMetros,
    this.profundidadeMetros,
    this.capacidadePublico,
    this.fotos = const [],
    this.fotoCapaIndex,
    this.horariosDisponiveis = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  PeladaCapaFoto? get fotoCapa {
    if (fotos.isEmpty) return null;
    if (fotoCapaIndex != null &&
        fotoCapaIndex! >= 0 &&
        fotoCapaIndex! < fotos.length) {
      final f = fotos[fotoCapaIndex!];
      if (f.hasValidBytes) return f;
    }
    for (final f in fotos) {
      if (f.hasValidBytes) return f;
    }
    return null;
  }

  String get enderecoCompleto {
    final parts = <String>[
      if (rua.trim().isNotEmpty) rua.trim(),
      if (numero.trim().isNotEmpty) numero.trim(),
      if (bairro.trim().isNotEmpty) bairro.trim(),
      if (cidade.trim().isNotEmpty) cidade.trim(),
      if (estado.trim().isNotEmpty) estado.trim(),
    ];
    return parts.where((e) => e.isNotEmpty).join(', ');
  }

  String get calcadosPermitidosLabel {
    if (calcadosPermitidos.isEmpty) return 'Não informado';
    return calcadosPermitidos.map((e) => e.label).join(', ');
  }

  String get dependenciasLabel {
    if (dependencias.isEmpty) return 'Nenhuma selecionada';
    return dependencias.map((e) => e.label).join(', ');
  }

  String get itensOpcionaisLabel {
    if (itensOpcionais.isEmpty) return 'Nenhum selecionado';
    return itensOpcionais.map((e) => e.label).join(', ');
  }

  int get capacidadeMaxima => quantidadePorLinha * quantidadePorLinha * 2;

  double? get areaM2 {
    if (larguraMetros == null || profundidadeMetros == null) return null;
    if (larguraMetros! <= 0 || profundidadeMetros! <= 0) return null;
    return (larguraMetros! * profundidadeMetros!).toDouble();
  }

  CampoArena copyWith({
    String? id,
    String? nome,
    String? responsavelNome,
    String? contato,
    String? estado,
    String? cidade,
    String? bairro,
    String? rua,
    String? numero,
    String? cep,
    double? latitude,
    double? longitude,
    String? proprietarioId,
    int? quantidadePorLinha,
    TipoGrama? tipoGrama,
    Set<TipoChuteira>? calcadosPermitidos,
    Set<DependenciaCampo>? dependencias,
    Set<ItemOpcionalCampo>? itensOpcionais,
    Set<ItemOpcionalCampo>? opcionaisConsultarTaxas,
    double? larguraMetros,
    double? profundidadeMetros,
    int? capacidadePublico,
    List<PeladaCapaFoto>? fotos,
    int? fotoCapaIndex,
    bool clearFotoCapaIndex = false,
    Set<String>? horariosDisponiveis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampoArena(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      responsavelNome: responsavelNome ?? this.responsavelNome,
      contato: contato ?? this.contato,
      estado: estado ?? this.estado,
      cidade: cidade ?? this.cidade,
      bairro: bairro ?? this.bairro,
      rua: rua ?? this.rua,
      numero: numero ?? this.numero,
      cep: cep ?? this.cep,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      proprietarioId: proprietarioId ?? this.proprietarioId,
      quantidadePorLinha: quantidadePorLinha ?? this.quantidadePorLinha,
      tipoGrama: tipoGrama ?? this.tipoGrama,
      calcadosPermitidos: calcadosPermitidos != null
          ? Set.unmodifiable(calcadosPermitidos)
          : Set.unmodifiable(this.calcadosPermitidos),
      dependencias: dependencias != null
          ? Set.unmodifiable(dependencias)
          : Set.unmodifiable(this.dependencias),
      itensOpcionais: itensOpcionais != null
          ? Set.unmodifiable(itensOpcionais)
          : Set.unmodifiable(this.itensOpcionais),
      opcionaisConsultarTaxas: opcionaisConsultarTaxas != null
          ? Set.unmodifiable(opcionaisConsultarTaxas)
          : Set.unmodifiable(this.opcionaisConsultarTaxas),
      larguraMetros: larguraMetros ?? this.larguraMetros,
      profundidadeMetros: profundidadeMetros ?? this.profundidadeMetros,
      capacidadePublico: capacidadePublico ?? this.capacidadePublico,
      fotos: fotos != null
          ? List.unmodifiable(fotos)
          : List.unmodifiable(this.fotos),
      fotoCapaIndex: clearFotoCapaIndex
          ? null
          : (fotoCapaIndex ?? this.fotoCapaIndex),
      horariosDisponiveis: horariosDisponiveis != null
          ? Set.unmodifiable(horariosDisponiveis)
          : Set.unmodifiable(this.horariosDisponiveis),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'responsavel_nome': responsavelNome,
      'contato': contato,
      'estado': estado,
      'cidade': cidade,
      'bairro': bairro,
      'rua': rua,
      'numero': numero,
      'cep': cep,
      'latitude': latitude,
      'longitude': longitude,
      'proprietario_id': proprietarioId,
      'quantidade_por_linha': quantidadePorLinha,
      'tipo_grama': tipoGrama.name,
      'calcados_permitidos': calcadosPermitidos.map((e) => e.name).toList(),
      'dependencias': dependencias.map((e) => e.name).toList(),
      'itens_opcionais': itensOpcionais.map((e) => e.name).toList(),
      'opcionais_consultar_taxas':
          opcionaisConsultarTaxas.map((e) => e.name).toList(),
      'largura_metros': larguraMetros,
      'profundidade_metros': profundidadeMetros,
      'capacidade_publico': capacidadePublico,
      'fotos': fotos.map((e) => e.toMap()).toList(),
      'foto_capa_index': fotoCapaIndex,
      'horarios_disponiveis': horariosDisponiveis.toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CampoArena.fromMap(Map<String, dynamic> map) {
    final qtdLinha = map['quantidade_por_linha'];
    double? parseDoubleNullable(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      final d = double.tryParse(s.replaceAll(',', '.'));
      return d;
    }

    return CampoArena(
      id: map['id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      responsavelNome: map['responsavel_nome'] as String? ?? '',
      contato: map['contato'] as String?,
      estado: map['estado'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      bairro: map['bairro'] as String? ?? '',
      rua: map['rua'] as String? ?? '',
      numero: (map['numero'] as Object?)?.toString() ?? '',
      cep: map['cep'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      proprietarioId: map['proprietario_id'] as String?,
      quantidadePorLinha: qtdLinha is int
          ? qtdLinha
          : (qtdLinha is num ? qtdLinha.toInt() : 7),
      tipoGrama: TipoGrama.fromString(map['tipo_grama'] as String?),
      calcadosPermitidos: Set.unmodifiable(
        ((map['calcados_permitidos'] as List?) ?? const []).map(
          (e) => TipoChuteira.fromString(e as String?),
        ),
      ),
      dependencias: Set.unmodifiable(
        ((map['dependencias'] as List?) ?? const []).map(
          (e) => DependenciaCampo.fromString(e as String?),
        ),
      ),
      itensOpcionais: Set.unmodifiable(
        ((map['itens_opcionais'] as List?) ?? const []).map(
          (e) => ItemOpcionalCampo.fromString(e as String?),
        ),
      ),
      opcionaisConsultarTaxas: Set.unmodifiable(
        ((map['opcionais_consultar_taxas'] as List?) ?? const []).map(
          (e) => ItemOpcionalCampo.fromString(e as String?),
        ),
      ),
      larguraMetros: parseDoubleNullable(map['largura_metros']),
      profundidadeMetros: parseDoubleNullable(map['profundidade_metros']),
      capacidadePublico: (map['capacidade_publico'] as num?)?.toInt(),
      fotos: List.unmodifiable(
        ((map['fotos'] as List?) ?? const []).map(
          (e) => PeladaCapaFoto.fromMap(Map<String, dynamic>.from(e as Map)),
        ),
      ),
      fotoCapaIndex: (map['foto_capa_index'] as num?)?.toInt(),
      horariosDisponiveis: Set.unmodifiable(
        ((map['horarios_disponiveis'] as List?) ?? const [])
            .whereType<String>()
            .toSet(),
      ),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String? get endereco => null;

  Null get modalidades => null;
}
