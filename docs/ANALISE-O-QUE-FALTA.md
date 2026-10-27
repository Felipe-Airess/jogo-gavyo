# O que falta — leitura completa (27/10/2026)

Base: branch `feat/hitbox-precisao` (`4e8e820`), testes 165/165 e 22/22,
execução no navegador sem erros (~0,85 ms por quadro nesta máquina).
Fontes: código, `AGENTS.md`, `docs/`, `arte/`, PRs #2 e #3 e o pedido
original (combate lateral 1×1 com movimentação de Mortal Kombat, distância de
UFC e impacto de Sifu) + a ideia do jogo em `docs/CONTEXTO.md` (GAVIÃO:
Sorriso, Gelado aliado, Bola chefe, Alice como objetivo, escola, humor seco).

Dois objetivos, em camadas:

1. **Combate pronto**: responsivo, leitura clara, contato preciso, transições
   naturais, impacto convincente — com os dois lutadores no mesmo nível.
2. **Jogo GAVIÃO**: algo que se começa, progride e termina (história, fases,
   inimigos, chefe), jogável no navegador do celular e no T400.

Legenda: 🔴 bloqueia o objetivo · 🟠 deveria entrar · 🟢 bom ter.

## 1. Combate — o que ainda impede “pronto”

### Arte e animação
- 🔴 **Sorriso ficou para trás.** O Miguel ganhou lote 4 (guarda lateral,
  bloqueio, reações, grogue, queda, levantar, corrida). O Sorriso continua com
  `hurt`/`fall`/`rise`/`block`/clinch antigos — agora é ele quem destoa. O
  pedido já existe (`arte/reformulacao/PEDIDO-LOTES-4-5.md`, P1 primeiro).
- 🔴 **Transições.** Não há quadros idle↔andar, guarda entrando/saindo, nem
  saída de golpe para andar. É a principal causa do “meio travado” que sobrou.
- 🔴 **Reação “esticada” do Miguel.** As reações duram o atordoamento
  segurando quadros (AGENTS: “reação por região esticada”). Contraria a regra
  de não esticar tempo: precisa de uma pose de sustentação (loop) ou de
  atordoamento menor que o desenho.
- 🟠 **Andar do Miguel desliza** (ciclo 36 px, passo desenhado ~10 px). Pedir
  o passo de boxe com avanço (LISTA-ANIMACOES item 2) ou casar velocidade.
- 🟠 **Arte com defeito conhecido**: salto de 13 px no combo jab→cotovelo→
  joelho; chute alto só no topo da cabeça; tênis brancos no lote 4 × escuros
  no lote 3; circular “no corpo” do Sorriso na altura do queixo.
- 🟠 **Clinch** ainda é v6 no Sorriso e não tem arte pareada; o sistema de
  golpe em par (`pair`) já existe e só espera as folhas (prompt seções 15–18).
- 🟢 Animação de vitória/derrota, provocação e respiração cansada.

### Mecânica
- 🔴 **Equilíbrio entre personagens**: Miguel vence ~70% porque tem mais
  golpes desenhados. Dar ao Sorriso os equivalentes (uppercut, cotovelada,
  combos) ou cortar do Miguel até ter paridade — e medir de novo.
- 🟠 **Esquiva sem comando.** O Miguel tem `m4_leanBack` no atlas; falta a
  mecânica (tecla, janela, contra-ataque). Pedido do brief: contra-atacar após
  esquiva.
- 🟠 **Parede e canto não contam.** Encurralar não muda nada além de parar o
  recuo. Faltam: quique/impacto na parede, mais dano/atordoamento no canto,
  saída do canto (passar por baixo, empurrão).
- 🟠 **Jab andando para frente** impossível (frente+J é sempre direto).
- 🟢 Golpes no chão para o Sorriso com arte própria; teep para criar espaço.

### Estrutura da luta
- 🔴 **Não existe partida.** Sem rounds, tempo, melhor de 3, contagem no
  chão, anúncio de “Luta”/“K.O.”, pausa entre rounds ou revanche organizada.
  Lutas com a IA acabam em ~20 s.
- 🟠 **Escolha de personagem** é um `<select>`; falta tela de seleção (lados,
  quem é o rival, retrato).
- 🟠 **Dificuldade da IA** existe no código (`calmo`, `firme`) mas não na tela.
  Falta um nível difícil e IA com estilos (agressivo, contra-golpeador).

### Controles
- 🔴 **Sem controle (gamepad).** Para jogo de luta no PC é essencial; a API do
  navegador resolve sem dependências.
