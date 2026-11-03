# Teste de Felipe — 02/11/2026 (build com animações do Codex + mapa cinza)

## O que Felipe relatou (prioridade nesta ordem)

1. **Locomoção travada:** correr, agachar e andar parecem travados. Algumas
   animações funcionam, outras não. Conferir a máquina de estados em
   `capitulo1/animacoes/controlador.gd`: transições, `speed_scale` casado com
   a velocidade e clipes travados no primeiro quadro.
2. **Hitbox do empurrão:** ele empurra o ar e o cultista cai. O cultista cai
   só para baixo, sem ir para trás. O contato precisa exigir a mão no tronco,
   e a reação precisa de impulso para trás (Hit_Knockback / Sweep_Fall com
   deslocamento real).
3. **Cultistas sem ameaça:** não correm e não tentam matar o jogador. O jogo
   não passa desespero. A caça precisa correr (`cultista_correr`) e agarrar
   de verdade; a perseguição precisa pressionar.
4. **Design do cultista ruim:** o visual precisa ser refeito (roupa/capuz,
   silhueta ameaçadora).
5. **Cutscenes ruins:** a abertura, o avistamento, a descoberta e o final
   precisam de direção de câmera e ritmo.
6. **Filtro retrô:** ficou bom, melhor que o jogo polido, mas fica **difícil
   de enxergar**. Clarear ambiente e névoa, subir a resolução baixa (ex.: 240
   linhas) e dar contraste nos pontos de interesse.
7. **Miguel escuro demais:** dar uma luz de recorte no jogador (rim light) ou
   material menos escuro. O Miguel v2 (branch `feat/modelo-miguel`) também
   está pendente de aprovação.

## O que o Codex não terminou

- O teste da base preservada, "punho não dá saltos artificiais", ainda falha
  (34 cm por quadro; o limite é 30 cm), pelas transições da nova máquina de
  estados.
- `Stunned` termina no chão e `Descending_Stairs` não fecha o ciclo: não usar
  em loop sem cortar ou adaptar.
- Ainda faltam do Mixamo: agachar, espiar, agarrar, ser agarrado, se soltar,
  procurar e facada.
- O atalho `builds/macos-teste/JOGAR.command` não abre o jogo no Mac. Usar
  `bash JOGAR-PROTOTIPO.command` ou `Godot --path godot-3d`.

## Estado dos testes (Claude, nuvem)

| Suíte | Resultado |
|---|---|
| Capítulo | 47/47 |
| Mapa | 18/18 |
| Nível | 10/10 |
| Toque | 10/10 |
| Percurso | 7/7 |
| Base preservada | 38/39 |

Os testes passam, mas o teste de Felipe mostra que a sensação está ruim. Tratar
os itens acima como prioridade sobre os números.

## Correção Parte B — ações e escada (02/11/2026)

Implementada na branch `feat/prototipo-terror-terceira-pessoa`, sobre a Parte A
já concluída. Os relatos acima ficam como histórico; esta seção registra a correção.

### Defeito reproduzido antes da correção

O teste `godot-3d/tests/capitulo1_animacao_test.gd` foi ampliado antes da mudança
no jogo. No Godot 4.5.1, as ações saíam 0,20 s antes do fim:

```text
ACAO novo/PickUp_Table: duracao=0.833 ultimo=0.617 retorno=Locomocao locomocao=false
ACAO novo/Interact: duracao=2.000 ultimo=1.783 retorno=Locomocao locomocao=false
ACAO novo/Chest_Open: duracao=1.367 ultimo=1.150 retorno=Locomocao locomocao=false
ACAO novo/ClimbUp_1m: duracao=0.667 ultimo=0.450 retorno=Locomocao locomocao=false
FAIL gate: mão toca alvo no quadro do evento (9 cm)
FAIL subir: pé apoia no degrau visual (9 cm)
FAIL descer: clipe correto na escada
FAIL descer: pé apoia no degrau visual (9 cm)
CAPITULO1_ANIMACAO: 41 passed, 20 failed
```

### O que mudou

- A saída automática espera o clipe inteiro, sem a antecipação de 0,20 s do
  crossfade. O controlador reativa a locomoção ao terminar a ação.
- Bolsa e porta aplicam seu efeito no contato. Armário e portão confirmam o
  contato e aguardam o fim do gesto antes de entrar/escalar. A escalada também
  aguarda seu próprio fim antes de passar ao encerramento.
- A mão se ajusta à grade pelo tempo do clipe, inclusive no evento de contato;
  não usa uma onda independente do evento. Os testes medem a mão na bolsa,
  maçaneta, armário e grade no tick do contato, com limite de 9 cm.
- Subida usa `Ascending_Stairs`; descida usa um derivado de `Descending_Stairs`.
  A descida recebida dura 0,933 s e não fecha. O controlador reamostra o trecho
  de 0,0 a 0,9 s a 30 Hz e mistura suavemente os últimos 0,2 s na primeira pose.
  Isso cria um ciclo contínuo com a própria captura de descida; não reutiliza
  as pernas de `Walk` do antigo `Descer_Ciclo`. FBX e biblioteca originais ficam
  intactos. A emenda do derivado é verificada em todas as trilhas de pose.
