import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:peladeiros_sa/widgets/profile_sports_rail_menu.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_colors.dart';
import '../models/enums.dart';
import '../models/pelada.dart';
import '../models/participation.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/title_case_input_formatter.dart';
import '../utils/form_focus_helper.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'campos_arenas_screen.dart';
import 'home_screen.dart';
import 'minhas_peladas_screen.dart';
import 'pelada_detail_screen.dart';
import '../utils/profile_navigation_helper.dart';

class ParticipantsScreen extends StatefulWidget {
  final String peladaId;

  const ParticipantsScreen({super.key, required this.peladaId});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  final _motivoBloqueioCtrl = TextEditingController();
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  bool _isLoading = false;
  String? _erro;
  bool _mostrarSomentePendentesPagamento = false;

  final _avulsoNomeCtrl = TextEditingController();
  final _avulsoApelidoCtrl = TextEditingController();
  final _avulsoIdadeCtrl = TextEditingController();
  final _avulsoTelefoneCtrl = TextEditingController();
  final _avulsoContatoEmergenciaCtrl = TextEditingController();
  final _avulsoFormKey = GlobalKey<FormState>();
  PosicaoAtleta? _avulsoPosicao;
  bool _avulsoAutovalidar = false;
  final Random _rnd = Random();

  @override
  void dispose() {
    _motivoBloqueioCtrl.dispose();
    _avulsoNomeCtrl.dispose();
    _avulsoApelidoCtrl.dispose();
    _avulsoIdadeCtrl.dispose();
    _avulsoTelefoneCtrl.dispose();
    _avulsoContatoEmergenciaCtrl.dispose();
    super.dispose();
  }

  void _setLoading(bool v) => setState(() => _isLoading = v);
  void _setErro(String? v) => setState(() => _erro = v);

  Future<void> _tratarErro(Future<void> Function() fn) async {
    try {
      _setErro(null);
      _setLoading(true);
      await fn();
    } catch (e) {
      _setErro('Erro inesperado: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _aviso(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _compartilharLista({
    required BuildContext shareContext,
    required Pelada pelada,
    required List<Participation> participantes,
    required DataService data,
  }) async {
    String hora(TimeOfDay value) =>
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    final linhasParticipantes = participantes.isEmpty
        ? 'Nenhum participante registrado.'
        : participantes
              .map((p) {
                final profile = data.getUserProfile(p.usuarioId);
                final idade =
                    p.usuarioIdade ??
                    profile?.idade ??
                    int.tryParse(
                      RegExp(
                            r'Idade:\s*(\d+)\s*anos',
                            caseSensitive: false,
                          ).firstMatch(p.observacao ?? '')?.group(1) ??
                          '',
                    );
                final posicao =
                    p.usuarioPosicaoPrincipal?.label ??
                    profile?.posicaoPrincipal?.label ??
                    'Não informada';
                final nome = p.usuarioNome.trim().isEmpty
                    ? (p.usuarioApelido?.trim().isNotEmpty == true
                          ? p.usuarioApelido!.trim()
                          : 'Nome não informado')
                    : p.usuarioNome.trim();

                return '$nome, ${idade == null ? 'Não informada' : '$idade anos'}, $posicao';
              })
              .join('\n');

    final texto = [
      'LISTA DE PARTICIPANTES — ${pelada.nome}',
      'Responsável: ${pelada.organizadorNome}',
      'Data: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(pelada.dataInicio)}',
      'Horário: ${hora(pelada.horaInicio)} às ${hora(pelada.horaFim)}',
      '',
      linhasParticipantes,
      '',
      'Acesse o aplicativo: https://peladeiros-sa.com.br',
    ].join('\n');

    try {
      final renderObject = shareContext.findRenderObject();
      final sharePositionOrigin = renderObject is RenderBox
          ? renderObject.localToGlobal(Offset.zero) & renderObject.size
          : null;
      await SharePlus.instance.share(
        ShareParams(
          title: 'Lista de participantes — ${pelada.nome}',
          subject: 'Participantes de ${pelada.nome}',
          text: texto,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (error) {
      _aviso('Não foi possível compartilhar a lista: $error', isError: true);
    }
  }

  void _voltarParaDetalhes() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PeladaDetailScreen(peladaId: widget.peladaId),
        ),
      );
    }
  }

