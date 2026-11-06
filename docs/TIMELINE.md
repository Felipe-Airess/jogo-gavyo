# Timeline — Gavião, capítulo 1 jogável

Definida com Felipe em 02/11/2026. Qualquer IA (Claude ou Codex) segue esta ordem,
**uma etapa por vez**. Ao fim de cada etapa: Felipe testa, e só então a próxima
começa. Ao pegar o trabalho, leia também `docs/TESTE-FELIPE-20261102.md` e
`docs/PASSAGEM-PARA-CLAUDE.md`. Marque o checklist ao concluir.

## Visão do capítulo (decisões de Felipe)

- **Meta:** capítulo 1 jogável do começo ao fim, de **20 a 30 minutos**, no **PC
  e no celular**. Sem prazo; Felipe tem bastante tempo por semana.
- **Medo:** perseguição, atmosfera, sustos e perturbação, os quatro.
- **Defesa:**
  - o **empurrão sai**;
  - sem item, o cultista **agarra** e começa um **minigame de escape em
    sequência** (botões/direções); falhar leva à morte;
  - há **um item escondido de uso único** que **finaliza** um cultista comum.
- **Perseguidor:** **nunca** pode ser finalizado; só fugir e se esconder.
  Aparece **só se o alerta se espalhar** (como hoje).
- **Quantidade:** 6 a 8 cultistas comuns e 1 perseguidor.
- **Morte:** cena **cruel e pesada** e depois o checkpoint.
- **Salvar:** checkpoints fixos e automáticos.
- **Nova abertura — decisão de Felipe, 02/11/2026:** substitui o início em que
  Miguel já acordava na salinha. De manhã, Miguel e Felipe saem de 3º Informática,
  descem a escada e se separam; Miguel atravessa o refeitório, deita na salinha
  e acorda à noite após um corte brusco no mesmo enquadramento. A luz diurna
  existe apenas nessa abertura, que deve ser pulável e não se repetir ao morrer.
- **Primeiro objetivo após acordar:** cozinha por fome; depois celular/bolsa,
  gravação do ritual e fuga. Primeiro cultista na cozinha com sequência
  cinematográfica e passagem jogável por timing entre coberturas. Vigilância
  cheia na cozinha mata e retoma o checkpoint anterior à cozinha; fora dela,
  dispara a caça. Checkpoints ao acordar e antes da cozinha.
- **Falas aprovadas na escada, sem alterações:**
  - Miguel: "Vou pra sala descansar."
  - Felipe: "Eu vou contigo."
  - Miguel: "Não, vai não, que tu é o porcão, gosta de ficar com o porcão não."
- **Objetivos:**
  - pegar a bolsa, gravar o ritual e fugir;
  - **notas do culto**;
  - **chave/acesso**, sem trancas arbitrárias, com propósito na história;
  - **item de finalizar**;
  - **pistas da ave**.
  O conteúdo (textos das notas, significado da ave) **Felipe escreve**. A IA só
  coloca no jogo e usa texto provisório marcado `[PROVISÓRIO]` até lá.
- **Visual dos inimigos:**
  - **cultistas comuns:** altos, "animais fingindo ser humanos", olhos fundos e
    escuros com pupila pequena; uns encapuzados, outros de cabelo comprido;
  - **perseguidores:** não escondem o rosto; pálidos, muito altos, cabelo
    longo, sorriso grande.
- **Cutscenes:** cinematográficas, com cortes de câmera e clima de filme. Falas
  de Miguel vêm de Felipe.
- **Trilha:** Felipe está criando e manda os arquivos.
- **Amigos:** Felipe também participa da nova abertura com seu modelo existente;
  Bola permanece no final. A decisão da abertura substitui a restrição anterior.
- **Proibido:** combate de luta (socos/combos), armas de fogo, gameplay do
  capítulo 2.
- **Trabalho:** Claude e Codex se revezam. Quem pega lê este arquivo e a
  passagem, e atualiza ao sair.

## Etapas

### Etapa 0 — Preparar
- [ ] Voltar ao Miguel original (`cp arte/miguel_animado.glb godot-3d/miguel_animado.glb`).
- [ ] Luz de contorno no Miguel, para ele aparecer no escuro.
- **Teste de Felipe:** o Miguel aparece bem?

### Etapa 1 — Medo

