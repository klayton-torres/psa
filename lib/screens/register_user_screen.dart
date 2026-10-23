import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../utils/form_focus_helper.dart';
import '../widgets/date_input_field.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _primeiroNomeCtrl = TextEditingController();
  final _sobrenomeCtrl = TextEditingController();
  final _apelidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _senhaConfCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _dataNascCtrl = TextEditingController();
  DateTime? _dataNasc;
  bool _mostrarSenha = false;
  bool _mostrarConfSenha = false;

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _primeiroNomeCtrl.dispose();
    _sobrenomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _senhaConfCtrl.dispose();
    _telefoneCtrl.dispose();
    _dataNascCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!validateAndFocusFirstError(_formKey)) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final ok = await auth.signUpWithEmail(
      email: _emailCtrl.text.trim(),
      senha: _senhaCtrl.text.trim(),
      primeiroNome: _primeiroNomeCtrl.text.trim(),
      sobrenome: _sobrenomeCtrl.text.trim(),
      apelido: _apelidoCtrl.text.trim().isEmpty
          ? null
          : _apelidoCtrl.text.trim(),
      telefone: _telefoneCtrl.text.trim().isEmpty
          ? null
          : _telefoneCtrl.text.trim(),
      dataNascimento: _dataNasc,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Erro no cadastro'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    var format;
    var decoration;
    var label;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Crie sua conta', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Preencha os campos abaixo para começar',
                    style: TextStyle(color: theme.hintColor),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: primary.withAlphaSafe(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, color: primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dados de identificação',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _primeiroNomeCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Primeiro Nome *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              auth.validateNome(v, campo: 'primeiro nome'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sobrenomeCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Sobrenome *',
                          ),
                          validator: (v) =>
                              auth.validateNome(v, campo: 'sobrenome'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _apelidoCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Apelido (opcional)',
                            prefixIcon: Icon(Icons.tag_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DateInputField(
                          controller: _dataNascCtrl,
                          value: _dataNasc,
                          labelText: 'Data Nascimento',
                          hintText: 'dd/mm/aaaa',
                          prefixIcon: Icons.cake_outlined,
                          firstDate: DateTime(1930),
                          lastDate: DateTime.now(),
                          onChanged: (d) => setState(() => _dataNasc = d),
                          validator: auth.validateDataNascimento,
                          format: DateFormat('yyyy-MM-dd'),
                          decoration: const InputDecoration(),
                          dateLabel: 'Data de Nascimento',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _telefoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneMask],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '(00) 00000-0000',
                    ),
                    validator: auth.validateTelefone,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlphaSafe(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.login,
                          color: AppColors.info,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Acesso à conta',
                            style: TextStyle(
                              color: AppColors.info.withAlphaSafe(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-mail *',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'seu@email.com',
                    ),
                    validator: auth.validateEmail,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: !_mostrarSenha,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Senha *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      helperText: 'Mínimo 6 caracteres',
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _mostrarSenha = !_mostrarSenha),
                        icon: Icon(
                          _mostrarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: auth.validateSenha,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _senhaConfCtrl,
                    obscureText: !_mostrarConfSenha,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Senha *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _mostrarConfSenha = !_mostrarConfSenha,
                        ),
                        icon: Icon(
                          _mostrarConfSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Confirme sua senha';
                      }
                      if (v != _senhaCtrl.text) return 'Senhas não coincidem';
                      return auth.validateSenha(v);
                    },
                    onFieldSubmitted: (_) => _cadastrar(),
                  ),
                  const SizedBox(height: 26),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _cadastrar,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Criar Conta'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Já tem conta?'),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: const Text('Entrar'),
                      ),
                    ],
                  ),
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
}
