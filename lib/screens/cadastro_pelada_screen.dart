import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/enums.dart';
import '../models/pelada.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/location_service.dart';
import '../utils/title_case_input_formatter.dart';
import '../utils/form_focus_helper.dart';
import '../widgets/checklist_card.dart';
import '../widgets/date_input_field.dart';
import '../widgets/estado_cidade_fields.dart';

class CadastroPeladaScreen extends StatefulWidget {
  final Pelada? pelada;
  final bool isClone;
  const CadastroPeladaScreen({super.key, this.pelada, this.isClone = false});

  @override
  State<CadastroPeladaScreen> createState() => _CadastroPeladaScreenState();
}

class _CadastroPeladaScreenState extends State<CadastroPeladaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  static const int _maxFotoBytes = 5 * 1024 * 1024;
  static const Set<String> _extPermitidas = {'jpg', 'jpeg', 'png', 'webp'};

  final ImagePicker _imagePicker = ImagePicker();
  final List<PeladaCapaFoto> _fotosCapa = [];
  PeladaCapaFoto? _fotoBraseao;
  PeladaCapaFoto? _fotoArena;
  PeladaCapaFoto? _fotoGalera;

  final _nomeCtrl = TextEditingController();
  final _organizadorCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _contatoCtrl = TextEditingController();
  final _dataInicioCtrl = TextEditingController();
  final _dataFimCtrl = TextEditingController();
  final _horaInicioCtrl = TextEditingController();
  final _horaFimCtrl = TextEditingController();
  final _taxaCtrl = TextEditingController(text: '0');
  final _quorumCtrl = TextEditingController(text: '10');
  final _quorumMaxCtrl = TextEditingController(text: '10');
  final _enderecoCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _localArenaCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _corPersonalizadoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();

  final _cepFocus = FocusNode();
  final _nomeFocus = FocusNode();
  final _organizadorFocus = FocusNode();
  final _cpfFocus = FocusNode();
  final _contatoFocus = FocusNode();
  final _dataInicioFocus = FocusNode();
  final _dataFimFocus = FocusNode();
  final _horaInicioFocus = FocusNode();
  final _horaFimFocus = FocusNode();
  final _taxaFocus = FocusNode();
  final _corPersonalizadoFocus = FocusNode();
  final _cepCampoFocus = FocusNode();
  final _ruaFocus = FocusNode();
  final _numeroFocus = FocusNode();
  final _localArenaFocus = FocusNode();
  final _bairroFocus = FocusNode();
  final _cidadeFocus = FocusNode();
  final _estadoFocus = FocusNode();

  final _keyNome = GlobalKey();
  final _keyOrganizador = GlobalKey();
  final _keyCpf = GlobalKey();
  final _keyContato = GlobalKey();
  final _keyDataInicio = GlobalKey();
  final _keyDataFim = GlobalKey();
  final _keyHoraInicio = GlobalKey();
  final _keyHoraFim = GlobalKey();
  final _keyTaxa = GlobalKey();
  final _keyModalidade = GlobalKey();
  final _keyTipoGrama = GlobalKey();
  final _keyTipoChuteira = GlobalKey();
  final _keyCategoria = GlobalKey();
  final _keyCorColete = GlobalKey();
  final _keyCorPersonalizada = GlobalKey();
  final _keyEnderecoLocal = GlobalKey();
  final _keyStatus = GlobalKey();
  final _keyLocalArena = GlobalKey();
  final _keyUf = GlobalKey();
  final _keyCidade = GlobalKey();
  final _keyBairro = GlobalKey();
  final _keyRua = GlobalKey();
  final _keyRecorrencia = GlobalKey();
  bool _cepCarregando = false;
  String? _cepErro;
  Timer? _cepDebounceTimer;

  DateTime _dataInicio = DateTime.now().add(const Duration(days: 1));
  DateTime _dataFim = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaInicio = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _horaFim = const TimeOfDay(hour: 22, minute: 0);

  Modalidade _modalidade = Modalidade.society;
  TipoGrama _tipoGrama = TipoGrama.sintetica;
  // ✅ Valor padrão do campo "Tipo de Chuteira":
  // Requisito do usuário → alterado de LIVRE para SOCIETY.
  // O usuário pode selecionar múltiplos valores; por padrão apenas
  // TipoChuteira.society fica selecionado, a validação exige ao
  // menos 1 valor preenchido (status quente: validado em _enviarForm).
  Set<TipoChuteira> _tiposChuteira = {TipoChuteira.society};
  CategoriaPelada _categoria = CategoriaPelada.livreAdulto;
  CategoriaGenero _categoriaGenero = CategoriaGenero.masc;
  bool? _beneficioGoleiro;
  Set<int> _coresColete = {5};
  StatusPelada _status = StatusPelada.ativa;
  Set<int> _recorrenciaDiasSemana = {};
  Map<String, bool> _checklist = {};

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cepMask = MaskTextInputFormatter(
    mask: '##.###-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _taxaCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _cepFocus.addListener(() {
      if (_cepFocus.hasFocus) {
        final String cepAtual = LocationService.apenasDigitos(_cepCtrl.text);
        if (cepAtual.isEmpty) {
          _limparCamposEndereco();
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final u = auth.currentUser;
      final p = widget.pelada;
      final clonando = widget.isClone;
      if (p != null) {
        _nomeCtrl.text = p.nome.toUpperCase();
        _organizadorCtrl.text = p.organizadorNome;
        _cpfCtrl.text = p.organizadorCpf ?? '';
        _contatoCtrl.text = p.contato;
        if (clonando) {
          final amanha = DateTime.now().add(const Duration(days: 1));
          _dataInicio = amanha;
          _dataFim = amanha;
          _horaInicio = p.horaInicio;
          _horaFim = p.horaFim;
          _status = StatusPelada.ativa;
        } else {
          _dataInicio = p.dataInicio;
          _dataFim = p.dataFim;
          _horaInicio = p.horaInicio;
          _horaFim = p.horaFim;
          _status = p.status;
        }
        _taxaCtrl.text = p.taxa % 1 == 0
            ? p.taxa.toInt().toString()
            : p.taxa.toString();
        _quorumCtrl.text = p.quorumMinimo.toString();
        _quorumMaxCtrl.text = p.quorumMaximoEfetivo.toString();
        _modalidade = p.modalidade;
        _tipoGrama = p.tipoGrama;
        _tiposChuteira = {
          ...(p.tiposChuteiraPermitidos.isNotEmpty
              ? p.tiposChuteiraPermitidos
              : [p.tipoChuteira]),
        };
        _categoria = p.categoria;
        _categoriaGenero = p.categoriaGenero;
        _beneficioGoleiro = p.beneficioGoleiro;
        _coresColete = {
          ...(p.coresColeteIndices.isNotEmpty
              ? p.coresColeteIndices
              : [p.corColeteIndex]),
        };
        _enderecoCtrl.text = p.endereco;
        final extraido = LocationService.extrairNumeroDoEndereco(
          p.endereco.trim(),
        );
        _enderecoCtrl.text = extraido.rua;
        if (extraido.numero.isNotEmpty && _numeroCtrl.text.trim().isEmpty) {
          _numeroCtrl.text = extraido.numero;
        }
        _localArenaCtrl.text = p.localArena.toUpperCase();
        _estadoCtrl.text = p.estado;
        _cidadeCtrl.text = p.cidade;
        _bairroCtrl.text = p.bairro;
        _cepCtrl.text = p.cep ?? '';
        _descricaoCtrl.text = p.descricao ?? '';
        _corPersonalizadoCtrl.text = p.corColetePersonalizado ?? '';
        _fotosCapa
          ..clear()
          ..addAll(p.fotosCapa);
        _fotoBraseao = p.fotoBraseao;
        _fotoArena = p.fotoArena;
        _fotoGalera = p.fotoGalera;
        _recorrenciaDiasSemana = {...p.recorrenciaDiasSemana};
        _checklist = Map<String, bool>.from(p.checklist);
      } else if (u != null) {
        _organizadorCtrl.text = u.nomeCompleto;
        _contatoCtrl.text = u.telefone ?? '';
      }
      _formatarDatas();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nomeCtrl.dispose();
    _organizadorCtrl.dispose();
    _cpfCtrl.dispose();
    _contatoCtrl.dispose();
    _dataInicioCtrl.dispose();
    _dataFimCtrl.dispose();
    _horaInicioCtrl.dispose();
    _horaFimCtrl.dispose();
    _taxaCtrl.dispose();
    _quorumCtrl.dispose();
    _quorumMaxCtrl.dispose();
    _enderecoCtrl.dispose();
    _numeroCtrl.dispose();
    _localArenaCtrl.dispose();
    _descricaoCtrl.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _bairroCtrl.dispose();
    _corPersonalizadoCtrl.dispose();
    _cepCtrl.dispose();
    _cepFocus.dispose();
    _nomeFocus.dispose();
    _organizadorFocus.dispose();
    _cpfFocus.dispose();
    _contatoFocus.dispose();
    _dataInicioFocus.dispose();
    _dataFimFocus.dispose();
    _horaInicioFocus.dispose();
    _horaFimFocus.dispose();
    _taxaFocus.dispose();
    _corPersonalizadoFocus.dispose();
    _cepCampoFocus.dispose();
    _ruaFocus.dispose();
    _numeroFocus.dispose();
    _localArenaFocus.dispose();
    _bairroFocus.dispose();
    _cidadeFocus.dispose();
    _estadoFocus.dispose();
    _cepDebounceTimer?.cancel();
    super.dispose();
  }

  void _formatarDatas() {
    _horaInicioCtrl.text = _fmtTime(_horaInicio);
    _horaFimCtrl.text = _fmtTime(_horaFim);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime _limiteDataFim() {
    final base = DateTime(_dataInicio.year, _dataInicio.month, _dataInicio.day);
    return base.add(const Duration(days: 60));
  }

  Future<void> _pickTime(bool inicio) async {
    final t = await showTimePicker(
      context: context,
      initialTime: inicio ? _horaInicio : _horaFim,
      builder: (ctx, w) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: w!,
      ),
    );
    if (t == null) return;
    setState(() {
      if (inicio) {
        _horaInicio = t;
      } else {
        _horaFim = t;
      }
      _formatarDatas();
    });
  }

  String? _validateRequired(String? v, {String msg = 'Campo obrigatório'}) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  String? _validateRequiredSemMensagem(String? v) {
    if (v == null || v.trim().isEmpty) {
      return '';
    }
    return null;
  }

  String? _validateCpfDadosPelada(String? v) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final resultado = auth.validateCpf(v);
    if (resultado == null) return null;
    if (resultado.toUpperCase().contains('OBRIGATÓRIO') ||
        resultado.toUpperCase().contains('OBRIGATORIO')) {
      return '';
    }
    return resultado;
  }

  String? _validateContatoDadosPelada(String? v) {
    final obrigatorio = _validateRequiredSemMensagem(v);
    if (obrigatorio != null) return obrigatorio;
    final auth = Provider.of<AuthService>(context, listen: false);
    return auth.validateTelefone(v);
  }

  String? _validateTaxa(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Informe a taxa ou use o botão GRÁTIS';
    }
    final texto = v.trim().toUpperCase();
    if (texto == 'GRÁTIS' || texto == 'GRATIS') {
      return null;
    }
    final valorNumerico = double.tryParse(v.replaceAll(',', '.'));
    if (valorNumerico == null) {
      return 'Valor inválido. Use número ou GRÁTIS';
    }
    if (valorNumerico < 0) {
      return 'A taxa não pode ser negativa';
    }
    return null;
  }

  void _onTapGratis() {
    unawaited(HapticFeedback.selectionClick());
    final current = _taxaCtrl.text.trim().toUpperCase();
    final isGratis = current == 'GRÁTIS' || current == 'GRATIS';
    if (isGratis) {
      _taxaCtrl.value = TextEditingValue(
        text: '0',
        selection: const TextSelection.collapsed(offset: 1),
      );
    } else {
      const valor = 'GRÁTIS';
      _taxaCtrl.value = TextEditingValue(
        text: valor,
        selection: TextSelection.collapsed(offset: valor.length),
      );
    }
    _formKey.currentState?.validate();
    setState(() {});
  }

  void _limparCamposEndereco() {
    if (!mounted) return;
    setState(() {
      _cepCtrl.text = '';
      _estadoCtrl.text = '';
      _cidadeCtrl.text = '';
      _bairroCtrl.text = '';
      _enderecoCtrl.text = '';
      _numeroCtrl.text = '';
      _cepErro = null;
    });
  }

  void _onCepChanged(String value) {
    _cepDebounceTimer?.cancel();
    setState(() {
      _cepErro = null;
    });
    final digitos = LocationService.apenasDigitos(value);
    if (digitos.length != 8) return;
    _cepDebounceTimer = Timer(const Duration(milliseconds: 450), () {
      _buscarCep(digitos);
    });
  }

  Future<void> _buscarCep(String digitos) async {
    if (!mounted) return;
    setState(() {
      _cepCarregando = true;
      _cepErro = null;
    });
    try {
      final resultado = await LocationService.consultarCep(digitos);
      if (!mounted) return;
      if (!resultado.sucesso) {
        setState(() {
          _cepErro = 'CEP não encontrado ou inválido';
        });
        return;
      }
      final r = resultado;
      setState(() {
        if (r.logradouro.trim().isNotEmpty &&
            _enderecoCtrl.text.trim().isEmpty) {
          _enderecoCtrl.text = r.logradouro.trim();
        }
        if (r.bairro.trim().isNotEmpty && _bairroCtrl.text.trim().isEmpty) {
          _bairroCtrl.text = r.bairro.trim();
        }
        if (r.cidade.trim().isNotEmpty && _cidadeCtrl.text.trim().isEmpty) {
          _cidadeCtrl.text = r.cidade.trim();
        }
        if (r.uf.trim().isNotEmpty &&
            AppConstants.estadosBrasil.contains(r.uf.trim()) &&
            _estadoCtrl.text.trim().isEmpty) {
          _estadoCtrl.text = r.uf.trim();
        }
      });
      if (r.cep.trim().isNotEmpty) {
        final digitosCep = LocationService.apenasDigitos(r.cep);
        if (digitosCep.length == 8) {
          final mascarado = MaskTextInputFormatter(
            mask: '##.###-###',
            filter: {'#': RegExp(r'[0-9]')},
          ).maskText(digitosCep);
          _cepCtrl.value = TextEditingValue(
            text: mascarado,
            selection: TextSelection.collapsed(offset: mascarado.length),
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          content: const Text('Endereço preenchido automaticamente'),
          duration: const Duration(seconds: 2),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _cepErro = 'Tempo limite. Verifique sua conexão e tente novamente.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cepErro = 'Falha ao consultar CEP. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _cepCarregando = false);
      }
    }
  }

  String _mimeFromExt(String ext) {
    return switch (ext.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }

  String _extFromName(String name) {
    final idx = name.lastIndexOf('.');
    if (idx == -1) return '';
    return name.substring(idx + 1).toLowerCase();
  }

  Future<PeladaCapaFoto?> _pickSingleFoto(String label) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return null;

      final ext = _extFromName(file.name);
      if (!_extPermitidas.contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label: Formato inválido. Use JPG, PNG ou WEBP.'),
          ),
        );
        return null;
      }

      final Uint8List bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxFotoBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label: Imagem muito grande. Limite: 5MB.')),
        );
        return null;
      }

      return PeladaCapaFoto.fromBytes(
        bytes: bytes,
        mimeType: _mimeFromExt(ext),
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar $label: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _adicionarFotoBraseao() async {
    final foto = await _pickSingleFoto('Brasão');
    if (foto == null || !mounted) return;
    setState(() => _fotoBraseao = foto);
  }

  Future<void> _adicionarFotoArena() async {
    final foto = await _pickSingleFoto('Arena');
    if (foto == null || !mounted) return;
    setState(() => _fotoArena = foto);
  }

  Future<void> _adicionarFotoGalera() async {
    final foto = await _pickSingleFoto('Galera');
    if (foto == null || !mounted) return;
    setState(() => _fotoGalera = foto);
  }

  void _removerFotoBraseao() => setState(() => _fotoBraseao = null);
  void _removerFotoArena() => setState(() => _fotoArena = null);
  void _removerFotoGalera() => setState(() => _fotoGalera = null);

  Future<void> _adicionarFotoCapa() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      final ext = _extFromName(file.name);
      if (!_extPermitidas.contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formato inválido. Use JPG, PNG ou WEBP.'),
          ),
        );
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxFotoBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem muito grande. Limite: 5MB.')),
        );
        return;
      }

      setState(() {
        _fotosCapa.add(
          PeladaCapaFoto.fromBytes(bytes: bytes, mimeType: _mimeFromExt(ext)),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar imagem: ${e.toString()}')),
      );
    }
  }

  void _removerFotoCapa(int index) {
    setState(() {
      _fotosCapa.removeAt(index);
    });
  }

  Future<bool> _validarCamposObrigatoriosComFoco() async {
    void showMsg(String msg) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.error,
          content: Text(
            msg,
            style: TextStyle(color: cs.onError, fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    Future<void> levarAte(GlobalKey k, FocusNode? f, String msg) async {
      showMsg(msg);
      try {
        final ctx = k.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            alignment: 0.12,
          );
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 340));
      if (mounted) {
        if (f != null) {
          FocusScope.of(context).requestFocus(f);
        } else {
          await focusRequiredWidget(k);
        }
      }
    }

    if (_nomeCtrl.text.trim().isEmpty) {
      await levarAte(_keyNome, _nomeFocus, 'Informe o nome da pelada.');
      return false;
    }
    if (_organizadorCtrl.text.trim().isEmpty) {
      await levarAte(
        _keyOrganizador,
        _organizadorFocus,
        'Informe o nome do organizador.',
      );
      return false;
    }
    final cpfLimpo = _cpfMask.unmaskText(_cpfCtrl.text);
    if (cpfLimpo.isEmpty) {
      await levarAte(_keyCpf, _cpfFocus, 'Informe o CPF do organizador.');
      return false;
    }
    if (_contatoCtrl.text.trim().isEmpty) {
      await levarAte(_keyContato, _contatoFocus, 'Informe o contato.');
      return false;
    }
    if (_dataInicioCtrl.text.trim().isEmpty) {
      await levarAte(
        _keyDataInicio,
        _dataInicioFocus,
        'Informe a data de início.',
      );
      return false;
    }
    if (_dataFimCtrl.text.trim().isEmpty) {
      await levarAte(_keyDataFim, _dataFimFocus, 'Informe a data de término.');
      return false;
    }
    if (_horaInicioCtrl.text.trim().isEmpty) {
      await levarAte(
        _keyHoraInicio,
        _horaInicioFocus,
        'Informe a hora de início.',
      );
      return false;
    }
    if (_horaFimCtrl.text.trim().isEmpty) {
      await levarAte(_keyHoraFim, _horaFimFocus, 'Informe a hora de término.');
      return false;
    }
    if (_validateTaxa(_taxaCtrl.text) != null) {
      await levarAte(
        _keyTaxa,
        _taxaFocus,
        _validateTaxa(_taxaCtrl.text) ??
            'Informe a taxa ou use o botão GRÁTIS.',
      );
      return false;
    }
    if (_modalidade.toString().isEmpty) {
      await levarAte(_keyModalidade, null, 'Selecione a modalidade.');
      return false;
    }
    if (_tipoGrama.toString().isEmpty) {
      await levarAte(_keyTipoGrama, null, 'Selecione o tipo de grama.');
      return false;
    }
    if (_tiposChuteira.isEmpty) {
      await levarAte(
        _keyTipoChuteira,
        null,
        'Selecione ao menos um tipo de chuteira permitida.',
      );
      return false;
    }
    if (_categoriaGenero.toString().isEmpty || _categoria.toString().isEmpty) {
      await levarAte(_keyCategoria, null, 'Selecione a categoria.');
      return false;
    }
    if (_coresColete.isEmpty) {
      await levarAte(
        _keyCorColete,
        null,
        'Selecione ao menos uma cor de colete.',
      );
      return false;
    }
    if (_coresColete.contains(10) &&
        _corPersonalizadoCtrl.text.trim().isEmpty) {
      await levarAte(
        _keyCorPersonalizada,
        _corPersonalizadoFocus,
        'Informe a cor personalizada do colete.',
      );
      return false;
    }
    if (_localArenaCtrl.text.trim().isEmpty) {
      await levarAte(
        _keyLocalArena,
        _localArenaFocus,
        'Informe o local ou arena da pelada.',
      );
      return false;
    }
    if (_estadoCtrl.text.trim().isEmpty) {
      await levarAte(_keyUf, _estadoFocus, 'Selecione o estado (UF).');
      return false;
    }
    if (_cidadeCtrl.text.trim().isEmpty) {
      await levarAte(_keyCidade, _cidadeFocus, 'Informe a cidade.');
      return false;
    }
    if (_bairroCtrl.text.trim().isEmpty) {
      await levarAte(_keyBairro, _bairroFocus, 'Informe o bairro.');
      return false;
    }
    if (_enderecoCtrl.text.trim().isEmpty) {
      await levarAte(_keyRua, _ruaFocus, 'Informe a rua ou avenida.');
      return false;
    }
    if (_status.toString().isEmpty) {
      await levarAte(_keyStatus, null, 'Selecione o status da pelada.');
      return false;
    }
    if (_recorrenciaDiasSemana.isEmpty) {
      await levarAte(
        _keyRecorrencia,
        null,
        'Selecione ao menos um dia da semana.',
      );
      return false;
    }
    return true;
  }

  void _showErrorSnack(String msg) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.error,
        content: Text(
          msg,
          style: TextStyle(color: cs.onError, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!validateAndFocusFirstError(_formKey)) return;
    final ok = await _validarCamposObrigatoriosComFoco();
    if (!ok) return;
    if (_coresColete.contains(10) &&
        _corPersonalizadoCtrl.text.trim().isEmpty) {
      _showErrorSnack('Informe a cor personalizada');
      return;
    }
    final limiteDataFim = _limiteDataFim();
    if (_dataFim.isAfter(limiteDataFim)) {
      _showErrorSnack(
        'A Data Fim não pode ultrapassar 90 dias consecutivos após a Data Inicial.',
      );
      return;
    }
    final auth = Provider.of<AuthService>(context, listen: false);
    final data = Provider.of<DataService>(context, listen: false);
    final user = auth.currentUser;
    final peladaEmEdicao = widget.isClone ? null : widget.pelada;
    final clonando = widget.isClone && widget.pelada != null;
    if (widget.pelada != null &&
        !clonando &&
        user?.id != widget.pelada!.organizadorId) {
      _showErrorSnack('Apenas o organizador pode editar');
      return;
    }

    final textoTaxa = _taxaCtrl.text.trim().toUpperCase();
    final bool isGratis = textoTaxa == 'GRÁTIS' || textoTaxa == 'GRATIS';
    final taxa = isGratis
        ? 0.0
        : (double.tryParse(_taxaCtrl.text.replaceAll(',', '.')) ?? 0.0);
    final quorum = int.tryParse(_quorumCtrl.text) ?? 10;
    final quorumMax = int.tryParse(_quorumMaxCtrl.text) ?? quorum;
    if (quorumMax < quorum) {
      _showErrorSnack('O quórum máximo não pode ser menor que o mínimo');
      return;
    }
    if (_tiposChuteira.isEmpty) {
      _showErrorSnack('Selecione ao menos um tipo de chuteira');
      return;
    }
    if (_coresColete.isEmpty) {
      _showErrorSnack('Selecione ao menos uma cor de colete');
      return;
    }
    final tipoChuteiraPrincipal = _tiposChuteira.first;
    final corColetePrincipal = _coresColete.first;

    Coordenadas? coords;
    final cepDigitado = LocationService.apenasDigitos(_cepCtrl.text);
    final enderecoParaGeo = _enderecoCtrl.text.trim();
    final numeroParaGeo = _numeroCtrl.text.trim();
    final localParaGeo = _localArenaCtrl.text.trim();
    final bairroParaGeo = _bairroCtrl.text.trim();
    final cidadeParaGeo = _cidadeCtrl.text.trim();
    final estadoParaGeo = _estadoCtrl.text.trim();
    String comporEnderecoParaSalvar() {
      final rua = _enderecoCtrl.text.trim();
      final num = _numeroCtrl.text.trim();
      if (num.isEmpty) return rua;
      if (rua.toLowerCase().endsWith(num.toLowerCase())) return rua;
      return '$rua, $num';
    }

    final enderecoSalvar = comporEnderecoParaSalvar();

    bool carregandoGeo =
        cepDigitado.length == 8 ||
        enderecoParaGeo.isNotEmpty ||
        localParaGeo.isNotEmpty;
    if (carregandoGeo && mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 14),
                Expanded(child: Text('Processando localização...')),
              ],
            ),
          ),
        ),
      );
      try {
        coords = await LocationService.geocodificarEndereco(
          endereco: enderecoParaGeo,
          numero: numeroParaGeo,
          bairro: bairroParaGeo,
          cidade: cidadeParaGeo,
          estado: estadoParaGeo,
          localArena: localParaGeo,
          cep: cepDigitado.length == 8 ? cepDigitado : null,
        ).timeout(const Duration(seconds: 14));
      } on TimeoutException {
        // ignora
      } catch (_) {
        // ignora, segue sem coordenadas
      } finally {
        if (mounted) Navigator.pop(context);
      }
    }

    final base = peladaEmEdicao;
    final cepSalvar = cepDigitado.length == 8 ? cepDigitado : null;
    final latitudeSalvar = coords?.latitude ?? base?.latitude;
    final longitudeSalvar = coords?.longitude ?? base?.longitude;
    final payload = base != null
        ? base.copyWith(
            nome: _nomeCtrl.text.trim(),
            organizadorNome: _organizadorCtrl.text.trim(),
            organizadorCpf: _cpfCtrl.text.trim().isEmpty
                ? null
                : _cpfCtrl.text.trim(),
            contato: _contatoCtrl.text.trim(),
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            recorrenciaDiasSemana: _recorrenciaDiasSemana.toList(),
            horaInicio: _horaInicio,
            horaFim: _horaFim,
            taxa: taxa,
            modalidade: _modalidade,
            tipoGrama: _tipoGrama,
            tipoChuteira: tipoChuteiraPrincipal,
            tiposChuteiraPermitidos: _tiposChuteira.toList(),
            categoria: _categoria,
            categoriaGenero: _categoriaGenero,
            beneficioGoleiro: _beneficioGoleiro,
            corColeteIndex: corColetePrincipal,
            coresColeteIndices: _coresColete.toList(),
            corColetePersonalizado: _coresColete.contains(10)
                ? _corPersonalizadoCtrl.text.trim()
                : null,
            endereco: enderecoSalvar,
            localArena: _localArenaCtrl.text.trim(),
            estado: _estadoCtrl.text.trim(),
            cidade: _cidadeCtrl.text.trim(),
            bairro: _bairroCtrl.text.trim(),
            cep: cepSalvar,
            latitude: latitudeSalvar,
            longitude: longitudeSalvar,
            status: _status,
            quorumMinimo: quorum,
            quorumMaximo: quorumMax,
            descricao: _descricaoCtrl.text.trim().isEmpty
                ? null
                : _descricaoCtrl.text.trim(),
            fotosCapa: List.of(_fotosCapa),
            fotoBraseao: _fotoBraseao,
            fotoArena: _fotoArena,
            fotoGalera: _fotoGalera,
            updatedAt: DateTime.now(),
            checklist: Map<String, bool>.from(_checklist),
          )
        : Pelada(
            id: '',
            nome: _nomeCtrl.text.trim(),
            organizadorId: user?.id ?? 'anon',
            organizadorNome: _organizadorCtrl.text.trim(),
            organizadorCpf: _cpfCtrl.text.trim().isEmpty
                ? null
                : _cpfCtrl.text.trim(),
            contato: _contatoCtrl.text.trim(),
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            recorrenciaDiasSemana: _recorrenciaDiasSemana.toList(),
            horaInicio: _horaInicio,
            horaFim: _horaFim,
            taxa: taxa,
            modalidade: _modalidade,
            tipoGrama: _tipoGrama,
            tipoChuteira: tipoChuteiraPrincipal,
            tiposChuteiraPermitidos: _tiposChuteira.toList(),
            categoria: _categoria,
            categoriaGenero: _categoriaGenero,
            beneficioGoleiro: _beneficioGoleiro,
            corColeteIndex: corColetePrincipal,
            coresColeteIndices: _coresColete.toList(),
            corColetePersonalizado: _coresColete.contains(10)
                ? _corPersonalizadoCtrl.text.trim()
                : null,
            endereco: enderecoSalvar,
            localArena: _localArenaCtrl.text.trim(),
            estado: _estadoCtrl.text.trim(),
            cidade: _cidadeCtrl.text.trim(),
            bairro: _bairroCtrl.text.trim(),
            cep: cepSalvar,
            latitude: coords?.latitude,
            longitude: coords?.longitude,
            status: _status,
            quorumMinimo: quorum,
            quorumMaximo: quorumMax,
            participantesConfirmados: 0,
            descricao: _descricaoCtrl.text.trim().isEmpty
                ? null
                : _descricaoCtrl.text.trim(),
            fotosCapa: List.of(_fotosCapa),
            fotoBraseao: _fotoBraseao,
            fotoArena: _fotoArena,
            fotoGalera: _fotoGalera,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            checklist: Map<String, bool>.from(_checklist),
          );

    final bool temRecorrencia =
        _recorrenciaDiasSemana.isNotEmpty && base == null;
    final res = temRecorrencia
        ? await data.cadastrarPeladasRecorrentes(payload)
        : (base != null
              ? await data.atualizarPelada(payload)
              : await data.cadastrarPelada(payload));
    if (!mounted) return;
    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res is Pelada && data.peladaSalvaSomenteNesteDispositivo(res.id)
                ? 'Sessão demonstrativa: evento salvo neste dispositivo. Use uma conta autenticada para salvar na nuvem.'
                : temRecorrencia
                ? 'Pelada cadastrada! ${res is int ? '$res sessões geradas.' : ''}'
                : (base != null
                      ? 'Pelada atualizada com sucesso!'
                      : 'Pelada cadastrada com sucesso!'),
          ),
        ),
      );
      final latSalvaFinal = (res is Pelada) ? res.latitude : latitudeSalvar;
      final lonSalvaFinal = (res is Pelada) ? res.longitude : longitudeSalvar;
      if (latSalvaFinal == null || lonSalvaFinal == null) {
        if (res is Pelada && res.id.trim().isNotEmpty) {
          Future<void>(() async {
            try {
              final novasCoords = await LocationService.geocodificarEndereco(
                endereco: enderecoParaGeo,
                numero: numeroParaGeo,
                bairro: bairroParaGeo,
                cidade: cidadeParaGeo,
                estado: estadoParaGeo,
                localArena: localParaGeo,
                cep: cepDigitado.length == 8 ? cepDigitado : null,
              ).timeout(const Duration(seconds: 18));
              if (novasCoords == null) return;
              final atualizada = res.copyWith(
                latitude: novasCoords.latitude,
                longitude: novasCoords.longitude,
                updatedAt: DateTime.now(),
              );
              await data.atualizarPelada(atualizada);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[CadastroPelada] retry geo background falhou: $e');
              }
            }
          });
        }
      }
      Navigator.pop(context);
    } else {
      _showErrorSnack(data.errorMessage ?? 'Erro ao cadastrar');
    }
  }

  Future<void> _mostrarAvisoCategoriaMenor() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.family_restroom_outlined),
        title: const Text('Atenção'),
        content: const Text(
          'Peça ajuda a seu responsável para organizar ou participar dos eventos que envolvam menores de 18 anos!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isEdicao = widget.pelada != null && !widget.isClone;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Pelada' : 'Cadastre sua Pelada'),
        actions: [
          Semantics(
            button: true,
            label: isEdicao ? 'Salvar alterações da pelada' : 'Publicar pelada',
            hint: 'Toque duas vezes para salvar e publicar',
            child: Tooltip(
              message: isEdicao ? 'Salvar' : 'Publicar',
              preferBelow: false,
              child: IconButton(
                onPressed: auth.isLoading ? null : _salvar,
                icon: Icon(
                  Icons.check_circle_outline_rounded,
                  color: auth.isLoading
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.white,
                  size: 26,
                ),
                style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary.withAlphaSafe(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primary.withAlphaSafe(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Preencha os dados abaixo para publicar sua pelada e alcançar mais jogadores.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Dados da Pelada', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _keyNome,
                    child: TextFormField(
                      controller: _nomeCtrl,
                      focusNode: _nomeFocus,
                      inputFormatters: [UpperCaseInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Nome da Pelada *',
                        prefixIcon: Icon(Icons.sports_soccer_outlined),
                        hintText: 'Ex: Pelada do Bairro',
                      ),
                      validator: _validateRequiredSemMensagem,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: KeyedSubtree(
                          key: _keyOrganizador,
                          child: TextFormField(
                            controller: _organizadorCtrl,
                            focusNode: _organizadorFocus,
                            decoration: const InputDecoration(
                              labelText: 'Organizador *',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: _validateRequiredSemMensagem,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KeyedSubtree(
                          key: _keyCpf,
                          child: TextFormField(
                            controller: _cpfCtrl,
                            focusNode: _cpfFocus,
                            inputFormatters: [_cpfMask],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'CPF *',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: Icon(Icons.badge_outlined),
                              hintText: '000.000.000-00',
                            ),
                            validator: _validateCpfDadosPelada,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _keyContato,
                    child: TextFormField(
                      controller: _contatoCtrl,
                      focusNode: _contatoFocus,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_phoneMask],
                      decoration: const InputDecoration(
                        labelText: 'Contato *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '(00) 00000-0000',
                      ),
                      validator: _validateContatoDadosPelada,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Data e Hora', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: KeyedSubtree(
                          key: _keyDataInicio,
                          child: DateInputField(
                            controller: _dataInicioCtrl,
                            focusNode: _dataInicioFocus,
                            value: _dataInicio,
                            labelText: 'Data Início *',
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 2),
                            ),
                            onChanged: (d) {
                              if (d == null) return;
                              setState(() {
                                _dataInicio = d;
                                final limite = _limiteDataFim();
                                if (_dataFim.isBefore(d)) {
                                  _dataFim = d;
                                } else if (_dataFim.isAfter(limite)) {
                                  _dataFim = limite;
                                }
                              });
                            },
                            validator: (d) {
                              if (d == null) return 'Campo obrigatório';
                              return null;
                            },
                            format: DateFormat('yyyy-MM-dd'),
                            decoration: const InputDecoration(),
                            dateLabel: 'Data Início',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KeyedSubtree(
                          key: _keyDataFim,
                          child: DateInputField(
                            controller: _dataFimCtrl,
                            focusNode: _dataFimFocus,
                            value: _dataFim,
                            labelText: 'Data Fim *',
                            firstDate: _dataInicio,
                            lastDate: _limiteDataFim(),
                            onChanged: (d) {
                              if (d == null) return;
                              setState(() => _dataFim = d);
                            },
                            validator: (d) {
                              if (d == null) return 'Campo obrigatório';
                              return null;
                            },
                            format: DateFormat('yyyy-MM-dd'),
                            decoration: const InputDecoration(),
                            dateLabel: 'Data Fim',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: KeyedSubtree(
                          key: _keyHoraInicio,
                          child: TextFormField(
                            controller: _horaInicioCtrl,
                            focusNode: _horaInicioFocus,
                            readOnly: true,
                            onTap: () => _pickTime(true),
                            decoration: const InputDecoration(
                              labelText: 'Hora Início *',
                              prefixIcon: Icon(Icons.access_time_outlined),
                            ),
                            validator: _validateRequired,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KeyedSubtree(
                          key: _keyHoraFim,
                          child: TextFormField(
                            controller: _horaFimCtrl,
                            focusNode: _horaFimFocus,
                            readOnly: true,
                            onTap: () => _pickTime(false),
                            decoration: const InputDecoration(
                              labelText: 'Hora Fim *',
                              prefixIcon: Icon(Icons.schedule_outlined),
                            ),
                            validator: _validateRequired,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _keyRecorrencia,
                    child: FormField<Set<int>>(
                      initialValue: _recorrenciaDiasSemana,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Selecione ao menos um dia da semana'
                          : null,
                      builder: (state) {
                        const todosDias = <int>{1, 2, 3, 4, 5, 6, 7};
                        final todosMarcados = _recorrenciaDiasSemana
                            .containsAll(todosDias);
                        final qtd = _recorrenciaDiasSemana.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Repetir nos dias da semana',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '*',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (final d in const [
                                  (1, 'Seg'),
                                  (2, 'Ter'),
                                  (3, 'Qua'),
                                  (4, 'Qui'),
                                  (5, 'Sex'),
                                  (6, 'Sáb'),
                                  (7, 'Dom'),
                                ])
                                  InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      setState(() {
                                        final v = d.$1;
                                        if (_recorrenciaDiasSemana.contains(
                                          v,
                                        )) {
                                          _recorrenciaDiasSemana.remove(v);
                                        } else {
                                          _recorrenciaDiasSemana.add(v);
                                        }
                                        state.didChange(_recorrenciaDiasSemana);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color:
                                              _recorrenciaDiasSemana.contains(
                                                d.$1,
                                              )
                                              ? theme.colorScheme.primary
                                              : state.hasError
                                              ? theme.colorScheme.error
                                                    .withAlphaSafe(alpha: 0.55)
                                              : theme.dividerColor
                                                    .withAlphaSafe(alpha: 0.6),
                                          width:
                                              _recorrenciaDiasSemana.contains(
                                                d.$1,
                                              )
                                              ? 1.4
                                              : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: _recorrenciaDiasSemana
                                                .contains(d.$1),
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  _recorrenciaDiasSemana.add(
                                                    d.$1,
                                                  );
                                                } else {
                                                  _recorrenciaDiasSemana.remove(
                                                    d.$1,
                                                  );
                                                }
                                                state.didChange(
                                                  _recorrenciaDiasSemana,
                                                );
                                              });
                                            },
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          Text(d.$2),
                                        ],
                                      ),
                                    ),
                                  ),
                                Semantics(
                                  label: todosMarcados
                                      ? 'Desmarcar todos os dias da semana'
                                      : 'Selecionar todos os dias da semana',
                                  button: true,
                                  toggled: todosMarcados,
                                  value: '$qtd de 7 dias selecionados',
                                  child: Tooltip(
                                    message: todosMarcados
                                        ? 'Desmarcar todos os dias'
                                        : 'Selecionar todos os dias',
                                    preferBelow: false,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          if (todosMarcados) {
                                            _recorrenciaDiasSemana.clear();
                                          } else {
                                            _recorrenciaDiasSemana.addAll(
                                              todosDias,
                                            );
                                          }
                                          state.didChange(
                                            _recorrenciaDiasSemana,
                                          );
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        curve: Curves.easeOut,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: todosMarcados
                                              ? theme.colorScheme.primary
                                                    .withAlphaSafe(alpha: 0.14)
                                              : theme
                                                    .colorScheme
                                                    .primaryContainer
                                                    .withAlphaSafe(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: todosMarcados
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.primary
                                                      .withAlphaSafe(
                                                        alpha: 0.35,
                                                      ),
                                            width: todosMarcados ? 1.6 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              todosMarcados
                                                  ? Icons.check_box_outlined
                                                  : Icons
                                                        .check_box_outline_blank_outlined,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'TODOS',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: todosMarcados
                                                    ? FontWeight.w800
                                                    : FontWeight.w700,
                                                letterSpacing: 0.4,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withAlphaSafe(alpha: 0.10),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$qtd/7',
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                                child: Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Taxa, Modalidade e Campo',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 600;
                      final bool isGratisSelected =
                          _taxaCtrl.text.trim().toUpperCase() == 'GRÁTIS' ||
                          _taxaCtrl.text.trim().toUpperCase() == 'GRATIS';

                      final gratisButton = Semantics(
                        button: true,
                        label: isGratisSelected
                            ? 'Desativar taxa grátis'
                            : 'Definir taxa como grátis',
                        hint: 'Toque duas vezes para marcar como grátis',
                        toggled: isGratisSelected,
                        child: Tooltip(
                          message: isGratisSelected
                              ? 'Desativar GRÁTIS'
                              : 'Marcar como GRÁTIS',
                          preferBelow: false,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.zero,
                              onTap: _onTapGratis,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: isGratisSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primaryContainer
                                            .withAlphaSafe(alpha: 0.35),
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(
                                    color: isGratisSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.primary
                                              .withAlphaSafe(alpha: 0.45),
                                    width: isGratisSelected ? 1.8 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGratisSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.card_giftcard_outlined,
                                      size: 18,
                                      color: isGratisSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'GRÁTIS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: isGratisSelected
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.primary,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      final taxaField = KeyedSubtree(
                        key: _keyTaxa,
                        child: TextFormField(
                          controller: _taxaCtrl,
                          focusNode: _taxaFocus,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: isGratisSelected
                              ? TextInputType.text
                              : const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                          decoration: InputDecoration(
                            labelText: 'Taxa * (R\$)',
                            prefixIcon: Icon(
                              isGratisSelected
                                  ? Icons.card_giftcard_rounded
                                  : Icons.attach_money_outlined,
                            ),
                            hintText: isGratisSelected ? 'GRÁTIS' : '0,00',
                            errorMaxLines: 2,
                          ),
                          validator: _validateTaxa,
                        ),
                      );

                      final taxaRow = IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: taxaField),
                            const SizedBox(width: 12),
                            gratisButton,
                          ],
                        ),
                      );

                      final quorumMinField = TextFormField(
                        controller: _quorumCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quórum Mínimo',
                          prefixIcon: Icon(Icons.group),
                          hintText: '10',
                        ),
                      );
                      final quorumMaxField = TextFormField(
                        controller: _quorumMaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quórum Máximo',
                          prefixIcon: Icon(Icons.groups_outlined),
                          hintText: '10',
                        ),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            taxaRow,
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: quorumMinField),
                                const SizedBox(width: 12),
                                Expanded(child: quorumMaxField),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: taxaRow),
                          const SizedBox(width: 12),
                          Expanded(child: quorumMinField),
                          const SizedBox(width: 12),
                          Expanded(child: quorumMaxField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _keyModalidade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _selecaoLabel('Modalidade *'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: Modalidade.values
                              .map(
                                (m) => ChoiceChip(
                                  label: Text(m.label),
                                  selected: _modalidade == m,
                                  onSelected: (_) =>
                                      setState(() => _modalidade = m),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _keyTipoGrama,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _selecaoLabel('Tipo de Grama *'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: TipoGrama.values
                              .map(
                                (m) => ChoiceChip(
                                  label: Text(m.label),
                                  selected: _tipoGrama == m,
                                  onSelected: (_) =>
                                      setState(() => _tipoGrama = m),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _keyTipoChuteira,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _selecaoLabel('Tipo de Chuteira *'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: TipoChuteira.values
                              .map(
                                (m) => FilterChip(
                                  label: Text(m.label),
                                  selected: _tiposChuteira.contains(m),
                                  onSelected: (sel) => setState(() {
                                    final next = Set<TipoChuteira>.from(
                                      _tiposChuteira,
                                    );
                                    if (sel) {
                                      next.add(m);
                                    } else {
                                      next.remove(m);
                                    }
                                    _tiposChuteira = next;
                                  }),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _keyCategoria,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormField<CategoriaGenero>(
                          initialValue: _categoriaGenero,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) =>
                              v == null ? 'Selecione a Categoria' : null,
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _selecaoLabel('Categoria *'),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: CategoriaGenero.values.map((g) {
                                    final sel = _categoriaGenero == g;
                                    final feminino = g == CategoriaGenero.fem;
                                    final corSelecionada = feminino
                                        ? theme.colorScheme.error
                                        : AppColors.success;
                                    final label = 'Categoria ${g.label}';
                                    return Semantics(
                                      label: label,
                                      button: true,
                                      selected: sel,
                                      child: ActionChip(
                                        tooltip: label,
                                        avatar: Icon(
                                          feminino ? Icons.female : Icons.male,
                                          size: 16,
                                          color: sel
                                              ? Colors.white
                                              : corSelecionada,
                                        ),
                                        label: Text(
                                          g.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: sel
                                                ? Colors.white
                                                : corSelecionada,
                                            fontSize: 13,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        backgroundColor: sel
                                            ? corSelecionada
                                            : corSelecionada.withAlphaSafe(
                                                alpha: 0.10,
                                              ),
                                        side: BorderSide(
                                          color: sel
                                              ? corSelecionada
                                              : corSelecionada.withAlphaSafe(
                                                  alpha: 0.55,
                                                ),
                                          width: sel ? 1.8 : 1,
                                        ),
                                        onPressed: () {
                                          unawaited(
                                            HapticFeedback.selectionClick(),
                                          );
                                          setState(() => _categoriaGenero = g);
                                          state.didChange(g);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      2,
                                      6,
                                      2,
                                      0,
                                    ),
                                    child: Text(
                                      state.errorText!,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _selecaoLabel('Sub-Categoria *'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: CategoriaPelada.values
                              .map(
                                (m) => ChoiceChip(
                                  label: Text(m.label),
                                  selected: _categoria == m,
                                  onSelected: (selected) {
                                    if (!selected) return;
                                    setState(() => _categoria = m);
                                    if (m == CategoriaPelada.sub10 ||
                                        m == CategoriaPelada.sub13 ||
                                        m == CategoriaPelada.sub15) {
                                      unawaited(_mostrarAvisoCategoriaMenor());
                                    }
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Benefícios para Goleiros',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(opcional)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Semantics(
                        label: 'Benefícios para Goleiro: SIM',
                        button: true,
                        selected: _beneficioGoleiro == true,
                        child: ActionChip(
                          tooltip: 'Possui benefício para goleiro',
                          avatar: Icon(
                            Icons.sports_handball_outlined,
                            size: 16,
                            color: _beneficioGoleiro == true
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                          label: Text(
                            'SIM',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _beneficioGoleiro == true
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              fontSize: 13,
                              letterSpacing: 0.4,
                            ),
                          ),
                          backgroundColor: _beneficioGoleiro == true
                              ? AppColors.success
                              : AppColors.success.withAlphaSafe(alpha: 0.10),
                          side: BorderSide(
                            color: _beneficioGoleiro == true
                                ? AppColors.success
                                : AppColors.success.withAlphaSafe(alpha: 0.55),
                            width: _beneficioGoleiro == true ? 1.8 : 1,
                          ),
                          onPressed: () {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() {
                              _beneficioGoleiro = _beneficioGoleiro == true
                                  ? null
                                  : true;
                            });
                          },
                        ),
                      ),
                      Semantics(
                        label: 'Benefícios para Goleiro: NÃO',
                        button: true,
                        selected: _beneficioGoleiro == false,
                        child: ActionChip(
                          tooltip: 'Não possui benefício para goleiro',
                          avatar: Icon(
                            Icons.block_outlined,
                            size: 16,
                            color: _beneficioGoleiro == false
                                ? Colors.white
                                : theme.colorScheme.error,
                          ),
                          label: Text(
                            'NÃO',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _beneficioGoleiro == false
                                  ? Colors.white
                                  : theme.colorScheme.error,
                              fontSize: 13,
                              letterSpacing: 0.4,
                            ),
                          ),
                          backgroundColor: _beneficioGoleiro == false
                              ? theme.colorScheme.error
                              : theme.colorScheme.error.withAlphaSafe(
                                  alpha: 0.10,
                                ),
                          side: BorderSide(
                            color: _beneficioGoleiro == false
                                ? theme.colorScheme.error
                                : theme.colorScheme.error.withAlphaSafe(
                                    alpha: 0.55,
                                  ),
                            width: _beneficioGoleiro == false ? 1.8 : 1,
                          ),
                          onPressed: () {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() {
                              _beneficioGoleiro = _beneficioGoleiro == false
                                  ? null
                                  : false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_beneficioGoleiro != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            _beneficioGoleiro == true
                                ? Icons.check_circle_outline_rounded
                                : Icons.info_outline_rounded,
                            size: 14,
                            color: _beneficioGoleiro == true
                                ? AppColors.success
                                : theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _beneficioGoleiro == true
                                ? 'Goleiros terão benefício (ex: taxa gratuita, prioridade, brindes). Esta informação será exibida publicamente no card da pelada.'
                                : 'Não há benefício especial para goleiros nesta pelada.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  KeyedSubtree(
                    key: _keyCorColete,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cor do Colete',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            AppColors.vestColorNames.length,
                            (i) {
                              final isSelected = _coresColete.contains(i);
                              if (i >= AppColors.vestColors.length) {
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    final next = Set<int>.from(_coresColete);
                                    if (isSelected) {
                                      next.remove(i);
                                    } else {
                                      next.add(i);
                                    }
                                    _coresColete = next;
                                  }),
                                  child: Container(
                                    height: 52,
                                    constraints: const BoxConstraints(
                                      minWidth: 100,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primary.withAlphaSafe(alpha: 0.12)
                                          : theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? primary
                                            : theme.dividerColor,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      AppColors.vestColorNames[i],
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected ? primary : null,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return GestureDetector(
                                onTap: () => setState(() {
                                  final next = Set<int>.from(_coresColete);
                                  if (isSelected) {
                                    next.remove(i);
                                  } else {
                                    next.add(i);
                                  }
                                  _coresColete = next;
                                }),
                                child: Tooltip(
                                  message: AppColors.vestColorNames[i],
                                  child: Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.vestColors[i],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? primary
                                            : Colors.black12,
                                        width: isSelected ? 3 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: primary.withAlphaSafe(
                                                  alpha: 0.35,
                                                ),
                                                blurRadius: 6,
                                                spreadRadius: 1.5,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: i == 5
                                                ? AppColors.graphite1
                                                : Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_coresColete.contains(10)) ...[
                          const SizedBox(height: 10),
                          KeyedSubtree(
                            key: _keyCorPersonalizada,
                            child: TextFormField(
                              controller: _corPersonalizadoCtrl,
                              focusNode: _corPersonalizadoFocus,
                              decoration: const InputDecoration(
                                labelText: 'Descreva a cor personalizada',
                                hintText: 'Ex: Listras azuis e amarelas',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  KeyedSubtree(
                    key: _keyEnderecoLocal,
                    child: Text(
                      'Endereço e Localização',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _keyLocalArena,
                    child: TextFormField(
                      controller: _localArenaCtrl,
                      focusNode: _localArenaFocus,
                      inputFormatters: [UpperCaseInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Local / Arena *',
                        prefixIcon: Icon(Icons.sports_soccer_outlined),
                        hintText: 'Ex: Arena Center, Quadra dos Amigos',
                      ),
                      maxLength: 30,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o local ou arena';
                        }
                        final value = v.trim();
                        if (value.length > 30) {
                          return 'Limite de 30 caracteres';
                        }
                        if (!RegExp(
                          r'^[a-zA-Z0-9À-ÿ\s\-.,&()!?:;]+$',
                        ).hasMatch(value)) {
                          return 'Use apenas letras, números e pontuação comum';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cepCtrl,
                          focusNode: _cepFocus,
                          onChanged: _onCepChanged,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _cepMask,
                          ],
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'CEP',
                            hintText: '00.000-000',
                            prefixIcon: const Icon(
                              Icons.local_post_office_outlined,
                            ),
                            suffixIcon: _cepCarregando
                                ? Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                  )
                                : (_cepErro != null
                                      ? Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Icon(
                                            Icons.error_outline,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            semanticLabel:
                                                'Erro na consulta do CEP',
                                          ),
                                        )
                                      : null),
                            helperText: _cepCarregando
                                ? 'Consultando CEP...'
                                : (_cepErro != null
                                      ? null
                                      : 'Opcional. Preenche o endereço automaticamente.'),
                            helperStyle: _cepCarregando
                                ? TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  )
                                : null,
                            errorText: _cepErro,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final digitos = LocationService.apenasDigitos(v);
                            if (digitos.isNotEmpty && digitos.length != 8) {
                              return 'Informe os 8 dígitos do CEP';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        label: 'Limpar CEP e endereço',
                        button: true,
                        child: Tooltip(
                          message: 'Limpar CEP e endereço',
                          preferBelow: false,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: FilledButton.tonalIcon(
                              onPressed: _cepCarregando
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      _limparCamposEndereco();
                                    },
                              icon: const Icon(Icons.clear_all_outlined),
                              label: const Text('Limpar'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 520;
                      final ufField = KeyedSubtree(
                        key: _keyUf,
                        child: EstadoUfDropdown(
                          controller: _estadoCtrl,
                          cidadeController: _cidadeCtrl,
                          label: 'UF *',
                          focusNode: _estadoFocus,
                          onChanged: (_) => setState(() {}),
                          validator: _validateRequired,
                        ),
                      );
                      final cidadeField = KeyedSubtree(
                        key: _keyCidade,
                        child: CidadeMunicipioAutocompleteField(
                          uf: _estadoCtrl.text,
                          controller: _cidadeCtrl,
                          label: 'Cidade *',
                          focusNode: _cidadeFocus,
                          validator: _validateRequired,
                        ),
                      );
                      if (compact) {
                        return Column(
                          children: [
                            ufField,
                            const SizedBox(height: 12),
                            cidadeField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          SizedBox(width: 140, child: ufField),
                          const SizedBox(width: 12),
                          Expanded(child: cidadeField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _keyBairro,
                    child: TextFormField(
                      controller: _bairroCtrl,
                      focusNode: _bairroFocus,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'Bairro *',
                        prefixIcon: Icon(Icons.place_outlined),
                        hintText: 'Ex: Jardins',
                        semanticCounterText: 'Campo obrigatório',
                      ),
                      maxLines: 1,
                      validator: (v) =>
                          _validateRequired(v, msg: 'Informe o bairro'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 500;
                      final ruaField = KeyedSubtree(
                        key: _keyRua,
                        child: TextFormField(
                          controller: _enderecoCtrl,
                          focusNode: _ruaFocus,
                          decoration: const InputDecoration(
                            labelText: 'Rua / Av. *',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            hintText: 'Ex: Av. Paulista',
                          ),
                          validator: _validateRequired,
                          maxLines: compact ? 2 : 1,
                          textInputAction: TextInputAction.next,
                        ),
                      );
                      final numeroField = TextFormField(
                        controller: _numeroCtrl,
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Número',
                          prefixIcon: Icon(Icons.tag_outlined),
                          hintText: 'Ex: 100A, S/N',
                          counterText: '',
                        ),
                        maxLength: 10,
                        textInputAction: TextInputAction.next,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final val = v.trim();
                          if (val.length > 10) {
                            return 'Até 10 caracteres';
                          }
                          if (!RegExp(
                            r'^[A-Za-z0-9À-ÿ\s\-./º°NnSs]+$',
                          ).hasMatch(val)) {
                            return 'Apenas letras/num. (S/N, 100A)';
                          }
                          return null;
                        },
                      );
                      if (compact) {
                        return Column(
                          children: [
                            ruaField,
                            const SizedBox(height: 12),
                            numeroField,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: ruaField),
                          const SizedBox(width: 12),
                          SizedBox(width: 160, child: numeroField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Fotos da Pelada (Brasão, Arena e Galera)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const double gap = 12;
                      const double minPorCard = 104;
                      final larguraTotal = constraints.maxWidth;
                      final larguraTres = (larguraTotal - gap * 2) / 3;
                      final bool tresPorLinha = larguraTres >= minPorCard;
                      if (!tresPorLinha) {
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            SizedBox(
                              width: (larguraTotal - gap) / 2,
                              child: _fotoUploadCard(
                                context,
                                label: 'Brasão',
                                icon: Icons.shield_outlined,
                                foto: _fotoBraseao,
                                onPick: _adicionarFotoBraseao,
                                onRemove: _removerFotoBraseao,
                              ),
                            ),
                            SizedBox(
                              width: (larguraTotal - gap) / 2,
                              child: _fotoUploadCard(
                                context,
                                label: 'Arena',
                                icon: Icons.sports_soccer,
                                foto: _fotoArena,
                                onPick: _adicionarFotoArena,
                                onRemove: _removerFotoArena,
                              ),
                            ),
                            SizedBox(
                              width: (larguraTotal - gap) / 2,
                              child: _fotoUploadCard(
                                context,
                                label: 'Galera',
                                icon: Icons.group_outlined,
                                foto: _fotoGalera,
                                onPick: _adicionarFotoGalera,
                                onRemove: _removerFotoGalera,
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _fotoUploadCard(
                              context,
                              label: 'Brasão',
                              icon: Icons.shield_outlined,
                              foto: _fotoBraseao,
                              onPick: _adicionarFotoBraseao,
                              onRemove: _removerFotoBraseao,
                            ),
                          ),
                          const SizedBox(width: gap),
                          Expanded(
                            child: _fotoUploadCard(
                              context,
                              label: 'Arena',
                              icon: Icons.sports_soccer,
                              foto: _fotoArena,
                              onPick: _adicionarFotoArena,
                              onRemove: _removerFotoArena,
                            ),
                          ),
                          const SizedBox(width: gap),
                          Expanded(
                            child: _fotoUploadCard(
                              context,
                              label: 'Galera',
                              icon: Icons.group_outlined,
                              foto: _fotoGalera,
                              onPick: _adicionarFotoGalera,
                              onRemove: _removerFotoGalera,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  ChecklistCard(
                    checklist: _checklist,
                    editable: true,
                    onChanged: (next) {
                      setState(() {
                        _checklist = next;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  KeyedSubtree(
                    key: _keyStatus,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status da Pelada',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: StatusPelada.values
                              .map(
                                (s) => ChoiceChip(
                                  label: Text(s.label),
                                  selected: _status == s,
                                  onSelected: (_) =>
                                      setState(() => _status = s),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descricaoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      prefixIcon: Icon(Icons.description_outlined),
                      hintText: 'Mais detalhes sobre a pelada...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(51.2),
                            padding: EdgeInsets.zero,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: auth.isLoading ? null : _salvar,
                          icon: const Icon(Icons.publish_outlined),
                          label: const Text('Publicar | Salvar'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(51.2),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (auth.isLoading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _selecaoLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );

  Widget _fotoUploadCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required PeladaCapaFoto? foto,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Semantics(
      label: 'Foto de $label',
      button: true,
      child: Tooltip(
        message: foto == null
            ? 'Adicionar foto de $label'
            : 'Foto de $label cadastrada',
        preferBelow: false,
        child: SizedBox(
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 11 / 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InkWell(
                        onTap: onPick,
                        borderRadius: BorderRadius.circular(14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: foto == null
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: primary.withAlphaSafe(alpha: 0.35),
                                    ),
                                    color: primary.withAlphaSafe(alpha: 0.05),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(icon, color: primary, size: 26),
                                      const SizedBox(height: 4),
                                      Text(
                                        label,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(foto.bytes, fit: BoxFit.cover),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withAlphaSafe(
                                              alpha: 0.55,
                                            ),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      alignment: Alignment.topLeft,
                                      padding: const EdgeInsets.all(6),
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (foto != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(28, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            iconSize: 14,
                            onPressed: onRemove,
                            icon: const Icon(Icons.close),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InvalidType {}