**Etapa jogável entregue para o teste de Felipe (02/11/2026).** Pressão e sete
patrulheiros na grade implementados. Morte e trilha definitivas continuam nas
pendências abaixo; os substitutos provisórios foram autorizados nas Partes 1/4.
- [x] Remover o empurrão.
- [x] Cultista vê → pausa 0,4 s → grita → corre a 3,0 m/s → cerca → agarra.
  Sem visão: último ponto visto, busca por 60 s, retorno lento ao posto.
- [x] Minigame de escape em sequência; falhar é morte. Implementado em 02/11/2026:
  WASD/setas e quatro botões de toque; morte temporária com tela preta de 1,5 s
  e retorno automático ao checkpoint. Cena de morte abaixo continua pendente.
- [ ] Cena de morte cruel e pesada, depois checkpoint.
- [x] Perseguição com pressão: passos novos por proximidade, respiração acelerada,
  tremor óptico leve e som de tensão [PROVISÓRIO]. Trilha final virá de Felipe.
- [x] Armários contra quem caça: só abre e retira Miguel quem viu a entrada.
  Memória individual por cultista; sem testemunha, ronda sem abrir.
- [x] Sete patrulheiros comuns nos postos 1–7 e perseguidor condicional no posto 8.
  Todos com caminho de até 10 m até armário; duas rotas continuam livres.
- **Teste de Felipe:** fugir dá desespero?

### Etapa 2 — Movimento
- [ ] Andar, correr e agachar sem travar: transições suaves, passo casado com
  a velocidade.
- [ ] Integrar o que falta do Mixamo (Felipe baixa): agachar, espiar, agarrar,
  ser agarrado, se soltar, procurar.
- **Teste de Felipe:** mover é gostoso?

### Etapa 3 — Enxergar
- [ ] Clarear a cena mantendo o filtro retrô.
- [ ] Resolução do filtro um pouco maior.
- [ ] Luzes guiando o caminho.
- **Teste de Felipe:** dá para jogar sem forçar a vista?

### Etapa 4 — Mapa e objetivos
- Revisão preparada em [REVISAO-MAPA.md](REVISAO-MAPA.md): plantas renderizadas,
  rota proposta e F9 de passeio em debug. Aguardando resposta de Felipe no próprio arquivo.
- [ ] Felipe aprova ou corrige a grade (`godot-3d/capitulo1/mapa/terreo.txt`).
- [x] Colocar quatro notas, chave/acesso, item opcional de finalizar e duas pistas
  da ave. Textos em `capitulo1/textos/objetivos.json`, todos `[PROVISÓRIO]`.
  Leitor PC/toque e registros no celular; checkpoints na chave e na bolsa.
  Entrega técnica de 03/11/2026 em [OBJETIVOS-ETAPA4.md](OBJETIVOS-ETAPA4.md).
  Abertura/cozinha do Prompt C continuam pendentes; isto não aprova o mapa.
- [ ] Ajustar a duração para 20 a 30 minutos. Medido em 03/11: percurso atual
  3 min 27 s; exploração estimada 9–13 min. Curto; sem conteúdo extra inventado.
- [ ] Decorar com as fotos (`docs/referencias/escola-fotos/`).
- **Teste de Felipe:** o caminho e os objetivos fazem sentido?

### Etapa 5 — Inimigos novos (visual)
- [x] modelos de Felipe integrados, aguardando teste (05/11/2026).
  Cultista de 2,00 m nos sete postos; perseguidor de 2,50 m continua condicional.
  QA dos originais e limitações em `../arte/modelos-definitivos/RESULTADO.md`.
- [ ] Cultistas comuns conforme a descrição acima.
- [ ] Perseguidor conforme a descrição acima.
- **Teste de Felipe:** dão medo?

### Etapa 6 — Cutscenes cinematográficas
- Nova direção registrada em 02/11/2026; implementação ainda pendente:
  - [x] Abertura diurna pulável com Miguel e o modelo existente do Felipe
    (`capitulo1/abertura.gd`, 05/11/2026, Claude). Falas exatas de Felipe.
  - [x] Cochilo, corte manhã/noite e entrega do controle com objetivo da cozinha.
  - [x] Primeiro cultista conforme storyboard, timing por coberturas no PC/toque
    (`capitulo1/cozinha.gd`). Erro de tempo enche a vigilância; cheia = morte direta.
  - [x] Vigilância no HUD (canto) e checkpoint na porta da cozinha.
  - [ ] Faltam sons da escola viva (vozes, sinal): Felipe manda. Hoje só silhuetas.
  - [ ] Cena de morte cruel: hoje é tela preta (provisório, como no agarrão).
  - **Aguardando teste de Felipe.**
