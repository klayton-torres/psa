enum TipoChuteira {
  trava,
  society,
  tenis,
  descalco,
  livre;

  String get label {
    switch (this) {
      case TipoChuteira.trava:
        return 'Trava';
      case TipoChuteira.society:
        return 'Society';
      case TipoChuteira.tenis:
        return 'Tênis';
      case TipoChuteira.descalco:
        return 'Descalço';
      case TipoChuteira.livre:
        return 'Livre';
    }
  }

  static TipoChuteira fromString(String? value) {
    if (value == null) return TipoChuteira.livre;
    switch (value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')) {
      case 'TRAVA':
        return TipoChuteira.trava;
      case 'SOCIETY':
        return TipoChuteira.society;
      case 'TENIS':
        return TipoChuteira.tenis;
      case 'DESCALCO':
        return TipoChuteira.descalco;
      default:
        return TipoChuteira.livre;
    }
  }
}

enum PosicaoAtleta {
  zagaFixo,
  lateralAla,
  meia,
  atacantePivo,
  ponta,
  goleiro;

  String get label {
    switch (this) {
      case PosicaoAtleta.zagaFixo:
        return 'Zaga / Fixo';
      case PosicaoAtleta.lateralAla:
        return 'Lateral / Ala';
      case PosicaoAtleta.meia:
        return 'Meia';
      case PosicaoAtleta.atacantePivo:
        return 'Atacante / Pivô';
      case PosicaoAtleta.ponta:
        return 'Ponta';
      case PosicaoAtleta.goleiro:
        return 'Goleiro';
    }
  }

  String get abreviacao {
    switch (this) {
      case PosicaoAtleta.zagaFixo:
        return 'ZAG.';
      case PosicaoAtleta.lateralAla:
        return 'LAT.';
      case PosicaoAtleta.meia:
        return 'MEI.';
      case PosicaoAtleta.atacantePivo:
        return 'ATA.';
      case PosicaoAtleta.ponta:
        return 'PON.';
      case PosicaoAtleta.goleiro:
        return 'GOL.';
    }
  }

  static PosicaoAtleta? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('Ô', 'O');
    switch (normalized) {
      case 'ZAGAFIXO':
      case 'ZAGA':
      case 'FIXO':
      case 'ZAG':
      case 'ZAG.':
        return PosicaoAtleta.zagaFixo;
      case 'LATERALALA':
      case 'LATERAL':
      case 'ALA':
      case 'LAT':
      case 'LAT.':
        return PosicaoAtleta.lateralAla;
      case 'MEIA':
      case 'MEIO':
      case 'MEIOCAMPO':
      case 'MEI':
      case 'MEI.':
        return PosicaoAtleta.meia;
      case 'ATACANTEPIVO':
      case 'ATACANTE':
      case 'PIVO':
      case 'ATA':
      case 'ATA.':
        return PosicaoAtleta.atacantePivo;
      case 'PONTA':
      case 'PONTEIRA':
      case 'PON':
      case 'PON.':
        return PosicaoAtleta.ponta;
      case 'GOLEIRO':
      case 'GOLEIRA':
      case 'GOL':
      case 'GOL.':
        return PosicaoAtleta.goleiro;
      default:
        return null;
    }
  }
}

enum CategoriaPelada {
  livreAdulto,
  sub10,
  sub13,
  sub15,
  sub17,
  sub20,
  sub23,
  sub35,
  acima35,
  acima40,
  acima50,
  acima60,
  acima70;

  String get label {
    switch (this) {
      case CategoriaPelada.livreAdulto:
        return 'Livre Adulto';
      case CategoriaPelada.sub10:
        return 'Sub 10';
      case CategoriaPelada.sub13:
        return 'Sub 13';
      case CategoriaPelada.sub15:
        return 'Sub 15';
      case CategoriaPelada.sub17:
        return 'Sub 17';
      case CategoriaPelada.sub20:
        return 'Sub 20';
      case CategoriaPelada.sub23:
        return 'Sub 23';
      case CategoriaPelada.sub35:
        return 'Sub 35';
      case CategoriaPelada.acima35:
        return 'Acima de 35';
      case CategoriaPelada.acima40:
        return 'Acima de 40';
      case CategoriaPelada.acima50:
        return 'Acima de 50';
      case CategoriaPelada.acima60:
        return 'Acima de 60';
      case CategoriaPelada.acima70:
        return 'Acima de 70';
    }
  }

