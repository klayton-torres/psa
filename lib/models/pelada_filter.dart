import 'package:flutter/material.dart';
import 'enums.dart';

class PeladaFilter {
  final String? estado;
  final String? cidade;
  final String? bairro;
  final String? localArena;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final TimeOfDay? horarioInicio;
  final TimeOfDay? horarioFim;
  final CategoriaPelada? faixaEtaria;
  final TipoGrama? tipoCampo;
  final Set<TipoChuteira> tiposChuteira;
  final Set<Modalidade> modalidades;
  final Set<CategoriaGenero> categoriasGenero;
  final Set<int> diasSemana;
  final bool? apenasAtivas;
  final bool? apenasComVagas;
  final bool mostrarPassadas;

  const PeladaFilter({
    this.estado,
    this.cidade,
    this.bairro,
    this.localArena,
    this.dataInicio,
    this.dataFim,
    this.horarioInicio,
    this.horarioFim,
    this.faixaEtaria,
    this.tipoCampo,
    this.tiposChuteira = const {},
    this.modalidades = const {},
    this.categoriasGenero = const {},
    this.diasSemana = const {},
    this.apenasAtivas = true,
    this.apenasComVagas,
    this.mostrarPassadas = false,
  });

  bool get isEmpty =>
      estado == null &&
      cidade == null &&
      bairro == null &&
      localArena == null &&
      dataInicio == null &&
      dataFim == null &&
      horarioInicio == null &&
      horarioFim == null &&
      faixaEtaria == null &&
      tipoCampo == null &&
      tiposChuteira.isEmpty &&
      modalidades.isEmpty &&
      categoriasGenero.isEmpty &&
      diasSemana.isEmpty &&
      (apenasAtivas == true) &&
      apenasComVagas == null &&
      !mostrarPassadas;

  int get activeFiltersCount {
    int count = 0;
    if (estado != null) count++;
    if (cidade != null) count++;
    if (bairro != null) count++;
    if (localArena != null) count++;
    if (dataInicio != null || dataFim != null) count++;
    if (horarioInicio != null || horarioFim != null) count++;
    if (faixaEtaria != null) count++;
    if (tipoCampo != null) count++;
    if (tiposChuteira.isNotEmpty) count++;
    if (modalidades.isNotEmpty) count++;
    if (categoriasGenero.isNotEmpty) count++;
    if (diasSemana.isNotEmpty) count++;
    if (apenasComVagas == true) count++;
    if (apenasAtivas == false) count++;
    if (mostrarPassadas) count++;
    return count;
  }

  PeladaFilter copyWith({
    String? estado,
    String? cidade,
    String? bairro,
    String? localArena,
    DateTime? dataInicio,
    DateTime? dataFim,
    TimeOfDay? horarioInicio,
    TimeOfDay? horarioFim,
    CategoriaPelada? faixaEtaria,
    TipoGrama? tipoCampo,
    Set<TipoChuteira>? tiposChuteira,
    Set<Modalidade>? modalidades,
    Set<CategoriaGenero>? categoriasGenero,
    Set<int>? diasSemana,
    bool? apenasAtivas,
    bool? apenasComVagas,
    bool? mostrarPassadas,
    bool clearEstado = false,
    bool clearCidade = false,
    bool clearBairro = false,
    bool clearLocalArena = false,
    bool clearData = false,
    bool clearHorario = false,
    bool clearFaixaEtaria = false,
    bool clearTipoCampo = false,
    bool clearTipoChuteira = false,
    bool clearModalidades = false,
    bool clearCategoriasGenero = false,
    bool clearDiasSemana = false,
  }) {
    return PeladaFilter(
      estado: clearEstado ? null : (estado ?? this.estado),
      cidade: clearCidade ? null : (cidade ?? this.cidade),
      bairro: clearBairro ? null : (bairro ?? this.bairro),
      localArena: clearLocalArena ? null : (localArena ?? this.localArena),
      dataInicio: clearData ? null : (dataInicio ?? this.dataInicio),
      dataFim: clearData ? null : (dataFim ?? this.dataFim),
      horarioInicio: clearHorario
          ? null
          : (horarioInicio ?? this.horarioInicio),
      horarioFim: clearHorario ? null : (horarioFim ?? this.horarioFim),
      faixaEtaria: clearFaixaEtaria ? null : (faixaEtaria ?? this.faixaEtaria),
      tipoCampo: clearTipoCampo ? null : (tipoCampo ?? this.tipoCampo),
      tiposChuteira: clearTipoChuteira
          ? const {}
          : (tiposChuteira ?? this.tiposChuteira),
      modalidades: clearModalidades
          ? const {}
          : (modalidades ?? this.modalidades),
      categoriasGenero: clearCategoriasGenero
          ? const {}
          : (categoriasGenero ?? this.categoriasGenero),
      diasSemana: clearDiasSemana ? const {} : (diasSemana ?? this.diasSemana),
      apenasAtivas: apenasAtivas ?? this.apenasAtivas,
      apenasComVagas: apenasComVagas ?? this.apenasComVagas,
      mostrarPassadas: mostrarPassadas ?? this.mostrarPassadas,
    );
  }

  PeladaFilter clear() {
    return const PeladaFilter();
  }
}