  void _abrirMinhasPeladas() {
    unawaited(HapticFeedback.selectionClick());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MinhasPeladasScreen()),
      (route) => false,
    );
  }

  void _resetFormAvulso() {
    _avulsoNomeCtrl.clear();
    _avulsoApelidoCtrl.clear();
    _avulsoIdadeCtrl.clear();
    _avulsoTelefoneCtrl.clear();
    _avulsoContatoEmergenciaCtrl.clear();
    _avulsoPosicao = null;
    _avulsoAutovalidar = false;
  }

  String? _validarNomeAvulso(String? v) {
    final nome = (v ?? '').trim();
    if (nome.isEmpty) return 'Campo obrigatório.';
    if (nome.length < 2) return 'Informe ao menos 2 caracteres.';
    if (nome.length > 80) return 'Limite de 80 caracteres.';
    return null;
  }

  String? _validarIdadeAvulso(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return 'Campo obrigatório.';
    final idade = int.tryParse(raw);
    if (idade == null) return 'Informe um número válido.';
    if (idade < 5) return 'Idade mínima permitida: 5 anos.';
    if (idade > 90) return 'Idade máxima permitida: 90 anos.';
    return null;
  }

  String? _validarPosicaoAvulso(PosicaoAtleta? v) {
    if (v == null) return 'Selecione a posição principal.';
    return null;
  }

  Future<void> _abrirModalAvulso({
    required Pelada pelada,
    required DataService data,
  }) async {
    if (!pelada.temVagas) {
      _aviso(
        'Quórum máximo já atingido (${pelada.participantesConfirmados}/${pelada.quorumMaximoEfetivo}). Não é possível adicionar novos participantes.',
        isError: true,
      );
      return;
    }
    _resetFormAvulso();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctxDialog) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void rebuildDialog(void Function() fn) => setDialogState(fn);
            return AlertDialog(
              scrollable: true,
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              title: Row(
                children: [
                  const Icon(
                    Icons.person_add_alt_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Novo Participante Avulso',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Semantics(
                    label: 'Fechar formulário de avulso',
                    child: Tooltip(
                      message: 'Fechar',
                      child: IconButton(
                        splashRadius: 18,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(ctxDialog).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: _avulsoFormKey,
                autovalidateMode: _avulsoAutovalidar
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: const Key('avulso_nome'),
                      controller: _avulsoNomeCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        TitleCaseInputFormatter(),
                        LengthLimitingTextInputFormatter(80),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        hintText: 'Nome completo do participante',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validarNomeAvulso,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('avulso_apelido'),
                      controller: _avulsoApelidoCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        TitleCaseInputFormatter(),
                        LengthLimitingTextInputFormatter(40),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Apelido',
                        hintText: 'Como é conhecido (opcional)',
                        prefixIcon: Icon(Icons.alternate_email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('avulso_idade'),
                      controller: _avulsoIdadeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Idade *',
                        hintText: 'Ex.: 28 (5 a 90 anos)',
                        prefixIcon: Icon(Icons.cake_outlined),
                        suffixText: 'anos',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validarIdadeAvulso,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('avulso_telefone'),
                      controller: _avulsoTelefoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        hintText: 'DDD + número (opcional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('avulso_contato_emergencia'),
                      controller: _avulsoContatoEmergenciaCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Contato de emergência',
                        hintText: 'DDD + número (opcional)',
                        prefixIcon: Icon(Icons.emergency_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PosicaoAtleta>(
                      key: const Key('avulso_posicao'),
                      initialValue: _avulsoPosicao,
                      decoration: const InputDecoration(
                        labelText: 'Posição principal *',
                        prefixIcon: Icon(Icons.sports_soccer_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      validator: _validarPosicaoAvulso,
                      isExpanded: true,
                      items: PosicaoAtleta.values
                          .map(
                            (p) => DropdownMenuItem<PosicaoAtleta>(
                              value: p,
                              child: Row(
                                children: [
                                  Icon(
                                    _iconePosicao(p),
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => rebuildDialog(() => _avulsoPosicao = v),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctxDialog).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                Semantics(
                  label: 'Adicionar participante avulso',
                  button: true,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 46),
                    ),
                    onPressed: () async {
                      rebuildDialog(() => _avulsoAutovalidar = true);
                      final ok = validateAndFocusFirstError(_avulsoFormKey);
                      if (!ok) return;
                      final pos = _avulsoPosicao;
                      if (pos == null) return;
                      Navigator.of(ctxDialog).pop();
                      await _tratarErro(() async {
                        await _adicionarAvulso(pelada: pelada, data: data);
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text(
                      'Adicionar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _iconePosicao(PosicaoAtleta p) {
    switch (p) {
      case PosicaoAtleta.goleiro:
        return Icons.sports_handball_outlined;
      case PosicaoAtleta.zagaFixo:
        return Icons.shield_outlined;
      case PosicaoAtleta.lateralAla:
        return Icons.swipe_right_alt_outlined;
      case PosicaoAtleta.meia:
        return Icons.linear_scale_outlined;
      case PosicaoAtleta.atacantePivo:
        return Icons.front_hand_outlined;
      case PosicaoAtleta.ponta:
        return Icons.flash_on_outlined;
    }
  }

  String? _extrairIdadeAvulsa(String? observacao) {
    if (observacao == null || observacao.trim().isEmpty) return null;
    final m = RegExp(
      r'Idade:\s*(\d+)\s*anos',
      caseSensitive: false,
    ).firstMatch(observacao);
    if (m == null) return null;
    final anos = m.group(1);
    if (anos == null || anos.isEmpty) return null;
    return '$anos anos';
  }

  Future<void> _abrirModalDetalhesParticipante(
    BuildContext context, {
    required Participation participacao,
    required DataService data,
    required bool isOrganizador,
  }) async {
    unawaited(HapticFeedback.selectionClick());
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final authProfile = context.read<AuthService>().currentUser;
    final profile =
        data.getUserProfile(participacao.usuarioId) ??
        (authProfile?.id == participacao.usuarioId ||
                authProfile?.authUid == participacao.usuarioId
            ? authProfile
            : null) ??
        await data.carregarPerfilUsuario(participacao.usuarioId);
    if (!context.mounted) return;

    final apelido =
        (participacao.usuarioApelido != null &&
            participacao.usuarioApelido!.trim().isNotEmpty)
        ? '"${participacao.usuarioApelido!.trim()}"'
        : (profile?.apelido != null && profile!.apelido!.trim().isNotEmpty
              ? '"${profile.apelido!.trim()}"'
              : 'Não informado');

    final posicaoPrincipal =
        participacao.usuarioPosicaoPrincipal?.label ??
        profile?.posicaoPrincipal?.label ??
        'Não informada';

    final posicaoAlternativa =
        profile?.posicaoAlternativa?.label ?? 'Não informada';

    final idadeTexto = profile?.idade != null
        ? '${profile!.idade} anos'
        : participacao.usuarioIdade != null
        ? '${participacao.usuarioIdade} anos'
        : (_extrairIdadeAvulsa(participacao.observacao) ?? 'Não informada');

    final telefone =
        profile?.telefone != null && profile!.telefone!.trim().isNotEmpty
        ? profile.telefone!.trim()
        : 'Não informado';

    final iniciais =
        (participacao.usuarioNome.trim().isEmpty
                ? '?'
                : participacao.usuarioNome.trim()[0])
            .toUpperCase();
    final valorPagoCtrl = TextEditingController(
      text: participacao.valorPago > 0
          ? participacao.valorPago.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    String? formaPagamentoSelecionada = participacao.formaPagamento;
    String? erroPagamento;

    final salvo = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctxDialog) {
        Widget linhaInfo({
          required IconData icone,
          required String rotulo,
          required String valor,
        }) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlphaSafe(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icone, color: scheme.primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rotulo,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return StatefulBuilder(
          builder: (ctxDialog, setDialogState) => Semantics(
            label: 'Dados do participante ${participacao.usuarioNome}',
            child: AlertDialog(
              scrollable: true,
              titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
              contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              actionsPadding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.success.withAlphaSafe(
                      alpha: 0.22,
                    ),
                    backgroundImage:
                        (participacao.usuarioFotoUrl != null &&
                            participacao.usuarioFotoUrl!.trim().isNotEmpty)
                        ? NetworkImage(participacao.usuarioFotoUrl!)
                        : null,
                    child:
                        (participacao.usuarioFotoUrl == null ||
                            participacao.usuarioFotoUrl!.trim().isEmpty)
                        ? Text(
                            iniciais,
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participacao.usuarioNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ) ??
                              const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Participante confirmado',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Fechar modal do participante',
                    button: true,
                    hint: 'Toque duas vezes para retornar à lista',
                    child: Tooltip(
                      message: 'Fechar',
                      preferBelow: false,
                      child: IconButton(
                        onPressed: () => Navigator.of(ctxDialog).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        splashRadius: 20,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 12),
                  linhaInfo(
                    icone: Icons.badge_outlined,
                    rotulo: 'NOME',
                    valor: participacao.usuarioNome.isEmpty
                        ? 'Não informado'
                        : participacao.usuarioNome,
                  ),
                  linhaInfo(
                    icone: Icons.alternate_email_outlined,
                    rotulo: 'APELIDO',
                    valor: apelido,
                  ),
                  linhaInfo(
                    icone: _iconePosicao(
                      participacao.usuarioPosicaoPrincipal ??
                          profile?.posicaoPrincipal ??
                          PosicaoAtleta.meia,
                    ),
                    rotulo: 'POSIÇÃO PRINCIPAL',
                    valor: posicaoPrincipal,
                  ),
                  linhaInfo(
                    icone: Icons.swap_horiz_rounded,
                    rotulo: 'POSIÇÃO ALTERNATIVA',
                    valor: posicaoAlternativa,
                  ),
                  linhaInfo(
                    icone: Icons.cake_outlined,
                    rotulo: 'IDADE',
                    valor: idadeTexto,
                  ),
                  linhaInfo(
                    icone: Icons.phone_outlined,
                    rotulo: 'TELEFONE',
                    valor: telefone,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: ['Cartão', 'Dinheiro', 'Pix'].map((forma) {
                      final selecionado = formaPagamentoSelecionada == forma;
                      void atualizarSelecao(bool? value) => setDialogState(() {
                        formaPagamentoSelecionada = value == true
                            ? forma
                            : null;
                        erroPagamento = null;
                      });
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: isOrganizador
                            ? () => atualizarSelecao(!selecionado)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.only(left: 4, right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selecionado
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: selecionado,
                                visualDensity: VisualDensity.compact,
                                onChanged: isOrganizador
                                    ? atualizarSelecao
                                    : null,
                              ),
                              Text(forma),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: valorPagoCtrl,
                    enabled: isOrganizador,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Valor pago * (R\$)',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) =>
                        setDialogState(() => erroPagamento = null),
                  ),
                  if (erroPagamento != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          erroPagamento!,
                          style: TextStyle(color: scheme.error, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    if (!isOrganizador) {
                      Navigator.of(ctxDialog).pop();
                      return;
                    }
                    final valor =
                        double.tryParse(
                          valorPagoCtrl.text.trim().replaceAll(',', '.'),
                        ) ??
                        0;
                    if (formaPagamentoSelecionada != null && valor <= 0) {
                      setDialogState(
                        () =>
                            erroPagamento = 'Informe um valor maior que zero.',
                      );
                      return;
                    }
                    if (valor > 0 && formaPagamentoSelecionada == null) {
                      setDialogState(
                        () => erroPagamento = 'Selecione a forma de pagamento.',
                      );
                      return;
                    }
                    final sucesso = await data.atualizarPagamentoParticipacao(
                      peladaId: participacao.peladaId,
                      usuarioId: participacao.usuarioId,
                      formaPagamento: valor > 0
                          ? formaPagamentoSelecionada
                          : null,
                      valorPago: valor > 0 ? valor : 0,
                    );
                    if (ctxDialog.mounted) {
                      Navigator.of(ctxDialog).pop(sucesso);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    isOrganizador ? 'Fechar / Salvar' : 'Fechar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    valorPagoCtrl.dispose();
    if (salvo == false && mounted) {
      _aviso(
        data.errorMessage ?? 'Não foi possível salvar o pagamento.',
        isError: true,
      );
    }
  }

  Future<void> _adicionarAvulso({
    required Pelada pelada,
    required DataService data,
  }) async {
    final nome = _avulsoNomeCtrl.text.trim();
    final apelido = _avulsoApelidoCtrl.text.trim();
    final idadeStr = _avulsoIdadeCtrl.text.trim();
    final posicao = _avulsoPosicao!;
    final idade = int.parse(idadeStr);

    if (!pelada.temVagas) {
      _aviso('Quórum máximo já atingido.', isError: true);
      return;
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final avulsoId =
        'avulso_${ts}_${_rnd.nextInt(99999).toString().padLeft(5, '0')}';
    final obsPieces = <String>['Participante avulso', 'Idade: $idade anos'];
    final telefone = _avulsoTelefoneCtrl.text.trim();
    final contatoEmergencia = _avulsoContatoEmergenciaCtrl.text.trim();
    if (telefone.isNotEmpty) obsPieces.add('Telefone: $telefone');
    if (contatoEmergencia.isNotEmpty) {
      obsPieces.add('Contato de emergência: $contatoEmergencia');
    }
    final observacao = obsPieces.join(' • ');

    final res = await data.registrarParticipacao(
      peladaId: pelada.id,
      usuarioId: avulsoId,
      usuarioNome: nome,
      usuarioApelido: apelido.isEmpty ? null : apelido,
      usuarioIdade: idade,
      usuarioPosicaoPrincipal: posicao,
      status: StatusParticipacao.confirmada,
      observacao: observacao,
    );

    if (res != null) {
      _aviso(
        '"$nome" foi adicionado como participante confirmado. Vaga atualizada.',
      );
    } else {
      final e =
          data.errorMessage ?? 'Não foi possível adicionar o participante.';
      _aviso(e, isError: true);
    }
  }

  bool _isOrganizador({Pelada? pelada, AuthService? auth}) {
    final user = auth?.currentUser;
    if (user == null || pelada == null) return false;
    return pelada.organizadorId.trim().isNotEmpty &&
        pelada.organizadorId == user.id;
  }

  Future<bool> _confirmarExclusao(Participation p) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir participante?'),
        content: Text(
          'Tem certeza que deseja excluir "${p.usuarioNome}" da lista de confirmados desta pelada? Essa ação libera a vaga mas não impede que o usuário confirme presença novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sim, excluir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<String?> _pedirMotivoBloqueio(String nome) async {
    _motivoBloqueioCtrl.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Bloquear $nome'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O usuário não poderá confirmar presença nesta pelada enquanto estiver bloqueado.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _motivoBloqueioCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              final m = _motivoBloqueioCtrl.text.trim();
              Navigator.of(ctx).pop(m.isEmpty ? null : m);
            },
            child: const Text(
              'Confirmar bloqueio',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final auth = context.watch<AuthService>();
    final pelada = data.getPeladaById(widget.peladaId);
    final theme = Theme.of(context);

    if (pelada == null) {
      final fallbackTheme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(
          backgroundColor: fallbackTheme.appBarTheme.backgroundColor,
          foregroundColor: fallbackTheme.appBarTheme.foregroundColor,
          surfaceTintColor: fallbackTheme.appBarTheme.surfaceTintColor,
          elevation: fallbackTheme.appBarTheme.elevation,
          titleTextStyle:
              fallbackTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: fallbackTheme.appBarTheme.foregroundColor,
                fontSize: 20,
              ) ??
              TextStyle(
                fontWeight: FontWeight.w800,
                color: fallbackTheme.appBarTheme.foregroundColor,
                fontSize: 20,
              ),
          iconTheme: fallbackTheme.appBarTheme.iconTheme,
          actionsIconTheme: fallbackTheme.appBarTheme.actionsIconTheme,
          title: const Text('Participantes'),
        ),
        body: const Center(child: Text('Pelada não encontrada.')),
      );
    }

    final isOrg = _isOrganizador(pelada: pelada, auth: auth);
    final todasParticipacoes = data.getParticipationsByPelada(widget.peladaId);
    final confirmadas = todasParticipacoes
        .where((p) => p.status == StatusParticipacao.confirmada)
        .toList();
    confirmadas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pagas = confirmadas
        .where((p) => p.formaPagamento != null && p.valorPago > 0)
        .toList();
    final pendentesPagamento = confirmadas
        .where((p) => p.formaPagamento == null || p.valorPago <= 0)
        .toList();
    final participantesConfirmadosExibidos =
        _mostrarSomentePendentesPagamento
        ? pendentesPagamento
        : confirmadas;
    double totalPorForma(String forma) => pagas
        .where((p) => p.formaPagamento == forma)
        .fold(0.0, (total, p) => total + p.valorPago);
    final totalCartao = totalPorForma('Cartão');
    final totalDinheiro = totalPorForma('Dinheiro');
    final totalPix = totalPorForma('Pix');
    final totalGeral = totalCartao + totalDinheiro + totalPix;
    final duvida = todasParticipacoes
        .where((p) => p.status == StatusParticipacao.tenhoDuvida)
        .toList();
    final bloqueios = data
        .getBloqueiosPelada(widget.peladaId)
        .where((b) => b.ativo)
        .toList();

    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final secondary = scheme.secondary;
    final onSurface = scheme.onSurface;
    final appBarBackground =
        theme.appBarTheme.backgroundColor ??
        (theme.useMaterial3 ? scheme.surface : scheme.primary);
    final organizadorBotaoFundo = appBarBackground.computeLuminance() > 0.179
        ? Colors.black
        : Colors.white;
    final organizadorBotaoTexto = organizadorBotaoFundo == Colors.black
        ? Colors.white
        : Colors.black;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: kToolbarHeight * 0.9,
        titleSpacing: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        surfaceTintColor: theme.appBarTheme.surfaceTintColor,
        elevation: theme.appBarTheme.elevation,
        titleTextStyle:
            theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.appBarTheme.foregroundColor,
              fontSize: 20,
            ) ??
            TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.appBarTheme.foregroundColor,
              fontSize: 20,
            ),
        iconTheme: theme.appBarTheme.iconTheme,
        actionsIconTheme: theme.appBarTheme.actionsIconTheme,
        leading: Semantics(
          label: 'Voltar para detalhes do evento',
          button: true,
          hint: 'Retorna à tela anterior',
          child: Tooltip(
            message: 'Voltar',
            preferBelow: false,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, size: 24),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _voltarParaDetalhes,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Gerenciar Participantes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ),
        ),
        actions: [
          if (isOrg)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Tooltip(
                message: 'Ir para Minhas Peladas',
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: OutlinedButton.icon(
                    key: const ValueKey('participants-btn-minhas-peladas'),
                    onPressed: _abrirMinhasPeladas,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: organizadorBotaoFundo,
                      foregroundColor: organizadorBotaoTexto,
                      side: BorderSide(
                        color: organizadorBotaoTexto,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    icon: const Icon(Icons.shield, size: 16),
                    label: const Text(
                      'ORGANIZADOR',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: null,
      bottomNavigationBar: Builder(
        builder: (context) {
          final auth = context.watch<AuthService>();
          Widget? centerMenu;
          if (auth.isAuthenticated) {
            const buttonDiameter = CustomBottomNavBar.fabDiameter;
            const labelColumnWidth = 92.0;
            const labelGutter = 10.0;
            centerMenu = ProfileSportsRailMenu(
              buttonDiameter: buttonDiameter,
              verticalSpacing: 6,
              labelColumnWidth: labelColumnWidth,
              labelGutter: labelGutter,
              labelOffsetAdjust: const EdgeInsets.only(right: 6),
              notchDockedOffset: 0,
              activeButtonId: 'peladas',
              navBarHeight: CustomBottomNavBar.barHeight,
            );
          }
          return CustomBottomNavBar(
            selectedIndex: -1,
            customCenterMenu: centerMenu,
            showCenterHomeButton: !auth.isAuthenticated,
            useCadastrarCampoNoIndiceZero: true,
            indiceZeroLabel: 'Avulso',
            indiceZeroIcon: Icons.person_add_alt_1_outlined,
            indiceZeroSelectedIcon: Icons.person_add_alt_1_rounded,
            indiceZeroUsaIconeSimples: true,
            onCadastrarCampoPressed: () {
              if (!auth.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Faça login para adicionar participantes.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              unawaited(HapticFeedback.selectionClick());
              _abrirModalAvulso(pelada: pelada, data: data);
            },
            onTabSelected: (i) async {
              switch (i) {
                case 1:
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(initialTab: 1),
                      ),
                      (r) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Não foi possível navegar: $e'),
                      ),
                    );
                  }
                  break;
                case 2:
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CamposArenasScreen(),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Não foi possível abrir Campos: $e'),
                      ),
                    );
                  }
                  break;
                case 3:
                  await navigateToProfile(context);
                  break;
              }
            },
            tipoFavoritoBadge: TipoFavoritoBadge.peladas,
          );
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final paddingHor = isWide ? 24.0 : 16.0;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  if (_erro != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          paddingHor,
                          12,
                          paddingHor,
                          6,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withAlphaSafe(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.danger.withAlphaSafe(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _erro!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        paddingHor,
                        16,
                        paddingHor,
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  pelada.nome,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (isOrg) ...[
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: isWide ? 170 : 128,
                                  child: _CampoTotalPagamento(
                                    label: 'Total Geral',
                                    valor: totalGeral,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isOrg) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _CampoTotalPagamento(
                                    label: 'Total Cartão',
                                    valor: totalCartao,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _CampoTotalPagamento(
                                    label: 'Total Dinheiro',
                                    valor: totalDinheiro,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _CampoTotalPagamento(
                                    label: 'Total Pix',
                                    valor: totalPix,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_outlined,
                                size: 16,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Pagos • ${pagas.length}/${confirmadas.length} participantes',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isOrg) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: Builder(
                                builder: (shareContext) => OutlinedButton.icon(
                                  key: const ValueKey(
                                    'participants-btn-compartilhar-lista',
                                  ),
                                  onPressed: () => _compartilharLista(
                                    shareContext: shareContext,
                                    pelada: pelada,
                                    participantes: todasParticipacoes,
                                    data: data,
                                  ),
                                  icon: const Icon(Icons.share_outlined),
                                  label: const Text(
                                    'COMPARTILHAR LISTA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Confirmados (${confirmadas.length}/${pelada.quorumMaximoEfetivo}) Vagas',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isOrg) ...[
                                SizedBox.square(
                                  dimension: 40,
                                  child: IconButton(
                                    tooltip: _mostrarSomentePendentesPagamento
                                        ? 'Mostrar todos os confirmados'
                                        : 'Filtrar pendentes de pagamento',
                                    onPressed: () => setState(
                                      () => _mostrarSomentePendentesPagamento =
                                          !_mostrarSomentePendentesPagamento,
                                    ),
                                    padding: EdgeInsets.zero,
                                    style: IconButton.styleFrom(
                                      foregroundColor: scheme.error,
                                      backgroundColor:
                                          _mostrarSomentePendentesPagamento
                                          ? scheme.error.withValues(
                                              alpha: 0.12,
                                            )
                                          : Colors.transparent,
                                      shape: const CircleBorder(),
                                      side: BorderSide(
                                        color: scheme.error.withValues(
                                          alpha:
                                              _mostrarSomentePendentesPagamento
                                              ? 0.65
                                              : 0.35,
                                        ),
                                      ),
                                      minimumSize: const Size(40, 40),
                                      maximumSize: const Size(40, 40),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.attach_money_rounded,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox.square(
                                  dimension: 40,
                                  child: IconButton(
                                    tooltip: 'Adicionar participante avulso',
                                    onPressed: () => _abrirModalAvulso(
                                      pelada: pelada,
                                      data: data,
                                    ),
                                    padding: EdgeInsets.zero,
                                    style: IconButton.styleFrom(
                                      foregroundColor: scheme.primary,
                                      shape: const CircleBorder(),
                                      side: BorderSide(
                                        color: scheme.primary,
                                      ),
                                      minimumSize: const Size(40, 40),
                                      maximumSize: const Size(40, 40),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isOrg)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          paddingHor,
                          8,
                          paddingHor,
                          16,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withAlphaSafe(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.tertiary.withAlphaSafe(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Apenas o organizador da pelada pode bloquear ou remover participantes!',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_mostrarSomentePendentesPagamento &&
                      participantesConfirmadosExibidos.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: paddingHor,
                          vertical: 24,
                        ),
                        child: Text(
                          'Não há pagamentos pendentes.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    _SessaoLista(
                      titulo: 'Confirmados',
                      icone: Icons.check_circle,
                      cor: AppColors.success,
                      participantes: participantesConfirmadosExibidos,
                      mostrarTitulo: false,
                      data: data,
                      paddingHor: paddingHor,
                      dateFmt: _dateFmt,
                      isOrganizador: isOrg,
                      onTapParticipant: (p) => _abrirModalDetalhesParticipante(
                        context,
                        participacao: p,
                        data: data,
                        isOrganizador: isOrg,
                      ),
                      onExcluir: isOrg
                          ? (p) => _tratarErro(() async {
                              final conf = await _confirmarExclusao(p);
                              if (!conf) return;
                              final ok = await data.removerParticipacao(
                                peladaId: pelada.id,
                                participationId: p.id,
                                usuarioId: p.usuarioId,
                              );
                              if (ok) {
                                _aviso(
                                  '"${p.usuarioNome}" foi removido. Vaga liberada.',
                                );
                              } else {
                                final e =
                                    data.errorMessage ??
                                    'Não foi possível excluir.';
                                _aviso(e, isError: true);
                              }
                            })
                          : null,
                      onBloquear: isOrg
                          ? (p) => _tratarErro(() async {
                              final motivo = await _pedirMotivoBloqueio(
                                p.usuarioNome,
                              );
                              if (motivo == null) return;
                              final res = await data.bloquearUsuario(
                                peladaId: pelada.id,
                                usuarioId: p.usuarioId,
                                usuarioNome: p.usuarioNome,
                                organizadorId: pelada.organizadorId,
                                motivo: motivo,
                              );
                              if (res != null) {
                                _aviso(
                                  '"${p.usuarioNome}" foi bloqueado desta pelada.',
                                );
                              } else {
                                final e =
                                    data.errorMessage ??
                                    'Não foi possível bloquear.';
                                _aviso(e, isError: true);
                              }
                            })
                          : null,
                    ),
                  if (duvida.isNotEmpty)
                    _SessaoLista(
                      titulo: 'Em dúvida',
                      icone: Icons.help_outline,
                      cor: AppColors.warning,
                      participantes: duvida,
                      paddingHor: paddingHor,
                      dateFmt: _dateFmt,
                      isOrganizador: isOrg,
                      onBloquear: isOrg
                          ? (p) => _tratarErro(() async {
                              final motivo = await _pedirMotivoBloqueio(
                                p.usuarioNome,
                              );
                              if (motivo == null) return;
                              final res = await data.bloquearUsuario(
                                peladaId: pelada.id,
                                usuarioId: p.usuarioId,
                                usuarioNome: p.usuarioNome,
                                organizadorId: pelada.organizadorId,
                                motivo: motivo,
                              );
                              if (res != null) {
                                _aviso('"${p.usuarioNome}" foi bloqueado.');
                              } else {
                                final e =
                                    data.errorMessage ?? 'Erro ao bloquear.';
                                _aviso(e, isError: true);
                              }
                            })
                          : null,
                    ),
                  if (bloqueios.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          paddingHor,
                          8,
                          paddingHor,
                          16,
                        ),
                        child: Card(
                          color: AppColors.danger.withAlphaSafe(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: AppColors.danger.withAlphaSafe(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.block,
                                      color: AppColors.danger,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Usuários bloqueados (${bloqueios.length})',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...bloqueios.map(
                                  (b) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: ListTile(
                                      tileColor: AppColors.danger.withAlphaSafe(
                                        alpha: 0.05,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.danger
                                            .withAlphaSafe(alpha: 0.2),
                                        child: Text(
                                          b.usuarioNome.isNotEmpty
                                              ? b.usuarioNome[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        b.usuarioNome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Bloqueado em ${_dateFmt.format(b.bloqueadoEm)}${b.motivo != null && b.motivo!.trim().isNotEmpty ? ' • ${b.motivo!.trim()}' : ''}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: isOrg
                                          ? IconButton(
                                              tooltip: 'Desbloquear',
                                              color: AppColors.success,
                                              onPressed: () => _tratarErro(
                                                () async {
                                                  final ok = await data
                                                      .desbloquearUsuario(
                                                        peladaId: pelada.id,
                                                        usuarioId: b.usuarioId,
                                                      );
                                                  if (ok) {
                                                    _aviso(
                                                      'Usuário desbloqueado.',
                                                    );
                                                  } else {
                                                    final e =
                                                        data.errorMessage ??
                                                        'Erro ao desbloquear.';
                                                    _aviso(e, isError: true);
                                                  }
                                                },
                                              ),
                                              icon: const Icon(
                                                Icons.lock_open_outlined,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (confirmadas.isEmpty &&
                      duvida.isEmpty &&
                      bloqueios.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(paddingHor),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 64,
                              color: theme.hintColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum participante confirmado ainda.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withAlphaSafe(alpha: 0.35),
                    alignment: Alignment.center,
                    child: const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 14),
                            Text(
                              'Processando...',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CampoTotalPagamento extends StatelessWidget {
  final String label;
  final double valor;

  const _CampoTotalPagamento({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          NumberFormat.currency(
            locale: 'pt_BR',
            symbol: '',
            decimalDigits: 2,
          ).format(valor).trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SessaoLista extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Color cor;
  final List<Participation> participantes;
  final double paddingHor;
  final DateFormat dateFmt;
  final bool isOrganizador;
  final bool mostrarTitulo;
  final DataService? data;
  final void Function(Participation)? onExcluir;
  final void Function(Participation)? onBloquear;
  final void Function(Participation)? onTapParticipant;

  const _SessaoLista({
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.participantes,
    required this.paddingHor,
    required this.dateFmt,
    required this.isOrganizador,
    this.mostrarTitulo = true,
    this.data,
    this.onExcluir,
    this.onBloquear,
    this.onTapParticipant,
  });

  Widget _menuParticipante(Participation p) {
    if (!isOrganizador || (onBloquear == null && onExcluir == null)) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      iconSize: 22,
      splashRadius: 18,
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      onSelected: (op) {
        if (op == 'bloquear') onBloquear?.call(p);
        if (op == 'excluir') onExcluir?.call(p);
      },
      itemBuilder: (_) => [
        if (onBloquear != null)
          const PopupMenuItem(
            value: 'bloquear',
            child: Row(
              children: [
                Icon(Icons.block_outlined, color: AppColors.warning, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Bloquear temporariamente',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (onExcluir != null)
          const PopupMenuItem(
            value: 'excluir',
            child: Row(
              children: [
                Icon(
                  Icons.delete_forever_outlined,
                  color: AppColors.danger,
                  size: 18,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Excluir da lista',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (participantes.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverMainAxisGroup(
      slivers: [
        if (mostrarTitulo)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(paddingHor, 16, paddingHor, 8),
              child: Row(
                children: [
                  Icon(icone, color: cor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$titulo (${participantes.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: paddingHor),
          sliver: SliverList.separated(
            itemCount: participantes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = participantes[i];
              final authProfile = Provider.of<AuthService>(
                context,
                listen: false,
              ).currentUser;
              final profile =
                  data?.getUserProfile(p.usuarioId) ??
                  (authProfile?.id == p.usuarioId ? authProfile : null);
              final apelido = p.usuarioApelido?.trim().isNotEmpty == true
                  ? p.usuarioApelido!.trim()
                  : (profile?.apelido?.trim().isNotEmpty == true
                        ? profile!.apelido!.trim()
                        : 'Sem apelido');
              final idade =
                  p.usuarioIdade ??
                  profile?.idade ??
                  int.tryParse(
                    RegExp(
                          r'Idade:\s*(\d+)\s*anos',
                          caseSensitive: false,
                        ).firstMatch(p.observacao ?? '')?.group(1) ??
                        '',
                  );
              final posicaoPrincipal =
                  p.usuarioPosicaoPrincipal?.label ??
                  profile?.posicaoPrincipal?.label ??
                  'Não informada';
              final isAvulso =
                  p.usuarioId.startsWith('avulso_') ||
                  (p.observacao?.toLowerCase().contains(
                        'participante avulso',
                      ) ??
                      false);
              final isParticipanteConfirmado = titulo == 'Confirmados';
              final pagamentoConfirmado =
                  p.formaPagamento != null && p.valorPago > 0;
              final iniciais =
                  (p.usuarioNome.trim().isEmpty ? '?' : p.usuarioNome.trim()[0])
                      .toUpperCase();
              final bool temAcao = onTapParticipant != null;
              return Semantics(
                button: temAcao,
                label: temAcao ? 'Abrir detalhes de ${p.usuarioNome}' : null,
                hint: temAcao
                    ? 'Toque duas vezes para visualizar os dados do participante'
                    : null,
                child: Tooltip(
                  message: temAcao ? 'Abrir detalhes' : '',
                  triggerMode: temAcao
                      ? TooltipTriggerMode.longPress
                      : TooltipTriggerMode.manual,
                  preferBelow: false,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: temAcao ? () => onTapParticipant!(p) : null,
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compacto = constraints.maxWidth < 420;
                              final avatar = CircleAvatar(
                                radius: (compacto ? 24 : 28) * 1.05,
                                backgroundImage:
                                    (p.usuarioFotoUrl != null &&
                                        p.usuarioFotoUrl!.trim().isNotEmpty)
                                    ? NetworkImage(p.usuarioFotoUrl!)
                                    : null,
                                backgroundColor: cor.withAlphaSafe(alpha: 0.18),
                                child:
                                    (p.usuarioFotoUrl == null ||
                                        p.usuarioFotoUrl!.trim().isEmpty)
                                    ? Text(
                                        iniciais,
                                        style: TextStyle(
                                          color: cor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: (compacto ? 16 : 18) * 1.05,
                                        ),
                                      )
                                    : null,
                              );
                              final menu = _menuParticipante(p);
                              if (isParticipanteConfirmado) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        avatar,
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      apelido,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  if (idade != null) ...[
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '($idade anos)',
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                p.usuarioNome,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.72),
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                posicaoPrincipal,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.72),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            menu,
                                            Tooltip(
                                              message: pagamentoConfirmado
                                                  ? 'Pagamento efetuado'
                                                  : 'Pagamento pendente',
                                              child: Icon(
                                                Icons.attach_money_rounded,
                                                color: pagamentoConfirmado
                                                    ? AppColors.success
                                                    : AppColors.danger,
                                                size: 42,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.68),
                                          fontSize: 12,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                'Confirmado em ${DateFormat('dd/MM/yyyy - HH:mm', 'pt_BR').format(p.createdAt)}',
                                          ),
                                          if (isAvulso)
                                            const TextSpan(
                                              text: '  (Avulso)',
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  avatar,
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isParticipanteConfirmado) ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  apelido,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (idade != null) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  '($idade anos)',
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            p.usuarioNome,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.72),
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            'Posição principal: $posicaoPrincipal',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.72),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text.rich(
                                            TextSpan(
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.68),
                                                fontSize: 12,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      'Confirmado em ${DateFormat('dd/MM/yy - HH:mm', 'pt_BR').format(p.createdAt)}',
                                                ),
                                                if (isAvulso)
                                                  const TextSpan(
                                                    text: '  (Avulso)',
                                                    style: TextStyle(
                                                      color: AppColors.success,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ] else ...[
                                          Text(
                                            p.usuarioNome,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if ((p.usuarioApelido != null &&
                                                  p.usuarioApelido!
                                                      .trim()
                                                      .isNotEmpty) ||
                                              p.usuarioPosicaoPrincipal != null)
                                            Text.rich(
                                              TextSpan(
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.58),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                children: [
                                                  if (p.usuarioApelido !=
                                                          null &&
                                                      p.usuarioApelido!
                                                          .trim()
                                                          .isNotEmpty)
                                                    TextSpan(
                                                      text:
                                                          '"${p.usuarioApelido!.trim()}"',
                                                    ),
                                                  if ((p.usuarioApelido !=
                                                              null &&
                                                          p.usuarioApelido!
                                                              .trim()
                                                              .isNotEmpty) &&
                                                      p.usuarioPosicaoPrincipal !=
                                                          null)
                                                    const TextSpan(text: ' · '),
                                                  if (p.usuarioPosicaoPrincipal !=
                                                      null)
                                                    TextSpan(
                                                      text: p
                                                          .usuarioPosicaoPrincipal!
                                                          .label,
                                                    ),
                                                ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_outlined,
                                                size: 13,
                                                color: Theme.of(
                                                  context,
                                                ).hintColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'Confirmado em ${dateFmt.format(p.createdAt)}',
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).hintColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (p.observacao != null &&
                                              p.observacao!
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              p.observacao!.trim(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).hintColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isParticipanteConfirmado)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 30,
                                        right: 2,
                                      ),
                                      child: Tooltip(
                                        message: pagamentoConfirmado
                                            ? 'Pagamento efetuado'
                                            : 'Pagamento pendente',
                                        child: Icon(
                                          Icons.attach_money_rounded,
                                          color: pagamentoConfirmado
                                              ? AppColors.success
                                              : AppColors.danger,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  if (isOrganizador &&
                                      (onBloquear != null || onExcluir != null))
                                    PopupMenuButton<String>(
                                      onSelected: (op) {
                                        if (op == 'bloquear') {
                                          onBloquear?.call(p);
                                        }
                                        if (op == 'excluir') onExcluir?.call(p);
                                      },
                                      itemBuilder: (_) => [
                                        if (onBloquear != null)
                                          const PopupMenuItem(
                                            value: 'bloquear',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.block_outlined,
                                                  color: AppColors.warning,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    'Bloquear temporariamente',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: AppColors.warning,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (onExcluir != null)
                                          const PopupMenuItem(
                                            value: 'excluir',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_forever_outlined,
                                                  color: AppColors.danger,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    'Excluir da lista',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: AppColors.danger,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