  static CategoriaPelada fromString(String? value) {
    if (value == null) return CategoriaPelada.livreAdulto;
    final normalized = value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A');
    switch (normalized) {
      case 'LIVREADULTO':
      case 'LIVRE':
        return CategoriaPelada.livreAdulto;
      case 'SUB10':
        return CategoriaPelada.sub10;
      case 'SUB13':
      case 'SUB12':
        return CategoriaPelada.sub13;
      case 'SUB15':
        return CategoriaPelada.sub15;
      case 'SUB17':
        return CategoriaPelada.sub17;
      case 'SUB20':
        return CategoriaPelada.sub20;
      case 'SUB23':
        return CategoriaPelada.sub23;
      case 'SUB35':
        return CategoriaPelada.sub35;
      case 'ACIMADE35':
      case 'ACIMA35':
        return CategoriaPelada.acima35;
      case 'ACIMADE40':
      case 'ACIMA40':
        return CategoriaPelada.acima40;
      case 'ACIMADE50':
      case 'ACIMA50':
        return CategoriaPelada.acima50;
      case 'ACIMADE60':
      case 'ACIMA60':
        return CategoriaPelada.acima60;
      case 'ACIMADE70':
      case 'ACIMA70':
        return CategoriaPelada.acima70;
      default:
        return CategoriaPelada.livreAdulto;
    }
  }
}

enum StatusPelada {
  ativa,
  suspensa,
  bloqueada,
  cancelada;

  String get label {
    switch (this) {
      case StatusPelada.ativa:
        return 'Ativa';
      case StatusPelada.suspensa:
        return 'Suspensa';
      case StatusPelada.bloqueada:
        return 'Bloqueada';
      case StatusPelada.cancelada:
        return 'Cancelada';
    }
  }

  static StatusPelada fromString(String? value) {
    if (value == null) return StatusPelada.ativa;
    switch (value.toUpperCase()) {
      case 'ATIVA':
        return StatusPelada.ativa;
      case 'SUSPENSA':
        return StatusPelada.suspensa;
      case 'BLOQUEADA':
        return StatusPelada.bloqueada;
      case 'CANCELADA':
        return StatusPelada.cancelada;
      default:
        return StatusPelada.ativa;
    }
  }
}

enum StatusParticipacao {
  confirmada,
  tenhoDuvida,
  naoIrei;

  String get label {
    switch (this) {
      case StatusParticipacao.confirmada:
        return 'Bora, vou!';
      case StatusParticipacao.tenhoDuvida:
        return 'Talvez';
      case StatusParticipacao.naoIrei:
        return 'Num vou!';
    }
  }

  static StatusParticipacao fromString(String? value) {
    if (value == null) return StatusParticipacao.tenhoDuvida;
    final normalized = value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('É', 'E');
    switch (normalized) {
      case 'CONFIRMADA':
      case 'CONFIRMADO':
        return StatusParticipacao.confirmada;
      case 'NAOTENHOCERTEZA':
      case 'TENHODUVIDA':
        return StatusParticipacao.tenhoDuvida;
      case 'NAOIREI':
        return StatusParticipacao.naoIrei;
      default:
        return StatusParticipacao.tenhoDuvida;
    }
  }
}

enum MotivoAusencia {
  dm,
  carona,
  patroa,
  semChuteira,
  outros;

  String get label {
    switch (this) {
      case MotivoAusencia.dm:
        return 'DM';
      case MotivoAusencia.carona:
        return 'Carona';
      case MotivoAusencia.patroa:
        return 'Patroa não deixa';
      case MotivoAusencia.semChuteira:
        return 'Estou sem chuteira';
      case MotivoAusencia.outros:
        return 'Outros motivos';
    }
  }

  static MotivoAusencia fromString(String? value) {
    if (value == null) return MotivoAusencia.outros;
    final normalized = value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A');
    switch (normalized) {
      case 'DM':
        return MotivoAusencia.dm;
      case 'CARONA':
        return MotivoAusencia.carona;
      case 'PATROANAODEIXA':
      case 'PATROA':
        return MotivoAusencia.patroa;
      case 'ESTOUSEMCHUTEIRA':
      case 'SEMCHUTEIRA':
        return MotivoAusencia.semChuteira;
      default:
        return MotivoAusencia.outros;
    }
  }
}

enum ChecklistItem {
  campoOk,
  bolasOk,
  coletesOk,
  apitoOk,
  cartoesOk,
  aguaOk,
  juizOk,
  goleirosOk,
  traves,
  redes,
  raquetes,
  bandeiras;

