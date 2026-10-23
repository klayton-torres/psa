import 'package:flutter_test/flutter_test.dart';
import 'package:peladeiros_sa/models/pelada_filter.dart';
import 'package:peladeiros_sa/services/data_service.dart';

void main() {
  group('PeladaFilter - localArena', () {
    test('isEmpty considera localArena', () {
      const vazio = PeladaFilter();
      expect(vazio.isEmpty, isTrue);

      const comArena = PeladaFilter(localArena: 'Arena');
      expect(comArena.isEmpty, isFalse);
    });

    test('activeFiltersCount incrementa quando localArena está preenchido', () {
      expect(const PeladaFilter().activeFiltersCount, 0);
      expect(const PeladaFilter(localArena: 'Arena').activeFiltersCount, 1);
    });

    test('copyWith atribui e limpa localArena', () {
      const base = PeladaFilter();
      final comArena = base.copyWith(localArena: 'Arena X');
      expect(comArena.localArena, 'Arena X');

      final limpo = comArena.copyWith(clearLocalArena: true);
      expect(limpo.localArena, isNull);
    });
  });

  group('DataService - filtro por Local/Arena', () {
    late DataService data;
    setUp(() => data = DataService());

    test('filtro exato "Arena Jardins" retorna apenas a pelada p1', () {
      data.setFilter(const PeladaFilter(localArena: 'Arena Jardins'));
      final resultado = data.filteredPeladas;
      expect(resultado, isNotEmpty);
      expect(
        resultado.every((p) => p.localArena.contains('Arena Jardins')),
        isTrue,
      );
      final ids = resultado.map((p) => p.id).toList();
      expect(ids, contains('p1'));
      expect(ids, isNot(contains('p2')));
    });

    test('filtro parcial "Arena" retorna múltiplas peladas com "Arena"', () {
      data.setFilter(const PeladaFilter(localArena: 'Arena'));
      final resultado = data.filteredPeladas;
      expect(resultado, isNotEmpty);
      expect(
        resultado.every((p) => p.localArena.toLowerCase().contains('arena')),
        isTrue,
      );
    });

    test('filtro por localArena inexistente retorna lista vazia', () {
      data.setFilter(const PeladaFilter(localArena: 'Nenhuma Arena Assim XX'));
      expect(data.filteredPeladas, isEmpty);
    });

    test('filtro por localArena combinado com estado funciona', () {
      data.setFilter(
        const PeladaFilter(localArena: 'Copacabana', estado: 'RJ'),
      );
      final resultado = data.filteredPeladas;
      expect(resultado.length, 1);
      expect(resultado.first.id, 'p3');
    });

    test('filtro por localArena é case-insensitive e trim', () {
      data.setFilter(const PeladaFilter(localArena: '  quadra AUGUSTA  '));
      final resultado = data.filteredPeladas;
      expect(resultado, isNotEmpty);
      expect(
        resultado.first.localArena.toLowerCase(),
        contains('quadra augusta'),
      );
    });
  });
}
