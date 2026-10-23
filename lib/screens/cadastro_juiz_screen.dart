import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:peladeiros_sa/screens/juizes_screen.dart' show JuizesScreen;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/juiz.dart';
import '../models/pelada.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/location_service.dart' show LocationService;
import '../utils/form_focus_helper.dart';
import '../widgets/date_input_field.dart';
import '../widgets/estado_cidade_fields.dart';
import 'package:peladeiros_sa/utils/title_case_input_formatter.dart';

class CadastroJuizScreen extends StatefulWidget {
  final Juiz? juiz;
  const CadastroJuizScreen({super.key, this.juiz});

  @override
  State<CadastroJuizScreen> createState() => _CadastroJuizScreenState();
}

class _CadastroJuizScreenState extends State<CadastroJuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _sobrenomeCtrl = TextEditingController();
  final _apelidoCtrl = TextEditingController();
  final _dataNascimentoCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _cepFocus = FocusNode();
  final _ufCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _taxaArbitragemCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  PeladaCapaFoto? _foto;
  bool _removerFoto = false;
  String? _situacaoFederativa;
  bool? _comAuxiliares;
  final Set<String> _atuacao = <String>{};
  final Set<String> _equipamentos = <String>{};
  final Set<String> _modalidades = <String>{};

  bool _cepCarregando = false;
  String? _cepErro;
  Timer? _cepDebounceTimer;

  DateTime? _dataNascimento;
  bool _syncingDtNasc = false;

  bool _salvando = false;

  static const Set<String> _extPermitidas = {'png', 'jpg', 'jpeg', 'webp'};
  static const int _maxFotoBytes = 5 * 1024 * 1024;

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cepMask = MaskTextInputFormatter(
    mask: '##.###-###',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final MaskTextInputFormatter _dataNascimentoMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _dataNascimentoCtrl.addListener(_onDtNascTextChanged);
    _cepFocus.addListener(() {
      if (_cepFocus.hasFocus) {
        final atual = LocationService.apenasDigitos(_cepCtrl.text);
        if (atual.isEmpty) _limparEndereco();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existente = widget.juiz;
      if (existente != null) {
        _nomeCtrl.text = existente.nome;
        _sobrenomeCtrl.text = existente.sobrenome;
        _apelidoCtrl.text = existente.apelido ?? '';
        if (existente.dataNascimento != null) {
          _syncingDtNasc = true;
          try {
            _dataNascimento = existente.dataNascimento;
            _dataNascimentoCtrl.text = _dateFormat.format(
              existente.dataNascimento!,
            );
          } finally {
            _syncingDtNasc = false;
          }
        }
        _telefoneCtrl.text = existente.telefone ?? '';
        _cepCtrl.text = existente.cep ?? '';
        _ufCtrl.text = existente.uf ?? '';
        _cidadeCtrl.text = existente.cidade ?? '';
        _bairroCtrl.text = existente.bairro ?? '';
        _situacaoFederativa = existente.situacaoFederativa;
        _comAuxiliares = existente.comAuxiliares;
        _atuacao.addAll(existente.atuacao);
        _equipamentos.addAll(existente.equipamentos);
        _modalidades.addAll(existente.modalidades);
        if (existente.taxaArbitragem != null) {
          _taxaArbitragemCtrl.text = existente.taxaArbitragem!
              .toStringAsFixed(2)
              .replaceAll('.', ',');
        }
        if (existente.foto != null && existente.foto!.hasValidBytes) {
          _foto = existente.foto;
        }
        setState(() {});
      }
    });
  }

  DateTime? _parseDataNascimentoManual(String text) {
    final plain = _dataNascimentoMask.unmaskText(text);
    if (plain.length != 8) return null;
    final d = int.tryParse(plain.substring(0, 2));
    final m = int.tryParse(plain.substring(2, 4));
    final a = int.tryParse(plain.substring(4, 8));
    if (d == null || m == null || a == null) return null;
    try {
      final cand = DateTime(a, m, d);
      if (cand.day != d || cand.month != m) return null;
      if (a < 1920) return null;
      final hoje = DateTime.now();
      final maxD = DateTime(hoje.year, hoje.month, hoje.day);
      if (cand.isAfter(maxD)) return null;
      return cand;
    } catch (_) {
      return null;
    }
  }

  void _onDtNascTextChanged() {
    if (_syncingDtNasc) return;
    final txt = _dataNascimentoCtrl.text.trim();
    if (txt.isEmpty) {
      if (_dataNascimento != null) {
        setState(() => _dataNascimento = null);
      }
      return;
    }
    final parsed = _parseDataNascimentoManual(txt);
    if (parsed != null &&
        (_dataNascimento == null || parsed.compareTo(_dataNascimento!) != 0)) {
      setState(() => _dataNascimento = parsed);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _sobrenomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _dataNascimentoCtrl.removeListener(_onDtNascTextChanged);
    _dataNascimentoCtrl.dispose();
    _telefoneCtrl.dispose();
    _cepCtrl.dispose();
    _cepFocus.dispose();
    _ufCtrl.dispose();
    _cidadeCtrl.dispose();
    _bairroCtrl.dispose();
    _taxaArbitragemCtrl.dispose();
    _cepDebounceTimer?.cancel();
    super.dispose();
  }

  void _limparEndereco() {
    if (!mounted) return;
    setState(() {
      _cepCtrl.text = '';
      _ufCtrl.text = '';
      _cidadeCtrl.text = '';
      _bairroCtrl.text = '';
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
        if (r.bairro.trim().isNotEmpty && _bairroCtrl.text.trim().isEmpty) {
          _bairroCtrl.text = r.bairro.trim();
        }
        if (r.cidade.trim().isNotEmpty && _cidadeCtrl.text.trim().isEmpty) {
          _cidadeCtrl.text = r.cidade.trim();
        }
        if (r.uf.trim().isNotEmpty &&
            AppConstants.estadosBrasil.contains(r.uf.trim()) &&
            _ufCtrl.text.trim().isEmpty) {
          _ufCtrl.text = r.uf.trim();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
            content: const Text('Endereço preenchido automaticamente'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  double? _parseTaxaArbitragem(String value) {
    final texto = value.trim();
    final normalizado = texto.contains(',')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto;
    if (normalizado.isEmpty) return null;
    return double.tryParse(normalizado);
  }

  Future<PeladaCapaFoto?> _pickFoto() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
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
          content: Text('Erro ao selecionar imagem: $e'),
        ),
      );
      return null;
    }
  }

  void _onCepChangedDebounced(String v) {
    setState(() => _cepErro = null);
    _cepDebounceTimer?.cancel();
    final digitos = LocationService.apenasDigitos(v);
    if (digitos.length == 8) {
      _cepDebounceTimer = Timer(const Duration(milliseconds: 350), () {
        _buscarCep(digitos);
      });
    }
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!validateAndFocusFirstError(_formKey)) return;
    final auth = context.read<AuthService>();
    final data = context.read<DataService>();
    if (!auth.isAuthenticated) {
      _showErrorSnack('Faça login para cadastrar um juiz.');
      return;
    }
    if (auth.requiresSupabaseSession &&
        !auth.hasSupabaseSession &&
        !auth.isDemoMode) {
      _showErrorSnack(
        'Sua sessão expirou. Entre novamente para publicar o juiz.',
      );
      return;
    }

    final user = auth.currentUser;
    setState(() => _salvando = true);
    try {
      final dtNasc = _dataNascimento;
      final telefone = _telefoneCtrl.text.trim();
      final cep = LocationService.apenasDigitos(_cepCtrl.text);
      final taxaArbitragem = _parseTaxaArbitragem(_taxaArbitragemCtrl.text);

      final Juiz base;
      final agora = DateTime.now();
      if (widget.juiz != null) {
        base = widget.juiz!.copyWith(
          nome: _nomeCtrl.text.trim(),
          sobrenome: _sobrenomeCtrl.text.trim(),
          apelido: _apelidoCtrl.text.trim().isNotEmpty
              ? _apelidoCtrl.text.trim()
              : null,
          clearApelido: _apelidoCtrl.text.trim().isEmpty,
          dataNascimento: dtNasc,
          clearDataNascimento: dtNasc == null,
          telefone: telefone.isNotEmpty ? telefone : null,
          clearTelefone: telefone.isEmpty,
          cep: cep.length == 8 ? _cepCtrl.text.trim() : null,
          clearCep: cep.length != 8,
          uf: _ufCtrl.text.trim().isNotEmpty ? _ufCtrl.text.trim() : null,
          clearUf: _ufCtrl.text.trim().isEmpty,
          cidade: _cidadeCtrl.text.trim().isNotEmpty
              ? _cidadeCtrl.text.trim()
              : null,
          clearCidade: _cidadeCtrl.text.trim().isEmpty,
          bairro: _bairroCtrl.text.trim().isNotEmpty
              ? _bairroCtrl.text.trim()
              : null,
          clearBairro: _bairroCtrl.text.trim().isEmpty,
          situacaoFederativa: _situacaoFederativa,
          clearSituacaoFederativa: _situacaoFederativa == null,
          comAuxiliares: _comAuxiliares,
          clearComAuxiliares: _comAuxiliares == null,
          atuacao: _atuacao.toList(growable: false),
          equipamentos: _equipamentos.toList(growable: false),
          modalidades: _modalidades.toList(growable: false),
          taxaArbitragem: taxaArbitragem,
          clearTaxaArbitragem: taxaArbitragem == null,
          foto: _foto,
          clearFoto:
              _removerFoto || (_foto == null && widget.juiz?.foto != null),
          updatedAt: agora,
        );
      } else {
        base = Juiz(
          id: _uuid.v4(),
          nome: _nomeCtrl.text.trim(),
          sobrenome: _sobrenomeCtrl.text.trim(),
          apelido: _apelidoCtrl.text.trim().isNotEmpty
              ? _apelidoCtrl.text.trim()
              : null,
          dataNascimento: dtNasc,
          telefone: telefone.isNotEmpty ? telefone : null,
          cep: cep.length == 8 ? _cepCtrl.text.trim() : null,
          uf: _ufCtrl.text.trim().isNotEmpty ? _ufCtrl.text.trim() : null,
          cidade: _cidadeCtrl.text.trim().isNotEmpty
              ? _cidadeCtrl.text.trim()
              : null,
          bairro: _bairroCtrl.text.trim().isNotEmpty
              ? _bairroCtrl.text.trim()
              : null,
          situacaoFederativa: _situacaoFederativa,
          comAuxiliares: _comAuxiliares,
          atuacao: _atuacao.toList(growable: false),
          equipamentos: _equipamentos.toList(growable: false),
          modalidades: _modalidades.toList(growable: false),
          taxaArbitragem: taxaArbitragem,
          foto: _foto,
          proprietarioId: user?.id,
          createdAt: agora,
          updatedAt: agora,
        );
      }

      final salvo = await data.atualizarJuiz(
        base,
        salvarLocalmente: auth.isDemoMode,
        proprietario: user,
      );
      if (salvo == null) {
        if (!mounted) return;
        _showErrorSnack(
          data.errorMessage ?? 'Falha ao salvar, tente novamente.',
        );
        return;
      }

      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      final isEdicao = widget.juiz != null;
      final mensagem = auth.isDemoMode
          ? 'Juiz "${salvo.nomeExibicao}" salvo localmente no modo de teste.'
          : isEdicao
          ? 'Juiz "${salvo.nomeExibicao}" atualizado com sucesso!'
          : 'Juiz "${salvo.nomeExibicao}" publicado com sucesso!';

      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              JuizesScreen(focoJuiz: salvo, mensagemSucesso: mensagem),
        ),
        (r) => false,
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
              widget.juiz == null ? 'Cadastrar Juiz' : 'Editar Juiz',
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
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPad,
                            18,
                            horizontalPad,
                            12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _secaoTitulo(
                                'FOTO',
                                obrigatoria: false,
                                primary: primary,
                                onSurfaceVariant: onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              _fotoField(primary: primary),
                              const SizedBox(height: 24),
                              _secaoTitulo(
                                'IDENTIFICAÇÃO',
                                obrigatoria: true,
                                primary: primary,
                                onSurfaceVariant: onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              _input(
                                label: 'NOME',
                                obrigatorio: true,
                                controller: _nomeCtrl,
                                hint: 'Primeiro nome do juiz',
                                prefixIcon: Icons.person_outline,
                                onSurface: onSurface,
                                scheme: scheme,
                                capitalization: TextCapitalization.words,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o primeiro nome.';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'Nome muito curto (min. 2 letras).';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _input(
                                label: 'SOBRENOME',
                                obrigatorio: true,
                                controller: _sobrenomeCtrl,
                                hint: 'Sobrenome completo',
                                prefixIcon: Icons.badge_outlined,
                                onSurface: onSurface,
                                scheme: scheme,
                                capitalization: TextCapitalization.words,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o sobrenome.';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'Sobrenome muito curto (min. 2 letras).';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _input(
                                label: 'APELIDO',
                                obrigatorio: false,
                                controller: _apelidoCtrl,
                                hint: 'Como o juiz é conhecido',
                                prefixIcon: Icons.alternate_email,
                                onSurface: onSurface,
                                scheme: scheme,
                                capitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 12),
                              _campoDataNascimento(scheme: scheme),
                              const SizedBox(height: 24),
                              _secaoTitulo(
                                'CONTATO',
                                obrigatoria: false,
                                primary: primary,
                                onSurfaceVariant: onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              _input(
                                label: 'FONE / ZAP',
                                labelDentro: true,
                                obrigatorio: false,
                                controller: _telefoneCtrl,
                                hint: '(00) 00000-0000',
                                prefixIcon: Icons.phone_in_talk_outlined,
                                onSurface: onSurface,
                                scheme: scheme,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [_phoneMask],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return null;
                                  }
                                  final d = LocationService.apenasDigitos(v);
                                  if (d.length < 11) {
                                    return 'Telefone incompleto.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _cepCtrl,
                                          focusNode: _cepFocus,
                                          onChanged: _onCepChanged,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            _cepMask,
                                          ],
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          decoration: InputDecoration(
                                            labelText: 'CEP',
                                            hintText: '00.000-000',
                                            prefixIcon: const Icon(
                                              Icons.local_post_office_outlined,
                                            ),
                                            suffixIcon: _cepCarregando
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          14,
                                                        ),
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                : (_cepErro != null
                                                      ? Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                14,
                                                              ),
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
                                            errorText: _cepErro,
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return null;
                                            }
                                            final digitos =
                                                LocationService.apenasDigitos(
                                                  v,
                                                );
                                            if (digitos.isNotEmpty &&
                                                digitos.length != 8) {
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
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: FilledButton.tonalIcon(
                                              onPressed: _cepCarregando
                                                  ? null
                                                  : () {
                                                      HapticFeedback.lightImpact();
                                                      _limparEndereco();
                                                    },
                                              icon: const Icon(
                                                Icons.clear_all_outlined,
                                              ),
                                              label: const Text('Limpar'),
                                              style: FilledButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 18,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 36,
                                      top: 4,
                                    ),
                                    child: Text(
                                      _cepCarregando
                                          ? 'Consultando CEP...'
                                          : 'Opcional. Preenche o endereço automaticamente.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: _cepCarregando
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            fontWeight: _cepCarregando
                                                ? FontWeight.w600
                                                : null,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: EstadoUfDropdown(
                                      controller: _ufCtrl,
                                      cidadeController: _cidadeCtrl,
                                      label: 'UF',
                                      prefixIcon: Icons.flag_outlined,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CidadeMunicipioAutocompleteField(
                                      uf: _ufCtrl.text,
                                      controller: _cidadeCtrl,
                                      label: 'CIDADE',
                                      hintText: 'Digite para buscar',
                                      prefixIcon: Icons.location_city_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _input(
                                label: 'BAIRRO',
                                labelDentro: true,
                                obrigatorio: false,
                                controller: _bairroCtrl,
                                hint: 'Centro',
                                prefixIcon: Icons.apartment_outlined,
                                onSurface: onSurface,
                                scheme: scheme,
                                capitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 24),
                              _secaoOpcoes(
                                titulo: 'PERFIL DO JUIZ',
                                opcoes: const [
                                  'Federado',
                                  'Ex. Federado',
                                  'Não Federado',
                                ],
                                selecionadas: _situacaoFederativa == null
                                    ? const <String>{}
                                    : {_situacaoFederativa!},
                                onSelecionadasChanged: (selecionadas) {
                                  setState(() {
                                    _situacaoFederativa = selecionadas.isEmpty
                                        ? null
                                        : selecionadas.first;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              _secaoOpcoes(
                                titulo: '',
                                subtitulo: 'AUXILIARES',
                                opcoes: const [
                                  'Com Auxiliares',
                                  'Sem Auxiliares',
                                ],
                                selecionadas: _comAuxiliares == null
                                    ? const <String>{}
                                    : {
                                        _comAuxiliares!
                                            ? 'Com Auxiliares'
                                            : 'Sem Auxiliares',
                                      },
                                onSelecionadasChanged: (selecionadas) {
                                  setState(() {
                                    _comAuxiliares = selecionadas.isEmpty
                                        ? null
                                        : selecionadas.first ==
                                              'Com Auxiliares';
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _campoTaxaArbitragem(scheme: scheme),
                              const SizedBox(height: 24),
                              _secaoOpcoes(
                                titulo: 'ATUAÇÃO',
                                opcoes: const [
                                  'Dentro da cidade',
                                  'Disponível para viagem',
                                ],
                                selecionadas: _atuacao,
                                onSelecionadasChanged: (selecionadas) {
                                  setState(() {
                                    _atuacao
                                      ..clear()
                                      ..addAll(selecionadas);
                                  });
                                },
                                multipla: true,
                              ),
                              const SizedBox(height: 24),
                              _secaoOpcoes(
                                titulo: 'EQUIPAMENTOS',
                                opcoes: const [
                                  'Apitos',
                                  'Cartões',
                                  'Bandeirinhas',
                                ],
                                selecionadas: _equipamentos,
                                onSelecionadasChanged: (selecionadas) {
                                  setState(() {
                                    _equipamentos
                                      ..clear()
                                      ..addAll(selecionadas);
                                  });
                                },
                                multipla: true,
                              ),
                              const SizedBox(height: 24),
                              _secaoOpcoes(
                                titulo: 'MODALIDADES',
                                opcoes: const [
                                  'Campo 11',
                                  'FUT 5',
                                  'FUT 6',
                                  'FUT 7',
                                  'FUT 8',
                                  'Futsal',
                                  'Praia',
                                  'Areia / Beach Soccer',
                                  'Vôlei',
                                  'Basquete',
                                  'Outros',
                                ],
                                selecionadas: _modalidades,
                                onSelecionadasChanged: (selecionadas) {
                                  setState(() {
                                    _modalidades
                                      ..clear()
                                      ..addAll(selecionadas);
                                  });
                                },
                                multipla: true,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: scheme.outlineVariant.withValues(
                                        alpha: 0.9,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _botaoPublicarRodape(
                                  scheme: scheme,
                                  primary: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _botaoPublicarRodape({
    required ColorScheme scheme,
    required Color primary,
  }) {
    final rotulo = widget.juiz == null ? 'PUBLICAR JUIZ' : 'ATUALIZAR CADASTRO';
    final icon = widget.juiz == null ? Icons.cloud_upload_outlined : Icons.save;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.9),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Revise os dados informados. Os campos marcados com * são obrigatórios.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withValues(alpha: 0.55),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.9,
                    ),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  icon: _salvando
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        )
                      : Icon(icon, size: 22),
                  label: Text(_salvando ? 'PROCESSANDO…' : rotulo),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fotoField({required Color primary}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const size = 130.0;
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? scheme.surfaceContainerHighest
                          : scheme.surface,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.85),
                        width: 1.2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_foto != null && _foto!.hasValidBytes)
                          ClipOval(
                            child: Image.memory(
                              _foto!.bytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.person,
                                color: primary,
                                size: size * 0.5,
                              ),
                            ),
                          )
                        else
                          Icon(Icons.person, color: primary, size: size * 0.5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Semantics(
                    button: true,
                    label: _foto != null && _foto!.hasValidBytes
                        ? 'Alterar foto do juiz'
                        : 'Selecionar foto do juiz',
                    hint: 'Toque duas vezes para escolher uma imagem',
                    child: Tooltip(
                      message: _foto != null && _foto!.hasValidBytes
                          ? 'Alterar foto'
                          : 'Selecionar foto',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            unawaited(HapticFeedback.selectionClick());
                            final f = await _pickFoto();
                            if (f != null && mounted) {
                              setState(() {
                                _foto = f;
                                _removerFoto = false;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? scheme.surface : Colors.white,
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_foto != null && _foto!.hasValidBytes)
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: Semantics(
                      button: true,
                      label: 'Remover foto do juiz',
                      hint: 'Toque duas vezes para remover a foto atual',
                      child: Tooltip(
                        message: 'Remover foto',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              unawaited(HapticFeedback.selectionClick());
                              setState(() {
                                _foto = null;
                                _removerFoto = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? scheme.surface : Colors.white,
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.delete_forever_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Toque no ícone de câmera para selecionar uma foto',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoDataNascimento({required ColorScheme scheme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATA DE NASCIMENTO',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        DateInputField(
          controller: _dataNascimentoCtrl,
          value: _dataNascimento,
          format: _dateFormat,
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
          decoration: const InputDecoration(),
          dateLabel: 'Data de Nascimento',
          labelText: 'Data de Nascimento',
          hintText: 'dd/mm/aaaa',
          prefixIcon: Icons.cake_outlined,
          onChanged: (d) {
            _syncingDtNasc = true;
            try {
              setState(() {
                _dataNascimento = d;
              });
            } finally {
              _syncingDtNasc = false;
            }
          },
          validator: (dt) {
            final texto = _dataNascimentoCtrl.text.trim();
            if (texto.isEmpty) return null;
            final parsed = _parseDataNascimentoManual(texto);
            if (parsed == null) {
              return 'Data inválida. Use dd/mm/aaaa.';
            }
            final min = DateTime(1920);
            final max = DateTime.now();
            if (parsed.isBefore(min) || parsed.isAfter(max)) {
              return 'Fora do intervalo permitido.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _secaoOpcoes({
    required String titulo,
    required List<String> opcoes,
    required Set<String> selecionadas,
    required ValueChanged<Set<String>> onSelecionadasChanged,
    String? subtitulo,
    bool multipla = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titulo.isNotEmpty)
          _secaoTitulo(
            titulo,
            obrigatoria: false,
            primary: scheme.primary,
            onSurfaceVariant: scheme.onSurfaceVariant,
          ),
        if (subtitulo != null) ...[
          if (titulo.isNotEmpty) const SizedBox(height: 14),
          Text(
            subtitulo,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            for (final opcao in opcoes)
              FilterChip(
                label: Text(opcao),
                selected: selecionadas.contains(opcao),
                showCheckmark: true,
                selectedColor: scheme.primaryContainer,
                checkmarkColor: scheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: selecionadas.contains(opcao)
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                  fontWeight: selecionadas.contains(opcao)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selecionadas.contains(opcao)
                      ? scheme.primary.withValues(alpha: 0.7)
                      : scheme.outlineVariant,
                ),
                onSelected: (selecionado) {
                  final novas = Set<String>.from(selecionadas);
                  if (!multipla) novas.clear();
                  if (selecionado) {
                    novas.add(opcao);
                  } else {
                    novas.remove(opcao);
                  }
                  onSelecionadasChanged(novas);
                  unawaited(HapticFeedback.selectionClick());
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _campoTaxaArbitragem({required ColorScheme scheme}) {
    return TextFormField(
      controller: _taxaArbitragemCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: 'TAXA DE ARBITRAGEM',
        hintText: '0,00',
        prefixText: 'R\$ ',
        prefixIcon: const Icon(Icons.payments_outlined),
        helperText: 'Opcional',
        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.92),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      validator: (value) {
        final texto = value?.trim() ?? '';
        if (texto.isNotEmpty && _parseTaxaArbitragem(texto) == null) {
          return 'Informe um valor válido.';
        }
        if ((_parseTaxaArbitragem(texto) ?? 0) < 0) {
          return 'A taxa não pode ser negativa.';
        }
        return null;
      },
    );
  }

  Widget _input({
    required String label,
    bool labelDentro = false,
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
    bool applyTitleCase = true,
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
    final formatters = <TextInputFormatter>[
      if (applyTitleCase &&
          keyboardType != TextInputType.number &&
          keyboardType != TextInputType.phone &&
          keyboardType != TextInputType.datetime &&
          keyboardType != TextInputType.emailAddress &&
          keyboardType != TextInputType.url &&
          keyboardType != TextInputType.visiblePassword)
        TitleCaseInputFormatter(),
      ...?inputFormatters,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!labelDentro)
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
        if (!labelDentro) const SizedBox(height: 6),
        TextFormField(
          enabled: enabled,
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          maxLength: maxLength,
          inputFormatters: formatters,
          validator: validator,
          style: TextStyle(
            color: enabled == false
                ? scheme.onSurface.withValues(alpha: 0.68)
                : onSurface,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            counterText: '',
            labelText: labelDentro ? label : null,
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
            isDense: labelDentro ? false : true,
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
}

extension on Object {
  Null get cidade => null;
}

extension on Object? {
  Null get uf => null;

  bool? get sucesso => null;

  Null get bairro => null;

  String? get cep => null;
}
