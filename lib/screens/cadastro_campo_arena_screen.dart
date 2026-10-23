import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:peladeiros_sa/screens/campos_arenas_screen.dart'
    show CamposArenasScreen;
import 'package:peladeiros_sa/utils/form_focus_helper.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/campo_arena.dart';
import '../models/enums.dart';
import '../models/pelada.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/location_service.dart';
import '../utils/title_case_input_formatter.dart';
import '../widgets/estado_cidade_fields.dart';
import '../widgets/horarios_disponiveis_table.dart';

class CadastroCampoArenaScreen extends StatefulWidget {
  final CampoArena? campoArena;
  const CadastroCampoArenaScreen({super.key, this.campoArena});

  @override
  State<CadastroCampoArenaScreen> createState() =>
      _CadastroCampoArenaScreenState();
}

class _CadastroCampoArenaScreenState extends State<CadastroCampoArenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keyQtdPorLinha = GlobalKey();
  final _keyCalcadosPermitidos = GlobalKey();
  final _nomeCtrl = TextEditingController();
  final _responsavelCtrl = TextEditingController();
  final _contatoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _cepFocus = FocusNode();
  final _estadoCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _larguraCtrl = TextEditingController();
  final _profundidadeCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _capacidadePublicoCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _cepCarregando = false;
  String? _cepErro;
  Timer? _cepDebounceTimer;

  int? _qtdPorLinha;
  TipoGrama _tipoGrama = TipoGrama.sintetica;
  Set<TipoChuteira> _calcadosPermitidos = <TipoChuteira>{};
  Set<DependenciaCampo> _dependencias = <DependenciaCampo>{};
  Set<ItemOpcionalCampo> _itensOpcionais = <ItemOpcionalCampo>{};
  Set<ItemOpcionalCampo> _opcionaisConsultarTaxas = <ItemOpcionalCampo>{};
  final List<PeladaCapaFoto> _fotosCampo = [];
  final Set<String> _horariosDisponiveis = {};
  int? _fotoCapaIndex;

  bool _salvando = false;

  static const Set<String> _extPermitidas = {'png', 'jpg', 'jpeg', 'webp'};
  static const int _maxFotosCampo = 3;
  static const int _maxFotoBytes = 5 * 1024 * 1024;

  double? get _areaCalculada {
    final l = _parseDouble(_larguraCtrl.text);
    final p = _parseDouble(_profundidadeCtrl.text);
    if (l == null || p == null || l <= 0 || p <= 0) return null;
    return l * p;
  }

  static double? _parseDouble(String v) {
    final s = v.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  static const List<int> _opcoesLinha = [3, 4, 5, 6, 7, 8, 9, 10];
  static const List<TipoGrama> _opcoesGrama = [
    TipoGrama.natural,
    TipoGrama.sintetica,
    TipoGrama.areia,
    TipoGrama.quadra,
    TipoGrama.picheAsfalto,
    TipoGrama.cimento,
    TipoGrama.outra,
  ];

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
    _larguraCtrl.addListener(_onMedidaChanged);
    _profundidadeCtrl.addListener(_onMedidaChanged);
    _cepFocus.addListener(() {
      if (_cepFocus.hasFocus) {
        final atual = LocationService.apenasDigitos(_cepCtrl.text);
        if (atual.isEmpty) _limparEndereco();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      final existente = widget.campoArena;
      if (existente != null) {
        _nomeCtrl.text = existente.nome.toUpperCase();
        _responsavelCtrl.text = existente.responsavelNome;
        _contatoCtrl.text = _formatarTelefone(existente.contato);
        _cepCtrl.text = existente.cep ?? '';
        _estadoCtrl.text = existente.estado;
        _cidadeCtrl.text = existente.cidade;
        _bairroCtrl.text = existente.bairro;
        _ruaCtrl.text = existente.rua;
        _numeroCtrl.text = existente.numero;
        _qtdPorLinha = existente.quantidadePorLinha;
        _tipoGrama = existente.tipoGrama;
        _capacidadePublicoCtrl.text =
            existente.capacidadePublico?.toString() ?? '';
        _calcadosPermitidos = {...existente.calcadosPermitidos};
        _dependencias = {...existente.dependencias};
        _itensOpcionais = {...existente.itensOpcionais};
        _opcionaisConsultarTaxas = {...existente.opcionaisConsultarTaxas};
        _fotosCampo.addAll(existente.fotos);
        _horariosDisponiveis.addAll(existente.horariosDisponiveis);
        _fotoCapaIndex = existente.fotoCapaIndex;
        if (existente.larguraMetros != null) {
          _larguraCtrl.text = existente.larguraMetros.toString();
        }
        if (existente.profundidadeMetros != null) {
          _profundidadeCtrl.text = existente.profundidadeMetros.toString();
        }
        _onMedidaChanged();
      } else if (user != null) {
        _responsavelCtrl.text = user.nomeCompleto;
        _contatoCtrl.text = _formatarTelefone(user.telefone);
      }
      setState(() {});
    });
  }

  String _formatarArea(double? area) {
    if (area == null) return '—';
    final abs = (area - area.truncate()).abs();
    return area.toStringAsFixed(abs < 0.005 ? 0 : 2);
  }

  String _formatarTelefone(String? valor) {
    final digitos = LocationService.apenasDigitos(valor ?? '');
    if (digitos.length != 11) return '';
    return _phoneMask.maskText(digitos);
  }

  String _mimeFromExt(String ext) {
    return switch (ext) {
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

  Future<PeladaCapaFoto?> _pickFotoCampo() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return null;

      final ext = _extFromName(file.name);
      if (!_extPermitidas.contains(ext)) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Formato inválido. Use JPG, PNG ou WEBP.'),
          ),
        );
        return null;
      }

      final Uint8List bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxFotoBytes) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Imagem muito grande. Limite: 5MB.'),
          ),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Falha ao carregar imagem: ${e.toString()}'),
        ),
      );
      return null;
    }
  }

  Future<void> _adicionarFotoCampo() async {
    unawaited(HapticFeedback.selectionClick());
    if (_fotosCampo.length >= _maxFotosCampo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Limite de $_maxFotosCampo fotos atingido.'),
        ),
      );
      return;
    }
    final foto = await _pickFotoCampo();
    if (foto == null || !mounted) return;
    setState(() {
      _fotosCampo.add(foto);
      if (_fotoCapaIndex == null && _fotosCampo.isNotEmpty) {
        _fotoCapaIndex = 0;
      }
    });
  }

  void _removerFotoCampo(int index) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _fotosCampo.removeAt(index);
      if (_fotosCampo.isEmpty) {
        _fotoCapaIndex = null;
      } else if (_fotoCapaIndex != null) {
        if (_fotoCapaIndex == index) {
          _fotoCapaIndex = 0;
        } else if (_fotoCapaIndex! > index) {
          _fotoCapaIndex = _fotoCapaIndex! - 1;
        }
      }
    });
  }

  void _selecionarFotoCapa(int index) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _fotoCapaIndex = index;
    });
  }

  void _onMedidaChanged() {
    if (!mounted) return;
    final formatado = _formatarArea(_areaCalculada);
    if (_areaCtrl.text != formatado) {
      _areaCtrl.value = TextEditingValue(
        text: formatado,
        selection: TextSelection.collapsed(offset: formatado.length),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _larguraCtrl.removeListener(_onMedidaChanged);
    _profundidadeCtrl.removeListener(_onMedidaChanged);
    _nomeCtrl.dispose();
    _responsavelCtrl.dispose();
    _contatoCtrl.dispose();
    _cepCtrl.dispose();
    _cepFocus.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _bairroCtrl.dispose();
    _ruaCtrl.dispose();
    _numeroCtrl.dispose();
    _larguraCtrl.dispose();
    _profundidadeCtrl.dispose();
    _areaCtrl.dispose();
    _capacidadePublicoCtrl.dispose();
    _cepDebounceTimer?.cancel();
    super.dispose();
  }

  String? _obrigatorio(String? v, {String msg = 'Campo obrigatório'}) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  Widget _ufField() {
    return EstadoUfDropdown(
      controller: _estadoCtrl,
      cidadeController: _cidadeCtrl,
      label: 'UF *',
      prefixIcon: Icons.flag_outlined,
      onChanged: (_) => setState(() {}),
      validator: (uf) => AppConstants.estadosBrasil.contains(uf)
          ? null
          : 'Informe uma UF válida.',
    );
  }

  void _limparEndereco() {
    if (!mounted) return;
    _cepDebounceTimer?.cancel();
    setState(() {
      _cepCtrl.text = '';
      _estadoCtrl.text = '';
      _cidadeCtrl.text = '';
      _bairroCtrl.text = '';
      _ruaCtrl.text = '';
      _numeroCtrl.text = '';
      _cepErro = null;
      _cepCarregando = false;
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
      final r = await LocationService.consultarCep(digitos);
      if (!mounted) return;
      if (!r.sucesso) {
        setState(() {
          _cepErro = 'CEP não encontrado ou inválido';
        });
        return;
      }
      setState(() {
        if (r.logradouro.trim().isNotEmpty && _ruaCtrl.text.trim().isEmpty) {
          _ruaCtrl.text = r.logradouro.trim();
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
          content: const Text('Endereço preenchido automaticamente.'),
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
      if (mounted) setState(() => _cepCarregando = false);
    }
  }

  Future<void> _salvar() async {
    unawaited(HapticFeedback.lightImpact());
    final auth = Provider.of<AuthService>(context, listen: false);
    final data = Provider.of<DataService>(context, listen: false);
    if (_salvando) return;
    if (!validateAndFocusFirstError(_formKey)) return;
    if (_qtdPorLinha == null) {
      await focusRequiredWidget(_keyQtdPorLinha);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Selecione a quantidade de jogadores por linha.'),
        ),
      );
      return;
    }
    if (_calcadosPermitidos.isEmpty) {
      await focusRequiredWidget(_keyCalcadosPermitidos);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Selecione ao menos um tipo de calçado permitido.'),
        ),
      );
      return;
    }
    final user = auth.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _salvando = true);
    try {
      final cepDigitado = LocationService.apenasDigitos(_cepCtrl.text);
      final enderecoParaGeo = _ruaCtrl.text.trim();
      final numeroParaGeo = _numeroCtrl.text.trim();
      final bairroParaGeo = _bairroCtrl.text.trim();
      final cidadeParaGeo = _cidadeCtrl.text.trim();
      final estadoParaGeo = _estadoCtrl.text.trim();
      final original = widget.campoArena;
      final enderecoMantido =
          original != null &&
          original.rua.trim() == enderecoParaGeo &&
          original.numero.trim() == numeroParaGeo &&
          original.bairro.trim() == bairroParaGeo &&
          original.cidade.trim() == cidadeParaGeo &&
          original.estado.trim() == estadoParaGeo &&
          LocationService.apenasDigitos(original.cep ?? '') == cepDigitado;
      Coordenadas? coords =
          enderecoMantido &&
              original.latitude != null &&
              original.longitude != null &&
              (original.latitude != 0 || original.longitude != 0)
          ? Coordenadas(original.latitude!, original.longitude!)
          : null;
      final deveProcessarCoords =
          cepDigitado.length == 8 ||
          (enderecoParaGeo.isNotEmpty &&
              cidadeParaGeo.isNotEmpty &&
              estadoParaGeo.isNotEmpty);
      if (deveProcessarCoords && coords == null && mounted) {
        unawaited(
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
          ),
        );
        try {
          final coordenadasLocalizadas =
              await LocationService.geocodificarEndereco(
                endereco: enderecoParaGeo,
                numero: numeroParaGeo,
                bairro: bairroParaGeo,
                cidade: cidadeParaGeo,
                estado: estadoParaGeo,
                localArena: _nomeCtrl.text.trim(),
                cep: cepDigitado.length == 8 ? cepDigitado : null,
              );
          coords = coordenadasLocalizadas ?? coords;
        } catch (_) {
          // A publicação pode continuar sem coordenadas se o serviço falhar.
        } finally {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      }

      final ruaFinal = _ruaCtrl.text.trim();
      final numeroFinal = _numeroCtrl.text.trim();

      final base = CampoArena(
        id: widget.campoArena?.id ?? '',
        nome: _nomeCtrl.text.trim(),
        responsavelNome: _responsavelCtrl.text.trim(),
        contato: _contatoCtrl.text.trim().isNotEmpty
            ? _contatoCtrl.text.trim()
            : null,
        estado: _estadoCtrl.text.trim(),
        cidade: _cidadeCtrl.text.trim(),
        bairro: _bairroCtrl.text.trim(),
        rua: ruaFinal,
        numero: numeroFinal,
        cep: cepDigitado.length == 8 ? _cepCtrl.text.trim() : null,
        latitude: coords?.latitude,
        longitude: coords?.longitude,
        proprietarioId: user?.id,
        quantidadePorLinha: _qtdPorLinha!,
        tipoGrama: _tipoGrama,
        calcadosPermitidos: Set.unmodifiable(_calcadosPermitidos),
        dependencias: Set.unmodifiable(_dependencias),
        itensOpcionais: Set.unmodifiable(_itensOpcionais),
        opcionaisConsultarTaxas: Set.unmodifiable(_opcionaisConsultarTaxas),
        larguraMetros: _parseDouble(_larguraCtrl.text),
        profundidadeMetros: _parseDouble(_profundidadeCtrl.text),
        capacidadePublico: int.tryParse(_capacidadePublicoCtrl.text.trim()),
        fotos: List.unmodifiable(_fotosCampo),
        fotoCapaIndex: _fotoCapaIndex,
        horariosDisponiveis: Set.unmodifiable(_horariosDisponiveis),
        createdAt: widget.campoArena?.createdAt ?? DateTime(0),
        updatedAt: DateTime.now(),
      );

      final CampoArena? salvo;
      if (widget.campoArena != null) {
        salvo = await data.atualizarCampoArena(base);
      } else {
        salvo = await data.cadastrarCampoArena(base);
      }

      if (salvo == null) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.danger,
              content: Text(
                data.errorMessage ?? 'Falha ao salvar, tente novamente.',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      final successMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final isEdicao = widget.campoArena != null;
      final camposDestino = CamposArenasScreen(focoCampo: salvo);
      await navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => camposDestino),
        (r) => false,
      );
      successMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          content: Text(
            isEdicao
                ? 'Campo "${salvo.nome}" atualizado com sucesso!'
                : 'Campo "${salvo.nome}" publicado com sucesso!',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        title: Semantics(
          header: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.campoArena == null
                  ? 'Cadastre seu Campo / Arena'
                  : 'Editar Campo / Arena',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.appBarTheme.foregroundColor,
              ),
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final maxContent = isWide ? 780.0 : double.infinity;
            final horizontalPad = isWide ? 28.0 : 18.0;
            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxContent),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      18,
                      horizontalPad,
                      40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _secaoTitulo(
                          'IDENTIFICAÇÃO',
                          obrigatoria: true,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          label: 'Nome do Campo',
                          obrigatorio: true,
                          controller: _nomeCtrl,
                          hint: 'Ex: Arena Verde Gramado',
                          prefixIcon: Icons.sports_soccer_outlined,
                          onSurface: onSurface,
                          scheme: scheme,
                          inputFormatters: [UpperCaseInputFormatter()],
                          validator: (v) =>
                              _obrigatorio(v, msg: 'Informe o nome do campo.'),
                        ),
                        const SizedBox(height: 10),
                        _input(
                          label: 'Responsável pelo estabelecimento',
                          obrigatorio: true,
                          controller: _responsavelCtrl,
                          hint: 'Nome completo do responsável',
                          prefixIcon: Icons.badge_outlined,
                          onSurface: onSurface,
                          scheme: scheme,
                          validator: (v) => _obrigatorio(
                            v,
                            msg: 'Informe o responsável pelo estabelecimento.',
                          ),
                        ),
                        const SizedBox(height: 10),
                        _input(
                          label: 'Contato (telefone)',
                          obrigatorio: false,
                          controller: _contatoCtrl,
                          hint: '(00) 00000-0000',
                          prefixIcon: Icons.phone_outlined,
                          onSurface: onSurface,
                          scheme: scheme,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [_phoneMask],
                          validator: (value) {
                            final digitos = LocationService.apenasDigitos(
                              value ?? '',
                            );
                            if (digitos.isNotEmpty && digitos.length != 11) {
                              return 'Informe um telefone com DDD e 9 dígitos.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'LOCALIZAÇÃO',
                          obrigatoria: true,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        _cepField(scheme: scheme, onSurface: onSurface),
                        const SizedBox(height: 10),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _ufField()),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: CidadeMunicipioAutocompleteField(
                                  uf: _estadoCtrl.text,
                                  controller: _cidadeCtrl,
                                  label: 'Cidade *',
                                  hintText: 'São Paulo',
                                  prefixIcon: Icons.location_city_outlined,
                                  validator: (v) =>
                                      _obrigatorio(v, msg: 'Informe a cidade.'),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _ufField(),
                          const SizedBox(height: 10),
                          CidadeMunicipioAutocompleteField(
                            uf: _estadoCtrl.text,
                            controller: _cidadeCtrl,
                            label: 'Cidade *',
                            hintText: 'São Paulo',
                            prefixIcon: Icons.location_city_outlined,
                            validator: (v) =>
                                _obrigatorio(v, msg: 'Informe a cidade.'),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _input(
                          label: 'Bairro',
                          obrigatorio: true,
                          controller: _bairroCtrl,
                          hint: 'Pinheiros',
                          prefixIcon: Icons.house_siding_outlined,
                          onSurface: onSurface,
                          scheme: scheme,
                          validator: (v) =>
                              _obrigatorio(v, msg: 'Informe o bairro.'),
                        ),
                        const SizedBox(height: 10),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _input(
                                  label: 'Rua / Avenida',
                                  obrigatorio: true,
                                  controller: _ruaCtrl,
                                  hint: 'Av. Paulista',
                                  prefixIcon: Icons.route_outlined,
                                  onSurface: onSurface,
                                  scheme: scheme,
                                  validator: (v) => _obrigatorio(
                                    v,
                                    msg: 'Informe a rua / avenida.',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _input(
                                  label: 'Número',
                                  obrigatorio: true,
                                  controller: _numeroCtrl,
                                  hint: '1500',
                                  keyboardType: TextInputType.streetAddress,
                                  prefixIcon: Icons.signpost_outlined,
                                  onSurface: onSurface,
                                  scheme: scheme,
                                  validator: (v) =>
                                      _obrigatorio(v, msg: 'Informe o número.'),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _input(
                            label: 'Rua / Avenida',
                            obrigatorio: true,
                            controller: _ruaCtrl,
                            hint: 'Av. Paulista',
                            prefixIcon: Icons.route_outlined,
                            onSurface: onSurface,
                            scheme: scheme,
                            validator: (v) => _obrigatorio(
                              v,
                              msg: 'Informe a rua / avenida.',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _input(
                            label: 'Número',
                            obrigatorio: true,
                            controller: _numeroCtrl,
                            hint: '1500',
                            keyboardType: TextInputType.streetAddress,
                            prefixIcon: Icons.signpost_outlined,
                            onSurface: onSurface,
                            scheme: scheme,
                            validator: (v) =>
                                _obrigatorio(v, msg: 'Informe o número.'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'QUANTIDADE NA LINHA',
                          obrigatoria: true,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        KeyedSubtree(
                          key: _keyQtdPorLinha,
                          child: _singleSelectWrap<int>(
                            values: _opcoesLinha,
                            labelBuilder: (v) => '${v}x$v',
                            selected: _qtdPorLinha,
                            onSelect: (v) {
                              unawaited(HapticFeedback.selectionClick());
                              setState(() => _qtdPorLinha = v);
                            },
                            scheme: scheme,
                          ),
                        ),
                        if (_qtdPorLinha == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'Selecione uma opção de tamanho de campo.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'TIPO DE CALÇADO PERMITIDO',
                          obrigatoria: true,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        KeyedSubtree(
                          key: _keyCalcadosPermitidos,
                          child: _multiSelectWrap<TipoChuteira>(
                            values: TipoChuteira.values,
                            labelBuilder: (v) => v.label,
                            selected: _calcadosPermitidos,
                            onToggle: (v) {
                              unawaited(HapticFeedback.selectionClick());
                              setState(() {
                                if (_calcadosPermitidos.contains(v)) {
                                  _calcadosPermitidos.remove(v);
                                } else {
                                  _calcadosPermitidos.add(v);
                                }
                                _calcadosPermitidos = {..._calcadosPermitidos};
                              });
                            },
                            scheme: scheme,
                          ),
                        ),
                        if (_calcadosPermitidos.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'Selecione ao menos um tipo de calçado permitido.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'TIPO DE GRAMA / PISO',
                          obrigatoria: true,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        _singleSelectWrap<TipoGrama>(
                          values: _opcoesGrama,
                          labelBuilder: (v) => v.label,
                          selected: _tipoGrama,
                          onSelect: (v) {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() => _tipoGrama = v);
                          },
                          scheme: scheme,
                        ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'MEDIDAS DO CAMPO / ARENA',
                          obrigatoria: false,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Unidade de medida padrão em metros (m).',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: onSurfaceVariant.withValues(alpha: 0.78),
                            ),
                          ),
                        ),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: _input(
                                  label: 'Largura',
                                  obrigatorio: false,
                                  controller: _larguraCtrl,
                                  hint: 'Ex: 28,5',
                                  prefixIcon: Icons.straighten_rounded,
                                  onSurface: onSurface,
                                  scheme: scheme,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  suffixText: 'm',
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9,.]'),
                                    ),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return null;
                                    }
                                    final d = _parseDouble(v);
                                    if (d == null || d <= 0) {
                                      return 'Informe um valor positivo.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: _input(
                                  label: 'Profundidade',
                                  obrigatorio: false,
                                  controller: _profundidadeCtrl,
                                  hint: 'Ex: 45',
                                  prefixIcon: Icons.height_rounded,
                                  onSurface: onSurface,
                                  scheme: scheme,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  suffixText: 'm',
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9,.]'),
                                    ),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return null;
                                    }
                                    final d = _parseDouble(v);
                                    if (d == null || d <= 0) {
                                      return 'Informe um valor positivo.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _input(
                            label: 'Largura',
                            obrigatorio: false,
                            controller: _larguraCtrl,
                            hint: 'Ex: 28,5',
                            prefixIcon: Icons.straighten_rounded,
                            onSurface: onSurface,
                            scheme: scheme,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            suffixText: 'm',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,.]'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final d = _parseDouble(v);
                              if (d == null || d <= 0) {
                                return 'Informe um valor positivo.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _input(
                            label: 'Profundidade',
                            obrigatorio: false,
                            controller: _profundidadeCtrl,
                            hint: 'Ex: 45',
                            prefixIcon: Icons.height_rounded,
                            onSurface: onSurface,
                            scheme: scheme,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            suffixText: 'm',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,.]'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final d = _parseDouble(v);
                              if (d == null || d <= 0) {
                                return 'Informe um valor positivo.';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        _areaCalculadaField(
                          scheme: scheme,
                          onSurface: onSurface,
                          primary: primary,
                        ),
                        const SizedBox(height: 10),
                        _input(
                          label: 'Capacidade de público',
                          obrigatorio: false,
                          controller: _capacidadePublicoCtrl,
                          hint: 'Ex: 250',
                          prefixIcon: Icons.groups_outlined,
                          onSurface: onSurface,
                          scheme: scheme,
                          keyboardType: TextInputType.number,
                          suffixText: 'pessoas',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final quantidade = int.tryParse(value.trim());
                            if (quantidade == null || quantidade <= 0) {
                              return 'Informe uma quantidade maior que zero.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'DEPENDÊNCIAS',
                          obrigatoria: false,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        _multiSelectWrap<DependenciaCampo>(
                          values: DependenciaCampo.values,
                          labelBuilder: (v) => v.label,
                          selected: _dependencias,
                          onToggle: (v) {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() {
                              if (_dependencias.contains(v)) {
                                _dependencias.remove(v);
                              } else {
                                _dependencias.add(v);
                              }
                              _dependencias = {..._dependencias};
                            });
                          },
                          scheme: scheme,
                        ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'CORTESIAS',
                          obrigatoria: false,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        _multiSelectWrap<ItemOpcionalCampo>(
                          values: ItemOpcionalCampo.values
                              .where(
                                (item) => item != ItemOpcionalCampo.chuteiras,
                              )
                              .toList(),
                          labelBuilder: (v) => v.label,
                          selected: _itensOpcionais,
                          onToggle: (v) {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() {
                              if (_itensOpcionais.contains(v)) {
                                _itensOpcionais.remove(v);
                              } else {
                                _itensOpcionais.add(v);
                              }
                              _itensOpcionais = {..._itensOpcionais};
                            });
                          },
                          scheme: scheme,
                        ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'OPCIONAIS (CONSULTAR TAXAS)',
                          obrigatoria: false,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        _multiSelectWrap<ItemOpcionalCampo>(
                          values: ItemOpcionalCampo.values,
                          labelBuilder: (v) => v.label,
                          selected: _opcionaisConsultarTaxas,
                          onToggle: (v) {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() {
                              if (_opcionaisConsultarTaxas.contains(v)) {
                                _opcionaisConsultarTaxas.remove(v);
                              } else {
                                _opcionaisConsultarTaxas.add(v);
                              }
                              _opcionaisConsultarTaxas = {
                                ..._opcionaisConsultarTaxas,
                              };
                            });
                          },
                          scheme: scheme,
                        ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'HORÁRIOS DISPONÍVEIS',
                          obrigatoria: false,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Marque os períodos em que o campo ou arena está disponível.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: onSurfaceVariant.withValues(alpha: 0.78),
                            ),
                          ),
                        ),
                        HorariosDisponiveisTable(
                          horariosSelecionados: _horariosDisponiveis,
                          mostrarAviso: true,
                          onToggle: (horario) {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() {
                              if (!_horariosDisponiveis.add(horario)) {
                                _horariosDisponiveis.remove(horario);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _secaoTitulo(
                          'FOTOS DO CAMPO',
                          obrigatoria: false,
                          primary: primary,
                          onSurfaceVariant: onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Envie até $_maxFotosCampo fotos. A primeira foto selecionada como capa será exibida nos cards de listagem.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: onSurfaceVariant.withValues(alpha: 0.78),
                            ),
                          ),
                        ),
                        _buildFotosSection(
                          scheme: scheme,
                          primary: primary,
                          onSurface: onSurface,
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Tooltip(
                                message: 'Voltar',
                                child: OutlinedButton(
                                  onPressed: _salvando
                                      ? null
                                      : () {
                                          unawaited(
                                            HapticFeedback.selectionClick(),
                                          );
                                          Navigator.pop(context);
                                        },
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(51.2),
                                    padding: EdgeInsets.zero,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 3,
                              child: FilledButton.icon(
                                onPressed: _salvando ? null : _salvar,
                                icon: _salvando
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 20,
                                      ),
                                label: Text(
                                  widget.campoArena == null
                                      ? 'PUBLICAR CAMPO'
                                      : 'SALVAR ALTERAÇÕES',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(51.2),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _secaoTitulo(
    String titulo, {
    required bool obrigatoria,
    required Color primary,
    required Color onSurfaceVariant,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w900,
              color: onSurfaceVariant,
            ),
          ),
        ),
        if (obrigatoria)
          Text(
            '* OBRIGATÓRIO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.danger.withValues(alpha: 0.92),
              letterSpacing: 0.6,
            ),
          ),
      ],
    );
  }

  Widget _input({
    required String label,
    required bool obrigatorio,
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required Color onSurface,
    required ColorScheme scheme,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.sentences,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String? value)? validator,
    String? suffixText,
    bool? enabled,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.92),
        width: 1.0,
      ),
    );
    final errorBorder = border.copyWith(
      borderSide: BorderSide(color: scheme.error, width: 1.2),
    );
    final focusedBorder = border.copyWith(
      borderSide: BorderSide(color: scheme.primary, width: 1.4),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label + (obrigatorio ? ' *' : ''),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          enabled: enabled,
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(
            color: enabled == false
                ? scheme.onSurface.withValues(alpha: 0.68)
                : onSurface,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
              fontWeight: FontWeight.w500,
            ),
            suffixText: suffixText,
            suffixStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.80),
              fontWeight: FontWeight.w700,
            ),
            isDense: true,
            filled: true,
            fillColor: scheme.surface,
            prefixIcon: Icon(prefixIcon, size: 19, color: scheme.primary),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: border,
            enabledBorder: border,
            errorBorder: errorBorder,
            focusedBorder: focusedBorder,
            focusedErrorBorder: errorBorder,
            disabledBorder: border,
          ),
        ),
      ],
    );
  }

  Widget _cepField({required ColorScheme scheme, required Color onSurface}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.92),
        width: 1.0,
      ),
    );
    final errorBorder = border.copyWith(
      borderSide: BorderSide(color: scheme.error, width: 1.2),
    );
    final focusedBorder = border.copyWith(
      borderSide: BorderSide(color: scheme.primary, width: 1.4),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Flexible(
              child: Text(
                'CEP',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 6),
            Tooltip(
              message:
                  'Digite o CEP para preencher automaticamente a rua, bairro, cidade e UF.',
              child: Icon(Icons.info_outline_rounded, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _cepCtrl,
                focusNode: _cepFocus,
                onChanged: _onCepChanged,
                keyboardType: TextInputType.number,
                inputFormatters: [_cepMask],
                validator: (_) {
                  final d = LocationService.apenasDigitos(_cepCtrl.text);
                  if (d.isNotEmpty && d.length != 8) {
                    return 'CEP inválido.';
                  }
                  return null;
                },
                style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '00.000-000',
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: scheme.surface,
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: scheme.primary,
                  ),
                  suffixIcon: _cepCarregando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  errorText: _cepErro,
                  border: border,
                  enabledBorder: border,
                  errorBorder: errorBorder,
                  focusedBorder: focusedBorder,
                  focusedErrorBorder: errorBorder,
                ),
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
                            unawaited(HapticFeedback.lightImpact());
                            _limparEndereco();
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
      ],
    );
  }

  Widget _areaCalculadaField({
    required ColorScheme scheme,
    required Color onSurface,
    required Color primary,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
        color: primary.withValues(alpha: 0.55),
        width: 1.2,
      ),
    );
    final area = _areaCalculada;
    final formatted = _formatarArea(area);
    return Semantics(
      label: 'Área calculada do campo em metros quadrados',
      value: area == null ? 'Não informada' : '$formatted metros quadrados',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined, size: 15, color: primary),
              const SizedBox(width: 6),
              Text(
                'ÁREA TOTAL (AUTOMÁTICO)',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w900,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AbsorbPointer(
            child: TextFormField(
              enabled: false,
              controller: _areaCtrl,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.86),
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: primary.withValues(alpha: 0.08),
                hintText: '0,00',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(
                  Icons.square_foot_rounded,
                  size: 19,
                  color: primary,
                ),
                suffixText: 'm²',
                suffixStyle: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: border,
                enabledBorder: border,
                disabledBorder: border,
                focusedBorder: border,
                errorBorder: border,
                focusedErrorBorder: border,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotosSection({
    required ColorScheme scheme,
    required Color primary,
    required Color onSurface,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.70),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 17, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Galeria (${_fotosCampo.length}/$_maxFotosCampo)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_fotosCampo.isNotEmpty)
                Text(
                  _fotoCapaIndex != null
                      ? 'Capa: Foto ${_fotoCapaIndex! + 1}'
                      : 'Capa: Automática (1ª)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final totalSlots = _maxFotosCampo;
              final slotWidth =
                  (constraints.maxWidth - (totalSlots - 1) * 10) / totalSlots;
              final slotHeight = slotWidth * 1.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < totalSlots; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: i != totalSlots - 1 ? 10 : 0,
                      ),
                      child: SizedBox(
                        width: slotWidth,
                        height: slotHeight,
                        child: i < _fotosCampo.length
                            ? _buildFotoSlot(
                                index: i,
                                foto: _fotosCampo[i],
                                isCapa:
                                    _fotoCapaIndex == i ||
                                    (_fotoCapaIndex == null && i == 0),
                                scheme: scheme,
                                primary: primary,
                                onSurface: onSurface,
                              )
                            : _buildAddFotoSlot(
                                enabled: _fotosCampo.length < _maxFotosCampo,
                                scheme: scheme,
                                primary: primary,
                              ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFotoSlot({
    required int index,
    required PeladaCapaFoto foto,
    required bool isCapa,
    required ColorScheme scheme,
    required Color primary,
    required Color onSurface,
  }) {
    final isCapaReal = isCapa && foto.hasValidBytes;
    return Semantics(
      button: true,
      label:
          'Foto ${index + 1} do campo. ${isCapaReal ? 'Esta é a foto de capa. Toque para alterar a capa ou toque no X para remover.' : 'Toque para definir como capa ou toque no X para remover.'}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _selecionarFotoCapa(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCapaReal ? primary : scheme.outlineVariant,
                    width: isCapaReal ? 2.2 : 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: foto.hasValidBytes
                    ? Image.memory(
                        foto.bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: scheme.surface,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: scheme.surface,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (isCapaReal)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_front_rounded,
                      size: 11,
                      color: scheme.onPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CAPA',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 5,
            top: 5,
            child: Semantics(
              button: true,
              label: 'Remover foto ${index + 1}',
              child: Tooltip(
                message: 'Remover foto',
                preferBelow: false,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.58),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _removerFotoCampo(index),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFotoSlot({
    required bool enabled,
    required ColorScheme scheme,
    required Color primary,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? 'Adicionar foto ao campo' : 'Limite de fotos atingido',
      child: Tooltip(
        message: enabled ? 'Adicionar foto' : 'Limite atingido',
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? _adicionarFotoCampo : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: enabled
                      ? primary.withValues(alpha: 0.45)
                      : scheme.outlineVariant.withValues(alpha: 0.45),
                  width: 1.2,
                  style: BorderStyle.solid,
                ),
                color: enabled
                    ? primary.withValues(alpha: 0.06)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    enabled ? Icons.add_a_photo_outlined : Icons.lock_outline,
                    size: 26,
                    color: enabled
                        ? primary
                        : scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    enabled ? 'ADICIONAR' : 'LOTADO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: enabled
                          ? primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _singleSelectWrap<T>({
    required List<T> values,
    required String Function(T v) labelBuilder,
    required T? selected,
    required void Function(T v) onSelect,
    required ColorScheme scheme,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSelected = selected == v;
        final bg = isSelected
            ? scheme.primary
            : scheme.surface.withValues(alpha: 0.96);
        final fg = isSelected
            ? scheme.onPrimary
            : scheme.onSurface.withValues(alpha: 0.88);
        final border = isSelected
            ? scheme.primary
            : scheme.outlineVariant.withValues(alpha: 0.95);
        return Semantics(
          button: true,
          selected: isSelected,
          label: labelBuilder(v),
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: border, width: 1.1),
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              onTap: () => onSelect(v),
              borderRadius: BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  labelBuilder(v),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _multiSelectWrap<T>({
    required List<T> values,
    required String Function(T v) labelBuilder,
    required Set<T> selected,
    required void Function(T v) onToggle,
    required ColorScheme scheme,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSelected = selected.contains(v);
        final bg = isSelected
            ? scheme.primary.withValues(alpha: 0.14)
            : scheme.surface.withValues(alpha: 0.96);
        final fg = isSelected
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: 0.88);
        final border = isSelected
            ? scheme.primary
            : scheme.outlineVariant.withValues(alpha: 0.95);
        return Semantics(
          button: true,
          selected: isSelected,
          label: labelBuilder(v),
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: border, width: 1.1),
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              onTap: () => onToggle(v),
              borderRadius: BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: fg,
                          width: isSelected ? 0 : 1.2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        color: isSelected ? scheme.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: scheme.onPrimary,
                              size: 13,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      labelBuilder(v),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
