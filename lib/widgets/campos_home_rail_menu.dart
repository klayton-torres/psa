import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CamposHomeRailMenu extends StatefulWidget {
  final double buttonDiameter;
  final double verticalSpacing;
  final double labelColumnWidth;
  final double labelGutter;
  final EdgeInsets labelOffsetAdjust;
  final double notchDockedOffset;
  final double navBarHeight;
  final double centerVerticalAtTopEdgeOffsetAdjust;
  final VoidCallback? onOptionOneTap;
  final VoidCallback? onOptionTwoTap;
  final VoidCallback? onOptionThreeTap;
  // TODO(PSA - FUTURO): Implementar rotinas de clique para as novas opções abaixo
  final VoidCallback? onOptionFourTap;
  final VoidCallback? onOptionFiveTap;
  final VoidCallback? onOptionSixTap;

  // Valor de referência do diâmetro original (base do layout do trilho),
  // usado para manter a largura total do trilho inalterada mesmo quando
  // buttonDiameter é reduzido. Garante alinhamento e sem cortes de borda.
  static const railLayoutReferenceDiameter = 68.4;

  const CamposHomeRailMenu({
    super.key,
    // buttonDiameter REDUZIDO para 60.0 (folga lateral = (68.4-60)/2 = 4.2px
    // em cada lado). Maior borda strokeOutside é 2.4px → folga de 4.2px
    // é suficiente para NUNCA cortar as bordas nos limites do trilho.
    this.buttonDiameter = 60.0,
    // verticalSpacing reduzido proporcionalmente junto com o diâmetro
    this.verticalSpacing = 5.0,
    this.labelColumnWidth = 92.0,
    this.labelGutter = 10.0,
    this.labelOffsetAdjust = EdgeInsets.zero,
    this.notchDockedOffset = 0.0,
    this.navBarHeight = 88.0,
    this.centerVerticalAtTopEdgeOffsetAdjust = 0.0,
    this.onOptionOneTap,
    this.onOptionTwoTap,
    this.onOptionThreeTap,
    // TODO(PSA - FUTURO): Conectar os callbacks abaixo nas rotinas correspondentes
    this.onOptionFourTap,
    this.onOptionFiveTap,
    this.onOptionSixTap,
  });

  @override
  State<CamposHomeRailMenu> createState() => _CamposHomeRailMenuState();
}

