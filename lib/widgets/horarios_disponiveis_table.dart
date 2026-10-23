import 'package:flutter/material.dart';

class HorariosDisponiveisTable extends StatelessWidget {
  const HorariosDisponiveisTable({
    super.key,
    required this.horariosSelecionados,
    this.onToggle,
    this.mostrarAviso = false,
  });

  final Set<String> horariosSelecionados;
  final ValueChanged<String>? onToggle;
  final bool mostrarAviso;

  static const List<(String, String)> _dias = [
    ('dom', 'Dom'),
    ('seg', 'Seg'),
    ('ter', 'Ter'),
    ('qua', 'Qua'),
    ('qui', 'Qui'),
    ('sex', 'Sex'),
    ('sab', 'Sáb'),
  ];

  static const List<(String, String, IconData)> _periodos = [
    ('manha', 'Manhã', Icons.wb_sunny_outlined),
    ('tarde', 'Tarde', Icons.wb_twilight_outlined),
    ('noite', 'Noite', Icons.nightlight_round),
  ];

  String _chave(String dia, String periodo) => '${dia}_$periodo';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onToggle = this.onToggle;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 42),
            for (final periodo in _periodos)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Icon(periodo.$3, size: 18, color: scheme.primary),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          periodo.$2,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final dia in _dias) ...[
          Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  dia.$2,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final periodo in _periodos)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _HorarioCell(
                      keyId: _chave(dia.$1, periodo.$1),
                      selecionado: horariosSelecionados.contains(
                        _chave(dia.$1, periodo.$1),
                      ),
                      habilitado: onToggle != null,
                      onTap: onToggle == null
                          ? null
                          : () => onToggle(_chave(dia.$1, periodo.$1)),
                    ),
                  ),
                ),
            ],
          ),
          if (dia != _dias.last) const SizedBox(height: 7),
        ],
        if (mostrarAviso) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '* Confirme os horários com o responsável.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.tertiary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HorarioCell extends StatelessWidget {
  const _HorarioCell({
    super.key,
    required this.keyId,
    required this.selecionado,
    required this.habilitado,
    required this.onTap,
  });

  final String keyId;
  final bool selecionado;
  final bool habilitado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const available = Color(0xFF2E7D32);
    const unavailable = Color(0xFFD32F2F);
    final color = selecionado ? available : unavailable;
    return Semantics(
      button: habilitado,
      checked: selecionado,
      label: keyId.replaceAll('_', ' '),
      child: Tooltip(
        message: '${keyId.replaceAll('_', ' ')}: '
            '${selecionado ? 'disponível' : 'indisponível'}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 42,
            decoration: BoxDecoration(
              color: selecionado
                  ? available.withValues(alpha: 0.12)
                  : unavailable.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: selecionado ? 0.95 : 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selecionado
                      ? available
                      : unavailable.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
