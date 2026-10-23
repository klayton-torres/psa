import 'enums.dart';

class Participation {
  final String id;
  final String peladaId;
  final String usuarioId;
  final String usuarioNome;
  final String? usuarioApelido;
  final int? usuarioIdade;
  final PosicaoAtleta? usuarioPosicaoPrincipal;
  final String? usuarioFotoUrl;
  final StatusParticipacao status;
  final MotivoAusencia? motivoAusencia;
  final String? observacao;
  final int? notaAvaliacao;
  final String? comentarioAvaliacao;
  final DateTime? dataAvaliacao;
  final String? formaPagamento;
  final double valorPago;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Participation({
    required this.id,
    required this.peladaId,
    required this.usuarioId,
    required this.usuarioNome,
    this.usuarioApelido,
    this.usuarioIdade,
    this.usuarioPosicaoPrincipal,
    this.usuarioFotoUrl,
    required this.status,
    this.motivoAusencia,
    this.observacao,
    this.notaAvaliacao,
    this.comentarioAvaliacao,
    this.dataAvaliacao,
    this.formaPagamento,
    this.valorPago = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Participation copyWith({
    String? id,
    String? peladaId,
    String? usuarioId,
    String? usuarioNome,
    String? usuarioApelido,
    int? usuarioIdade,
    PosicaoAtleta? usuarioPosicaoPrincipal,
    String? usuarioFotoUrl,
    StatusParticipacao? status,
    MotivoAusencia? motivoAusencia,
    String? observacao,
    int? notaAvaliacao,
    String? comentarioAvaliacao,
    DateTime? dataAvaliacao,
    String? formaPagamento,
    bool clearFormaPagamento = false,
    double? valorPago,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Participation(
      id: id ?? this.id,
      peladaId: peladaId ?? this.peladaId,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      usuarioApelido: usuarioApelido ?? this.usuarioApelido,
      usuarioIdade: usuarioIdade ?? this.usuarioIdade,
      usuarioPosicaoPrincipal:
          usuarioPosicaoPrincipal ?? this.usuarioPosicaoPrincipal,
      usuarioFotoUrl: usuarioFotoUrl ?? this.usuarioFotoUrl,
      status: status ?? this.status,
      motivoAusencia: motivoAusencia ?? this.motivoAusencia,
      observacao: observacao ?? this.observacao,
      notaAvaliacao: notaAvaliacao ?? this.notaAvaliacao,
      comentarioAvaliacao: comentarioAvaliacao ?? this.comentarioAvaliacao,
      dataAvaliacao: dataAvaliacao ?? this.dataAvaliacao,
      formaPagamento: clearFormaPagamento
          ? null
          : (formaPagamento ?? this.formaPagamento),
      valorPago: valorPago ?? this.valorPago,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pelada_id': peladaId,
      'usuario_id': usuarioId,
      'usuario_nome': usuarioNome,
      'usuario_apelido': usuarioApelido,
      'usuario_idade': usuarioIdade,
      'usuario_posicao_principal': usuarioPosicaoPrincipal?.name,
      'usuario_foto_url': usuarioFotoUrl,
      'status': status.name,
      'motivo_ausencia': motivoAusencia?.name,
      'observacao': observacao,
      'nota_avaliacao': notaAvaliacao,
      'comentario_avaliacao': comentarioAvaliacao,
      'data_avaliacao': dataAvaliacao?.toIso8601String(),
      'forma_pagamento': formaPagamento,
      'valor_pago': valorPago,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Participation.fromMap(Map<String, dynamic> map) {
    return Participation(
      id: map['id'] as String,
      peladaId: map['pelada_id'] as String? ?? '',
      usuarioId: map['usuario_id'] as String? ?? '',
      usuarioNome: map['usuario_nome'] as String? ?? '',
      usuarioApelido: map['usuario_apelido'] as String?,
      usuarioIdade: (map['usuario_idade'] as num?)?.toInt(),
      usuarioPosicaoPrincipal: PosicaoAtleta.fromString(
        map['usuario_posicao_principal'] as String?,
      ),
      usuarioFotoUrl: map['usuario_foto_url'] as String?,
      status: StatusParticipacao.fromString(map['status'] as String?),
      motivoAusencia: map['motivo_ausencia'] != null
          ? MotivoAusencia.fromString(map['motivo_ausencia'] as String?)
          : null,
      observacao: map['observacao'] as String?,
      notaAvaliacao: (map['nota_avaliacao'] as num?)?.toInt(),
      comentarioAvaliacao: map['comentario_avaliacao'] as String?,
      dataAvaliacao: map['data_avaliacao'] != null
          ? DateTime.tryParse(map['data_avaliacao'] as String)
          : null,
      formaPagamento: map['forma_pagamento'] as String?,
      valorPago: (map['valor_pago'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