- A cápsula continua na rampa física existente. A cadência segue o tamanho real
  dos degraus, dois passos por ciclo. O controlador ajusta o quadril e articula as pernas,
  mantém o pé de apoio no degrau e levanta o pé livre sobre a quina, sem alongar
  ossos. O teste mede apoio nos pisos visuais e deslocamento do pé durante apoio.
- `Stunned` continua com `LOOP_NONE`; não foi transformado em ciclo.
- `capitulo1/animacoes/controlador.gd` continua sendo o único controlador de
  reprodução. Nenhuma chamada concorrente a `AnimationPlayer.play/seek/advance`.

### Como Felipe testa

No Terminal:

```bash
cd /Users/felipe/Projetos/jogo-gavyo
bash JOGAR-PROTOTIPO.command
```

1. Aperte Enter. Use WASD para andar, mouse para olhar e Espaço para interagir.
2. Abra uma porta: Miguel se aproxima, toca a maçaneta, termina o gesto e volta
   ao controle. Caminhe logo depois para conferir que a locomoção continua.
3. Suba a escada andando, pare, volte a subir e depois desça. Observe os pés nos
   degraus. O corpo físico segue a rampa, enquanto as pernas acompanham os pisos.
4. Pegue a bolsa no andar superior. A bolsa some no contato; o gesto termina
   antes de devolver o controle. Não deve permanecer parado na última pose.
5. Entre e saia de um armário com Espaço. A entrada aguarda o gesto completo;
   depois de sair, andar e correr continuam funcionando.
6. Após gravar o ritual, vá ao portão 1 e aperte Espaço. Observe o contato inicial,
   as mãos na grade e a escalada completa antes do encerramento.

Validação automática:

```bash
bash scripts/testar-capitulo1.sh
bash scripts/testar-percurso.sh
```

O primeiro comando inclui locomoção da Parte A, ações e escada. Os testes de
pose verificam coordenadas dos ossos, não apenas nomes de estados. Execução
headless não substitui a avaliação visual de Felipe sobre naturalidade.

