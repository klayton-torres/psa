import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pelada.dart';
import '../services/data_service.dart';
import '../widgets/pelada_card.dart';
import 'pelada_detail_screen.dart';

class PeladaListViewScreen extends StatefulWidget {
  final String? initialPeladaId;

  const PeladaListViewScreen({super.key, this.initialPeladaId});

  @override
  State<PeladaListViewScreen> createState() => _PeladaListViewScreenState();
}

class _PeladaListViewScreenState extends State<PeladaListViewScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final theme = Theme.of(context);
    final lista = List<Pelada>.of(data.filteredPeladas);
    final initialIndex = lista.indexWhere(
      (pelada) => pelada.id == widget.initialPeladaId,
    );
    if (initialIndex > 0) {
      final selected = lista.removeAt(initialIndex);
      lista.insert(0, selected);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos')),
      body: lista.isEmpty
          ? Center(
              child: Text(
                'Nenhuma pelada encontrada',
                style: theme.textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final p = lista[i];
                return PeladaCard(
                  pelada: p,
                  highlighted: p.id == widget.initialPeladaId,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PeladaDetailScreen(peladaId: p.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
