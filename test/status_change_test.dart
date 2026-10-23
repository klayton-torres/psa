import 'package:flutter_test/flutter_test.dart';
import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/services/data_service.dart';

void main() {
  test('emite notificação quando status muda para Suspensa', () async {
    final data = DataService();
    final original = data.getPeladaById('p1')!;

    final future = data.statusChanges.firstWhere(
      (e) => e.peladaId == original.id && e.newStatus == StatusPelada.suspensa,
    );

    await data.atualizarPelada(
      original.copyWith(status: StatusPelada.suspensa, statusMotivo: 'Chuva'),
    );

    final event = await future;
    expect(event.oldStatus, StatusPelada.ativa);
    expect(event.newStatus, StatusPelada.suspensa);
    expect(event.motivo, 'Chuva');
  });

  test('emite notificação quando status muda para Bloqueada', () async {
    final data = DataService();
    final original = data.getPeladaById('p2')!;

    final future = data.statusChanges.firstWhere(
      (e) => e.peladaId == original.id && e.newStatus == StatusPelada.bloqueada,
    );

    await data.atualizarPelada(
      original.copyWith(
        status: StatusPelada.bloqueada,
        statusMotivo: 'Regra violada',
      ),
    );

    final event = await future;
    expect(event.oldStatus, StatusPelada.ativa);
    expect(event.newStatus, StatusPelada.bloqueada);
    expect(event.motivo, 'Regra violada');
  });

  test('emite notificação quando status muda para Cancelada', () async {
    final data = DataService();
    final original = data.getPeladaById('p3')!;

    final future = data.statusChanges.firstWhere(
      (e) => e.peladaId == original.id && e.newStatus == StatusPelada.cancelada,
    );

    await data.atualizarPelada(
      original.copyWith(
        status: StatusPelada.cancelada,
        statusMotivo: 'Campo indisponível',
      ),
    );

    final event = await future;
    expect(event.oldStatus, StatusPelada.ativa);
    expect(event.newStatus, StatusPelada.cancelada);
    expect(event.motivo, 'Campo indisponível');
  });
}

