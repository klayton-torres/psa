import 'package:flutter_test/flutter_test.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

DateTime? _parseDate(
  String text,
  MaskTextInputFormatter mask, {
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  firstDate ??= DateTime(1900);
  lastDate ??= DateTime(2100);
  final unmasked = mask.unmaskText(text);
  if (unmasked.length != 8) return null;
  final dia = int.tryParse(unmasked.substring(0, 2));
  final mes = int.tryParse(unmasked.substring(2, 4));
  final ano = int.tryParse(unmasked.substring(4, 8));
  if (dia == null || mes == null || ano == null) return null;
  try {
    final candidate = DateTime(ano, mes, dia);
    if (candidate.day != dia || candidate.month != mes) return null;
    if (ano < 1900) return null;
    final lastDateOnly = DateTime(
      lastDate.year,
      lastDate.month,
      lastDate.day,
      23,
      59,
      59,
    );
    final firstDateOnly = DateTime(
      firstDate.year,
      firstDate.month,
      firstDate.day,
    );
    if (candidate.isAfter(lastDateOnly)) return null;
    if (candidate.isBefore(firstDateOnly)) return null;
    return candidate;
  } catch (_) {
    return null;
  }
}

void main() {
  group('Máscara de data dd/mm/aaaa', () {
    final mask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );

    test('Aplica máscara corretamente durante digitação', () {
      expect(
        mask
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '0'),
            )
            .text,
        '0',
      );
      expect(
        mask
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '01'),
            )
            .text,
        '01',
      );
      expect(
        mask
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '010'),
            )
            .text,
        '01/0',
      );
      expect(
        mask
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '0101'),
            )
            .text,
        '01/01',
      );
      expect(
        mask
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '01012'),
            )
            .text,
        '01/01/2',
      );
      expect(
        mask
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '0101202'),
            )
            .text,
        '01/01/202',
      );
      expect(
        mask
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '01012026'),
            )
            .text,
        '01/01/2026',
      );
    });

    test('Limita a 10 caracteres com máscara', () {
      final result = mask.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '01012026123456'),
      );
      expect(result.text.length, 10);
      expect(result.text, '01/01/2026');
    });

    test('Bloqueia caracteres não numéricos', () {
      final result = mask.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '01a01b2026'),
      );
      expect(result.text, '01/01/2026');
      expect(mask.unmaskText(result.text), '01012026');
    });
  });

  group('Parsing e validação de datas', () {
    final mask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );

    test('Datas válidas são parseadas corretamente', () {
      expect(_parseDate('01/01/2026', mask), DateTime(2026, 1, 1));
      expect(_parseDate('31/12/2025', mask), DateTime(2025, 12, 31));
      expect(_parseDate('15/06/1990', mask), DateTime(1990, 6, 15));
    });

    test('Valida dias inválidos por mês', () {
      expect(_parseDate('31/04/2026', mask), isNull);
      expect(_parseDate('31/06/2026', mask), isNull);
      expect(_parseDate('31/09/2026', mask), isNull);
      expect(_parseDate('31/11/2026', mask), isNull);
      expect(_parseDate('32/01/2026', mask), isNull);
      expect(_parseDate('00/01/2026', mask), isNull);
    });

    test('Valida meses inválidos', () {
      expect(_parseDate('15/00/2026', mask), isNull);
      expect(_parseDate('15/13/2026', mask), isNull);
    });

    test('Valida fevereiro - ano não bissexto', () {
      expect(_parseDate('29/02/2023', mask), isNull);
      expect(_parseDate('28/02/2023', mask), DateTime(2023, 2, 28));
    });

    test(
      'Valida fevereiro - ano bissexto (divisível por 4 e não 100, ou por 400)',
      () {
        expect(_parseDate('29/02/2024', mask), DateTime(2024, 2, 29));
        expect(_parseDate('29/02/2000', mask), DateTime(2000, 2, 29));
        expect(_parseDate('29/02/1900', mask), isNull);
      },
    );

    test('Bloqueia anos anteriores a 1900', () {
      expect(_parseDate('01/01/1899', mask), isNull);
      expect(_parseDate('01/01/1900', mask), DateTime(1900, 1, 1));
    });

    test('Respeita firstDate customizado', () {
      final hoje = DateTime.now();
      final ontem = hoje.subtract(const Duration(days: 1));
      expect(
        _parseDate(
          '${ontem.day.toString().padLeft(2, '0')}/${ontem.month.toString().padLeft(2, '0')}/${ontem.year}',
          mask,
          firstDate: hoje,
        ),
        isNull,
      );
      expect(
        _parseDate(
          '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}',
          mask,
          firstDate: hoje,
        ),
        DateTime(hoje.year, hoje.month, hoje.day),
      );
    });

    test('Respeita lastDate customizado (ex: não permite data futura)', () {
      final hoje = DateTime.now();
      final amanha = hoje.add(const Duration(days: 1));
      expect(
        _parseDate(
          '${amanha.day.toString().padLeft(2, '0')}/${amanha.month.toString().padLeft(2, '0')}/${amanha.year}',
          mask,
          lastDate: DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59),
        ),
        isNull,
      );
    });

    test('Entrada incompleta retorna null', () {
      expect(_parseDate('01/01/20', mask), isNull);
      expect(_parseDate('01/01/', mask), isNull);
      expect(_parseDate('01/', mask), isNull);
      expect(_parseDate('', mask), isNull);
    });
  });

  group('Validação de intervalos de datas', () {
    final mask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );
    final hoje = DateTime.now();
    final primeiroDeJaneiro = DateTime(hoje.year, 1, 1);

    test('Data fim não pode ser anterior ao início', () {
      final dataInicio = _parseDate('10/01/2026', mask)!;
      final dataFimTexto = '09/01/2026';
      final dataFim = _parseDate(dataFimTexto, mask, firstDate: dataInicio);
      expect(dataFim, isNull);
    });

    test('Data fim igual ao início é permitida', () {
      final dataInicio = _parseDate('10/01/2026', mask)!;
      final dataFim = _parseDate('10/01/2026', mask, firstDate: dataInicio);
      expect(dataFim, equals(dataInicio));
    });

    test('Data inicial não pode ser anterior a hoje (peladas)', () {
      final ontem = hoje.subtract(const Duration(days: 1));
      final formatted =
          '${ontem.day.toString().padLeft(2, '0')}/${ontem.month.toString().padLeft(2, '0')}/${ontem.year}';
      final result = _parseDate(
        formatted,
        mask,
        firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      );
      expect(result, isNull);
    });
  });

  group('Bugs corrigidos: comparação por valor e normalização de horários', () {
    final mask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );

    test('firstDate com horário da tarde NÃO invalida a data de hoje', () {
      final hojeComHora = DateTime.now().add(const Duration(hours: 14));
      final hojeFormatado =
          '${hojeComHora.day.toString().padLeft(2, '0')}/${hojeComHora.month.toString().padLeft(2, '0')}/${hojeComHora.year}';
      final result = _parseDate(
        hojeFormatado,
        mask,
        firstDate: hojeComHora,
        lastDate: hojeComHora.add(const Duration(days: 30)),
      );
      expect(result, isNotNull);
      expect(result!.year, hojeComHora.year);
      expect(result.month, hojeComHora.month);
      expect(result.day, hojeComHora.day);
    });

    test('lastDate com horário da manhã NÃO invalida o último dia', () {
      final ultimoDia = DateTime(2026, 12, 31, 10, 0, 0);
      final result = _parseDate(
        '31/12/2026',
        mask,
        firstDate: DateTime(2026, 1, 1),
        lastDate: ultimoDia,
      );
      expect(result, equals(DateTime(2026, 12, 31)));
    });

    test('amanhã é permitido mesmo lastDate sendo amanhã às 00:01', () {
      final amanha = DateTime.now().add(const Duration(days: 1));
      final amanhaFormatado =
          '${amanha.day.toString().padLeft(2, '0')}/${amanha.month.toString().padLeft(2, '0')}/${amanha.year}';
      final lastDateAmanhaCedo = DateTime(
        amanha.year,
        amanha.month,
        amanha.day,
        0,
        1,
      );
      final result = _parseDate(
        amanhaFormatado,
        mask,
        firstDate: DateTime.now(),
        lastDate: lastDateAmanhaCedo,
      );
      expect(result, isNotNull);
      expect(result!.day, amanha.day);
    });

    test(
      'comparação de datas iguais com horários diferentes considera mesma data',
      () {
        final d1 = DateTime(2026, 8, 20, 10, 30);
        final d2 = DateTime(2026, 8, 20, 22, 45);
        bool isSameDate(DateTime? a, DateTime? b) {
          if (a == null && b == null) return true;
          if (a == null || b == null) return false;
          return a.year == b.year && a.month == b.month && a.day == b.day;
        }

        expect(isSameDate(d1, d2), isTrue);
        expect(
          isSameDate(DateTime(2026, 8, 20), DateTime(2026, 8, 21)),
          isFalse,
        );
        expect(isSameDate(null, null), isTrue);
        expect(isSameDate(DateTime(2026, 1, 1), null), isFalse);
      },
    );

    test('ano bissexto 2000 funciona (divisível por 400)', () {
      expect(_parseDate('29/02/2000', mask), DateTime(2000, 2, 29));
    });

    test('ano 1900 NÃO é bissexto (século não divisível por 400)', () {
      expect(_parseDate('29/02/1900', mask), isNull);
    });

    test('mês 02 dia 30 é inválido em qualquer ano', () {
      expect(_parseDate('30/02/2024', mask), isNull);
      expect(_parseDate('30/02/2025', mask), isNull);
    });
  });
}