- [ ] Abertura, primeiro cultista, perseguidor descobrindo o Miguel, final.
- [ ] Falas de Miguel enviadas por Felipe.
- **Teste de Felipe:** parecem filme?

### Etapa 7 — Trilha e som

SFX da Parte 3 integrados em 02/11/2026; tabela em `SONS-FELIPE-PARTE3.md`.
Trilha, respiração humana e canto definitivo não vieram nesse pacote.
- [ ] Integrar a trilha de Felipe.
- [ ] Mixagem de ambiente, sustos e tensão.

### Etapa 8 — Miguel
- [x] modelos de Felipe integrados, aguardando teste (05/11/2026).
  Miguel definitivo de 1,76 m, malha/textura/pesos preservados; galeria debug F10.
- [ ] Aprovação visual de Felipe do modelo definitivo; não remodelar o corpo.
  O original permanece arquivado e `arte/miguel_animado.glb` está intacto.

### Etapa 9 — Publicar
- [ ] Build web por PR para a `main` (pasta `capitulo1/`), testada no PC e no
  celular.

## Decisões de direção — 05/11/2026 (questionário com Felipe)

- **Iluminação:** luar frio (azulado pelas janelas e pátios, interiores mais
  escuros). O ritual mantém as **velas quentes**, uma ilha laranja perigosa de
  atravessar. Com a IA nova, luz expõe e sombra esconde.
- **Cozinha:** passa a ser **obrigatória** (o caminho da chave passa pelo
  primeiro cultista).
- **Duração (meta 20–30 min):** mais encontros roteirizados (**biblioteca** e
  **laboratório**; Claude propõe e Felipe aprova), puzzles de **distração**
  (jogar objeto, ligar algo para tirar o cultista do caminho) e **fuga longa
  roteirizada** do perseguidor até o portão (portas batendo, obstáculos).
- **Morte:** mostrar mais, cruel. **Felipe vai baixar as animações do Mixamo.**
- **Ordem:** luz → cozinha obrigatória → encontros (biblioteca/laboratório) → fuga.
- **Encontros aprovados (05/11):**
  - **Biblioteca — "O leitor":** um cultista anda devagar entre as estantes,
    lendo em voz baixa. Miguel atravessa usando a distração (jogar um livro ou
    objeto para um lado e passar pelo outro). Há uma nota do culto opcional na
    mesa.
  - **Laboratório — "Trancado por dentro":** Miguel entra para pegar a pista
    da ave; um cultista entra logo atrás e tranca a porta. Miguel se esconde
    sob a bancada ou no armário de jalecos e precisa ficar parado e agachado
    enquanto ele mexe nos frascos, cada vez mais perto (mover ou sair antes
    enche a vigilância). Ao sair, o cultista deixa a porta aberta.
- **Mais decisões (05/11, questionário 2):**
  - **Lanterna do celular:** sem bateria; **pisca e falha** em momentos de tensão.
  - **Perseguidor:** primeira aparição só observando, numa cutscene **logo depois
    da cozinha** (fim do corredor/pátio); depois volta como perseguidor.
  - **Ventilações:** novo recurso. **Atalho rastejando**: entra por uma grade,
    rasteja por um duto curto e sai em outra sala. São **totalmente seguras**.
  - **Dificuldade:** uma só, sem opção no menu.
  - **Final:** o mesmo roteiro, porém **mais cinematográfico** (Etapa 6).
  - **Celular:** **mensagens dos amigos** (Bola/Felipe) durante o capítulo,
    com textos de Felipe e `[PROVISÓRIO]` até lá.
  - **Sustos:** **jumpscare raro**, poucos e fortes, em momentos-chave.
  - **Vozes dos cultistas:** **murmúrios ininteligíveis** (cantos, sussurros).
  - **Plataforma:** **PC primeiro**; celular só precisa funcionar.