  String get label {
    switch (this) {
      case ChecklistItem.campoOk:
        return 'Campo';
      case ChecklistItem.bolasOk:
        return 'Bolas';
      case ChecklistItem.coletesOk:
        return 'Coletes';
      case ChecklistItem.apitoOk:
        return 'Apito';
      case ChecklistItem.cartoesOk:
        return 'Cartões';
      case ChecklistItem.aguaOk:
        return 'Água';
      case ChecklistItem.juizOk:
        return 'Juiz';
      case ChecklistItem.goleirosOk:
        return 'Goleiros';
      case ChecklistItem.traves:
        return 'Traves';
      case ChecklistItem.redes:
        return 'Redes';
      case ChecklistItem.raquetes:
        return 'Raquetes';
      case ChecklistItem.bandeiras:
        return 'Bandeiras';
    }
  }
}

enum Modalidade {
  futebolCampo,
  futebolRua,
  futsal,
  society,
  areia,
  praia,
  futevolei,
  voley,
  basquete,
  outros;

  static var campo7;

  static var campo11;

  String get label {
    switch (this) {
      case Modalidade.futebolCampo:
        return 'Futebol de Campo';
      case Modalidade.futebolRua:
        return 'Futebol de Rua';
      case Modalidade.futsal:
        return 'Futsal';
      case Modalidade.society:
        return 'Society';
      case Modalidade.areia:
        return 'Futebol de Areia';
      case Modalidade.praia:
        return 'Praia';
      case Modalidade.futevolei:
        return 'Futevôlei';
      case Modalidade.voley:
        return 'Vôlei';
      case Modalidade.basquete:
        return 'Basquete';
      case Modalidade.outros:
        return 'Outros';
    }
  }

