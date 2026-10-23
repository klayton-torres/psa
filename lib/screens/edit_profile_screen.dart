import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../services/app_preferences_service.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../utils/profile_avatar_helper.dart';
import '../utils/form_focus_helper.dart';
import '../utils/title_case_input_formatter.dart';
import '../widgets/estado_cidade_fields.dart';
import '../screens/login_screen.dart';

DateTime? _parseDataNascimentoFlexivel(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.length < 6 || clean.length > 8) return null;
  String dd, mm, aaaa;
  if (clean.length == 8) {
    dd = clean.substring(0, 2);
    mm = clean.substring(2, 4);
    aaaa = clean.substring(4, 8);
  } else if (clean.length == 7) {
    dd = clean.substring(0, 2);
    mm = clean.substring(2, 3);
    aaaa = clean.substring(3, 7);
  } else {
    dd = clean.substring(0, 2);
    mm = clean.substring(2, 4);
    aaaa = clean.substring(4, 6);
    final now = DateTime.now();
    final anoCurto2k = int.tryParse(aaaa);
    if (anoCurto2k != null) {
      aaaa =
          (anoCurto2k > (now.year % 100)
                  ? (now.year ~/ 100 - 1) * 100 + anoCurto2k
                  : (now.year ~/ 100) * 100 + anoCurto2k)
              .toString();
    }
  }
  final dia = int.tryParse(dd);
  final mes = int.tryParse(mm);
  final ano = int.tryParse(aaaa);
  if (dia == null || mes == null || ano == null) return null;
  if (dia < 1 || dia > 31 || mes < 1 || mes > 12) return null;
  if (ano < 1900) return null;
  try {
    final data = DateTime(ano, mes, dia);
    if (data.day != dia || data.month != mes || data.year != ano) return null;
    final hoje = DateTime.now();
    final hojeMeiaNoite = DateTime(hoje.year, hoje.month, hoje.day);
    if (data.isAfter(hojeMeiaNoite)) return null;
    return data;
  } catch (_) {
    return null;
  }
}

String _formatarDataNascimento(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length && i < 8; i++) {
    if (i == 2 || i == 4) buffer.write('/');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final onlyDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final n = onlyDigits.length;
    if (n <= 2) {
      return TextEditingValue(
        text: n == 0 ? '' : '($onlyDigits',
        selection: TextSelection.collapsed(offset: n == 0 ? 0 : n + 1),
      );
    } else if (n <= 6) {
      final ddd = onlyDigits.substring(0, 2);
      final local = onlyDigits.substring(2, n);
      final formatted = '($ddd) $local';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else if (n <= 10) {
      final ddd = onlyDigits.substring(0, 2);
      final parte1 = onlyDigits.substring(2, 6);
      final parte2 = onlyDigits.substring(6, n);
      final formatted = '($ddd) $parte1-$parte2';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      final ddd = onlyDigits.substring(0, 2);
      final parte1 = onlyDigits.substring(2, 7);
      final parte2 = onlyDigits.substring(7, 11);
      final formatted = '($ddd) $parte1-$parte2';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
}

String? _validarDataNascimento(String? valor, DateTime? data) {
  final txt = (valor ?? '').trim();
  if (txt.isEmpty) {
    return null;
  }
  if (data == null) {
    final clean = txt.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 8) {
      return 'Data incompleta (ex.: 31/12/1990)';
    }
    return 'Data inválida. Use formato DD/MM/AAAA';
  }
  final hoje = DateTime.now();
  final hojeMeiaNoite = DateTime(hoje.year, hoje.month, hoje.day);
  if (data.isAfter(hojeMeiaNoite)) {
    return 'Data de nascimento não pode ser futura';
  }
  if (data.year < 1900) {
    return 'Data não pode ser anterior a 1900';
  }
  return null;
}

String? _validarTelefone(String? valor) {
  final txt = (valor ?? '').trim();
  if (txt.isEmpty) return null;
  final digits = txt.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 10 && digits.length != 11) {
    return 'Telefone inválido (10 ou 11 dígitos)';
  }
  final ddd = int.tryParse(digits.substring(0, 2));
  if (ddd == null || ddd < 11 || ddd > 99) {
    return 'DDD inválido';
  }
  final nonoDigito = digits.length == 11 ? digits[2] : null;
  if (digits.length == 11 && nonoDigito != '9') {
    return 'Celular deve começar com 9 após o DDD';
  }
  if (digits.length == 10) {
    final sextoDigito = digits[2];
    if (sextoDigito == '9' || sextoDigito == '8' || sextoDigito == '7') {
      return 'Faltam dígitos (celular precisa de 11 dígitos)';
    }
  }
  final digitosIguais = digits.split('').every((d) => d == digits[0]);
  if (digitosIguais) {
    return 'Número inválido';
  }
  return null;
}