class _CamposHomeRailMenuState extends State<CamposHomeRailMenu>
    with SingleTickerProviderStateMixin {
  bool _aberto = false;
  late final AnimationController _anim;
  late final List<Animation<double>> _itemAnims;
  static const _staggerMillis = 60;
  static const _baseAnimMillis = 280;

  // Total de itens no menu rail (inclui as novas opções 4, 5 e 6)
  static const _totalMenuItems = 6;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: _baseAnimMillis + (_totalMenuItems - 1) * _staggerMillis,
      ),
    );
    _itemAnims = List.generate(_totalMenuItems, (i) {
      final start = i * _staggerMillis / _anim.duration!.inMilliseconds;
      const duration =
          _baseAnimMillis /
          (_baseAnimMillis + (_totalMenuItems - 1) * _staggerMillis);
      final end = start + duration;
      return CurvedAnimation(
        parent: _anim,
        curve: Interval(
          start,
          (end > 1.0) ? 1.0 : end,
          curve: Curves.easeOutBack,
        ),
      );
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _alternarMenu() {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _aberto = !_aberto;
      if (_aberto) {
        _anim.forward();
      } else {
        _anim.reverse();
      }
    });
  }

  void _acionarComFechamento(VoidCallback? callback) {
    if (mounted) {
      setState(() {
        _aberto = false;
      });
      unawaited(
        _anim.reverse().then((_) {
          if (callback != null) {
            callback.call();
          }
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final paddingBottom = mq.padding.bottom;
    // Usa a referência ORIGINAL do diâmetro para manter o centro vertical
    // do botão principal (e a LARGURA DO TRILHO) inalterados.
    const refDiameter = CamposHomeRailMenu.railLayoutReferenceDiameter;
    final halfRefDiameter = refDiameter / 2;
    final labelTotalWidth = widget.labelColumnWidth + widget.labelGutter;
    // ⚠ Largura do TRILHO (container) MANTIDA com base no diâmetro original,
    // evita cortes e preserva o alinhamento externo do componente.
    final totalWidth = labelTotalWidth + refDiameter;
    // Gap vertical entre os itens (usa diâmetro reduzido + spacing reduzido)
    final itemVerticalGap = widget.buttonDiameter + widget.verticalSpacing;
    // Deslocamento horizontal para manter o centro visual dos botões
    // idêntico ao original (centraliza o botão menor no mesmo ponto do
    // botão maior que existia anteriormente).
    // ✅ buttonDiameter PERMANECE INTACTO (53.2) — dimensões dos filhos
    //    NÃO são alteradas conforme requisito.
    // ✅ Folga lateral por lado = (68.4 - 53.2)/2 = 7.6px
    //    > nova folga de container 2.64px → 0 cortes, garantido.
    final buttonCenteringOffsetX = (refDiameter - widget.buttonDiameter) / 2;
    // ============================================================
    // ✅ DESLOCAMENTO VERTICAL PARA CORRIGIR SOBREPOSIÇÃO PELADAS vs HOME:
    // Todos os 6 itens do menu são deslocados para CIMA do botão Home
    // em (buttonDiameter + 2px). Isso garante 0 sobreposição.
    // ============================================================
    final buttonVerticalOffsetFromHome = widget.buttonDiameter + 2;
    // ============================================================
    // ✅ AUMENTO DE 10% NA ESTRUTURA CONTAINER DO TRILHO
    // Obs: maxOutsideStrokeWidth e borderPadding descrevem FOLGAS do
    // container (padding/margem virtual de folga). Aumentando-os,
    // a ESTRUTURA do trilho cresce, enquanto os botões (buttonDiameter,
    // verticalSpacing) permanecem INTACTOS (53.2 e 3.8, respectivamente).
    // ============================================================
    // Folga de borda (AUMENTADA em 10%):
    //    antes 2.4 → agora 2.64 (2.4 * 1.10)
    // borderPadding simétrico (2 lados):
    //    antes 4.8 → agora 5.28 (4.8 * 1.10 = 2 * 2.64)
    const maxOutsideStrokeWidth = 2.64;
    const borderPadding = 2 * maxOutsideStrokeWidth;
    // Largura do Stack externo (folga adicional para bordas laterais):
    // aumenta proporcionalmente ao borderPadding de 10%.
    final stackTotalWidth = totalWidth + borderPadding;
    // Altura do Stack externo:
    // (Home) + (gap Home→itens) + (6 itens + 5 gaps) + (folga interna 12→13.2×1.10)
    // + (folga bordas borderPadding).
    // → Folga altura também aumentada em 10%: 12 × 1.10 = 13.2
    const internalHeightGap = 13.2;
    final stackTotalHeight =
        widget.buttonDiameter +
        buttonVerticalOffsetFromHome +
        (_totalMenuItems - 1) * itemVerticalGap +
        internalHeightGap +
        borderPadding;

    // ============================================================
    // 🔧 POSICIONAMENTO DO BOTÃO HOME NO CENTRO SUPERIOR DA NAVBAR
    // bottomPos: distância da base da tela até a borda inferior do
    // container expandido do trilho. Calculado para que o CENTRO do
    // botão HOME (refDiameter/2) coincida exatamente com a BORDA SUPERIOR
    // da CustomBottomNavBar, agregado e alinhado no meio da barra (notch).
    // ✅ NÃO subtraímos maxOutsideStrokeWidth de bottomPos: folga de
    // bordas é tratada APENAS internamente via stackInnerOffsetX/Y.
    // ============================================================
    final yCentroSuperior =
        paddingBottom +
        widget.centerVerticalAtTopEdgeOffsetAdjust +
        halfRefDiameter;
    final bottomPos =
        yCentroSuperior - halfRefDiameter + widget.notchDockedOffset;
    // Offset interno para centralizar o conteúdo dentro da folga de bordas
    const stackInnerOffsetX = maxOutsideStrokeWidth;
    const stackInnerOffsetY = maxOutsideStrokeWidth;

    // ============================================================
    // ✅ ALTURA EXTERNA DO SIZEDBOX RAIZ (valor ORIGINAL ~80px)
    // Essa altura é CRÍTICA para que o Scaffold, ao usar
    // FloatingActionButtonLocation.centerDocked, alinhe o componente
    // agregado à barra de navegação. MANTENDO a altura original garante
    // a SINCRONIZAÇÃO PERFEITA com animações e transformações da navbar
    // (ex: shrink, expand, scroll-driven animations).
    // ============================================================
    final originalScaffoldFabHeight = widget.navBarHeight + paddingBottom;

    return SizedBox(
      width: screenWidth,
      height: originalScaffoldFabHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topLeft,
        children: [
          // ============================================================
          // ✅ 1º FILHO (z-index MENOR — fica ATRÁS):
          // GestureDetector para FECHAR MENU ao clicar FORA da área dos
          // botões do trilho.
          // - HitTestBehavior.translucent + Stack(clipBehavior: Clip.none)
          //   → captura cliques em TODA a área da tela (incluindo para cima
          //   da altura reduzida de 80px do SizedBox raiz, onde ficam os
          //   6 botões do menu expandido).
          // - Como 1º filho, fica atrás (z-index menor). Toques que CAEM
          //   em cima dos botões (último filho da lista abaixo) SÃO
          //   entregues primeiro ao botão (responde com navegação); toques
          //   FORA do trilho → chegam neste detector → fecha o menu.
          // ============================================================
          if (_aberto)
            Positioned.fill(
              child: Semantics(
                label: 'Fechar menu',
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _alternarMenu,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          // ============================================================
          // ✅ 2º E ÚLTIMO FILHO (z-index MAIOR — fica NA FRENTE):
          // Positioned com o TRILHO + BOTÃO HOME + 6 BOTÕES.
          // Por ser o ÚLTIMO filho do Stack → recebe os toques ANTES do
          // GestureDetector de fechar → resolve o bug em que nenhum botão
          // respondia a cliques (os toques eram absorvidos pelo detector).
          // ============================================================
          Positioned(
            left: 0,
            bottom: bottomPos,
            width: stackTotalWidth,
            height: stackTotalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomLeft,
              children: [
                Positioned(
                  left: stackInnerOffsetX,
                  bottom: stackInnerOffsetY,
                  width: totalWidth,
                  height:
                      widget.buttonDiameter +
                      buttonVerticalOffsetFromHome +
                      (_totalMenuItems - 1) * itemVerticalGap +
                      internalHeightGap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomLeft,
                    children: [
                      _buildMainButton(
                        totalWidth: totalWidth,
                        buttonCenteringOffsetX: buttonCenteringOffsetX,
                      ),
                      _buildOptionItem(
                        indiceDeBaixoParaCima: 5,
                        indiceVisualDeCimaParaBaixo: 5,
                        animation: _itemAnims[5],
                        title: 'JUÍZES',
                        semanticLabel: 'Abrir tela de Juízes',
                        tooltip: 'Juízes',
                        buttonVerticalOffsetFromHome:
                            buttonVerticalOffsetFromHome,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF0F0F0), Color(0xFF9A9A9A)],
                        ),
                        icon: Icons.sports_rounded,
                        iconColor: Colors.black,
                        iconShadowColor: const Color(0xFF2A2A2A),
                        strokeWidth: 2.4,
                        onTap: () =>
                            _acionarComFechamento(widget.onOptionFourTap),
                        itemVerticalGap: itemVerticalGap,
                        buttonCenteringOffsetX: buttonCenteringOffsetX,
                        enabled: true,
                        showLabel: true,
                      ),
                      // ============================================================
                      // Botão CAMPOS — atualiza a tela atual (Campos e Arenas)
                      // HABILITADO: funcionalidade completa.
                      // ============================================================
                      _buildOptionItem(
                        indiceDeBaixoParaCima: 4,
                        indiceVisualDeCimaParaBaixo: 4,
                        animation: _itemAnims[4],
                        title: 'CAMPOS',
                        semanticLabel: 'Atualizar tela de Campos e Arenas',
                        tooltip: 'Atualizar Campos',
                        buttonVerticalOffsetFromHome:
                            buttonVerticalOffsetFromHome,
                        // ↓↓ Gradiente do botão ARENA/CAMPOS [85E673 → 00793B]
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF85E673), Color(0xFF00793B)],
                        ),
                        // ↓↓ Ícone do botão ARENA/CAMPOS (stadium)
                        icon: Icons.stadium_rounded,
                        // ↓↓ Cor do ícone do botão ARENA/CAMPOS [07160E]
                        iconColor: Color(0xFF07160E),
                        // ↓↓ Cor da borda do botão ARENA/CAMPOS [004024]
                        iconShadowColor: const Color(0xFF004024),
                        // ↓↓ Largura da borda do botão ARENA/CAMPOS (2.0)
                        strokeWidth: 2.0,
                        onTap: () =>
                            _acionarComFechamento(widget.onOptionFiveTap),
                        itemVerticalGap: itemVerticalGap,
                        buttonCenteringOffsetX: buttonCenteringOffsetX,
                        // ✅ HABILITADO (funcionalidade: atualiza a tela atual)
                        enabled: true,
                      ),
                      // ============================================================
                      // Botão VÁRIOS — navega para Home com filtro de exclusão
                      // HABILITADO: funcionalidade completa.
                      // ============================================================
                      _buildOptionItem(
                        indiceDeBaixoParaCima: 3,
                        indiceVisualDeCimaParaBaixo: 3,
                        animation: _itemAnims[3],
                        title: 'VÁRIOS',
                        semanticLabel:
                            'Filtrar modalidades que não são futebol, vôlei ou basquete',
                        tooltip: 'Outras modalidades',
                        buttonVerticalOffsetFromHome:
                            buttonVerticalOffsetFromHome,
                        // ↓↓ Gradiente do botão VÁRIOS [D4EF5A → 7EA600]
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD4EF5A), Color(0xFF7EA600)],
                        ),
                        // ↓↓ Ícone do botão VÁRIOS (sports_tennis)
                        icon: Icons.sports_tennis_rounded,
                        // ↓↓ Cor do ícone do botão VÁRIOS (branco)
                        iconColor: Colors.white,
                        // ↓↓ Cor da borda do botão VÁRIOS [2E4300]
                        iconShadowColor: const Color(0xFF2E4300),
                        // ↓↓ Largura da borda do botão VÁRIOS (2.0)
                        strokeWidth: 2.0,
                        onTap: () =>
                            _acionarComFechamento(widget.onOptionSixTap),
                        itemVerticalGap: itemVerticalGap,
                        buttonCenteringOffsetX: buttonCenteringOffsetX,
                        // ✅ HABILITADO (filtra modalidades diversas)
                        enabled: true,
                      ),
                      // ============================================================
                      // Botão BASQUETE — configuração EXTRAÍDA DO TRAIL MENU DA TELA HOME
                      // (ProfileSportsRailMenu, id: 'basquete').
                      // ============================================================
                      _buildOptionItem(
                        indiceDeBaixoParaCima: 2,
                        indiceVisualDeCimaParaBaixo: 2,
                        animation: _itemAnims[2],
                        title: 'BASQUETE',
                        semanticLabel: 'Menu Basquete',
                        tooltip: 'Basquete',
                        buttonVerticalOffsetFromHome:
                            buttonVerticalOffsetFromHome,
                        // ↓↓ Gradiente do botão BASQUETE da Home [FF8A3D → C94807]
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF8A3D), Color(0xFFC94807)],
                        ),
                        // ↓↓ Ícone do botão BASQUETE da Home (sports_basketball)
                        icon: Icons.sports_basketball_rounded,
                        // ↓↓ Cor do ícone do botão BASQUETE da Home [3B1400]
                        iconColor: Color(0xFF3B1400),
                        // ↓↓ Cor da borda do botão BASQUETE da Home [4A1700]
                        iconShadowColor: const Color(0xFF4A1700),
                        // ↓↓ Largura da borda do botão BASQUETE da Home (2.0)
                        strokeWidth: 2.0,
                        onTap: () =>
                            _acionarComFechamento(widget.onOptionOneTap),
                        itemVerticalGap: itemVerticalGap,
                        buttonCenteringOffsetX: buttonCenteringOffsetX,
                        enabled: true,
                      ),
                      // ============================================================
                      // Botão VÔLEI — configuração EXTRAÍDA DO TRAIL MENU DA TELA HOME
                      // (ProfileSportsRailMenu, id: 'volei').
                      // ============================================================
                      _buildOptionItem(
                        indiceDeBaixoParaCima: 1,
                        indiceVisualDeCimaParaBaixo: 1,
                        animation: _itemAnims[1],
                        title: 'VÔLEI',
                        semanticLabel: 'Menu Vôlei',
                        tooltip: 'Vôlei',
                        buttonVerticalOffsetFromHome:
                            buttonVerticalOffsetFromHome,
                        // ↓↓ Gradiente do botão VÔLEI da Home [FFDB4D → 0C4DA2]
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFDB4D), Color(0xFF0C4DA2)],
                        ),
                        // ↓↓ Ícone do botão VÔLEI da Home (sports_volleyball)
                        icon: Icons.sports_volleyball_rounded,
                        // ↓↓ Cor do ícone do botão VÔLEI da Home [10316B]
                        iconColor: Color(0xFF10316B),
                        // ↓↓ Cor da borda do botão VÔLEI da Home [0A2E63]
                        iconShadowColor: const Color(0xFF0A2E63),
                        // ↓↓ Largura da borda do botão VÔLEI da Home (2.0)
                        strokeWidth: 2.0,
                        onTap: () =>
                            _acionarComFechamento(widget.onOptionTwoTap),
                        itemVerticalGap: itemVerticalGap,
                        buttonCenteringOffsetX: buttonCenteringOffsetX,
                        enabled: true,
                      ),
                      // ============================================================
                      // Botão PELADAS — configuração EXTRAÍDA DO TRAIL MENU DA TELA HOME
                      // (ProfileSportsRailMenu, id: 'peladas').
                      // ============================================================
                      _buildOptionItem(
                        indiceDeBaixoParaCima: 0,
                        indiceVisualDeCimaParaBaixo: 0,
                        animation: _itemAnims[0],
                        title: 'PELADAS',
                        semanticLabel: 'Menu Peladas',
                        tooltip: 'Peladas',
                        buttonVerticalOffsetFromHome:
                            buttonVerticalOffsetFromHome,
                        // ↓↓ Gradiente do botão PELADAS da Home [FFFFFF → DCDCDC]
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFDCDCDC)],
                        ),
                        // ↓↓ Ícone do botão PELADAS da Home (sports_soccer)
                        icon: Icons.sports_soccer_rounded,
                        // ↓↓ Cor do ícone do botão PELADAS da Home (preto)
                        iconColor: Colors.black,
                        // ↓↓ Cor da borda do botão PELADAS da Home (preto)
                        iconShadowColor: Colors.black,
                        // ↓↓ Largura da borda do botão PELADAS da Home (2.4)
                        strokeWidth: 2.4,
                        onTap: () =>
                            _acionarComFechamento(widget.onOptionThreeTap),
                        itemVerticalGap: itemVerticalGap,
                        buttonCenteringOffsetX: buttonCenteringOffsetX,
                        enabled: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required int indiceDeBaixoParaCima,
    required int indiceVisualDeCimaParaBaixo,
    required Animation<double> animation,
    required String title,
    required String semanticLabel,
    required String tooltip,
    required LinearGradient gradient,
    required IconData icon,
    required Color iconColor,
    required Color iconShadowColor,
    required double strokeWidth,
    required VoidCallback onTap,
    required double itemVerticalGap,
    required double buttonCenteringOffsetX,
    // Offset vertical que empurra os 6 itens PARA CIMA do botão Home,
    // eliminando a sobreposição (PELADAS e HOME não mais compartilham espaço).
    required double buttonVerticalOffsetFromHome,
    // Controla se o botão está habilitado para clique ou bloqueado
    required bool enabled,
    // Quando true, exibe também o chip de texto AO LADO do botão redondo.
    // Quando false (ex: botão Juízes com apito), exibe apenas o botão.
    bool showLabel = true,
  }) {
    final xLabel = 0.0;
    // Mantém o label alinhado no mesmo ponto (na coluna de labels)
    // e desloca apenas o botão para centralizá-lo no centro original.
    final xButton =
        widget.labelColumnWidth + widget.labelGutter + buttonCenteringOffsetX;
    // ✅ y agora é deslocado por buttonVerticalOffsetFromHome para os
    // itens ficarem ACIMA do botão Home, sem sobreposição.
    final y =
        buttonVerticalOffsetFromHome +
        indiceVisualDeCimaParaBaixo * itemVerticalGap;
    return Positioned(
      left: 0,
      bottom: y,
      // Largura usa a referência original para não cortar o trilho
      width:
          CamposHomeRailMenu.railLayoutReferenceDiameter +
          widget.labelGutter +
          widget.labelColumnWidth,
      height: widget.buttonDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: [
          if (showLabel)
            Positioned(
              left: xLabel,
              bottom: 0,
              // Estende o chip até o início do botão; assim o rótulo fica
              // alinhado à esquerda do botão sem invadir sua área.
              width:
                  widget.labelColumnWidth +
                  widget.labelGutter +
                  buttonCenteringOffsetX,
              height: widget.buttonDiameter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.25, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: _OptionLabel(
                    text: title,
                    adjust: widget.labelOffsetAdjust,
                    enabled: enabled,
                    // ✅ Label de texto agora é CLICÁVEL e dispara a MESMA
                    // rotina do botão redondo ao lado.
                    onTap: onTap,
                    semanticLabel: semanticLabel,
                    tooltip: tooltip,
                  ),
                ),
              ),
            ),
          Positioned(
            left: xButton,
            bottom: 0,
            child: ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: _CamposHomeRailItem(
                  onTap: onTap,
                  gradient: gradient,
                  icon: icon,
                  iconColor: iconColor,
                  iconShadowColor: iconShadowColor,
                  strokeWidth: strokeWidth,
                  semanticLabel: semanticLabel,
                  tooltip: tooltip,
                  diameter: widget.buttonDiameter,
                  enabled: enabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton({
    required double totalWidth,
    required double buttonCenteringOffsetX,
  }) {
    const gradientHome = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFDEDEDE)],
    );
    // Mantém o mesmo centro horizontal do botão principal original.
    final mainLeft =
        widget.labelColumnWidth + widget.labelGutter + buttonCenteringOffsetX;
    return Positioned(
      left: mainLeft,
      bottom: 0,
      // ✅ Opacidade uniforme de 0.85 aplicada no botão principal
      child: Opacity(
        opacity: 0.85,
        child: Semantics(
          button: true,
          label: _aberto ? 'Fechar menu da Home' : 'Abrir menu da Home',
          hint: 'Toque duas vezes para acionar',
          child: Tooltip(
            message: _aberto ? 'Fechar menu' : 'Abrir menu da Home',
            preferBelow: false,
            verticalOffset: widget.buttonDiameter / 2,
            child: SizedBox(
              width: widget.buttonDiameter,
              height: widget.buttonDiameter,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: Ink(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradientHome,
                    border: Border.all(
                      color: Colors.black,
                      width: 3.0,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: _aberto ? 0.32 : 0.22,
                        ),
                        blurRadius: _aberto ? 20 : 16,
                        spreadRadius: _aberto ? 0.5 : 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    splashFactory: InkRipple.splashFactory,
                    splashColor: Colors.black.withValues(alpha: 0.10),
                    highlightColor: Colors.white.withValues(alpha: 0.22),
                    onTap: _alternarMenu,
                    // ✅ Padding interno reduzido de 0.14 → 0.12 do diâmetro
                    // para compensar a redução geral de 5% dos botões.
                    // Com diâmetro 53.2: 12% = 6.384px → ícone fica com ~40.4px,
                    // ainda grande, garantindo legibilidade e área de toque.
                    child: Padding(
                      padding: EdgeInsets.all(widget.buttonDiameter * 0.12),
                      child: const FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: Icon(Icons.home_rounded, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CamposHomeRailItem extends StatelessWidget {
  final double diameter;
  final VoidCallback onTap;
  final Gradient gradient;
  final IconData icon;
  final Color iconColor;
  final Color iconShadowColor;
  final double strokeWidth;
  final String semanticLabel;
  final String tooltip;
  // Controla estado do botão: habilitado (clicável) ou desabilitado
  final bool enabled;

  const _CamposHomeRailItem({
    required this.diameter,
    required this.onTap,
    required this.gradient,
    required this.icon,
    required this.iconColor,
    required this.iconShadowColor,
    required this.strokeWidth,
    required this.semanticLabel,
    required this.tooltip,
    // Default para true garante retrocompatibilidade
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Quando desabilitado: ignora clique e aplica redução de opacidade + overlay
    final effectiveOnTap = enabled ? onTap : null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      hint: enabled
          ? 'Toque duas vezes para acionar'
          : 'Funcionalidade em desenvolvimento',
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        verticalOffset: diameter / 2,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Opacity(
            // ✅ Opacidade BASE uniforme de 0.85 aplicada a TODOS os botões
            // (aplica adicional de 0.55 quando desabilitado, sem quebrar a uniformidade base)
            opacity: enabled ? 0.85 : 0.85 * 0.55,
            child: IgnorePointer(
              // Bloqueia interações visuais quando desabilitado
              ignoring: !enabled,
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient,
                    border: Border.all(
                      color: iconShadowColor,
                      width: strokeWidth,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    boxShadow: [
                      if (enabled)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          spreadRadius: 0.6,
                          offset: const Offset(0, 6),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 6,
                          spreadRadius: 0.2,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      InkWell(
                        customBorder: const CircleBorder(),
                        splashFactory: enabled
                            ? InkRipple.splashFactory
                            : NoSplash.splashFactory,
                        splashColor: enabled
                            ? Colors.white.withValues(alpha: 0.20)
                            : Colors.transparent,
                        highlightColor: enabled
                            ? Colors.black.withValues(alpha: 0.08)
                            : Colors.transparent,
                        onTap: effectiveOnTap,
                        // ✅ Padding interno reduzido de 0.14 → 0.12 do diâmetro
                        // para compensar a redução geral de 5% dos botões.
                        // Com diâmetro 53.2: 12% = 6.384px por lado, resultando
                        // em ~40.4px para o ícone (FittedBox dimensiona).
                        // Garante 24px de mínimos de ícones (MDG).
                        child: Padding(
                          padding: EdgeInsets.all(diameter * 0.12),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            child: Icon(
                              icon,
                              color: iconColor,
                              shadows: enabled
                                  ? [
                                      Shadow(
                                        color: iconShadowColor.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      // Overlay de "Em Breve" apenas quando desabilitado
                      if (!enabled)
                        Positioned(
                          top: diameter * 0.06,
                          right: diameter * 0.06,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '🔒',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets adjust;
  // Controla o estado visual do label: opacidade reduzida se desabilitado
  final bool enabled;
  // Callback quando usuário clica no chip de texto ao lado do botão.
  // Deve disparar a MESMA rotina do botão redondo correspondente.
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? tooltip;

  const _OptionLabel({
    required this.text,
    required this.adjust,
    // Default para true garante retrocompatibilidade
    this.enabled = true,
    this.onTap,
    this.semanticLabel,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Quando desabilitado: bloqueia clique no label (igual ao botão ao lado)
    final effectiveOnTap = enabled ? onTap : null;
    final labelChild = Opacity(
      // ✅ Opacidade UNIFORME de 0.85 aplicada a TODOS os labels, sem variação
      opacity: 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          left: adjust.left,
          right: adjust.right,
          top: adjust.top,
          bottom: adjust.bottom,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          // Material puro + InkWell garante animação de ripple no clique
          // do chip de texto (consistente com os botões redondos).
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              splashFactory: InkRipple.splashFactory,
              splashColor: Colors.black.withValues(alpha: 0.06),
              highlightColor: Colors.black.withValues(alpha: 0.04),
              onTap: effectiveOnTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1F2C).withValues(alpha: 0.90)
                      : Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  // ✅ BORDA REMOVIDA COMPLETAMENTE
                  // Sombra UNIFORME aplicada a TODOS os labels
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? (isDark ? Colors.white : const Color(0xFF1F2430))
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : const Color(0xFF6B7280)),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Envolve em Tooltip + Semantics apenas se houver informação disponível
    // (mantém consistência com o Tooltip aplicado aos botões redondos).
    Widget child = labelChild;
    if (semanticLabel != null || tooltip != null) {
      child = Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        hint: enabled
            ? 'Toque duas vezes para acionar'
            : 'Funcionalidade em desenvolvimento',
        child: tooltip != null
            ? Tooltip(message: tooltip!, preferBelow: false, child: child)
            : child,
      );
    }
    // IgnorePointer quando !enabled + onTap existir, garante que o label
    // desabilitado não receba eventos acidentalmente.
    if (!enabled && onTap != null) {
      child = IgnorePointer(ignoring: true, child: child);
    }
    return child;
  }
}

void unawaited(Future<void>? f) {
  if (f == null) return;
}