- **Mais decisões (05/11, questionário 3):**
  - **A ave:** mistério só visto (ritual e pistas); o significado fica para depois.
  - **HUD mínimo:** a vigilância só aparece com perigo; o objetivo, ao apertar uma tecla.
  - **Sem mapa.** A orientação vem da **luz guiando** o caminho principal e de
    **pensamentos do Miguel** quando o jogador fica perdido muito tempo (textos
    de Felipe; `[PROVISÓRIO]` até lá).
  - **Morte:** tudo reinicia no checkpoint, com todos os cultistas nos postos.
  - **Tela de título cinematográfica:** logo GAVIÃO, a escola à noite ao fundo e a trilha.
  - **Créditos:** depois, na publicação.
  - **Sem gancho** para o capítulo 2: termina na casa do Felipe.
- **Mais decisões (05/11, questionário 4):**
  - **Jumpscares (2):** ao abrir a caixa de materiais na salinha; e um rosto na
    grade ao sair da ventilação. Só susto: a ventilação continua segura.
  - **Medo do Miguel:** respiração (ofegante perto de inimigos, presa quando
    escondido), tremor leve de câmera quando a vigilância sobe, batimentos
    audíveis acelerando e lentidão breve depois de um susto.
  - **Parado ou escondido por muito tempo:** um cultista passa a rondar a área.
  - **Cutscenes médias (20–45 s)**, como a abertura atual.
- **Clima por área (06/11, questionário 5):**
  - **Pátio aberto e quadra:** neblina baixa com luar; silhuetas aparecem e somem nela.
  - **Corredores internos:** lâmpadas falhando (algumas piscam, outras queimadas,
    trechos de breu).
  - **Andar de cima:** respiro calmo, mais silencioso e escuro; alívio enganoso.
  - **Sinais do culto:** penas e restos pelo chão e trilhas de velas apagadas
    levando ao pátio de química.

### Iluminação de luar — feita em 06/11/2026 (Claude), aguardando teste de Felipe
- [x] Luar frio no pátio e na quadra: brilho azulado nos pisos e telhados a céu
  aberto, mais uma luz azul fraca que acompanha Miguel do lado de fora. O
  renderizador de compatibilidade ignora a máscara de luz, então uma lua
  direcional vazaria para dentro (medido: dobrava o brilho do andar de cima).
- [x] Interior mais escuro (ambiente 0,27), neblina azulada.
- [x] Lâmpadas: as do caminho principal ficam firmes (a luz guia); das 40, 9
  piscam e 12 estão queimadas.
- [x] Ritual com velas quentes; trilha de velas apagadas e penas até o pátio de química.
- [x] Lanterna pisca e falha quando a vigilância sobe ou há perseguição.
- [x] A IA conta o luar: a céu aberto Miguel aparece mais que num corredor escuro.
- Captura: [capturas/iluminacao-luar-20261106.jpg](capturas/iluminacao-luar-20261106.jpg).

### Cozinha obrigatória e o perseguidor observando — feito em 06/11/2026 (Claude)
- [x] A chave saiu do estoque e foi para o canto da cozinha; Miguel a pega na
  cena, ao chegar à última cobertura. Textos dizem "na cozinha" (`[PROVISÓRIO]`).
- [x] Ao sair, primeira aparição do perseguidor: parado ao longe no corredor,
  com contraluz fria, só observando (por cima do ombro → zoom → reação de
  Miguel), e some no corte. Cerca de 6 s.
- [x] Teste de percurso joga a cozinha; teste da abertura verifica a chave e a aparição.

### Ventilações — feito em 06/11/2026 (Claude), aguardando teste de Felipe
- [x] `capitulo1/ventilacao.gd`: grades na parede (35 cm do chão), uma em cada sala.
  - **Materiais de esportes ↔ Estoque da cozinha:** evita o refeitório vigiado.
  - **Laboratório Informática 2 ↔ Laboratório de hardware:** ala oeste.
- [x] Totalmente seguras: dentro do duto Miguel fica escondido e ninguém o vê.
- [x] Jumpscare na primeira saída no estoque: cultista visto de baixo, através
  da grade, com luz fria e grito; só susto, uma vez por sessão.
- [ ] Trocar o rastejar provisório pela animação "Crawling" quando Felipe mandar.
- Teste: `tests/capitulo1_ventilacao_test.gd` (12). Captura:
  [capturas/ventilacao-20261106.jpg](capturas/ventilacao-20261106.jpg).