APIs conferidas na tag `4.5.1-stable`: [AnimationNodeStateMachineTransition](https://github.com/godotengine/godot/blob/4.5.1-stable/doc/classes/AnimationNodeStateMachineTransition.xml)
e [Animation](https://github.com/godotengine/godot/blob/4.5.1-stable/doc/classes/Animation.xml).
Os métodos e as propriedades usados também foram executados pelo teste nessa versão.

### Resultado final no Godot 4.5.1 Compatibility

```text
CAPITULO1_ANIMACAO: 74 passed, 0 failed
CAPITULO1_TEST: 41 passed, 0 failed
CAPITULO1_MAPA: 18 passed, 0 failed
CAPITULO1_NIVEL: 10 passed, 0 failed
CAPITULO1_PERCURSO[rota]: 7 passed, 0 failed
```

Na escada, clipe, tempo e apoio passaram em 280/280 quadros na subida e
195/195 na descida. Os apoios ficaram fixos em 257/257 e 179/179 intervalos,
respectivamente; o maior desvio medido arredondou para 0,0000 m. O limite do
teste é 2 cm por quadro de apoio, sem aceitar falhas. O apoio deve ficar a
menos de 9 cm do piso visual em todos os quadros medidos.

As ações completas retornam a parado e retomam andar sem outro pedido de clipe.
Os contatos medidos na bolsa, maçaneta, armário e grade arredondaram para
0,0000 m de erro. Os testes também confirmam os efeitos: bolsa recolhida,
porta aberta, entrada no armário e escalada terminada do outro lado do portão.
O teste antigo do portão agora aguarda aproximação e os 2 s completos de
`Interact`, em vez de exigir a escalada antes de terminar esse gesto.

## Correção Parte C — transições, apoio e rolamento (02/11/2026)

Esta seção substitui as decisões da Parte B sobre crossfade e ritmo dos passos.
A Parte B evitava cortar ações zerando o crossfade de saída; isso produzia cortes
visíveis. O teste inicial desta rodada também encontrou saltos de pose de até
0,8657 m, 863 arestas com duração inadequada e descida chegando a 5,700x.

### Transições e reprodução

- Arestas entre estados de locomoção usam `xfade_time=0.15`. Entradas e saídas
  de ações e escada usam `0.22`. Parado/andar/correr dentro do BlendSpace também
  interpolam durante 0,15 s; alterar o parâmetro instantaneamente cortava a pose.
- Ações finitas têm uma cauda de timeline de 0,22 s. Assim, o clipe termina
  antes do crossfade, e `finished` chega quando a mistura termina. Não é preciso
  zerar a transição para tocar o gesto inteiro.
- Reiniciar uma ação percorre uma segunda instância do estado com crossfade.
  `playback.start` fica restrito à inicialização e à bancada de amostragem do
  próprio controlador. Pedidos do jogo só usam `travel`; não avaliam nem trocam
  a pose no meio de um evento de input.
- A inércia de pose e o ajuste dos apoios também respeitam a continuidade. O
  teste mede mãos e pés no mundo: limite de 8 cm entre quadros nas transições.
  A interpolação conserva comprimentos dos ossos.

### Medição dos passos e contato com o chão

`animacoes/metricas_passo.gd` avalia a cinemática das trilhas a 120 amostras por
ciclo, sem reproduzir outro AnimationPlayer. Mede o recuo do pé de apoio,
exclui os intervalos de voo e calcula a velocidade média durante o apoio.
O passo de um ciclo é essa velocidade multiplicada pela duração. A taxa usada é:

```text
taxa do clipe = velocidade horizontal real / (passo aplicado / duração)
```

Medições da captura, antes do ajuste espacial aos degraus:

| Clipe | Ciclo (s) | Passo (m) | Velocidade nativa (m/s) |
|---|---:|---:|---:|
| Walk | 1,333 | 1,269 | 0,952 |
| Sprint | 0,667 | 2,325 | 3,488 |
| Crouch_Fwd | 2,000 | 1,274 | 0,637 |
| Walking_Backwards | 0,967 | 1,210 | 1,252 |
| Ascending_Stairs | 1,367 | 0,448 | 0,328 |
| Running_Up_Stairs | 0,600 | 0,361 | 0,602 |
| Descending_Stairs (derivado fechado) | 0,900 | 0,248 | 0,275 |

No plano, mantêm-se andar **1,45 m/s**, correr **3,8 m/s** e agachado **1,05 m/s**.
As taxas correspondentes ficam aproximadamente em 1,52x, 1,09x e 1,65x.
O teto de 1,8x da caminhada vale para cada fonte do BlendSpace, inclusive
quando ela ainda contribui durante a mistura com corrida.

Os apoios ficam presos no mundo; o pé livre avança e levanta entre contatos.
A corrida admite intervalos de voo. A medição desconta a altura real do pivô
do tornozelo sobre a sola, **0,072821 m**, obtida da pose de repouso do modelo.
O teste mede a deriva acumulada durante cada apoio, com limite de **3 cm**,
para Miguel e cultista andando, correndo e agachados. Não basta comparar o
avanço de um relógio com uma constante nem medir apenas um quadro isolado.

### Escada e esquiva

- Shift na subida seleciona `Running_Up_Stairs` pelo pedido de corrida, mesmo
  quando a projeção da física na rampa reduz a velocidade horizontal. Antes,
  decidir só pela velocidade projetada podia selecionar a caminhada.
- Os passos são ajustados espacialmente a dois degraus por ciclo: neste mapa,
  **0,8 m por ciclo**. A cápsula acompanha a rampa existente; as solas acompanham
  os pisos visuais. A taxa usa esse passo aplicado e a velocidade real.
- Subida andando fica até **1,8x**; subida correndo usa a captura de corrida,
  também até **1,8x**. Descida andando ou correndo usa `Descending_Stairs`,
  até **1,6x**. O corpo reduz a velocidade na escada para acompanhar o clipe:
  neste mapa, limites horizontais de aproximadamente 1,05 m/s na caminhada
  de subida, 2,4 m/s correndo na subida e 1,42 m/s na descida.
- `Descending_Stairs` mantém o fechamento documentado na Parte B. `Stunned`
  permanece sem loop.
- **Esquiva desativada nesta rodada.** O Roll do Quaternius UAL1 foi avaliado
  com OpenGL Compatibility real. Integrar o recuo dos apoios deu 3,242 m em
  1,467 s, mas exigiu um pico de 9,13 m/s na entrada: a combinação da captura
  com essa trajetória não ficou convincente. A alternativa autorizada por
  Felipe foi aplicada. O botão de toque passa a dizer **SOLTAR**; Q e clique
  direito continuam permitindo escapar do agarrão. O teste confirma que o
  comando desativado não desloca Miguel nem inicia uma animação invisível.

### Como Felipe testa esta rodada

```bash
cd /Users/felipe/Projetos/jogo-gavyo
bash JOGAR-PROTOTIPO.command
```

1. Enter começa. Ande com WASD, pressione Shift para correr e solte para andar.
   Pare e retome várias vezes: mãos e pés devem misturar as poses sem cortes.
2. Alterne Ctrl parado e andando. Observe a transição de altura e o apoio das
   solas; Miguel não deve deslizar com o pé plantado. Observe também os cultistas.
3. Suba a escada andando e depois com Shift. Correndo, deve haver uma passada de
   corrida de escada, não a caminhada acelerada. Desça com e sem Shift: há limite
   de ritmo e de velocidade do corpo na descida.
4. A esquiva está desativada. Clique direito, sem agarrão, não deve mover
   Miguel nem fazê-lo rolar. Quando um cultista agarrar, use Q, clique direito
   ou SOLTAR no toque repetidamente para escapar.
5. Abra uma porta, pegue a bolsa e use um armário. As ações devem continuar
   completas, agora com entrada e saída suaves. Após gravar, teste o portão.

Validação: `scripts/testar-capitulo1.sh` inclui agora
`tests/capitulo1_movimento_test.gd`, além dos testes da Parte A/B. O percurso
contínuo permanece em `scripts/testar-percurso.sh`. As APIs novas foram
executadas no Godot 4.5.1; os limites internos de TimeScale também são
verificados durante os blends, não apenas pelo nome informado do clipe.

O teste físico antigo da subida aguarda até 12 s para completar o lance: a
caminhada agora respeita o teto de 1,8x, em vez de manter 2 m/s acelerando a
captura. Continua exigindo chegada ao corredor superior por colisão real.

### Resultado final da Parte C — Godot 4.5.1 Compatibility

```text
CROSSFADE transicoes_invalidas=0
CHAO Miguel velocidade=1.45 apoios=271 desvio=0.0237 m
CHAO Miguel velocidade=3.80 apoios=147 desvio=0.0252 m
CHAO Miguel velocidade=1.05 apoios=271 desvio=0.0244 m
CHAO cultista velocidade=1.45 apoios=271 desvio=0.0237 m
CHAO cultista velocidade=3.80 apoios=148 desvio=0.0258 m
CHAO cultista velocidade=1.05 apoios=270 desvio=0.0227 m
ESCADA_RITMO sobe=true corre=true clipe=novo/Running_Up_Stairs correto=49/49 escala=1.800x salto=0.0713 m
ESCADA_RITMO sobe=false corre=true clipe=novo/Descending_Stairs correto=49/49 escala=1.600x salto=0.0664 m
ESQUIVA desativada deslocamento=0.000 m estado=idle
CAPITULO1_MOVIMENTO: 33 passed, 0 failed
CAPITULO1_ANIMACAO: 74 passed, 0 failed
CAPITULO1_TEST: 41 passed, 0 failed
CAPITULO1_MAPA: 18 passed, 0 failed
CAPITULO1_NIVEL: 10 passed, 0 failed
CAPITULO1_PERCURSO[rota]: 7 passed, 0 failed
```

O maior salto medido nas transições ficou em 0,0770 m, dentro dos 8 cm.
As medidas de apoio usam a deriva acumulada desde o primeiro quadro de cada
contato; a pior foi 0,0258 m, dentro dos 3 cm. O percurso contínuo terminou
com zero mortes no modo de validação de rota. Isso verifica geometria e fluxo;
a avaliação de naturalidade continua sendo feita jogando.


## Parte D — clipes originais, sem correção de ossos (02/11/2026)

Esta revisão substitui a abordagem da Parte C. Os resultados antigos de apoio
até 3 cm e saltos até 8 cm foram obtidos com correção procedural de poses e
**não comprovam a naturalidade dos clipes**. Essa correção causou as pernas em
tesoura e pés torcidos vistos na gravação; foi removida.

Removidos `_feet`, `_smooth_pose`, `_limit_transition_pose`, retarget de passada,
reescrita da descida e correções externas durante locomoção e suas misturas.
Agora só o AnimationTree combina os clipes originais: crossfade de 0,15 s no
plano e 0,22 s em ações/escada, com TimeScale calculado do passo original.
A corrida de subida usa Running_Up_Stairs. A descida inteira repete por crossfade
entre dois estados, sem alterar suas chaves. O corpo desacelera na escada para
respeitar os limites de ritmo; não há promessa de pé preso ao piso.

Os testes agora medem: clipe correto, avanço, ausência de congelamento, mistura
e fidelidade de todos os ossos ao clipe. Deriva de apoio e amplitude acima de
8 cm geram aviso. Não existe correção de pose para satisfazer essas medidas.
A colisão da câmera considera só o mundo; cultistas junto da lente ficam
ocultos e reaparecem ao se afastar.

[Prova visual, quadros a cada 0,1 s e limitações](verificacao-animacoes/README.md).
Foram examinadas as sequências laterais: sem as torções e tesouras procedurais;
ainda existe deslizamento e desencontro entre os pés originais e alguns degraus.

### Como Felipe testa

Na raiz, execute `bash JOGAR-PROTOTIPO.command`. Enter inicia.

1. WASD para andar; Shift para correr. Solte para parar e retome várias vezes.
2. Ctrl parado e andando. Veja os joelhos e a direção dos pés.
3. Suba e desça a escada com e sem Shift. Subindo com Shift, observe a corrida
   de escada; descendo, espere uma passada mais lenta e flexionada.
4. Aproxime-se dos cultistas e gire a câmera: um corpo encostado na lente deve
   desaparecer e voltar ao sair de perto. A câmera continua bloqueada por paredes.
5. A esquiva continua desativada. Q/clique direito/SOLTAR ainda permitem escapar
   de um agarrão.


### Saídas desta revisão

```text
CAPITULO1_MOVIMENTO: 33 passed, 0 failed
CAPITULO1_ANIMACAO: 70 passed, 0 failed
CAPITULO1_TEST: 41 passed, 0 failed
CAPITULO1_MAPA: 18 passed, 0 failed
CAPITULO1_NIVEL: 10 passed, 0 failed
CAPITULO1_PERCURSO[rota]: 7 passed, 0 failed
```

Saídas completas: [capítulo](verificacao-animacoes/testar-capitulo1.txt) e
[percurso](verificacao-animacoes/testar-percurso.txt). A contagem de animação
mudou porque apoio fixo/encaixe artificial viraram avisos e a expectativa de
loop gerado foi substituída pelo recurso original intacto.

Na medição aproximada de apoio, a deriva máxima ficou entre 0,105 e 0,171 m
no plano. Esse detector inclui uma faixa de altura em torno do chão; não
comprova pé plantado exato. A amplitude máxima quadro a quadro medida nas
trocas foi 0,163 m. Ambos são publicados como avisos, sem truncar movimentos.


## Etapa 1 — escape em sequência (02/11/2026)

Substitui o escape por Q/clique direito/quatro apertos das seções anteriores.
Encostar em um cultista comum ou no perseguidor abre uma sequência aleatória.
Leia da esquerda para a direita: WASD ou setas no PC; no celular aparecem quatro
botões grandes de seta, somente durante o minigame. A próxima seta fica em
vermelho e as concluídas em verde. Repetição automática de tecla não conta.

O primeiro agarrão tem 3 setas e 3,0 s no total. Cada agarrão seguinte soma
uma seta (máximo 7) e tira 0,3 s (mínimo 1,5 s). Essa progressão dura a partida
e não é apagada ao retornar ao checkpoint; reabrir o jogo começa em 3/3,0 s.
Errar qualquer direção ou esgotar o prazo falha imediatamente.

Acerto: Miguel recua até 30 cm, limitado pela colisão do cenário; o agressor
fica parado/atordoado por 2 s. Durante 1,5 s nenhum inimigo pode agarrar Miguel.
O perseguidor retoma a caça e nunca é finalizado. Os corpos ficam de frente,
com distância de aproximadamente 0,6 m (0,58 m comuns; 0,66 m perseguidor,
cuja cápsula é maior), sem desativar colisões. A aproximação da IA também foi
ajustada: ela não para mais antes de alcançar o contato.

Falha: tela preta por 1,5 s, seguida do checkpoint automaticamente.
**[PROVISÓRIO: trocar pela cena de morte quando chegarem as animações]**
Nenhum osso ou clipe foi alterado para implementar/testar essa mecânica.
O atordoamento usa o parado existente; não usa Stunned em loop.

Há somente o gancho `finisher_item_available`, sem objeto colocado no mapa nem
cena de finalização. Quando ativado pelo futuro inventário, consome um uso e
evita o agarrão comum. Nunca evita o do perseguidor, nem consome o item nele.
A faca antiga não substitui esse item e não pula a sequência.

### Como Felipe testa

1. Execute `bash JOGAR-PROTOTIPO.command` e comece com Enter.
2. Encoste em um cultista. Repita as setas com WASD ou direcionais: Miguel se
   solta, recua e ganha tempo para fugir. No próximo agarrão a sequência cresce.
3. Encoste novamente e erre uma seta. Confira a tela preta e o retorno automático.
4. Em outro agarrão, não aperte nada: o prazo deve produzir o mesmo retorno.
5. Durante a perseguição, deixe o perseguidor encostar: ele também abre a
   sequência. Acertar só o atordoa; ele continua vivo e retoma a caça.
6. Para conferir o toque no PC, use o comando abaixo. No celular os quatro
   botões substituem o analógico enquanto o minigame está aberto.

```bash
work/ferramentas/godot/Godot.app/Contents/MacOS/Godot --path godot-3d -- --toque
```

`tests/capitulo1_escape_test.gd` cobre contato e aproximação reais, alinhamento,
acerto, erro, prazo esgotado, progressão/limites, pausa, item, perseguidor e toque.
Capturas renderizadas do PC, toque e tela preta foram inspecionadas localmente;
isso não substitui teste em celular físico.

APIs conferidas na versão exata e executadas no Godot 4.5.1 Compatibility:
[RandomNumberGenerator](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/RandomNumberGenerator.xml),
[InputEventKey](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/InputEventKey.xml),
[PhysicsBody3D.move_and_collide](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/PhysicsBody3D.xml),
[desenho de CanvasItem](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/CanvasItem.xml).


### Saídas — Godot 4.5.1 Compatibility

```text
CAPITULO1_ESCAPE: 37 passed, 0 failed
CAPITULO1_MOVIMENTO: 33 passed, 0 failed
CAPITULO1_ANIMACAO: 70 passed, 0 failed
CAPITULO1_TEST: 36 passed, 0 failed
CAPITULO1_MAPA: 18 passed, 0 failed
CAPITULO1_NIVEL: 10 passed, 0 failed
CAPITULO1_TOQUE: 9 passed, 0 failed
CAPITULO1_PERCURSO[rota]: 7 passed, 0 failed
```

As cinco expectativas do agarrão antigo saíram de `capitulo1_test.gd` e foram
substituídas pela suíte de 37 verificações do escape. O script do capítulo
executa essa suíte automaticamente. O percurso de rota terminou com zero mortes.


## Etapa 1 — Parte 2: percepção, caça e armários (02/11/2026)

Um cultista comum que enxerga Miguel para por 0,4 s, emite um grito e inicia
perseguição a 3,0 m/s no plano, com Sprint original. Miguel mantém 1,45 m/s
andando e 3,8 m/s correndo. Assim, andar perde distância e correr ganha distância.
O grito não repete a cada quadro; também espalha o alerta pelo mecanismo existente.
**[PROVISÓRIO]** O áudio do grito reutiliza o efeito `susto` até a Parte 3 trazer
os sons novos. Não é uma voz nova gravada.

Ao perder a visão, o cultista vai ao último ponto realmente visto. Só ao chegar
começa a busca de 60 s: caminha por pontos próximos e intercala pausas para olhar
com o corpo inteiro. Não acompanha a posição escondida de Miguel. Se o vir de
novo, retoma a perseguição. Sem reencontro, volta ao posto original a 0,8 m/s.
Nas escadas permanecem os limites de ritmo dos clipes da revisão anterior;
a navegação agora pede corrida quando a intenção é correr.

Cada cultista guarda a própria memória da entrada no armário. Quem presenciou
aproxima, abre a folha móvel e tira Miguel para o minigame da Parte 1. Quem não
presenciou pode rondar a região, mas não descobre o armário por conhecer a posição
interna do jogador. A informação de um cultista não concede visão ao perseguidor.

Vários caçadores escolhem lados distintos ao redor do último ponto visível de
Miguel e ajustam a direção para se afastar dos vizinhos próximos. As cápsulas
continuam colidindo. Não há teletransporte nem escrita de ossos para separá-los.
Nenhum clipe, trilha ou pose foi alterado nesta parte.

### Como Felipe testa

1. Execute `bash JOGAR-PROTOTIPO.command`. Entre no campo de visão de um comum:
   ele deve parar brevemente, gritar e correr. Andando ele alcança; correndo você
   ganha distância em trecho livre.
2. Quebre a visão numa esquina ou porta. Observe de longe: ele deve ir ao último
   ponto, rondar/olhar a região por cerca de um minuto e voltar devagar ao posto.
3. Entre num armário diante dele: espere a abertura e o minigame de setas.
4. Repita após quebrar a visão, entrando sem testemunha. Ele pode passar perto;
   não deve abrir o armário por adivinhar onde Miguel está.
5. Atraia vários comuns para área aberta: eles devem buscar lados diferentes,
   respeitando a separação dos corpos.

### Validação e limite dos testes

`tests/capitulo1_caca_test.gd` usa o jogo real, linhas de visão bloqueadas por
parede, corpos físicos e armário com folha móvel. Mede a pausa, o disparo do
grito, deslocamento/velocidade/clipe, memória, duração da busca, retorno, entrada
vista e não vista, vantagem de corrida e cerco com três cultistas. Só lê animações.

O percurso automático padrão sempre foi um teste de mapa e fluxo com comuns
isolados. A antiga técnica de apagar a suspeita a cada quadro não funciona com
reconhecimento imediato. Agora essa simulação usa `tests/capitulo1_rota_game.gd`,
subclasse de teste que desativa visão/agarrão dos comuns somente nos modos rota
ou pátio. Os modos real/furtivo mantêm a percepção. A IA de produção não recebe
nenhum desvio de comportamento para teste; a suíte de caça não usa essa subclasse.

APIs conferidas e executadas em Godot 4.5.1 Compatibility:
[AudioStreamPlayer3D](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/AudioStreamPlayer3D.xml),
[AStarGrid2D](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/AStarGrid2D.xml),
[PhysicsBody3D](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/PhysicsBody3D.xml) e
[Tween](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/Tween.xml).
O tween move apenas a folha do armário, nunca ossos.


Medições da suíte de caça: Sprint percorreu 1,000 m em 0,333 s (3,000 m/s).
Em um segundo de deslocamento dos dois corpos, Miguel andando perdeu 1,550 m
para o cultista; correndo ganhou 0,800 m. No cerco com três comuns, a menor
separação foi 0,7624 m. Desvio de cerco bloqueado por parede recai na aproximação
pelo ponto visto. Vizinhos em outro pavimento não aplicam repulsão horizontal.
A folha do armário foi conferida renderizada aberta e fechada, sem modificar
a iluminação do jogo.

A expectativa antiga de perseguição a 3,8 m/s em `capitulo1_animacao_test.gd`
foi atualizada para os 3,0 m/s pedidos. Patrulha continua a 1,45 m/s. O orçamento
do teste de aproximação do escape passou a incluir a pausa inicial de 0,4 s.
As verificações de clipe, avanço, cadência e movimento dos membros continuam
ativas. O índice vazio de esconderijo nunca é tratado como armário conhecido.


### Saídas da Parte 2 — Godot 4.5.1 Compatibility

```text
CAPITULO1_CACA: 32 passed, 0 failed
CAPITULO1_ESCAPE: 37 passed, 0 failed
CAPITULO1_MOVIMENTO: 33 passed, 0 failed
CAPITULO1_ANIMACAO: 70 passed, 0 failed
CAPITULO1_TEST: 36 passed, 0 failed
CAPITULO1_MAPA: 18 passed, 0 failed
CAPITULO1_NIVEL: 10 passed, 0 failed
CAPITULO1_PERCURSO[rota]: 7 passed, 0 failed
```

`scripts/testar-capitulo1.sh` e `scripts/testar-percurso.sh` terminaram com código
0. O percurso registrou 187,3 s de jogo e zero mortes no modo isolado de rota.
Avaliação de tensão, dificuldade e áudio continua dependendo de Felipe jogar.


## Etapa 1 — Parte 3: sons recebidos de Felipe (02/11/2026)

[Inventário completo e tabela final de usos](SONS-FELIPE-PARTE3.md).
Foram copiados os 376 áudios de `Downloads/GAVYO_SFX_EXPANDIDO/sons` para
`godot-3d/capitulo1/assets/sons`, mantendo nomes/subpastas e bytes originais.
77 arquivos entram em 20 bancos de eventos; 299 ficam importados como reserva.
Arquivos `.DS_Store` não foram copiados. Créditos por arquivo e documentos de
procedência recebidos estão em `capitulo1/assets/sons/CREDITOS.md` e `procedencia/`.

Passos agora seguem o deslocamento real e o piso da grade: azulejo usa os passos
secos genéricos do RPG Audio; cimento usa concreto; escada usa pedra/concreto
com reverberação curta. São aproximações dos materiais, não gravações dedicadas
de azulejo e escada. Há variação de arquivo sem repetição imediata e pequenas
variações de pitch/volume. Parado ou no ar não continua tocando passos.
Cultistas têm timbre mais grave; o perseguidor mais grave ainda. Os emissores
são 3D e ficam presos ao corpo: Miguel alcança 7 m, passos/gritos inimigos 10 m.
A alteração de som não muda percepção, velocidade ou animação da Parte 2.

Substituído o `susto.wav` usado como grito por vocalizações monstruosas recebidas.
Portas têm abertura/fechamento, armários rangido/fecho, bolsa manuseio de couro,
portão contato metálico, agarrão impacto abafado + roupa. Setas corretas,
conclusão, seta errada e falha por prazo têm sinais próprios.
O portão toca no avanço do clipe; bolsa só toca ao confirmar o contato.

O pacote informa não conter respiração humana convincente, canto ritual ou
ambiência longa. Portanto `respiracao.wav`, `culto.wav` e o grilo anterior ficam
preservados. A respiração sintética existente ganhou perfis normal, corrida e
agarrado, com volume e ritmo diferentes; isso não equivale a três gravações novas.
As licenças desses recursos antigos continuam a confirmar por Felipe.
Removidos apenas os provisórios sem uso do capítulo: `metal`, `parede`, `carne`,
`susto` e `bloqueio`, com seus `.import`. Sons usados pelo protótipo permanecem.

### Níveis, importação e web

Som é carregado por `load()` como AudioStream importado, nunca por leitura de
bytes. Ganhos individuais vêm de medição da decodificação em Godot 4.5.1:
RMS alvo -21 dBFS e pico individual até -9 dBFS antes dos buses, com teto de ganho.
Há buses para efeitos, escada, voz, UI e ambiente e limitador no Master a -1 dBFS.
Na suíte final, a decodificação independente mediu pico individual de -9,00 dBFS
e a sobreposição de efeitos/UI mediu pico de -18,03 dBFS no Master. São medidas
desses cenários, não certificação LUFS nem aprovação auditiva de Felipe.

O pacote Web foi exportado para PCK e validado em diretório vazio: 376/376 sons
carregaram por recurso, e CREDITOS.md estava presente. Isso verifica o
empacotamento/carregamento; não substitui ouvir num navegador/celular real.
APIs executadas em 4.5.1: AudioStreamPlayback.mix_audio, AudioStreamPlayer3D,
AudioServer, AudioEffectReverb e AudioEffectHardLimiter. Nenhuma pose foi alterada.
`tools/medir_sons.gd` permite refazer os ganhos após importar outros áudios.

### O que Felipe deve ouvir

1. Execute `bash JOGAR-PROTOTIPO.command`, de preferência com fones.
2. Ande do piso interno para o cimento do pátio e depois pela escada. Compare
   timbre, variações e ressonância; solte o movimento e confira que os passos param.
3. Deixe um comum vê-lo: após a pausa de 0,4 s, ouça o grito e os passos seguindo
   o corpo. Afaste-se até cerca de 7–10 m e gire a câmera para conferir direção.
4. Na perseguição, compare os passos mais graves do perseguidor.
5. Abra/feche porta; entre/saia de um armário; pegue a bolsa e pule o portão.
6. Deixe agarrar: ouça impacto, roupa e mudança de respiração. Acerte a sequência,
   erre uma direção e deixe o prazo acabar em tentativas diferentes.
7. Compare a respiração normal/correndo/agarrado. Ela ainda é sintética provisória
   porque não veio gravação humana no pacote.

### Saídas da Parte 3

```text
AUDIO_RECURSOS carregados=376/376
AUDIO_NIVEL pico_decodificado_com_ganho=-9.00 dBFS
AUDIO_MIX pico_master=-18.03 dBFS
CAPITULO1_AUDIO: 30 passed, 0 failed
CAPITULO1_CACA: 32 passed, 0 failed
CAPITULO1_ESCAPE: 37 passed, 0 failed
CAPITULO1_MOVIMENTO: 33 passed, 0 failed
CAPITULO1_ANIMACAO: 70 passed, 0 failed
CAPITULO1_TEST: 36 passed, 0 failed
CAPITULO1_MAPA: 18 passed, 0 failed
CAPITULO1_NIVEL: 10 passed, 0 failed
AUDIO_WEB_PCK: 376/376 recursos carregados
AUDIO_WEB_CREDITOS: true
```

`scripts/testar-capitulo1.sh`, exportação do PCK Web e teste dos recursos
empacotados terminaram com código 0.


## Etapa 1 — Parte 4: pressão da perseguição e postos (02/11/2026)

Há sete patrulheiros comuns nos postos 1–7 de `mapa/terreo.txt`; o posto 8
reserva o nascimento do único perseguidor. Ele continua ausente no início e
só aparece após alerta espalhado e vídeo gravado, como no gatilho anterior.
Os participantes visuais do ritual permanecem; não foram convertidos em atacantes
adicionais. [Postos, coordenadas e abrigos](../godot-3d/capitulo1/mapa/LEIA-ME.md).

A pressão lê o estado real dos caçadores, sem modificar a IA: há tensão baixa
durante busca distante e crescente com a proximidade. Os passos novos recebem
até +5 dB de reforço próximo, além da atenuação 3D. A respiração sintética ainda
provisória acelera e fica mais audível. A câmera recebe desvio óptico horizontal
de até 4,5 mm e vertical de até 2,925 mm, sem deslocar corpo, ossos ou colisão.
Impactos anteriores conservam seu tremor independente.

**[PROVISÓRIO]** O pacote não traz faixa de tensão: foi sintetizado um pulso/drone
local de 8 s, sem samples externos, carregado por `load()` e repetido em loop.
Gerador em `tools/gerar_tensao_provisoria.py`; crédito em `assets/sons/CREDITOS.md`.
A trilha final virá de Felipe. Quando a última caça termina, o reforço, respiração,
tremor e som de tensão voltam suavemente ao normal. Pausa/checkpoint limpam a
pressão. Um alerta salvo, sem ninguém caçando, não liga o efeito sozinho.

### Como Felipe testa

1. Execute `bash JOGAR-PROTOTIPO.command`, de preferência com fones.
2. Deixe um comum vê-lo e corra. Compare passos/respiração/tremor quando ele fica
   perto e quando você ganha distância. O corpo e as animações devem permanecer
   originais; só a câmera e o áudio recebem pressão.
3. Quebre a visão e se esconda sem testemunha. Durante a busca ainda existe tensão
   baixa; após os 60 s, com todos voltando aos postos, confira o retorno ao normal.
4. Compare rota norte e sul até o pátio de química. Postos novos ficam no refeitório,
   na borda do pátio e na sala opcional; nenhum ocupa sozinho um gargalo obrigatório.
5. Grave sem espalhar alerta: o perseguidor deve continuar ausente. Numa tentativa
   com alerta, grave e confira a aparição a partir do posto 8 e pressão na fuga.

A Etapa 1 está entregue como jogável para avaliação de Felipe. Cena de morte
cruel definitiva continua pendente das animações; tela preta/checkpoint da Parte 1
permanece. "Fugir passa desespero" depende desse teste de Felipe; testes automáticos
verificam efeitos, estados, níveis e rotas, sem declarar aprovação de diversão.


### Saídas da Parte 4 — Godot 4.5.1 Compatibility

```text
PRESSAO longe=0.200 perto=0.962 reforco_passo=4.58 dB tremor=0.00421 m
CAPITULO1_PRESSAO: 19 passed, 0 failed
CAPITULO1_AUDIO: 30 passed, 0 failed
CAPITULO1_CACA: 32 passed, 0 failed
CAPITULO1_ESCAPE: 37 passed, 0 failed
CAPITULO1_MOVIMENTO: 33 passed, 0 failed
CAPITULO1_ANIMACAO: 70 passed, 0 failed
CAPITULO1_TEST: 36 passed, 0 failed
CAPITULO1_MAPA: 18 passed, 0 failed
CAPITULO1_NIVEL: 15 passed, 0 failed
CAPITULO1_PERCURSO[rota]: 7 passed, 0 failed
```

Teste de nível isolado, `scripts/testar-capitulo1.sh` e `scripts/testar-percurso.sh`
terminaram com código 0. O percurso registrou 187,2 s de jogo, zero mortes no modo
isolado de rota. Maior caminho de posto até abrigo: 7,33 m. A pressão foi testada
com estados reais de caça/busca, emissores de passos, respiração e câmera.
