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