const List<String> kMarcasChuteiraPadrao = [
  'Nike',
  'Adidas',
  'Puma',
  'Mizuno',
  'Topper',
  'Umbro',
  'Olympikus',
  'New Balance',
  'Asics',
  'Joma',
  'Kelme',
  'Penalty',
  'Outras',
];

const Map<String, List<Modalidade>> kModalidadesPorCategoria = {
  'Futebol': [
    Modalidade.futebolCampo,
    Modalidade.futebolRua,
    Modalidade.futsal,
    Modalidade.society,
    Modalidade.areia,
    Modalidade.praia,
  ],
  'Vôlei': [Modalidade.voley, Modalidade.futevolei],
  'Basquete': [Modalidade.basquete],
  'Vários': [Modalidade.outros],
};

const double kMinTamanhoChuteira = 30.0;
const double kMaxTamanhoChuteira = 45.0;
const double kCmPorPontoChuteira = 0.66;

double chuteiraPtsParaCm(double pts) => pts * kCmPorPontoChuteira;
String chuteiraCmFormatado(double pts) =>
    '≈ ${chuteiraPtsParaCm(pts).toStringAsFixed(2)} cm';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modalidadesKey = GlobalKey();
  final ImageService _imageService = ImageService();
  Uint8List? _avatarBytes;
  String? _avatarMimeType;
  String? _avatarFileName;
  String? _fotoUrlTemp;

  late final TextEditingController _primeiroNomeCtrl;
  late final TextEditingController _sobrenomeCtrl;
  late final TextEditingController _apelidoCtrl;
  late final TextEditingController _nascimentoCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _telefoneEmergenciaCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _alturaCtrl;
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _cidadeCtrl;
  late final TextEditingController _estadoCtrl;

  late final FocusNode _nascimentoFocus;

  DateTime? _dataNascimento;
  PosicaoAtleta? _posicaoPrincipal;
  PosicaoAtleta? _posicaoAlternativa;
  double _pontuacaoChuteira = kMaxTamanhoChuteira;
  final Set<String> _marcasSelecionadas = <String>{};
  List<Modalidade> _modalidadesPraticadas = const [];

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final u = auth.currentUser;
    _primeiroNomeCtrl = TextEditingController(text: u?.primeiroNome ?? '');
    _sobrenomeCtrl = TextEditingController(text: u?.sobrenome ?? '');
    _apelidoCtrl = TextEditingController(text: u?.apelido ?? '');
    _nascimentoCtrl = TextEditingController(
      text: u?.dataNascimento == null
          ? ''
          : '${u!.dataNascimento!.day.toString().padLeft(2, '0')}/'
                '${u.dataNascimento!.month.toString().padLeft(2, '0')}/'
                '${u.dataNascimento!.year}',
    );
    _nascimentoFocus = FocusNode();
    _dataNascimento = u?.dataNascimento;
    _telefoneCtrl = TextEditingController(text: u?.telefone ?? '');
    _telefoneEmergenciaCtrl = TextEditingController(
      text: u?.telefoneEmergencia ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tel = u?.telefone;
      if (tel != null && tel.trim().isNotEmpty) {
        _telefoneCtrl.value = _TelefoneInputFormatter().formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: tel),
        );
      }
      final telefoneEmergencia = u?.telefoneEmergencia;
      if (telefoneEmergencia != null && telefoneEmergencia.trim().isNotEmpty) {
        _telefoneEmergenciaCtrl.value = _TelefoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue.empty,
              TextEditingValue(text: telefoneEmergencia),
            );
      }
    });
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _alturaCtrl = TextEditingController(
      text: u?.altura == null ? '' : u!.altura!.toStringAsFixed(2),
    );
    _pesoCtrl = TextEditingController(
      text: u?.peso == null ? '' : u!.peso!.toStringAsFixed(1),
    );
    _cidadeCtrl = TextEditingController(text: u?.cidade ?? '');
    _estadoCtrl = TextEditingController(text: u?.estado ?? '');
    _fotoUrlTemp = u?.fotoUrl;
    _posicaoPrincipal = u?.posicaoPrincipal;
    _posicaoAlternativa = u?.posicaoAlternativa;
    final ptsOrig = u?.pontuacaoChuteira ?? 0;
    _pontuacaoChuteira =
        (ptsOrig < kMinTamanhoChuteira || ptsOrig > kMaxTamanhoChuteira
                ? kMaxTamanhoChuteira
                : ptsOrig)
            .clamp(kMinTamanhoChuteira, kMaxTamanhoChuteira);
    _modalidadesPraticadas = List.of(u?.modalidadesPraticadas ?? const []);
    if (_modalidadesPraticadas.isEmpty && u?.modalidadePraticada != null) {
      _modalidadesPraticadas = [u!.modalidadePraticada!];
    }
    _marcasSelecionadas.clear();
  }

  @override
  void dispose() {
    _primeiroNomeCtrl.dispose();
    _sobrenomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _nascimentoCtrl.dispose();
    _telefoneCtrl.dispose();
    _telefoneEmergenciaCtrl.dispose();
    _emailCtrl.dispose();
    _alturaCtrl.dispose();
    _pesoCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _nascimentoFocus.dispose();
    super.dispose();
  }

  Future<void> _alterarAvatar() async {
    await _imageService.showAvatarPicker(
      context,
      onSelecionada: (res) {
        setState(() {
          _avatarBytes = res.bytes;
          _avatarMimeType = res.mimeType;
          _avatarFileName = res.fileName;
          _fotoUrlTemp = 'memory://${DateTime.now().millisecondsSinceEpoch}';
        });
      },
    );
  }

  Future<void> _pickDataNascimento() async {
    final now = DateTime.now();
    final data = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _dataNascimento ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (data != null && mounted) {
      setState(() {
        _dataNascimento = data;
        _nascimentoCtrl.text =
            '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
      });
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _onNascimentoChanged(String value) {
    final formatted = _formatarDataNascimento(value);
    if (_nascimentoCtrl.text != formatted) {
      _nascimentoCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    final parsed = _parseDataNascimentoFlexivel(formatted);
    setState(() {
      _dataNascimento = parsed;
    });
  }

  Future<void> _salvar() async {
    final auth = context.read<AuthService>();
    final original = auth.currentUser;
    if (original == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
      return;
    }
    final schemeBase = Theme.of(context).colorScheme;
    if (!validateAndFocusFirstError(_formKey)) return;
    if (_modalidadesPraticadas.isEmpty) {
      await focusRequiredWidget(_modalidadesKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text('Selecione pelo menos uma modalidade praticada.'),
          backgroundColor: schemeBase.error,
        ),
      );
      return;
    }
    final modalidadePrincipal = _modalidadesPraticadas.first;

    double? altura;
    double? peso;
    if (_alturaCtrl.text.trim().isNotEmpty) {
      altura = double.tryParse(_alturaCtrl.text.trim().replaceAll(',', '.'));
      if (altura == null || altura <= 0 || altura > 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Altura inválida (ex.: 1,75).')),
        );
        return;
      }
    }
    if (_pesoCtrl.text.trim().isNotEmpty) {
      peso = double.tryParse(_pesoCtrl.text.trim().replaceAll(',', '.'));
      if (peso == null || peso <= 0 || peso > 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peso inválido (ex.: 70,5).')),
        );
        return;
      }
    }

    setState(() => _salvando = true);
    try {
      unawaited(HapticFeedback.lightImpact());
      final List<Modalidade> modalidades = List.of(_modalidadesPraticadas);
      final cidadeTxt = _cidadeCtrl.text.trim();
      final estadoTxt = _estadoCtrl.text.trim();
      final userId = original.id.trim();
      final prefs = context.read<AppPreferencesService>();

      Uint8List? croppedBytes;
      String? fotoTxt;
      if (_avatarBytes != null) {
        final validacao = ProfileAvatarHelper.validateBytes(
          _avatarBytes!,
          path: _avatarFileName,
          mime: _avatarMimeType,
        );
        if (!validacao.valid) {
          setState(() => _salvando = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Foto inválida: ${validacao.errorMessage ?? 'Tente novamente.'}',
              ),
              backgroundColor: schemeBase.error,
            ),
          );
          return;
        }
        croppedBytes = ProfileAvatarHelper.cropSquare(_avatarBytes!);
        final thumbBytes = ProfileAvatarHelper.generateThumbnail(croppedBytes);
        fotoTxt = await auth.updateProfileAvatar(
          croppedJpegBytes: croppedBytes,
          thumbnailJpegBytes: thumbBytes,
        );
        if (croppedBytes.isNotEmpty && userId.isNotEmpty) {
          try {
            await prefs.setString('avatar_$userId', base64Encode(croppedBytes));
          } catch (_) {}
        }
      } else {
        if (_fotoUrlTemp != null &&
            _fotoUrlTemp!.trim().isNotEmpty &&
            !_fotoUrlTemp!.trim().startsWith('memory:')) {
          fotoTxt = _fotoUrlTemp!.trim();
        } else {
          fotoTxt = original.fotoUrl;
        }
      }

      final atualizado = original.copyWith(
        primeiroNome: _primeiroNomeCtrl.text.trim(),
        sobrenome: _sobrenomeCtrl.text.trim(),
        apelido: _apelidoCtrl.text.trim().isEmpty
            ? null
            : _apelidoCtrl.text.trim(),
        dataNascimento: _dataNascimento,
        telefone: _telefoneCtrl.text.trim().isEmpty
            ? null
            : _telefoneCtrl.text.trim(),
        telefoneEmergencia: _telefoneEmergenciaCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        fotoUrl: fotoTxt,
        modalidadePraticada: modalidadePrincipal,
        modalidadesPraticadas: modalidades,
        posicaoPrincipal: _posicaoPrincipal,
        posicaoAlternativa: _posicaoAlternativa,
        pontuacaoChuteira: _pontuacaoChuteira,
        altura: altura,
        peso: peso,
        marcasChuteiraFavoritas: _marcasSelecionadas.toList(growable: false),
        updatedAt: DateTime.now(),
        cidade: cidadeTxt.isEmpty ? null : cidadeTxt,
        estado: estadoTxt.isEmpty ? null : estadoTxt,
      );
      await auth.updateUser(atualizado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text('Dados salvos com sucesso!'),
          backgroundColor: schemeBase.primary,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Erro ao salvar: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const ValueKey('edit-profile-screen'),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          'Editar Perfil',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.15),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        surfaceTintColor: theme.appBarTheme.surfaceTintColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
          children: [
            _AvatarEditPicker(
              key: const ValueKey('edit-avatar-button'),
              avatarBytes: _avatarBytes,
              fotoUrl: _fotoUrlTemp,
              iniciais:
                  '${_primeiroNomeCtrl.text.trim().isNotEmpty ? _primeiroNomeCtrl.text.trim()[0] : ''}'
                          '${_sobrenomeCtrl.text.trim().isNotEmpty ? _sobrenomeCtrl.text.trim()[0] : ''}'
                      .toUpperCase(),
              onAlterar: _alterarAvatar,
            ),
            const SizedBox(height: 16),
            _Secao(
              title: 'Identificação',
              icon: Icons.badge_outlined,
              children: [
                TextFormField(
                  key: const ValueKey('edit-field-primeiro-nome'),
                  controller: _primeiroNomeCtrl,
                  inputFormatters: <TextInputFormatter>[
                    TitleCaseInputFormatter(),
                  ],
                  decoration: const InputDecoration(labelText: 'Primeiro nome'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o primeiro nome'
                      : null,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  key: const ValueKey('edit-field-sobrenome'),
                  controller: _sobrenomeCtrl,
                  inputFormatters: <TextInputFormatter>[
                    TitleCaseInputFormatter(),
                  ],
                  decoration: const InputDecoration(labelText: 'Sobrenome'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o sobrenome'
                      : null,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _apelidoCtrl,
                  inputFormatters: <TextInputFormatter>[
                    TitleCaseInputFormatter(),
                  ],
                  decoration: const InputDecoration(labelText: 'Apelido'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  key: const ValueKey('edit-field-data-nascimento'),
                  controller: _nascimentoCtrl,
                  focusNode: _nascimentoFocus,
                  readOnly: false,
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.next,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Data de nascimento',
                    hintText: 'DD/MM/AAAA',
                    helperText: 'Digite ou clique no calendário',
                    counterText: '',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_dataNascimento != null)
                          IconButton(
                            icon: const Icon(Icons.close_outlined),
                            onPressed: () {
                              setState(() {
                                _dataNascimento = null;
                                _nascimentoCtrl.text = '';
                              });
                            },
                            tooltip: 'Limpar data',
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: _pickDataNascimento,
                          tooltip: 'Escolher data',
                        ),
                      ],
                    ),
                  ),
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  onChanged: _onNascimentoChanged,
                  onTap: () {
                    HapticFeedback.selectionClick();
                  },
                  validator: (v) => _validarDataNascimento(v, _dataNascimento),
                ),
                const SizedBox(height: 11),
                TextFormField(
                  key: const ValueKey('edit-field-telefone'),
                  controller: _telefoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(11) 99999-9999 ou (11) 3333-3333',
                    helperText: 'Informe DDD + número',
                    counterText: '',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    _TelefoneInputFormatter(),
                  ],
                  validator: _validarTelefone,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  key: const ValueKey('edit-field-telefone-emergencia'),
                  controller: _telefoneEmergenciaCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Telefone de emergência',
                    hintText: '(11) 99999-9999',
                    helperText: 'Opcional · Informe DDD + número',
                    counterText: '',
                    prefixIcon: Icon(Icons.emergency_outlined, size: 20),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    _TelefoneInputFormatter(),
                  ],
                  validator: _validarTelefone,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final txt = v ?? '';
                    if (txt.isEmpty) return null;
                    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    return regex.hasMatch(txt.trim())
                        ? null
                        : 'E-mail inválido';
                  },
                ),
                const SizedBox(height: 11),
                EstadoUfDropdown(
                  controller: _estadoCtrl,
                  cidadeController: _cidadeCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 11),
                CidadeMunicipioAutocompleteField(
                  uf: _estadoCtrl.text,
                  controller: _cidadeCtrl,
                  key: ValueKey('edit-field-cidade-${_estadoCtrl.text}'),
                ),
                const SizedBox(height: 11),
              ],
            ),
            const SizedBox(height: 16),
            _Secao(
              title: 'Perfil do Atleta',
              icon: Icons.sports_soccer_outlined,
              children: [
                if (_modalidadesPraticadas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Selecione pelo menos uma modalidade',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                      key: const ValueKey('edit-modalidades-empty'),
                    ),
                  ),
                Wrap(
                  key: _modalidadesKey,
                  spacing: 8,
                  runSpacing: 8,
                  children: Modalidade.values
                      .map((m) {
                        final selecionado = _modalidadesPraticadas.contains(m);
                        final sch = theme.colorScheme;
                        return FilterChip(
                          key: ValueKey('edit-chip-${m.name}'),
                          label: Text(
                            m.label,
                            style: TextStyle(
                              color: selecionado
                                  ? sch.primary
                                  : sch.onSurfaceVariant,
                              fontWeight: selecionado
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: selecionado,
                          selectedColor: sch.primary.withValues(alpha: 0.16),
                          checkmarkColor: sch.primary,
                          backgroundColor: selecionado
                              ? sch.primary.withValues(alpha: 0.08)
                              : sch.surface,
                          side: BorderSide(
                            color: selecionado
                                ? sch.primary.withValues(alpha: 0.55)
                                : sch.outline,
                            width: selecionado ? 1.3 : 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          onSelected: (sel) {
                            setState(() {
                              final nova = List<Modalidade>.of(
                                _modalidadesPraticadas,
                              );
                              if (sel) {
                                nova.add(m);
                              } else {
                                nova.remove(m);
                              }
                              _modalidadesPraticadas = nova;
                            });
                            HapticFeedback.selectionClick();
                          },
                        );
                      })
                      .toList(growable: false),
                ),
                if (_modalidadesPraticadas.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Builder(
                    builder: (ctx) {
                      final sch = Theme.of(ctx).colorScheme;
                      return Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 15,
                            color: sch.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_modalidadesPraticadas.length} ${_modalidadesPraticadas.length == 1 ? 'modalidade' : 'modalidades'} selecionada${_modalidadesPraticadas.length == 1 ? '' : 's'}. Clique novamente em uma modalidade para remover.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: sch.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<PosicaoAtleta>(
                  initialValue: _posicaoPrincipal,
                  decoration: const InputDecoration(
                    labelText: 'Posição principal',
                  ),
                  items: PosicaoAtleta.values
                      .map(
                        (p) => DropdownMenuItem<PosicaoAtleta>(
                          value: p,
                          child: Text(p.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _posicaoPrincipal = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PosicaoAtleta>(
                  initialValue: _posicaoAlternativa,
                  decoration: const InputDecoration(
                    labelText: 'Posição alternativa',
                  ),
                  items: PosicaoAtleta.values
                      .map(
                        (p) => DropdownMenuItem<PosicaoAtleta>(
                          value: p,
                          child: Text(p.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _posicaoAlternativa = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _alturaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Altura (m)',
                          hintText: '1,75',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pesoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          hintText: '70,5',
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Builder(
                  builder: (ctx) {
                    final sch = Theme.of(ctx).colorScheme;
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Tamanho da chuteira',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_pontuacaoChuteira.toInt()}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: sch.primary,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'pts',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: sch.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: sch.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                chuteiraCmFormatado(_pontuacaoChuteira),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: sch.onSurface,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2.5,
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 11,
                            ),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9,
                            ),
                            valueIndicatorShape:
                                const RectangularSliderValueIndicatorShape(),
                            valueIndicatorColor: sch.primary,
                            valueIndicatorTextStyle: theme.textTheme.bodySmall
                                ?.copyWith(
                                  color: sch.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          child: Slider(
                            min: kMinTamanhoChuteira,
                            max: kMaxTamanhoChuteira,
                            divisions:
                                (kMaxTamanhoChuteira - kMinTamanhoChuteira)
                                    .toInt(),
                            label:
                                '${_pontuacaoChuteira.toInt()} pts · ${chuteiraCmFormatado(_pontuacaoChuteira)}',
                            value: _pontuacaoChuteira,
                            activeColor: sch.primary,
                            inactiveColor: sch.onSurface.withValues(
                              alpha: 0.20,
                            ),
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _pontuacaoChuteira = v);
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${kMinTamanhoChuteira.toInt()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: sch.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${kMaxTamanhoChuteira.toInt()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: sch.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Marcas de chuteira favoritas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Builder(
                  builder: (ctx) {
                    final sch = Theme.of(ctx).colorScheme;
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kMarcasChuteiraPadrao.map((m) {
                        final selecionada = _marcasSelecionadas.contains(m);
                        return FilterChip(
                          label: Text(m),
                          selected: selecionada,
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _marcasSelecionadas.add(m);
                              } else {
                                _marcasSelecionadas.remove(m);
                              }
                            });
                          },
                          selectedColor: sch.primary.withValues(alpha: 0.18),
                          checkmarkColor: sch.primary,
                          side: BorderSide(
                            color: selecionada ? sch.primary : sch.outline,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Builder(
              builder: (ctx) {
                final sch = Theme.of(ctx).colorScheme;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const ValueKey('edit-btn-salvar'),
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sch.primary,
                      foregroundColor: sch.onPrimary,
                      disabledBackgroundColor: sch.primary.withValues(
                        alpha: 0.45,
                      ),
                      disabledForegroundColor: sch.onPrimary.withValues(
                        alpha: 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    icon: _salvando
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: sch.onPrimary,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _salvando ? 'Salvando…' : 'Salvar alterações',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('edit-btn-voltar-perfil'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarEditPicker extends StatelessWidget {
  final Uint8List? avatarBytes;
  final String? fotoUrl;
  final String iniciais;
  final VoidCallback onAlterar;
  const _AvatarEditPicker({
    super.key,
    required this.avatarBytes,
    required this.fotoUrl,
    required this.iniciais,
    required this.onAlterar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sch = theme.colorScheme;
    final temFoto =
        avatarBytes != null ||
        (fotoUrl != null &&
            fotoUrl!.trim().isNotEmpty &&
            !fotoUrl!.startsWith('memory:'));
    return Semantics(
      label: 'Alterar foto de perfil',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(54),
        onTap: onAlterar,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sch.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sch.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [sch.primary, sch.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: sch.surface, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (avatarBytes != null)
                              Image.memory(
                                avatarBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    iniciais.isEmpty ? 'U' : iniciais,
                                    style: TextStyle(
                                      color: sch.onPrimary,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            else if (fotoUrl != null &&
                                fotoUrl!.trim().isNotEmpty &&
                                !fotoUrl!.trim().startsWith('memory:'))
                              Image.network(
                                fotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    iniciais.isEmpty ? 'U' : iniciais,
                                    style: TextStyle(
                                      color: sch.onPrimary,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Center(
                                child: Text(
                                  iniciais.isEmpty ? 'U' : iniciais,
                                  style: TextStyle(
                                    color: sch.onPrimary,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: sch.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: sch.surface, width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.24),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: sch.onPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temFoto ? 'Alterar foto' : 'Adicionar foto',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escolha na galeria ou tire uma nova foto',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: sch.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: const ValueKey('edit-avatar-btn-alterar'),
                      onPressed: onAlterar,
                      icon: const Icon(Icons.image_search_outlined, size: 18),
                      label: const Text('Selecionar foto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: sch.primary,
                        side: BorderSide(
                          color: sch.primary.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Secao({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sch = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: sch.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sch.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: sch.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
