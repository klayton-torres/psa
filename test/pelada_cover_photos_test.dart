import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:peladeiros_sa/models/enums.dart';
import 'package:peladeiros_sa/models/pelada.dart';
import 'package:peladeiros_sa/screens/pelada_detail_screen.dart';
import 'package:peladeiros_sa/services/data_service.dart';
import 'package:peladeiros_sa/widgets/pelada_card.dart';

const _oneByOnePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ZkAAAAASUVORK5CYII=';

Pelada _peladaComFotos({required int fotos}) {
  final foto = PeladaCapaFoto.fromBytes(
    bytes: base64Decode(_oneByOnePngBase64),
    mimeType: 'image/png',
  );

  return Pelada(
    id: 'p1',
    nome: 'Pelada Teste',
    organizadorId: 'u1',
    organizadorNome: 'Organizador',
    organizadorCpf: '000.000.000-00',
    contato: '(11) 99999-9999',
    dataInicio: DateTime(2030, 1, 1),
    dataFim: DateTime(2030, 1, 1),
    horaInicio: const TimeOfDay(hour: 20, minute: 0),
    horaFim: const TimeOfDay(hour: 22, minute: 0),
    taxa: 0,
    modalidade: Modalidade.society,
    tipoGrama: TipoGrama.sintetica,
    tipoChuteira: TipoChuteira.livre,
    categoria: CategoriaPelada.livreAdulto,
    categoriaGenero: CategoriaGenero.masc,
    corColeteIndex: 0,
    endereco: 'Rua X',
    localArena: 'Arena Teste',
    estado: 'SP',
    cidade: 'São Paulo',
    bairro: 'Centro',
    status: StatusPelada.ativa,
    fotosCapa: List.generate(fotos, (_) => foto),
    createdAt: DateTime(2030, 1, 1),
    updatedAt: DateTime(2030, 1, 1),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR');
  });

  test('DataService rejeita cadastro com mais de 2 fotos de capa', () async {
    final ds = DataService();
    final pelada = _peladaComFotos(fotos: 3);
    final res = await ds.cadastrarPelada(pelada);
    expect(res, isNull);
    expect(ds.errorMessage, contains('Limite'));
  });

  testWidgets('PeladaCard exibe foto de capa', (WidgetTester tester) async {
    final ds = DataService();
    final pelada = _peladaComFotos(fotos: 2);

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: ds,
        child: MaterialApp(
          home: Scaffold(body: PeladaCard(pelada: pelada)),
        ),
      ),
    );

    final imagens = find.byWidgetPredicate(
      (w) => w is Image && w.image is MemoryImage,
    );
    expect(imagens, findsWidgets);
  });

  testWidgets('Tela de detalhe exibe fotos de capa', (
    WidgetTester tester,
  ) async {
    final pelada = _peladaComFotos(fotos: 2);
    final ds = DataService();
    final future = ds.cadastrarPelada(pelada);
    await tester.pump(const Duration(milliseconds: 900));
    await future;

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: ds,
        child: const MaterialApp(home: PeladaDetailScreen(peladaId: 'p1')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(PageView), findsOneWidget);

    final imagens = find.byWidgetPredicate(
      (w) => w is Image && w.image is MemoryImage,
    );
    expect(imagens, findsWidgets);
  });
}
