import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../widgets/estado_cidade_fields.dart';
import '../models/enums.dart';
import '../models/goleiro.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/profile_sports_rail_menu.dart';
import 'cadastro_goleiro_screen.dart';
import 'home_screen.dart';
import 'goleiros_favoritos_screen.dart';
import '../utils/profile_navigation_helper.dart';

class GoleirosScreen extends StatefulWidget {
  final String? focoGoleiroId;
  final Goleiro? focoGoleiro;
  final String? mensagemSucesso;

  const GoleirosScreen({
    super.key,
    this.focoGoleiroId,
    this.focoGoleiro,
    this.mensagemSucesso,
  });

  @override
  State<GoleirosScreen> createState() => _GoleirosScreenState();
}

class _GoleirosScreenState extends State<GoleirosScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _navIndex = -1;
  final ScrollController _scrollController = ScrollController();
  String? _focoDestacado;
  Timer? _timerRemoveDestaque;
  bool _mensagemExibida = false;
  _GoleiroFiltros _filtros = const _GoleiroFiltros();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _exibirMensagemSucesso();
      Future<void>.delayed(const Duration(milliseconds: 240), () {
        if (!mounted) return;
        _realizarFocoGoleiro();
      });
    });
  }

  @override
  void dispose() {
    _timerRemoveDestaque?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _exibirMensagemSucesso() {
    if (_mensagemExibida) return;
    final msg = widget.mensagemSucesso?.trim();
    if (msg == null || msg.isEmpty) return;
    _mensagemExibida = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
          content: Text(msg),
        ),
      );
    });
  }

  void _realizarFocoGoleiro() {
    final id = widget.focoGoleiro?.id ?? widget.focoGoleiroId;
    if (id == null || id.isEmpty) return;
    final ctxKey = GlobalObjectKey('goleiro_card_$id');
    final targetCtx = ctxKey.currentContext;
    if (targetCtx == null) {
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (!mounted) return;
        _realizarFocoGoleiro();
      });
      return;
    }
    setState(() => _focoDestacado = id);
    _timerRemoveDestaque?.cancel();
    _timerRemoveDestaque = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _focoDestacado = null);
    });
    try {
      final rb = targetCtx.findRenderObject();
      if (rb is RenderObject) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Scrollable.ensureVisible(
            targetCtx,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            alignment: 0.25,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _onCadastrarGoleiroTap(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    final a = context.read<AuthService>();
    final theme = Theme.of(context);
    if (!a.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.colorScheme.error,
          content: const Text(
            'Faça login ou cadastre-se antes de cadastrar juí­zes.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    try {
      final navigator = Navigator.of(context);
      final r = await navigator.push<Goleiro?>(
        MaterialPageRoute(builder: (_) => const CadastroGoleiroScreen()),
      );
      if (!mounted) return;
      if (r != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
            content: Text(
              'Goleiro "${r.nomeExibicao}" cadastrado com sucesso!',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('NÃ£o foi possÃ­vel abrir cadastro: $e'),
        ),
      );
    }
  }

  Future<void> _abrirFiltros() async {
    final nomeCtrl = TextEditingController(text: _filtros.nome);
    final ufCtrl = TextEditingController(text: _filtros.uf);
    final cidadeCtrl = TextEditingController(text: _filtros.cidade);
    final bairroCtrl = TextEditingController(text: _filtros.bairro);
    final taxaMinCtrl = TextEditingController(
      text: _filtros.taxaMin?.toStringAsFixed(2),
    );
    final taxaMaxCtrl = TextEditingController(
      text: _filtros.taxaMax?.toStringAsFixed(2),
    );
    var federacao = _filtros.federacao ?? '';
    var viagem = _filtros.viagem == null
        ? ''
        : (_filtros.viagem! ? 'sim' : 'nao');

    _GoleiroFiltros? resultado;
    try {
      resultado = await showDialog<_GoleiroFiltros>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Filtrar goleiros'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome ou apelido',
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    EstadoUfDropdown(
                      controller: ufCtrl,
                      cidadeController: cidadeCtrl,
                      label: 'Estado (UF)',
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    CidadeMunicipioAutocompleteField(
                      uf: ufCtrl.text,
                      controller: cidadeCtrl,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bairroCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Bairro',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: federacao,
                      decoration: const InputDecoration(
                        labelText: 'Nível do goleiro',
                        prefixIcon: Icon(Icons.shield_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'Profissional',
                          child: Text('Profissional'),
                        ),
                        DropdownMenuItem(
                          value: 'Semiprofissional',
                          child: Text('Semiprofissional'),
                        ),
                        DropdownMenuItem(
                          value: 'Amador',
                          child: Text('Amador'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => federacao = value ?? ''),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: viagem,
                      decoration: const InputDecoration(
                        labelText: 'Disponibilidade para viagem',
                        prefixIcon: Icon(Icons.flight_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Qualquer')),
                        DropdownMenuItem(
                          value: 'sim',
                          child: Text('Disponível para viagem'),
                        ),
                        DropdownMenuItem(
                          value: 'nao',
                          child: Text('Não disponível para viagem'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => viagem = value ?? ''),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: taxaMinCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cachê mínimo (R\$)',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: taxaMaxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cachê máximo (R\$)',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar', maxLines: 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () => setDialogState(() {
                          nomeCtrl.clear();
                          ufCtrl.clear();
                          cidadeCtrl.clear();
                          bairroCtrl.clear();
                          taxaMinCtrl.clear();
                          taxaMaxCtrl.clear();
                          federacao = '';
                          viagem = '';
                        }),
                        child: const Text('Limpar', maxLines: 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () => Navigator.pop(
                          dialogContext,
                          _GoleiroFiltros(
                            nome: nomeCtrl.text.trim(),
                            uf: ufCtrl.text.trim().toUpperCase(),
                            cidade: cidadeCtrl.text.trim(),
                            bairro: bairroCtrl.text.trim(),
                            federacao: federacao.isEmpty ? null : federacao,
                            viagem: viagem.isEmpty ? null : viagem == 'sim',
                            taxaMin: _parseTaxaFiltro(taxaMinCtrl.text),
                            taxaMax: _parseTaxaFiltro(taxaMaxCtrl.text),
                          ),
                        ),
                        child: const Text('Aplicar', maxLines: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      nomeCtrl.dispose();
      ufCtrl.dispose();
      cidadeCtrl.dispose();
      bairroCtrl.dispose();
      taxaMinCtrl.dispose();
      taxaMaxCtrl.dispose();
    }
    if (resultado != null && mounted) setState(() => _filtros = resultado!);
  }

  double? _parseTaxaFiltro(String value) {
    final texto = value.trim().replaceAll(RegExp(r'[^0-9,.]'), '');
    if (texto.isEmpty) return null;
    final normalizado = texto.contains(',')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto;
    return double.tryParse(normalizado);
  }

  List<Goleiro> _aplicarFiltros(List<Goleiro> goleiros) {
    final nome = _filtros.nome.toLowerCase();
    final uf = _filtros.uf.toLowerCase();
    final cidade = _filtros.cidade.toLowerCase();
    final bairro = _filtros.bairro.toLowerCase();
    return goleiros
        .where((goleiro) {
          final nomeCompleto =
              '${goleiro.nomeCompleto} ${goleiro.apelido ?? ''}'.toLowerCase();
          final federacao = (goleiro.situacaoFederativa ?? '')
              .trim()
              .toLowerCase();
          final disponivelViagem = goleiro.atuacao.any(
            (item) => item.trim().toLowerCase() == 'disponível para viagem',
          );
          final taxa = goleiro.taxaArbitragem;
          return (nome.isEmpty || nomeCompleto.contains(nome)) &&
              (uf.isEmpty || (goleiro.uf ?? '').toLowerCase().contains(uf)) &&
              (cidade.isEmpty ||
                  (goleiro.cidade ?? '').toLowerCase().contains(cidade)) &&
              (bairro.isEmpty ||
                  (goleiro.bairro ?? '').toLowerCase().contains(bairro)) &&
              (_filtros.federacao == null ||
                  federacao == _filtros.federacao!.toLowerCase()) &&
              (_filtros.viagem == null ||
                  disponivelViagem == _filtros.viagem) &&
              (_filtros.taxaMin == null ||
                  (taxa != null && taxa >= _filtros.taxaMin!)) &&
              (_filtros.taxaMax == null ||
                  (taxa != null && taxa <= _filtros.taxaMax!));
        })
        .toList(growable: false);
  }

  Future<void> _editarGoleiro(Goleiro goleiro) async {
    unawaited(HapticFeedback.selectionClick());
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: const Text('Faça login para editar goleiros.'),
        ),
      );
      return;
    }
    try {
      await Navigator.of(context).push<Goleiro?>(
        MaterialPageRoute(
          builder: (_) => CadastroGoleiroScreen(goleiro: goleiro),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao abrir edição: $error')));
    }
  }

  void _mostrarDetalhesGoleiro(Goleiro goleiro, {required bool podeEditar}) {
    unawaited(HapticFeedback.selectionClick());
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _GoleiroDetalhesDialog(
        goleiro: goleiro,
        onEdit: podeEditar ? () => _editarGoleiro(goleiro) : null,
      ),
    );
  }

  // ============================================================
  // HELPERS DE NAVEGAÇÃO DO TRAIL MENU (ProfileSportsRailMenu)
  // Implementados com consistência entre as telas.
  // ============================================================

  /// Modalidades classificadas como "PELADAS": futebol em todas as
  /// suas variantes (campo, rua, futsal, society, areia, praia e
  /// futevôlei). Usado para montar o conjunto "VÁRIOS" por exclusão.
  static const Set<Modalidade> _modalidadesPeladas = {
    Modalidade.futebolCampo,
    Modalidade.futebolRua,
    Modalidade.futsal,
    Modalidade.society,
    Modalidade.areia,
    Modalidade.praia,
  };

  /// Filtro do botão "VÁRIOS": calculado dinamicamente excluindo
  /// exatamente as 3 categorias principais:
  ///   1) Futebol em geral (_modalidadesPeladas)
  ///   2) Vôlei (Modalidade.voley)
  ///   3) Basquete (Modalidade.basquete)
  /// Usa Modalidade.values como base → novas modalidades no enum
  /// entram automaticamente no filtro "VÁRIOS".
  static final Set<Modalidade> _modalidadesVarios = {
    ...Modalidade.values,
  }..removeAll({..._modalidadesPeladas, Modalidade.voley, Modalidade.basquete});

  /// Constrói uma rota animada (fade + slide vertical) com duração
  /// de 280ms (< 1s) para consistência visual entre telas.
  static PageRouteBuilder<T> _rotaAnimada<T>(
    WidgetBuilder builder, {
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (ctx, anim, sec) => builder(ctx),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (ctx, anim, sec, child) {
        final fade = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: anim, curve: curve));
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: curve));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  /// Verifica se o usuário atual tem permissão para acessar Goleiros.
  /// Regra mínima: precisa estar autenticado. Ponto de extensão
  /// para roles administrativos no futuro.
  bool _usuarioPodeAcessarGoleiros() {
    final auth = context.read<AuthService>();
    return auth.isAuthenticated;
  }

  /// Constrói uma tela de erro de permissão amigável (acesso negado).
  Widget _buildTelaErroPermissao({required String funcionalidade}) {
    final theme = Theme.of(context);
    final sch = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso Negado'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_outlined,
                size: 96,
                color: sch.error.withValues(alpha: 0.70),
              ),
              const SizedBox(height: 20),
              Text(
                'Você não tem permissão para acessar $funcionalidade.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Entre em contato com o administrador ou verifique seu plano de assinatura.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_outlined),
                label: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navega para a Home aplicando filtro de modalidades.
  ///
  /// - [modalidades] = null → botão PELADAS (nenhum filtro)
  /// - [modalidades] = {voley} → botão VÔLEI etc.
  /// - Usa `pushAndRemoveUntil((r) => r.isFirst)` evita múltiplas
  ///   instâncias da Home na pilha de navegação.
  /// - Filtro é aplicado via [HomeScreen.modalidadesIniciais] que
  ///   é processado antes da renderização, economizando carregamento
  ///   de dados de outras modalidades.
  void _trailNavegarHomeComModalidades(
    Set<Modalidade>? modalidades, {
    required String erroMensagem,
  }) {
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    try {
      Navigator.of(context).pushAndRemoveUntil(
        _rotaAnimada((_) => HomeScreen(modalidadesIniciais: modalidades)),
        (r) => r.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      final sch = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: sch.error,
          content: Text(
            '$erroMensagem: $e',
            style: TextStyle(color: sch.onError),
          ),
        ),
      );
    }
  }

  /// Abre uma tela genérica por push (mantém GoleirosScreen na pilha
  /// para permitir voltar). Tratamento de erro com SnackBar temático.
  void _trailAbrirTela(Widget tela, String erroMensagem) {
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    try {
      Navigator.of(context).push(_rotaAnimada((_) => tela));
    } catch (e) {
      if (!mounted) return;
      final sch = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: sch.error,
          content: Text(
            '$erroMensagem: $e',
            style: TextStyle(color: sch.onError),
          ),
        ),
      );
    }
  }

  /// Wrapper do botão GOLEIROS: valida permissão ANTES de efetuar
  /// a navegação. Se negado, exibe tela de erro explicativa.
  void _trailAbrirGoleiros() {
    if (!mounted) return;
    if (!_usuarioPodeAcessarGoleiros()) {
      _trailAbrirTela(
        _buildTelaErroPermissao(funcionalidade: 'Goleiros'),
        'Não foi possível verificar permissões',
      );
      return;
    }
    _trailAbrirTela(const GoleirosScreen(), 'Não foi possível abrir Goleiros');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final appBarPlusColor =
        theme.appBarTheme.actionsIconTheme?.color ??
        theme.appBarTheme.iconTheme?.color ??
        theme.appBarTheme.foregroundColor ??
        (theme.useMaterial3
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onPrimary);
    final auth = context.watch<AuthService>();
    final data = context.watch<DataService>();
    final user = auth.currentUser;
    final todosGoleiros = data.goleiros;
    final goleirosFiltrados = _aplicarFiltros(todosGoleiros);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => _trailNavegarHomeComModalidades(
            null,
            erroMensagem: 'Não foi possível voltar para a Home',
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Semantics(
          header: true,
          child: const Text(
            'Goleiros',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filtrar goleiros${_filtros.ativo ? ' (ativo)' : ''}',
            onPressed: _abrirFiltros,
            icon: Badge(
              isLabelVisible: _filtros.ativo,
              child: const Icon(Icons.filter_list_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Cadastrar goleiro',
            onPressed: () => _onCadastrarGoleiroTap(context),
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: appBarPlusColor,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final maxContentWidth = isWide ? 780.0 : double.infinity;
            final horizontalPad = isWide ? 28.0 : 18.0;
            final onSurface = theme.colorScheme.onSurfaceVariant;
            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                padding: EdgeInsets.only(
                  left: horizontalPad,
                  right: horizontalPad,
                  bottom: 24,
                ),
                child: CustomScrollView(
                  clipBehavior: Clip.none,
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              size: 18,
                              color: onSurface,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'TODOS OS GOLEIROS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.6,
                                  color: onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _filtros.ativo
                                  ? '${goleirosFiltrados.length}/${todosGoleiros.length}'
                                  : '${todosGoleiros.length} ${todosGoleiros.length == 1 ? 'cadastrado' : 'cadastrados'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (todosGoleiros.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          onCadastrar: () => _onCadastrarGoleiroTap(context),
                        ),
                      )
                    else if (goleirosFiltrados.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 52,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Nenhum goleiro corresponde aos filtros.',
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => _filtros = const _GoleiroFiltros(),
                                ),
                                child: const Text('Limpar filtros'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: LayoutBuilder(
                          key: const ValueKey<String>('grid_layout'),
                          builder: (ctx, gridConstraints) {
                            final mq = MediaQuery.of(ctx);
                            final screenH = mq.size.height;
                            final w = gridConstraints.maxWidth;
                            final crossAxisCount = w >= 1100
                                ? 4
                                : (w >= 760 ? 3 : 2);
                            const nCardsColunaViewport = 3;
                            const espacamento = 6.0;
                            const appBarH = kToolbarHeight;
                            final paddingTop = mq.padding.top;
                            final paddingBottom = mq.padding.bottom;
                            const navBarH = kBottomNavigationBarHeight;
                            const titulosH = 42;
                            const paddingsH = 24 + 24 + 12 + 10 + 24;
                            final totalGapVerticalViewport =
                                espacamento * (nCardsColunaViewport - 1);
                            final alturaLiquidaViewport =
                                screenH -
                                appBarH -
                                paddingTop -
                                paddingBottom -
                                navBarH -
                                titulosH -
                                paddingsH -
                                totalGapVerticalViewport;
                            final larguraCard =
                                (w - espacamento * (crossAxisCount - 1)) /
                                crossAxisCount;
                            final alturaCardOriginal = larguraCard;
                            final alturaCardAlvo40Pct =
                                alturaCardOriginal * 1.40;
                            final alturaCardPorViewport =
                                alturaLiquidaViewport > 0
                                ? alturaLiquidaViewport / nCardsColunaViewport
                                : 140.0;
                            final alturaCard = alturaCardPorViewport > 0
                                ? alturaCardPorViewport
                                      .clamp(
                                        (alturaCardAlvo40Pct * 0.85).clamp(
                                          90.0,
                                          double.infinity,
                                        ),
                                        alturaCardAlvo40Pct.clamp(110.0, 360.0),
                                      )
                                      .toDouble()
                                : alturaCardAlvo40Pct
                                      .clamp(110.0, 360.0)
                                      .toDouble();
                            final aspect = (larguraCard / alturaCard).clamp(
                              0.55,
                              1.05,
                            );
                            return GridView.builder(
                              key: const PageStorageKey<String>(
                                'goleiros_grid',
                              ),
                              clipBehavior: Clip.none,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: espacamento,
                                    crossAxisSpacing: espacamento,
                                    childAspectRatio: aspect,
                                  ),
                              itemCount: goleirosFiltrados.length,
                              itemBuilder: (ctx, i) {
                                final goleiro = goleirosFiltrados[i];
                                final isOwner =
                                    user != null &&
                                    goleiro.proprietarioId != null &&
                                    goleiro.proprietarioId == user.id;
                                final isHighlighted =
                                    _focoDestacado != null &&
                                    _focoDestacado == goleiro.id;
                                return KeyedSubtree(
                                  key: GlobalObjectKey(
                                    'goleiro_card_${goleiro.id}',
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 360),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isHighlighted
                                          ? [
                                              BoxShadow(
                                                color: primary.withValues(
                                                  alpha: 0.55,
                                                ),
                                                blurRadius: 14,
                                                spreadRadius: 2.2,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                      border: Border.all(
                                        color: isHighlighted
                                            ? primary
                                            : Colors.transparent,
                                        width: isHighlighted ? 3 : 0,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        isHighlighted ? 13 : 16,
                                      ),
                                      child: _GoleiroGridCard(
                                        goleiro: goleiro,
                                        isOwner: isOwner,
                                        highlighted: isHighlighted,
                                        onDelete: () async {
                                          final a = context.read<AuthService>();
                                          if (!a.isAuthenticated ||
                                              a.currentUser == null)
                                            return;
                                          final confirmado = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Excluir goleiro?',
                                              ),
                                              content: Text(
                                                'Deseja realmente excluir o goleiro "${goleiro.nomeExibicao}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors.danger,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text('Excluir'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmado != true ||
                                              !context.mounted)
                                            return;
                                          final ok = await context
                                              .read<DataService>()
                                              .excluirGoleiro(
                                                goleiroId: goleiro.id,
                                                usuarioId: a.currentUser!.id,
                                              );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: ok
                                                  ? Colors.green[700]
                                                  : theme.colorScheme.error,
                                              content: Text(
                                                ok
                                                    ? 'Goleiro excluído com sucesso.'
                                                    : (context
                                                              .read<
                                                                DataService
                                                              >()
                                                              .errorMessage ??
                                                          'Não foi possível excluir.'),
                                              ),
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        },
                                        onEdit: () => _editarGoleiro(goleiro),
                                        onTap: () => _mostrarDetalhesGoleiro(
                                          goleiro,
                                          podeEditar: isOwner,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Consumer<AuthService>(
        builder: (context, auth, _) {
          Widget? centerMenu;
          if (auth.isAuthenticated) {
            centerMenu = ProfileSportsRailMenu(
              buttonDiameter: CustomBottomNavBar.fabDiameter,
              verticalSpacing: 6,
              labelColumnWidth: 92,
              labelGutter: 10,
              labelOffsetAdjust: const EdgeInsets.only(right: 6),
              notchDockedOffset: 0,
              activeButtonId: 'goleiros',
              navBarHeight: CustomBottomNavBar.barHeight,
            );
          }
          return CustomBottomNavBar(
            selectedIndex: _navIndex,
            customCenterMenu: centerMenu ?? const SizedBox.shrink(),
            useCadastrarCampoNoIndiceZero: true,
            tipoFavoritoBadge: TipoFavoritoBadge.goleiros,
            indiceZeroIcon: Icons.sports_handball_outlined,
            indiceZeroSelectedIcon: Icons.sports_handball_outlined,
            indiceZeroLabel: 'Goleiros',
            sobrescreverIndiceUm: true,
            indiceUmIcon: Icons.star_border,
            indiceUmSelectedIcon: Icons.star,
            indiceUmLabel: 'Favoritos',
            indiceUmUsaIconeSimples: true,
            indiceUmUsaBadgeFavoritos: true,
            sobrescreverIndiceDois: true,
            indiceDoisIcon: Icons.sports_soccer_outlined,
            indiceDoisSelectedIcon: Icons.sports_soccer,
            indiceDoisLabel: 'Peladas',
            indiceDoisUsaIconeSimples: true,
            showFavoritesBadge: context
                .read<DataService>()
                .temGoleirosFavoritos,
            favoritesBadgeCount: context
                .read<DataService>()
                .quantidadeGoleirosFavoritos,
            onTabSelected: (index) {
              switch (index) {
                case 0:
                  unawaited(_onCadastrarGoleiroTap(context));
                  break;
                case 1:
                  _trailAbrirTela(
                    const GoleirosFavoritosScreen(),
                    'Não foi possível abrir favoritos',
                  );
                  break;
                case 2:
                  _trailNavegarHomeComModalidades(
                    null,
                    erroMensagem: 'Não foi possível abrir início',
                  );
                  break;
                case 3:
                  unawaited(navigateToProfile(context));
                  break;
                default:
                  break;
              }
            },
          );
        },
      ),
    );
  }
}

class _GoleiroFiltros {
  final String nome;
  final String uf;
  final String cidade;
  final String bairro;
  final String? federacao;
  final bool? viagem;
  final double? taxaMin;
  final double? taxaMax;

  const _GoleiroFiltros({
    this.nome = '',
    this.uf = '',
    this.cidade = '',
    this.bairro = '',
    this.federacao,
    this.viagem,
    this.taxaMin,
    this.taxaMax,
  });

  bool get ativo =>
      nome.isNotEmpty ||
      uf.isNotEmpty ||
      cidade.isNotEmpty ||
      bairro.isNotEmpty ||
      federacao != null ||
      viagem != null ||
      taxaMin != null ||
      taxaMax != null;
}

class _GoleiroDetalhesDialog extends StatelessWidget {
  final Goleiro goleiro;
  final VoidCallback? onEdit;

  const _GoleiroDetalhesDialog({required this.goleiro, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nascimento = goleiro.dataNascimento;
    final idade = _idade(nascimento);
    final telefone = _valor(goleiro.telefone);
    final endereco = [
      if ((goleiro.bairro ?? '').trim().isNotEmpty) goleiro.bairro!.trim(),
      if ((goleiro.cidade ?? '').trim().isNotEmpty) goleiro.cidade!.trim(),
      if ((goleiro.uf ?? '').trim().isNotEmpty)
        goleiro.uf!.trim().toUpperCase(),
    ].join(' • ');
    final foto = goleiro.foto;
    final apelido = (goleiro.apelido ?? '').trim();
    final nomeDoTitulo = apelido.isEmpty ? goleiro.nomeExibicao : apelido;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 480,
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 190,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (foto != null && foto.hasValidBytes)
                    Image.memory(
                      foto.bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: scheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: scheme.onPrimaryContainer,
                          size: 64,
                        ),
                      ),
                    )
                  else
                    ColoredBox(
                      color: scheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        color: scheme.onPrimaryContainer,
                        size: 64,
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _favoriteAction(context),
                        const SizedBox(height: 8),
                        _shareAction(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nomeDoTitulo,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (apelido.isNotEmpty &&
                      goleiro.nomeCompleto.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      goleiro.nomeCompleto,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('IDENTIFICAÇÃO', scheme),
                    _detail('Apelido', _valor(goleiro.apelido)),
                    _detail('Nome completo', goleiro.nomeCompleto),
                    _detail(
                      'Data de nascimento',
                      nascimento == null
                          ? 'Não informado'
                          : '${nascimento.day.toString().padLeft(2, '0')}/'
                                '${nascimento.month.toString().padLeft(2, '0')}/'
                                '${nascimento.year}${idade == null ? '' : ' ($idade anos)'}',
                    ),
                    _detail('Telefone de contato', telefone),
                    const SizedBox(height: 8),
                    _sectionTitle('ENDEREÇO', scheme),
                    _detail(
                      'Bairro, cidade e UF',
                      endereco.isEmpty ? 'Não informado' : endereco,
                    ),
                    const SizedBox(height: 8),
                    _sectionTitle('NÍVEL DO GOLEIRO', scheme),
                    _detail(
                      'Nível do goleiro',
                      _valor(goleiro.situacaoFederativa),
                    ),
                    _detail(
                      'Goleiro reserva',
                      goleiro.comAuxiliares == null
                          ? 'Não informado'
                          : (goleiro.comAuxiliares!
                                ? 'Com reserva'
                                : 'Sem reserva'),
                    ),
                    _detail(
                      'Cachê por partida',
                      goleiro.taxaArbitragem == null
                          ? 'Não informado'
                          : 'R\$ ${goleiro.taxaArbitragem!.toStringAsFixed(2).replaceAll('.', ',')}',
                    ),
                    const SizedBox(height: 8),
                    _sectionTitle('ATUAÇÃO', scheme),
                    _detail('Disponibilidade', _lista(goleiro.atuacao)),
                    const SizedBox(height: 8),
                    _sectionTitle('EQUIPAMENTOS', scheme),
                    _detail('Itens', _lista(goleiro.equipamentos)),
                    const SizedBox(height: 8),
                    _sectionTitle('MODALIDADES', scheme),
                    _detail(
                      'Modalidades atendidas',
                      _lista(goleiro.modalidades),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.primary,
                      side: BorderSide(color: scheme.primary, width: 1.5),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Fechar'),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => onEdit!(),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar cadastro'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteAction(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<DataService>(
      builder: (context, data, _) {
        final favorito = data.isGoleiroFavorito(goleiro.id);
        return Material(
          color: scheme.surface.withValues(alpha: 0.90),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: favorito ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            onPressed: () async {
              unawaited(HapticFeedback.selectionClick());
              try {
                await data.toggleGoleiroFavorito(goleiro.id);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Não foi possível favoritar: $error')),
                );
              }
            },
            icon: Icon(
              favorito ? Icons.star_rounded : Icons.star_border_rounded,
              color: favorito ? AppColors.secondaryColor : scheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _shareAction(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final endereco = goleiro.enderecoCurto;
    final telefone = _valor(goleiro.telefone);
    return Material(
      color: scheme.surface.withValues(alpha: 0.90),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Compartilhar goleiro',
        onPressed: () async {
          unawaited(HapticFeedback.selectionClick());
          final box = context.findRenderObject();
          final origin = box is RenderBox && box.hasSize
              ? box.localToGlobal(Offset.zero) & box.size
              : null;
          try {
            await SharePlus.instance.share(
              ShareParams(
                title: 'Goleiro ${goleiro.nomeExibicao}',
                text: [
                  'Goleiro: ${goleiro.nomeExibicao}',
                  if (endereco.isNotEmpty) 'Localização: $endereco',
                  if (telefone != 'Não informado') 'Contato: $telefone',
                  'Conheça no aplicativo Peladeiros SA: https://peladeiros.app',
                ].join('\n'),
                sharePositionOrigin: origin,
              ),
            );
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Não foi possível compartilhar: $error')),
            );
          }
        },
        icon: Icon(Icons.share_outlined, color: scheme.primary),
      ),
    );
  }

  static Widget _sectionTitle(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: scheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  static Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  static String _valor(String? value) {
    final texto = value?.trim() ?? '';
    return texto.isEmpty ? 'Não informado' : texto;
  }

  static String _lista(List<String> values) =>
      values.isEmpty ? 'Não informado' : values.join(' • ');

  static int? _idade(DateTime? nascimento) {
    if (nascimento == null) return null;
    final hoje = DateTime.now();
    var idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }
    return idade;
  }
}

class _GoleiroGridCard extends StatelessWidget {
  final Goleiro goleiro;
  final bool isOwner;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onTap;
  final bool highlighted;

  const _GoleiroGridCard({
    required this.goleiro,
    required this.isOwner,
    required this.onDelete,
    required this.onEdit,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final apelido = (goleiro.apelido ?? '').trim();
    final titulo = apelido.isNotEmpty ? apelido : goleiro.nome.trim();
    final idade = _calcularIdade(goleiro.dataNascimento);
    final profissional =
        (goleiro.situacaoFederativa ?? '').trim().toLowerCase() ==
        'profissional';
    final disponivelViagem = goleiro.atuacao.any(
      (item) => item.trim().toLowerCase() == 'disponível para viagem',
    );
    final telefone = (goleiro.telefone ?? '').trim();
    final bairro = (goleiro.bairro ?? '').trim();
    final cidadeUf = [
      if ((goleiro.cidade ?? '').trim().isNotEmpty) goleiro.cidade!.trim(),
      if ((goleiro.uf ?? '').trim().isNotEmpty)
        goleiro.uf!.trim().toUpperCase(),
    ].join(' - ');
    final foto = goleiro.foto;
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.16),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Semantics(
            button: true,
            label: 'Card do goleiro ${goleiro.nomeExibicao}',
            hint: 'Toque para ver todos os detalhes do cadastro',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Builder(
                        builder: (_) {
                          if (foto != null && foto.hasValidBytes) {
                            return Image.memory(
                              foto.bytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _goleiroPlaceholder(primary: primary),
                            );
                          }
                          return _goleiroPlaceholder(primary: primary);
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.78),
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.78),
                            ],
                            stops: const [0.0, 0.30, 0.70, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: titulo,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          height: 1.12,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          if (idade != null)
                                            TextSpan(
                                              text: ' ($idade anos)',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (goleiro.nomeCompleto.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        goleiro.nomeCompleto,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.88,
                                          ),
                                          fontWeight: FontWeight.w400,
                                          fontSize: 11,
                                          height: 1.1,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 3,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _favoriteButton(context),
                                  if (profissional) ...[
                                    const SizedBox(height: 3),
                                    _cardIndicator(
                                      icon: Icons.shield_rounded,
                                      label: 'Goleiro profissional',
                                    ),
                                  ],
                                  if (disponivelViagem) ...[
                                    const SizedBox(height: 3),
                                    _cardIndicator(
                                      icon: Icons.flight_rounded,
                                      label: 'Disponível para viagem',
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: isOwner ? 48 : 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (telefone.isNotEmpty)
                            _bottomInfoRow(
                              icon: Icons.phone_in_talk_outlined,
                              text: telefone,
                            ),
                          if (bairro.isNotEmpty)
                            _bottomInfoRow(
                              icon: Icons.location_on_outlined,
                              text: bairro,
                            ),
                          if (cidadeUf.isNotEmpty)
                            _bottomInfoRow(
                              icon: Icons.location_city_outlined,
                              text: cidadeUf,
                            ),
                        ],
                      ),
                    ),
                    if (isOwner)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ownerAction(
                              label: 'Editar goleiro ${goleiro.nomeExibicao}',
                              icon: Icons.edit_outlined,
                              color: AppColors.info,
                              onTap: onEdit,
                            ),
                            const SizedBox(height: 5),
                            _ownerAction(
                              label: 'Excluir goleiro ${goleiro.nomeExibicao}',
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.danger,
                              onTap: onDelete,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goleiroPlaceholder({required Color primary}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.90),
            primary.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_handball_outlined,
          color: Colors.white.withValues(alpha: 0.85),
          size: 54,
        ),
      ),
    );
  }

  int? _calcularIdade(DateTime? nascimento) {
    if (nascimento == null) return null;
    final hoje = DateTime.now();
    var idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }
    return idade;
  }

  Widget _favoriteButton(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, data, _) {
        final favorito = data.isGoleiroFavorito(goleiro.id);
        return Semantics(
          button: true,
          label: favorito ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
          child: Tooltip(
            message: favorito ? 'Remover dos favoritos' : 'Favoritar goleiro',
            child: Material(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  unawaited(HapticFeedback.selectionClick());
                  try {
                    await data.toggleGoleiroFavorito(goleiro.id);
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Não foi possível atualizar favorito: $error',
                        ),
                      ),
                    );
                  }
                },
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    favorito ? Icons.star_rounded : Icons.star_border_rounded,
                    color: favorito ? AppColors.secondaryColor : Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cardIndicator({required IconData icon, required String label}) {
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _bottomInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 11),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 9.5,
                height: 1.05,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              onTap();
            },
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(icon, color: Colors.white, size: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCadastrar;

  const _EmptyState({required this.onCadastrar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final imgSize = isWide ? 220.0 : 160.0;
        final horizontal = isWide ? 48.0 : 24.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: imgSize,
                    height: imgSize,
                    decoration: BoxDecoration(
                      color: primary.withAlphaSafe(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sports_handball_outlined,
                      size: imgSize * 0.5,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nenhum goleiro cadastrado',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comece agora mesmo cadastrando o primeiro goleiro na plataforma.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onCadastrar,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('CADASTRAR PRIMEIRO GOLEIRO'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