  static Modalidade fromString(String? value) {
    if (value == null) return Modalidade.futebolCampo;
    final normalized = value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('/', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('Ó', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Ê', 'E')
        .replaceAll('Ô', 'O');
    switch (normalized) {
      case 'FUTEBOLDECAMPO':
      case 'CAMPO':
        return Modalidade.futebolCampo;
      case 'FUTEBOLDERUA':
      case 'RUA':
        return Modalidade.futebolRua;
      case 'FUTSAL':
        return Modalidade.futsal;
      case 'SOCIETY':
        return Modalidade.society;
      case 'FUTEBOLDEAREIA':
      case 'AREIA':
        return Modalidade.areia;
      case 'PRAIA':
        return Modalidade.praia;
      case 'FUTEVOLEI':
      case 'FUTEVÔLEI':
      case 'FUTVOLEI':
      case 'FUTVÔLEI':
        return Modalidade.futevolei;
      case 'VOLEI':
      case 'VÔLEI':
      case 'VOLEY':
        return Modalidade.voley;
      case 'BASQUETE':
      case 'BASQUETE':
        return Modalidade.basquete;
      case 'OUTROS':
      case 'OUTRO':
        return Modalidade.outros;
      default:
        return Modalidade.futebolCampo;
    }
  }
}

enum CategoriaGenero {
  masc,
  fem;

  String get label {
    switch (this) {
      case CategoriaGenero.masc:
        return 'MASC.';
      case CategoriaGenero.fem:
        return 'FEM.';
    }
  }

  static CategoriaGenero fromString(String? value) {
    if (value == null) return CategoriaGenero.masc;
    final n = value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A');
    switch (n) {
      case 'MASC':
      case 'MASCULINO':
      case 'M':
        return CategoriaGenero.masc;
      case 'FEM':
      case 'FEMININO':
      case 'F':
        return CategoriaGenero.fem;
      default:
        return CategoriaGenero.masc;
    }
  }
}

enum TipoGrama {
  natural,
  sintetica,
  areia,
  quadra,
  picheAsfalto,
  cimento,
  outra;

  String get label {
    switch (this) {
      case TipoGrama.natural:
        return 'Natural';
      case TipoGrama.sintetica:
        return 'Sintética';
      case TipoGrama.areia:
        return 'Areia';
      case TipoGrama.quadra:
        return 'Quadra';
      case TipoGrama.picheAsfalto:
        return 'Piche/Asfalto';
      case TipoGrama.cimento:
        return 'Cimento';
      case TipoGrama.outra:
        return 'Outra';
    }
  }

  static TipoGrama fromString(String? value) {
    if (value == null) return TipoGrama.natural;
    switch (value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('/', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')) {
      case 'NATURAL':
        return TipoGrama.natural;
      case 'SINTETICA':
        return TipoGrama.sintetica;
      case 'SOCIETY':
        return TipoGrama.sintetica;
      case 'AREIA':
        return TipoGrama.areia;
      case 'QUADRA':
        return TipoGrama.quadra;
      case 'PICHE':
      case 'ASFALTO':
      case 'PICHEASFALTO':
      case 'ASFALTOPICHE':
        return TipoGrama.picheAsfalto;
      case 'CIMENTO':
        return TipoGrama.cimento;
      case 'OUTRO':
      case 'OUTRA':
        return TipoGrama.outra;
      default:
        return TipoGrama.outra;
    }
  }
}

enum DependenciaCampo {
  estacionamento,
  arquibancada,
  vestiario,
  chuveiros,
  banheiros,
  bebedouros,
  bar,
  sinuca,
  salaoFestaseEventos,
  lanchonete,
  restaurante,
  salaEspera,
  alugaParaEventos,
  espacoKids;

  String get label {
    switch (this) {
      case DependenciaCampo.estacionamento:
        return 'Estacionamento';
      case DependenciaCampo.arquibancada:
        return 'Arquibancada';
      case DependenciaCampo.vestiario:
        return 'Vestiário';
      case DependenciaCampo.chuveiros:
        return 'Chuveiros';
      case DependenciaCampo.banheiros:
        return 'Banheiros';
      case DependenciaCampo.bebedouros:
        return 'Bebedouros';
      case DependenciaCampo.bar:
        return 'Bar';
      case DependenciaCampo.sinuca:
        return 'Sinuca';
      case DependenciaCampo.salaoFestaseEventos:
        return 'Salão de festas';
      case DependenciaCampo.lanchonete:
        return 'Lanchonete';
      case DependenciaCampo.restaurante:
        return 'Restaurante';
      case DependenciaCampo.salaEspera:
        return 'Sala de espera';
      case DependenciaCampo.alugaParaEventos:
        return 'Aluga para eventos';
      case DependenciaCampo.espacoKids:
        return 'Espaço Kids';
    }
  }

  static DependenciaCampo fromString(String? value) {
    if (value == null) return DependenciaCampo.estacionamento;
    final n = value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('Õ', 'O')
        .replaceAll('Â', 'A');
    switch (n) {
      case 'ESTACIONAMENTO':
        return DependenciaCampo.estacionamento;
      case 'ARQUIBANCADA':
        return DependenciaCampo.arquibancada;
      case 'VESTIARIO':
        return DependenciaCampo.vestiario;
      case 'CHUVEIROS':
        return DependenciaCampo.chuveiros;
      case 'BANHEIROS':
        return DependenciaCampo.banheiros;
      case 'BEBEDOUROS':
        return DependenciaCampo.bebedouros;
      case 'BAR':
        return DependenciaCampo.bar;
      case 'SINUCA':
        return DependenciaCampo.sinuca;
      case 'SALAODEFESTAS':
      case 'SALAODEFESTAS':
      case 'FESTASEVENTOS':
      case 'SALÃODEFESTAS':
        return DependenciaCampo.salaoFestaseEventos;
      case 'LANCHONETE':
        return DependenciaCampo.lanchonete;
      case 'RESTAURANTE':
        return DependenciaCampo.restaurante;
      case 'SALADEESPERA':
        return DependenciaCampo.salaEspera;
      case 'ALUGAPARAEVENTOS':
      case 'ALUGUEVENTOS':
      case 'ALUGAPARAEVENTO':
        return DependenciaCampo.alugaParaEventos;
      case 'ESPACOKIDS':
        return DependenciaCampo.espacoKids;
      default:
        return DependenciaCampo.estacionamento;
    }
  }
}

enum ItemOpcionalCampo {
  aguaMineral,
  coletes,
  bola,
  apito,
  cartoes,
  chuteiras;

  String get label {
    switch (this) {
      case ItemOpcionalCampo.aguaMineral:
        return 'Água mineral';
      case ItemOpcionalCampo.coletes:
        return 'Coletes';
      case ItemOpcionalCampo.bola:
        return 'Bola';
      case ItemOpcionalCampo.apito:
        return 'Apito';
      case ItemOpcionalCampo.cartoes:
        return 'Cartões';
      case ItemOpcionalCampo.chuteiras:
        return 'Chuteiras';
    }
  }

  static ItemOpcionalCampo fromString(String? value) {
    if (value == null) return ItemOpcionalCampo.bola;
    final n = value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('Õ', 'O')
        .replaceAll('Á', 'A');
    switch (n) {
      case 'AGUAMINERAL':
        return ItemOpcionalCampo.aguaMineral;
      case 'COLETES':
        return ItemOpcionalCampo.coletes;
      case 'BOLA':
        return ItemOpcionalCampo.bola;
      case 'APITO':
        return ItemOpcionalCampo.apito;
      case 'CARTOES':
      case 'CARTÕES':
        return ItemOpcionalCampo.cartoes;
      case 'CHUTEIRAS':
        return ItemOpcionalCampo.chuteiras;
      default:
        return ItemOpcionalCampo.bola;
    }
  }
}