- 🟠 Sem remapear teclas; sem mostrar a lista de comandos dentro do jogo
  (hoje fica na página).
- 🟢 Modo treino de verdade: mostrar entradas, dados de quadro (preparação/
  recuperação/vantagem), boneco que repete uma ação, reiniciar posição.

### Impacto e som
- 🟠 **Som mínimo** (13 linhas, ruído sintetizado). Faltam sons por tipo de
  golpe e região, bloqueio, queda no chão, passos, aparo, nocaute, ambiente
  da escola e música. Sem som, o impacto de “Sifu” não chega.
- 🟢 Interação com o cenário (aprovada como ideia, não feita): armários,
  porta, balde, mochila, parede que treme, fundo vivo.
- 🟢 Câmera: leve zoom no nocaute e aproximação quando os dois estão perto
  (no Canvas, só com cuidado de nitidez).

## 2. Técnico

- 🔴 **Publicação desatualizada.** `main` e o GitHub Pages ainda estão na
  0.7.0. PR #3 está empilhado sobre o #2 (base `feat/combate-duelo-1x1`):
  mesclar #2 → `main`, depois #3, e conferir o site publicado.
- 🔴 **Sem CI.** Não há `.github/workflows`; os testes só rodam se alguém
  lembrar. Um workflow de `npm test` em todo PR evita regressão.
- 🟠 **Memória dos atlas**: `sorriso-v70.png` 1024×6720 + `miguel.png`
  1024×4512 ≈ 46 MB descomprimidos, com muitas folhas antigas que o duelo não
  usa; o rival recolorido cria uma textura por quadro exibido (109 texturas
  numa luta). Para o T400/celular: podar o atlas, separar por personagem,
  limitar o cache.
- 🟠 **Nunca medido no T400 nem em celular físico.** Falta um medidor (FPS,
  tempo de quadro, memória) e um roteiro de teste no aparelho.
- 🟠 **Dois motores de combate**: `battle.mjs` (corredor) e `duel/`. Decidir:
  corredor vira modo treino em cima do motor do duelo, ou fica congelado.
  Manter os dois dobra o custo de cada ajuste.
- 🟢 `AGENTS.md` cresceu com o histórico de cada rodada; separar “estado
  atual” de “histórico” para o próximo agente ler rápido.
- 🟢 Ferramenta de consistência de sprites (medir cabeça, altura, paleta,
  contorno e normalizar cor/escala) — pedida e ainda não feita; o lote 4 do
  Miguel já faz parte disso em `scripts/miguel-lote4/`.

## 3. Jogo GAVIÃO — o que nem começou

- 🔴 **Modo história / progressão**: nada além de treino e duelo. Falta a
  estrutura: capítulos/fases na escola, objetivo (Alice), fim.
- 🔴 **Elenco**: Gelado (aliado), Bola (chefe), inimigos comuns — sem arte nem
  regras. O motor é 1×1; um beat 'em up precisa de vários inimigos, ondas,
  IA de grupo e decidir se a profundidade volta (o duelo é só lateral).
- 🟠 **Cenários**: só o corredor B. Faltam outros ambientes da escola.
- 🟠 **Narrativa e humor**: diálogos, cenas curtas, tom “humor seco em
  objetos institucionais” (DESIGN.md) ainda só existe no fundo do corredor.
- 🟠 **Menus e salvamento**: tela inicial, opções (som, sangue, controles,
  dificuldade), progresso salvo.
- 🟢 Acessibilidade: reduzir tremida/clarão, cores dos indicadores, legendas.

## 4. Ordem recomendada

1. **Publicar o que existe**: mesclar #2 e #3, CI com `npm test`, conferir o
   GitHub Pages. (curto, destrava teste no celular de verdade)
2. **Partida de verdade**: rounds, tempo, melhor de 3, anúncio, revanche,
   tela de seleção com dificuldade. (código, sem arte)
3. **Gamepad** + lista de comandos no jogo.
4. **Sorriso lote 4 (P1)** pelo pedido existente, com o kit de referência;
   depois transições dos dois. (arte → integração)
5. **Paridade e equilíbrio**: golpes equivalentes, medir vitória ~50%.
6. **Esquiva, parede/canto** e **som** por tipo de impacto.
7. **Medir no T400 e no celular**; podar atlas se preciso.
8. **Decidir o corredor** (modo treino no motor novo ou congelado).
9. **Fatia vertical do GAVIÃO**: uma fase curta da escola com 2–3 inimigos,
   Gelado aparecendo, um chefe pequeno e uma cena de abertura — para provar o
   jogo antes de produzir tudo.
