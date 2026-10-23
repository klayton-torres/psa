import 'pelada.dart';

class Goleiro {
  final String id;
  final PeladaCapaFoto? foto;
  final String nome;
  final String sobrenome;
  final String? apelido;
  final DateTime? dataNascimento;
  final String? telefone;
  final String? cep;
  final String? uf;
  final String? cidade;
  final String? bairro;
  final String? situacaoFederativa;
  final bool? comAuxiliares;
  final List<String> atuacao;
  final List<String> equipamentos;
  final List<String> modalidades;
  final double? taxaArbitragem;
  final String? proprietarioId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goleiro({
    required this.id,
    this.foto,
    required this.nome,
    required this.sobrenome,
    this.apelido,
    this.dataNascimento,
    this.telefone,
    this.cep,
    this.uf,
    this.cidade,
    this.bairro,
    this.situacaoFederativa,
    this.comAuxiliares,
    this.atuacao = const [],
    this.equipamentos = const [],
    this.modalidades = const [],
    this.taxaArbitragem,
    this.proprietarioId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get nomeCompleto {
    final sb = StringBuffer(nome.trim());
    final sn = sobrenome.trim();
    if (sn.isNotEmpty) {
      sb.write(' ');
      sb.write(sn);
    }
    return sb.toString();
  }

  String get nomeExibicao {
    if (apelido != null && apelido!.trim().isNotEmpty) {
      return apelido!.trim();
    }
    return nomeCompleto;
  }

  String get enderecoCurto {
    final partes = <String>[];
    if (bairro != null && bairro!.trim().isNotEmpty) {
      partes.add(bairro!.trim());
    }
    final cid = <String>[];
    if (cidade != null && cidade!.trim().isNotEmpty) {
      cid.add(cidade!.trim());
    }
    if (uf != null && uf!.trim().isNotEmpty) {
      cid.add(uf!.trim());
    }
    if (cid.isNotEmpty) {
      partes.add(cid.join(' - '));
    }
    return partes.join(', ');
  }

  Goleiro copyWith({
    String? id,
    PeladaCapaFoto? foto,
    bool clearFoto = false,
    String? nome,
    String? sobrenome,
    String? apelido,
    bool clearApelido = false,
    DateTime? dataNascimento,
    bool clearDataNascimento = false,
    String? telefone,
    bool clearTelefone = false,
    String? cep,
    bool clearCep = false,
    String? uf,
    bool clearUf = false,
    String? cidade,
    bool clearCidade = false,
    String? bairro,
    bool clearBairro = false,
    String? situacaoFederativa,
    bool clearSituacaoFederativa = false,
    bool? comAuxiliares,
    bool clearComAuxiliares = false,
    List<String>? atuacao,
    List<String>? equipamentos,
    List<String>? modalidades,
    double? taxaArbitragem,
    bool clearTaxaArbitragem = false,
    String? proprietarioId,
    bool clearProprietarioId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goleiro(
      id: id ?? this.id,
      foto: clearFoto ? null : (foto ?? this.foto),
      nome: nome ?? this.nome,
      sobrenome: sobrenome ?? this.sobrenome,
      apelido: clearApelido ? null : (apelido ?? this.apelido),
      dataNascimento: clearDataNascimento
          ? null
          : (dataNascimento ?? this.dataNascimento),
      telefone: clearTelefone ? null : (telefone ?? this.telefone),
      cep: clearCep ? null : (cep ?? this.cep),
      uf: clearUf ? null : (uf ?? this.uf),
      cidade: clearCidade ? null : (cidade ?? this.cidade),
      bairro: clearBairro ? null : (bairro ?? this.bairro),
      situacaoFederativa: clearSituacaoFederativa
          ? null
          : (situacaoFederativa ?? this.situacaoFederativa),
      comAuxiliares: clearComAuxiliares
          ? null
          : (comAuxiliares ?? this.comAuxiliares),
      atuacao: atuacao ?? this.atuacao,
      equipamentos: equipamentos ?? this.equipamentos,
      modalidades: modalidades ?? this.modalidades,
      taxaArbitragem: clearTaxaArbitragem
          ? null
          : (taxaArbitragem ?? this.taxaArbitragem),
      proprietarioId: clearProprietarioId
          ? null
          : (proprietarioId ?? this.proprietarioId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foto': foto?.toMap(),
      'nome': nome,
      'sobrenome': sobrenome,
      'apelido': apelido,
      'data_nascimento': dataNascimento?.toIso8601String(),
      'telefone': telefone,
      'cep': cep,
      'uf': uf,
      'cidade': cidade,
      'bairro': bairro,
      'situacao_federativa': situacaoFederativa,
      'com_auxiliares': comAuxiliares,
      'atuacao': atuacao,
      'equipamentos': equipamentos,
      'modalidades': modalidades,
      'taxa_arbitragem': taxaArbitragem,
      'proprietario_id': proprietarioId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Goleiro.fromMap(Map<String, dynamic> map) {
    final fotoRaw = map['foto'];
    PeladaCapaFoto? foto;
    if (fotoRaw is Map) {
      try {
        foto = PeladaCapaFoto.fromMap(Map<String, dynamic>.from(fotoRaw));
      } catch (_) {
        foto = null;
      }
    }

    return Goleiro(
      id: map['id'] as String? ?? '',
      foto: foto,
      nome: map['nome'] as String? ?? '',
      sobrenome: map['sobrenome'] as String? ?? '',
      apelido: map['apelido'] as String?,
      dataNascimento: DateTime.tryParse(
        (map['data_nascimento'] as String?) ?? '',
      ),
      telefone: map['telefone'] as String?,
      cep: map['cep'] as String?,
      uf: map['uf'] as String?,
      cidade: map['cidade'] as String?,
      bairro: map['bairro'] as String?,
      situacaoFederativa: map['situacao_federativa'] as String?,
      comAuxiliares: map['com_auxiliares'] as bool?,
      atuacao: _stringList(map['atuacao']),
      equipamentos: _stringList(map['equipamentos']),
      modalidades: _stringList(map['modalidades']),
      taxaArbitragem: (map['taxa_arbitragem'] as num?)?.toDouble(),
      proprietarioId: map['proprietario_id'] as String?,
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updated_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}