### Biblioteca — "O leitor" — feito em 06/11/2026 (Claude), aguardando teste de Felipe
- [x] `capitulo1/biblioteca.gd`: 5 fileiras de estantes (1,9 m, com livros) e
  corredores no fundo e na frente; a área da porta fica livre.
- [x] O leitor é o 8º cultista comum: anda devagar (0,7 m/s) pelos corredores e
  para de 3 a 5,5 s para ler. Percepção, caça e agarrão são os de sempre.
- [x] Distração: dois livros na entrada para jogar ([T]). O barulho atrai o
  leitor sem alertá-lo. A regra antiga mandava todo arremesso depois do
  primeiro direto para a posição do Miguel; agora isso só acontece ao repetir
  o truque no mesmo lugar em menos de 20 s.
- [x] Recompensa: a pista da ave 1 foi para o fundo da biblioteca; a nota 3 continua lá.
- Murmúrios de leitura: hoje só um ruído leve; faltam os sons de voz (Felipe).
- Teste: `tests/capitulo1_biblioteca_test.gd` (8). Os testes que contavam 7
  cultistas agora contam os 7 dos postos mais o leitor.

### Laboratório — "Trancado por dentro" — feito em 06/11/2026 (Claude), aguardando teste de Felipe
- [x] `capitulo1/laboratorio.gd`, no **Laboratório de matemática** (ao lado da
  biblioteca, uma porta, uma bancada, sem posto). A pista da ave 2 foi para lá.
- [x] Pegar a pista → um cultista entra e **tranca a porta**. São 3 s para
  apertar [Espaço/toque] e se esconder atrás da bancada; sem isso, morte direta.
- [x] Escondido: tecla de movimento enche a vigilância; parado, só sobe um pouco
  quando ele está colado. Ele mexe nos frascos em 3 pontos, cada vez mais perto,
  e sai deixando a porta aberta. Vigilância cheia = morte direta → checkpoint.
- [x] Câmera baixa ao lado do Miguel: o cultista aparece por cima da bancada.
- Teste: `tests/capitulo1_laboratorio_test.gd` (11). Captura:
  [capturas/laboratorio-20261106.jpg](capturas/laboratorio-20261106.jpg).

### Fuga final roteirizada — feita em 06/11/2026 (Claude), aguardando teste de Felipe
- [x] `capitulo1/fuga.gd`. Com o vídeo gravado, o perseguidor **sempre** vem,
  com ou sem alerta (antes, só com alerta). Ele surge do ritual, atrás de
  Miguel, nunca no caminho do portão.
- [x] Pressão colada: fica ~4,5 m atrás de quem corre; quem para ou anda devagar
  por mais de 1,4 s é alcançado. Não é finalizável; esconder-se continua possível.
- [x] Eventos pela distância até o portão: 25% uma porta bate atrás · 50% as
  luzes perto estouram e apagam · 75% um carrinho tomba ao lado do caminho ·
  perto do portão, ele grita.
- Testes: `tests/capitulo1_fuga_test.gd` (8). O percurso corre na fuga e chega
  ao portão sem mortes. Testes que exigiam "vídeo sem alerta não cria
  perseguidor" foram atualizados para a decisão nova.

### Medo e atmosfera — feito em 06/11/2026 (Claude), aguardando teste de Felipe
- [x] `capitulo1/medo.gd`.
- [x] **Coração:** som próprio gerado por código (`assets/sons/gerados/coracao.wav`).
  Acelera de 60 para ~126 bpm e fica mais alto com a pressão, a vigilância, a
  fuga e os sustos. Soma-se à respiração, ao tremor e à tensão que já existiam.
- [x] **Lentidão depois de um susto:** 55% da velocidade por ~1,2 s (caixa,
  rosto na grade, perseguidor observando, grito da fuga).
- [x] **Jumpscare da caixa de materiais** na salinha: uma ave escura sai voando
  na cara do jogador, com grito agudo. Só susto, uma vez (amarra com o mistério da ave).
- [x] **Parado ou escondido por 45 s:** o cultista livre mais próximo vem rondar.
- [x] **Pensamentos do Miguel:** depois de 2,5 min sem avançar, uma dica do
  objetivo atual (cozinha → bolsa → ritual → portão), a cada 2 min no máximo.
  Textos `[PROVISÓRIO]` em `objetivos.json`, para Felipe escrever.
- Teste: `tests/capitulo1_medo_test.gd` (10).
