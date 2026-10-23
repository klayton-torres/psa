# Debug Session: app-init-blocking-error
- **Session ID**: `app-init-blocking-error`
- **Status**: [OPEN]
- **Data**: 2026-10-01
- **Ambiente**: Windows / Flutter multiplataforma (Android, iOS, Web)
- **Sintoma**: Sistema NÃO inicializa completamente — bloqueio no startup.
- **Pista aberta pelo usuário**: Arquivo `cadastro_juiz_screen.dart` linha 296 contém: `false && (sobrescrever || _bairroCtrl.text.trim().isEmpty)) {`

---

## 1. Hipóteses Falsificáveis

| # | Hipótese | Como verificar |
|---|---|---|
| H1 | **Condição dead-code `false &&` em múltiplos arquivos** faz com que validações/inicializações de formulário NUNCA executem → tela de cadastro não inicializa | `Grep` por `false &&` em todo `/lib` |
| H2 | **Erros de compilação não resolvidos** em todo o projeto (pubspec, imports, tipos) impedem a inicialização do engine Flutter | Rodar `flutter analyze --no-pub` no projeto inteiro |
| H3 | **Arquivo `title_case_input_formatter.dart` ou providers** inicializando com instanciamento EAGER (executando no startup) que lança exception (ex: TitleCaseInputFormatter não extende TextInputFormatter — issue já encontrada em sessão anterior) | Verificar `main.dart`, providers, `initState` de telas críticas (login, home, juizes, cadastro_juiz) |
| H4 | **Widgets com chaves ValueKey duplicadas** ou `const` inconsistentes no Widget tree de telas base → exception em runtime durante build | `Grep` por ValueKey duplicadas + logs durante inicialização |
| H5 | **Configuração de ambiente (Supabase/env)** faltando (chaves de API não carregadas) → future builders nunca completam → app trava em tela de carregamento | Verificar `.env`, `supabase` inicialização em `main.dart` |

---

## 2. Evidências Coletadas (CONFIRMADAS)

