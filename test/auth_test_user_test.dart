import 'package:flutter_test/flutter_test.dart';
import 'package:peladeiros_sa/services/auth_service.dart';

void main() {
  test('Login com usuário demo funciona (modo offline)', () async {
    final auth = AuthService();

    final ok = await auth.signInWithEmail(
      AuthService.demoUserEmail,
      AuthService.demoUserPassword,
    );

    expect(ok, isTrue);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser?.email, AuthService.demoUserEmail);
    expect(auth.initialized, isTrue);
  });

  test('Validação de e-mail funciona', () {
    final auth = AuthService();
    expect(auth.validateEmail(''), isNotNull);
    expect(auth.validateEmail('invalido'), isNotNull);
    expect(auth.validateEmail('usuario@teste.com'), isNull);
  });

  test('Validação de senha funciona', () {
    final auth = AuthService();
    expect(auth.validateSenha(''), isNotNull);
    expect(auth.validateSenha('12345'), isNotNull);
    expect(auth.validateSenha('123456'), isNull);
  });

  test('mockLoginDemo autentica usuário demo', () {
    final auth = AuthService();
    auth.mockLoginDemo();
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser?.primeiroNome, 'João');
    expect(auth.currentUser?.modalidadesPraticadas.isNotEmpty, isTrue);
  });

  test('Logout limpa usuário atual', () async {
    final auth = AuthService();
    auth.mockLoginDemo();
    expect(auth.isAuthenticated, isTrue);
    await auth.signOut();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.currentUser, isNull);
  });
}
