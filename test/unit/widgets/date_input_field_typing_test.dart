import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:peladeiros_sa/widgets/date_input_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TextEditingController controller;
  late DateFormat dateFormat;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    controller = TextEditingController();
    dateFormat = DateFormat('dd/MM/yyyy');
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> pumpDateField(
    WidgetTester tester, {
    DateTime? value,
    DateTime? firstDate,
    DateTime? lastDate,
    required void Function(DateTime?) onChanged,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    Key? fieldKey,
    bool showCalendarIcon = true,
  }) async {
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.binding.platformDispatcher.clearAllTestValues();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DateInputField(
                key: fieldKey,
                controller: controller,
                value: value,
                firstDate: firstDate ?? DateTime(1900),
                lastDate: lastDate ?? DateTime(2100),
                onChanged: onChanged,
                format: dateFormat,
                dateLabel: labelText ?? 'Data',
                decoration: const InputDecoration(),
                labelText: labelText ?? 'Data',
                hintText: hintText ?? 'dd/mm/aaaa',
                prefixIcon: prefixIcon ?? Icons.calendar_today,
                showCalendarIcon: showCalendarIcon,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DateInputField · Digitação Manual (não apaga texto parcial)', () {
    testWidgets(
      '1. Digitar "10" (dia incompleto) → controller TEXTO PRESERVADO, NÃO é apagado por onChanged',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(tester, onChanged: (d) => callbackRecebido = d);

        final campo = find.byType(TextFormField).first;
        expect(campo, findsOneWidget);
        expect(controller.text, '', reason: 'inicialmente vazio');

        await tester.enterText(campo, '10');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          controller.text,
          '10',
          reason:
              'Texto "10" digitado deve ser PRESERVADO no controller (BUG FIX: onChanged não pode limpar controller)',
        );
        expect(
          callbackRecebido,
          isNull,
          reason:
              'Data incompleta (apenas dia) → onChanged deve receber null (não dispara data válida)',
        );
      },
    );

    testWidgets(
      '2. Digitar "1001" (dia + mês parcial, sem ano) → controller preserva "10/01"',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(tester, onChanged: (d) => callbackRecebido = d);

        final campo = find.byType(TextFormField).first;
        await tester.enterText(campo, '1001');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          controller.text,
          '10/01',
          reason:
              'Máscara aplicou corretamente e o controller NÃO foi limpo pelo onChanged',
        );
        expect(
          callbackRecebido,
          isNull,
          reason: 'Data incompleta (sem ano) → callback onChanged = null',
        );
      },
    );

    testWidgets(
      '3. Digitar data COMPLETA VÁLIDA "10012000" → onChanged recebe DateTime correto + texto formatado',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(tester, onChanged: (d) => callbackRecebido = d);

        final campo = find.byType(TextFormField).first;
        await tester.enterText(campo, '10012000');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          controller.text,
          '10/01/2000',
          reason: 'Máscara aplicou "10/01/2000" corretamente',
        );
        expect(
          callbackRecebido,
          isNotNull,
          reason: 'Data completa válida → onChanged recebe DateTime não-nulo',
        );
        expect(callbackRecebido!.year, 2000);
        expect(callbackRecebido!.month, 1);
        expect(callbackRecebido!.day, 10);
      },
    );

    testWidgets(
      '4. Digitar data COMPLETA mas INVÁLIDA "30022000" (30/fev) → controller preserva texto, onChanged = null',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(tester, onChanged: (d) => callbackRecebido = d);

        final campo = find.byType(TextFormField).first;
        await tester.enterText(campo, '30022000');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          controller.text,
          '30/02/2000',
          reason:
              'Mesmo data inválida (30 fev) o TEXTO deve permanecer no controller para o usuário corrigir',
        );
        expect(
          callbackRecebido,
          isNull,
          reason: 'Data inválida → callback onChanged = null',
        );
      },
    );

    testWidgets(
      '5. Digitar data VÁLIDA, depois APAGAR parcialmente → controller aceita estado parcial',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(tester, onChanged: (d) => callbackRecebido = d);

        final campo = find.byType(TextFormField).first;

        await tester.enterText(campo, '15061990');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        expect(controller.text, '15/06/1990');
        expect(callbackRecebido, DateTime(1990, 6, 15));

        await tester.enterText(campo, '1506');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          controller.text,
          '15/06',
          reason:
              'Texto parcial "15/06" deve ser PRESERVADO após apagar o ano (não pode limpar tudo)',
        );
      },
    );
  });

  group('DateInputField · Caracteres Bloqueados / Máscara', () {
    testWidgets(
      '6. Bloqueia caracteres não-numéricos (letras/símbolos) via formatter',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(tester, onChanged: (d) => callbackRecebido = d);

        final campo = find.byType(TextFormField).first;
        await tester.enterText(campo, 'a1b0c./-!@#01d2e0f2g0');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          controller.text,
          '10/01/2020',
          reason:
              'Apenas dígitos passam; caracteres alfanuméricos e símbolos são filtrados por FilteringTextInputFormatter.digitsOnly',
        );
      },
    );

    testWidgets(
      '7. Limita a 10 caracteres (8 dígitos + 2 separadores: dd/mm/aaaa)',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(tester, onChanged: (d) => callbackRecebido = d);

        final campo = find.byType(TextFormField).first;
        await tester.enterText(campo, '12345678901234567890');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          controller.text.length,
          10,
          reason: 'Campo de data deve limitar a 10 caracteres com máscara',
        );
        expect(controller.text, '12/34/5678');
      },
    );
  });

  group('DateInputField · Valor Inicial + DatePicker', () {
    testWidgets(
      '8. value pré-definida → controller mostra texto formatado corretamente',
      (tester) async {
        DateTime? callbackRecebido;
        final inicial = DateTime(1985, 12, 25);
        await pumpDateField(
          tester,
          value: inicial,
          onChanged: (d) => callbackRecebido = d,
        );

        expect(
          controller.text,
          '25/12/1985',
          reason:
              'value fornecido → campo já abre com data formatada no controller',
        );
        expect(
          callbackRecebido,
          isNull,
          reason: 'Valor inicial não dispara onChanged (apenas interação)',
        );
      },
    );

    testWidgets(
      '9. Ícone do calendário (calendar_month_outlined) renderiza com tooltip correto',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(
          tester,
          onChanged: (d) => callbackRecebido = d,
        );

        final iconBtn = find.byIcon(Icons.calendar_month_outlined).first;
        expect(iconBtn, findsOneWidget);
        final tooltipAncestor = find.ancestor(
          of: iconBtn,
          matching: find.byType(Tooltip),
        );
        expect(tooltipAncestor, findsWidgets);
        final tt = tester.widget<Tooltip>(tooltipAncestor.first);
        expect(
          tt.message,
          'Selecionar data no calendário',
          reason: 'Tooltip do ícone calendário deve estar correto',
        );
      },
    );
  });

  group('DateInputField · Intervalo de Datas (firstDate / lastDate)', () {
    testWidgets(
      '10. firstDate = 01/01/2000 → data ANTERIOR 31/12/1999 não é aceita por onChanged',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(
          tester,
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime(2030, 12, 31),
          onChanged: (d) => callbackRecebido = d,
        );

        final campo = find.byType(TextFormField).first;
        await tester.enterText(campo, '31121999');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          controller.text,
          '31/12/1999',
          reason:
              'Texto PERMANECE no controller (usuário pode corrigir) - NÃO pode limpar',
        );
        expect(
          callbackRecebido,
          isNull,
          reason: 'Data anterior a firstDate → onChanged = null',
        );
      },
    );

    testWidgets(
      '11. lastDate = 31/12/2030 → data POSTERIOR 01/01/2031 não é aceita',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(
          tester,
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime(2030, 12, 31),
          onChanged: (d) => callbackRecebido = d,
        );

        final campo = find.byType(TextFormField).first;
        await tester.enterText(campo, '01012031');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(controller.text, '01/01/2031');
        expect(callbackRecebido, isNull);
      },
    );
  });

  group('DateInputField · Caso Especial: Cadastro Juiz (Data de Nascimento)', () {
    testWidgets(
      '12. Cenário real: Usuário digita data de nascimento caractere por caractere → SEM perdas intermediárias',
      (tester) async {
        DateTime? callbackRecebido;
        await pumpDateField(
          tester,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          prefixIcon: Icons.cake_outlined,
          labelText: 'Data de Nascimento',
          onChanged: (d) => callbackRecebido = d,
        );

        final campo = find.byType(TextFormField).first;

        final etapas = <List<String>>[
          ['0', '0'],
          ['05', '05'],
          ['050', '05/0'],
          ['0503', '05/03'],
          ['05031', '05/03/1'],
          ['050319', '05/03/19'],
          ['0503199', '05/03/199'],
          ['05031997', '05/03/1997'],
        ];

        for (int i = 0; i < etapas.length; i++) {
          final entrada = etapas[i][0];
          final esperado = etapas[i][1];
          await tester.enterText(campo, entrada);
          await tester.pumpAndSettle(const Duration(milliseconds: 150));
          expect(
            controller.text,
            esperado,
            reason:
                'Etapa ${i + 1}: entrada "$entrada" → esperado "$esperado", mas obteve "${controller.text}". O texto está sendo apagado!',
          );
        }

        expect(
          callbackRecebido,
          DateTime(1997, 3, 5),
          reason: 'Data final válida: 05/03/1997',
        );
      },
    );
  });
}
