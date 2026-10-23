import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../utils/form_focus_helper.dart';
import 'home_screen.dart';
import 'register_user_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _recoveryEmailCtrl = TextEditingController();
  bool _mostrarSenha = false;
  bool _recoveryMode = false;
  final _recoveryFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _recoveryEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!validateAndFocusFirstError(_formKey)) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final ok = await auth.signInWithEmail(
      _emailCtrl.text.trim(),
      _senhaCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Erro ao entrar'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _entrarGoogle() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _entrarDemo() {
    Provider.of<AuthService>(context, listen: false).mockLoginDemo();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _enviarRecuperacao() async {
    if (!validateAndFocusFirstError(_recoveryFormKey)) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final ok = await auth.sendPasswordResetEmail(
      _recoveryEmailCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-mail de recuperação enviado! Verifique sua caixa de entrada.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _recoveryMode = false;
        _emailCtrl.text = _recoveryEmailCtrl.text.trim();
        _recoveryEmailCtrl.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Erro ao enviar recuperação'),
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

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _recoveryMode
                    ? _buildRecoveryView(auth, theme, primary)
                    : _buildLoginView(auth, theme, primary),
              ),
            ),
            if (auth.isLoading)
              Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginView(AuthService auth, ThemeData theme, Color primary) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primary.withAlphaSafe(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_soccer,
              size: 54,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Peladeiros S/A',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: primary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Garanta o quórum da sua pelada!',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Text('Entrar', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Conecte-se e encontre peladas perto de você.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'seu@email.com',
            ),
            validator: (v) => auth.validateEmail(v),
            onFieldSubmitted: (_) => _entrar(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _senhaCtrl,
            obscureText: !_mostrarSenha,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                icon: Icon(
                  _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            validator: (v) => auth.validateSenha(v),
            onFieldSubmitted: (_) => _entrar(),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () => setState(() {
                      _recoveryMode = true;
                      if (_emailCtrl.text.isNotEmpty) {
                        _recoveryEmailCtrl.text = _emailCtrl.text;
                      }
                    }),
              child: const Text('Esqueci minha senha'),
            ),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _entrar,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Entrar com E-mail'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: auth.isLoading ? null : _entrarGoogle,
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Continuar com Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: auth.isLoading ? null : _entrarDemo,
            child: const Text('Entrar no modo demo (teste)'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ainda não tem conta?'),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterUserScreen()),
                ),
                child: const Text('Cadastre-se'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryView(AuthService auth, ThemeData theme, Color primary) {
    return Form(
      key: _recoveryFormKey,
      child: Column(
        key: const ValueKey('recovery'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withAlphaSafe(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_outlined,
              size: 54,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Recuperar Senha',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: primary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Text('Esqueci minha senha', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Informe seu e-mail para receber o link de redefinição de senha.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _recoveryEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'E-mail cadastrado',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'seu@email.com',
            ),
            validator: (v) => auth.validateEmail(v),
            onFieldSubmitted: (_) => _enviarRecuperacao(),
          ),
          const SizedBox(height: 26),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _enviarRecuperacao,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Enviar link de recuperação'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: auth.isLoading
                ? null
                : () => setState(() {
                    _recoveryMode = false;
                    _recoveryEmailCtrl.clear();
                  }),
            icon: const Icon(Icons.arrow_back_outlined, size: 18),
            label: const Text('Voltar para o login'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Lembrou a senha?'),
              TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => setState(() {
                        _recoveryMode = false;
                        _recoveryEmailCtrl.clear();
                      }),
                child: const Text('Entrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