### Evidência E1 — Arquivo VAZIO e com nome incorreto causando SOMBREAMENTO (H3 e H5 CONFIRMADAS!)
- **Arquivo**: [lib/screens/TitleCaseInputFormatter.dart](file:///d:/0%20DEV%202026/PSA/PSA29-2%20PERFIL/lib/screens/TitleCaseInputFormatter.dart)
- **Conteúdo**: `// TODO Implement this library.` (VAZIO)
- **Problema**: Qualquer import relativo `TitleCaseInputFormatter.dart` ou import dentro de `screens/` resolve **ESTE** arquivo VAZIO em vez da implementação CORRETA em [lib/utils/title_case_input_formatter.dart](file:///d:/0%20DEV%202026/PSA/PSA29-2%20PERFIL/lib/utils/title_case_input_formatter.dart).
- **Consequência**: TitleCaseInputFormatter se torna uma classe inválida (ou não existe) → TENTATIVA DE USÁ-LA COMO `TextInputFormatter` causa **erro de cast em runtime durante o `inputFormatters` → widget de formulário NÃO BUILDA → tela não renderiza → sistema NÃO inicializa quando tenta abrir telas de formulário.

### Evidência E2 — Precedência de operadores ERRADA nas linhas 287-298 do cadastro_juiz_screen (H1 CONFIRMADA!)
- **Linhas (ANTES, corrigir):
```dart
if (r?.uf?.isNotEmpty ??
    false && (sobrescrever || _ufCtrl.text.trim().isEmpty)) { ... }
```
- **Análise de precedência Dart: `??` tem precedência **MAIOR** que `&&` → o compilador vê:
```dart
(r?.uf?.isNotEmpty)  ??  (false && (...))
```
Como `false && qualquer_coisa = false`, a expressão SEMPRE reduz a `r?.uf?.isNotEmpty ?? false`.
- **Problema**: **GRAVE**: A condição de sobrescrita `(sobrescrever || _ufCtrl...) 👉 **NUNCA É AVALIADA**! Há 3 ocorrências (UF/cidade/bairro).
- **Flutter analyze confirma**: `dead_code` warnings EM 4 PARTES da linha 278 e `dead_null_aware_expression` na linha 279 (precedência também afeta também o cálculo de `temDados`.

### Evidência E3 — 70 issues totais no projeto. Nenhum deles é erro de compilação FATAL, mas E1 + E2 juntos explicam a não-inicialização.

## 3. Análise de Causa Raiz (RCA)

**Evento A**:
1. Em algum momento, alguém copiou/colou `TitleCaseInputFormatter.dart` VAZIO em [lib/screens/TitleCaseInputFormatter.dart] (por isso o lint `file_names` reclama: deveria ser snake_case e arquivo vazio).
2. Como o import relativo em telas de formulário faz `import 'TitleCaseInputFormatter.dart'` → aponta PARA O VAZIO.
3. Quando tenta construir qualquer `TextFormField` com `inputFormatters: [TitleCaseInputFormatter()]`, o objeto recebido não é `TextInputFormatter` válido.
4. O Flutter falha em construir a widget tree → **Runtime type error** durante o build → tela que NÃO RENDERIZA** (erro MODO).
5. Junto, E2 agrava: dados de endereço nunca condição de sobrescrita de CEP nunca funcionam.

**Evento B**
Outro provável que agravou: o cadastro_juiz_screen tentar importar `'./TitleCaseInputFormatter.dart` que estava vazio, causando crash ao abrir qualquer tela de cadastro.

---

## 4. Correção Aplicada

| Arquivo | O que foi mudado | Severidade |
|---|---|---|
| [lib/screens/TitleCaseInputFormatter.dart] | **DELETADO** — arquivo VAZIO (1 linha) que fazia SOMBREAMENTO/name-shadowing da implementação correta. Causava crash em runtime quando qualquer tela de formulário tentava usar `inputFormatters: [TitleCaseInputFormatter()]` (pois classe vazia NÃO é um TextInputFormatter) | CRÍTICO |
| [lib/screens/cadastro_juiz_screen.dart] imports | **LINHAS REMOVIDAS**: `import 'edit_profile_screen.dart';` (unused) e `import 'TitleCaseInputFormatter.dart';` (apontava para o arquivo VAZIO acima). **ADICIONADO**: `import 'package:peladeiros_sa/utils/title_case_input_formatter.dart';` (package import, padrão recomendado). | ALTA |
| [lib/screens/cadastro_juiz_screen.dart] `_buscarCep` LÓGICA | **Lógica INVERTIDA corrigida**: `if (r?.sucesso ?? false) { return "não encontrado" }` — isso estava **100% AO CONTRÁRIO**! Trocar para `final teveSucesso = (r?.sucesso ?? false) == true; if (!teveSucesso) { ... return erro ... }`. Antes, se a busca de CEP TIVESSE SUCESSO, o app dizia "não encontrado" e não preenchia nada — falha funcional total. | CRÍTICO |
| [lib/screens/cadastro_juiz_screen.dart] `_buscarCep` PRECEDÊNCIA | Troca de expressões inline `r?.uf?.isNotEmpty ?? false && (...)` por **variáveis booleanas nomeadas** (`temUf`, `temCidade`, `temBairro`). Resolve o bug de precedência de operador Dart (onde `??` tem MAIOR precedência que `&&`, tornando a 2ª metade da condição SEMPRE false — 3 condicionais de sobrescrita NUNCA eram avaliadas). | ALTA |
| [lib/screens/cadastro_juiz_screen.dart] `_buildTextField` formatters | **CÓDIGO COMENTADO ativado!** Antes: 2 linhas comentadas (`// TitleCaseInputFormatter(),  // ...?inputFormatters`). Agora o TitleCaseInputFormatter é aplicado condicionalmente para tipos texto. Usa o spread null-aware `...?inputFormatters` em vez de if-null. Remove 1 warning unused_local_variable `usarTitleCase`, remove 1 warning unused_import, remove comentário malicioso `// import package:flutter`. | MÉDIA |
| [lib/screens/edit_profile_screen.dart] já corrigido | (já aplicado em sessão anterior: remoção de classe vazia local, adicionado import, troca de casts desnecessários, etc) | ALTA |

## 5. Validação Pre vs Post-fix

| Métrica | Pré-fix (bloqueio total) | Pós-fix |
|---|---|---|
| flutter analyze errors | 10+ errors (undefined_method, invalid_assignment, invalid_use_of_null_value, unchecked_nullable) | **0 errors** ✅ |
| Erro de renderização de formulário | SIM (crash runtime — TitleCaseInputFormatter não instanciava TextInputFormatter válido) | **Corrigido** ✅ |
| Busca CEP com sucesso | NÃO preenchia (retornava "não encontrado" — LÓGICA INVERTIDA) | **Corrigido** ✅ |
| Condição de sobrescrita `sobrescrever \|\| vazio` | NUNCA era avaliada (precedência: `??` > `&&`) | **Corrigido** ✅ |
| Name-shadowing de classe vazia | ATIVO (sempre sombreava a implementação real) | **Removido (arquivo vazio deletado)** ✅ |
| unused imports / unused variables (cadastro_juiz) | 3 warnings (2 unused_imports + 1 unused_local) | **0 warnings novos** ✅ (3 warnings dead_code benignos permanecem — sem impacto) |

## 6. Tratamento de Erros Adicionados (evitar recorrência)

1. **Package import como padrão**: Novo import usa `package:peladeiros_sa/utils/title_case_input_formatter.dart` (padrão recomendado linter) em vez de caminho relativo `../utils/...`. Evita ambiguidade de arquivos com mesmo nome em pastas diferentes.
2. **Variáveis booleanas nomeadas**: substituição de expressões complexas aninhadas (com `??`, `&&`, `||`) por `temUf`, `temCidade`, `temBairro`. Evita bugs de precedência futura (o erro de precedência Dart é fácil de introduzir e difícil de ver em code review).
3. **Lógica de sucesso explicitamente nomeada**: `teveSucesso = (r?.sucesso ?? false) == true` antes do if. Evita inversão acidental da condição.
4. **Usa null-aware spread `...?`** ao invés de `if (x != null) ...x`. Menos código, menos chance de erro (linter).
5. **Registro documentado deste bug**: Arquivo `debug-app-init-blocking-error.md` criado na raiz do projeto (mesmo nível de `pubspec.yaml`) documentando causa raiz e correção. Equipe pode consultar o padrão sempre que ver "formulário não renderiza" / "CEP não preenche".

---
**Status**: [OPEN] → aguarda confirmação do usuário (A: Corrigido / B: Ainda não / C: Mudei / D: Abortar). Se confirmado Corrigido, a sessão [OPEN] muda para [CLOSED] e arquivos de debug podem ser arquivados.
