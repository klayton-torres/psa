import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'enums.dart';

class PeladaCapaFoto {
  final String mimeType;
  final String base64Data;

  const PeladaCapaFoto({required this.mimeType, required this.base64Data});

  factory PeladaCapaFoto.fromBytes({
    required Uint8List bytes,
    required String mimeType,
  }) {
    return PeladaCapaFoto(mimeType: mimeType, base64Data: base64Encode(bytes));
  }

  Uint8List get bytes {
    if (base64Data.trim().isEmpty) return Uint8List(0);
    try {
      return base64Decode(base64Data);
    } catch (_) {
      return Uint8List(0);
    }
  }

  bool get hasValidBytes {
    final data = base64Data.trim();
    if (data.isEmpty) return false;
    try {
      final decoded = base64Decode(data);
      return decoded.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toMap() => {'mime_type': mimeType, 'base64': base64Data};

  factory PeladaCapaFoto.fromMap(Map<String, dynamic> map) {
    return PeladaCapaFoto(
      mimeType: map['mime_type'] as String? ?? 'image/jpeg',
      base64Data: map['base64'] as String? ?? '',
    );
  }

  String? get url => null;
}

class Pelada {
  final String id;
  final String nome;
  final String organizadorId;
  final String organizadorNome;
  final String? organizadorCpf;
  final String contato;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? recorrenciaGrupoId;
  final List<int> recorrenciaDiasSemana;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFim;
  final double taxa;
  final Modalidade modalidade;
  final TipoGrama tipoGrama;
  final TipoChuteira tipoChuteira;
  final List<TipoChuteira> tiposChuteiraPermitidos;
  final CategoriaPelada categoria;
  final CategoriaGenero categoriaGenero;
  final bool? beneficioGoleiro;
  final int corColeteIndex;
  final List<int> coresColeteIndices;
  final String? corColetePersonalizado;
  final String endereco;
  final String localArena;
  final String estado;
  final String cidade;
  final String bairro;
  final String? cep;
  final double? latitude;
  final double? longitude;
  final StatusPelada status;
  final String? statusMotivo;
  final int quorumMinimo;
  final int quorumMaximo;
  final int participantesConfirmados;
  final double avaliacaoMedia;
  final int totalAvaliacoes;
  final String? descricao;
  final Map<String, bool> checklist;
  final List<PeladaCapaFoto> fotosCapa;
  final PeladaCapaFoto? fotoBraseao;
  final PeladaCapaFoto? fotoArena;
  final PeladaCapaFoto? fotoGalera;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pelada({
    required this.id,
    required this.nome,
    required this.organizadorId,
    required this.organizadorNome,
    this.organizadorCpf,
    required this.contato,
    required this.dataInicio,
    required this.dataFim,
    this.recorrenciaGrupoId,
    this.recorrenciaDiasSemana = const [],
    required this.horaInicio,
    required this.horaFim,
    required this.taxa,
    required this.modalidade,
    required this.tipoGrama,
    required this.tipoChuteira,
    this.tiposChuteiraPermitidos = const [],
    required this.categoria,
    required this.categoriaGenero,
    this.beneficioGoleiro,
    required this.corColeteIndex,
    this.coresColeteIndices = const [],
    this.corColetePersonalizado,
    required this.endereco,
    required this.localArena,
    required this.estado,
    required this.cidade,
    required this.bairro,
    this.cep,
    this.latitude,
    this.longitude,
    required this.status,
    this.statusMotivo,
    this.quorumMinimo = 10,
    this.quorumMaximo = 22,
    this.participantesConfirmados = 0,
    this.avaliacaoMedia = 0.0,
    this.totalAvaliacoes = 0,
    this.descricao,
    this.checklist = const {},
    this.fotosCapa = const [],
    this.fotoBraseao,
    this.fotoArena,
    this.fotoGalera,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get temQuorum => participantesConfirmados >= quorumMinimo;

  int get quorumMaximoEfetivo => quorumMaximo > 0 ? quorumMaximo : quorumMinimo;

  bool get temVagas => participantesConfirmados < quorumMaximoEfetivo;

  double get progressoQuorum => quorumMinimo > 0
      ? (participantesConfirmados / quorumMinimo).clamp(0.0, 1.0)
      : 0.0;

  Pelada copyWith({
    String? id,
    String? nome,
    String? organizadorId,
    String? organizadorNome,
    String? organizadorCpf,
    String? contato,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? recorrenciaGrupoId,
    List<int>? recorrenciaDiasSemana,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFim,
    double? taxa,
    Modalidade? modalidade,
    TipoGrama? tipoGrama,
    TipoChuteira? tipoChuteira,
    List<TipoChuteira>? tiposChuteiraPermitidos,
    CategoriaPelada? categoria,
    CategoriaGenero? categoriaGenero,
    bool? beneficioGoleiro,
    bool clearBeneficioGoleiro = false,
    int? corColeteIndex,
    List<int>? coresColeteIndices,
    String? corColetePersonalizado,
    String? endereco,
    String? localArena,
    String? estado,
    String? cidade,
    String? bairro,
    String? cep,
    double? latitude,
    double? longitude,
    StatusPelada? status,
    String? statusMotivo,
    int? quorumMinimo,
    int? quorumMaximo,
    int? participantesConfirmados,
    double? avaliacaoMedia,
    int? totalAvaliacoes,
    String? descricao,
    Map<String, bool>? checklist,
    List<PeladaCapaFoto>? fotosCapa,
    PeladaCapaFoto? fotoBraseao,
    PeladaCapaFoto? fotoArena,
    PeladaCapaFoto? fotoGalera,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pelada(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      organizadorId: organizadorId ?? this.organizadorId,
      organizadorNome: organizadorNome ?? this.organizadorNome,
      organizadorCpf: organizadorCpf ?? this.organizadorCpf,
      contato: contato ?? this.contato,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      recorrenciaGrupoId: recorrenciaGrupoId ?? this.recorrenciaGrupoId,
      recorrenciaDiasSemana:
          recorrenciaDiasSemana ?? List.of(this.recorrenciaDiasSemana),
      horaInicio: horaInicio ?? this.horaInicio,
      horaFim: horaFim ?? this.horaFim,
      taxa: taxa ?? this.taxa,
      modalidade: modalidade ?? this.modalidade,
      tipoGrama: tipoGrama ?? this.tipoGrama,
      tipoChuteira: tipoChuteira ?? this.tipoChuteira,
      tiposChuteiraPermitidos:
          tiposChuteiraPermitidos ?? List.of(this.tiposChuteiraPermitidos),
      categoria: categoria ?? this.categoria,
      categoriaGenero: categoriaGenero ?? this.categoriaGenero,
      beneficioGoleiro: clearBeneficioGoleiro
          ? null
          : (beneficioGoleiro ?? this.beneficioGoleiro),
      corColeteIndex: corColeteIndex ?? this.corColeteIndex,
      coresColeteIndices:
          coresColeteIndices ?? List.of(this.coresColeteIndices),
      corColetePersonalizado:
          corColetePersonalizado ?? this.corColetePersonalizado,
      endereco: endereco ?? this.endereco,
      localArena: localArena ?? this.localArena,
      estado: estado ?? this.estado,
      cidade: cidade ?? this.cidade,
      bairro: bairro ?? this.bairro,
      cep: cep ?? this.cep,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      statusMotivo: statusMotivo ?? this.statusMotivo,
      quorumMinimo: quorumMinimo ?? this.quorumMinimo,
      quorumMaximo: quorumMaximo ?? this.quorumMaximo,
      participantesConfirmados:
          participantesConfirmados ?? this.participantesConfirmados,
      avaliacaoMedia: avaliacaoMedia ?? this.avaliacaoMedia,
      totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
      descricao: descricao ?? this.descricao,
      checklist: checklist ?? Map.from(this.checklist),
      fotosCapa: fotosCapa ?? List.of(this.fotosCapa),
      fotoBraseao: fotoBraseao ?? this.fotoBraseao,
      fotoArena: fotoArena ?? this.fotoArena,
      fotoGalera: fotoGalera ?? this.fotoGalera,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'organizador_id': organizadorId,
      'organizador_nome': organizadorNome,
      'organizador_cpf': organizadorCpf,
      'contato': contato,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'recorrencia_grupo_id': recorrenciaGrupoId,
      'recorrencia_dias_semana': recorrenciaDiasSemana,
      'hora_inicio':
          '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
      'hora_fim':
          '${horaFim.hour.toString().padLeft(2, '0')}:${horaFim.minute.toString().padLeft(2, '0')}',
      'taxa': taxa,
      'modalidade': modalidade.name,
      'tipo_grama': tipoGrama.name,
      'tipo_chuteira': tipoChuteira.name,
      'tipos_chuteira_permitidos': tiposChuteiraPermitidos
          .map((e) => e.name)
          .toList(),
      'categoria': categoria.name,
      'categoria_genero': categoriaGenero.name,
      'beneficio_goleiro': beneficioGoleiro,
      'cor_colete_index': corColeteIndex,
      'cores_colete_indices': coresColeteIndices,
      'cor_colete_personalizado': corColetePersonalizado,
      'endereco': endereco,
      'local_arena': localArena,
      'estado': estado,
      'cidade': cidade,
      'bairro': bairro,
      'cep': cep,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'status_motivo': statusMotivo,
      'quorum_minimo': quorumMinimo,
      'quorum_maximo': quorumMaximo,
      'participantes_confirmados': participantesConfirmados,
      'avaliacao_media': avaliacaoMedia,
      'total_avaliacoes': totalAvaliacoes,
      'descricao': descricao,
      'checklist': checklist,
      'fotos_capa': fotosCapa.map((e) => e.toMap()).toList(),
      'foto_braseao': fotoBraseao?.toMap(),
      'foto_arena': fotoArena?.toMap(),
      'foto_galera': fotoGalera?.toMap(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Pelada.fromMap(Map<String, dynamic> map) {
    TimeOfDay parseHora(dynamic value) {
      if (value == null) return TimeOfDay.now();
      final parts = (value as String).split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      return TimeOfDay.now();
    }

    return Pelada(
      id: map['id'] as String,
      nome: map['nome'] as String? ?? 'Pelada',
      organizadorId: map['organizador_id'] as String? ?? '',
      organizadorNome: map['organizador_nome'] as String? ?? 'Organizador',
      organizadorCpf: map['organizador_cpf'] as String?,
      contato: map['contato'] as String? ?? '',
      dataInicio:
          DateTime.tryParse(map['data_inicio'] as String? ?? '') ??
          DateTime.now(),
      dataFim:
          DateTime.tryParse(map['data_fim'] as String? ?? '') ?? DateTime.now(),
      recorrenciaGrupoId: map['recorrencia_grupo_id'] as String?,
      recorrenciaDiasSemana: List<int>.from(
        map['recorrencia_dias_semana'] as List? ?? [],
      ),
      horaInicio: parseHora(map['hora_inicio']),
      horaFim: parseHora(map['hora_fim']),
      taxa: (map['taxa'] as num?)?.toDouble() ?? 0.0,
      modalidade: Modalidade.fromString(map['modalidade'] as String?),
      tipoGrama: TipoGrama.fromString(map['tipo_grama'] as String?),
      tipoChuteira: TipoChuteira.fromString(map['tipo_chuteira'] as String?),
      tiposChuteiraPermitidos:
          ((map['tipos_chuteira_permitidos'] as List?) ?? const [])
              .map((e) => TipoChuteira.fromString(e as String?))
              .toList(),
      categoria: CategoriaPelada.fromString(map['categoria'] as String?),
      categoriaGenero: CategoriaGenero.fromString(
        map['categoria_genero'] as String?,
      ),
      beneficioGoleiro: () {
        final raw = map['beneficio_goleiro'];
        if (raw == null) return null;
        if (raw is bool) return raw;
        if (raw is String) {
          final v = raw.trim().toLowerCase();
          if (v == 'true' || v == '1' || v == 'sim' || v == 's') return true;
          if (v == 'false' ||
              v == '0' ||
              v == 'nao' ||
              v == 'não' ||
              v == 'n') {
            return false;
          }
        }
        if (raw is num) return raw != 0;
        return null;
      }(),
      corColeteIndex: (map['cor_colete_index'] as num?)?.toInt() ?? 0,
      coresColeteIndices: List<int>.from(
        map['cores_colete_indices'] as List? ?? [],
      ),
      corColetePersonalizado: map['cor_colete_personalizado'] as String?,
      endereco: map['endereco'] as String? ?? '',
      localArena: map['local_arena'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      bairro: map['bairro'] as String? ?? '',
      cep: map['cep'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      status: StatusPelada.fromString(map['status'] as String?),
      statusMotivo: map['status_motivo'] as String?,
      quorumMinimo: (map['quorum_minimo'] as num?)?.toInt() ?? 10,
      quorumMaximo:
          (map['quorum_maximo'] as num?)?.toInt() ??
          (map['quorum_minimo'] as num?)?.toInt() ??
          0,
      participantesConfirmados:
          (map['participantes_confirmados'] as num?)?.toInt() ?? 0,
      avaliacaoMedia: (map['avaliacao_media'] as num?)?.toDouble() ?? 0.0,
      totalAvaliacoes: (map['total_avaliacoes'] as num?)?.toInt() ?? 0,
      descricao: map['descricao'] as String?,
      checklist: Map<String, bool>.from(map['checklist'] as Map? ?? {}),
      fotosCapa: ((map['fotos_capa'] as List?) ?? const [])
          .map(
            (e) => PeladaCapaFoto.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .where((e) => e.base64Data.isNotEmpty)
          .toList(),
      fotoBraseao: map['foto_braseao'] != null
          ? PeladaCapaFoto.fromMap(
              Map<String, dynamic>.from(map['foto_braseao'] as Map),
            )
          : null,
      fotoArena: map['foto_arena'] != null
          ? PeladaCapaFoto.fromMap(
              Map<String, dynamic>.from(map['foto_arena'] as Map),
            )
          : null,
      fotoGalera: map['foto_galera'] != null
          ? PeladaCapaFoto.fromMap(
              Map<String, dynamic>.from(map['foto_galera'] as Map),
            )
          : null,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
