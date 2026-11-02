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
