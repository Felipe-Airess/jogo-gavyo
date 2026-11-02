# Etapa inicial — escala, câmera e avaliação de movimentos

01/11/2026. Iniciada após Felipe dizer “vamos começar”, usando `find-skills`.
Este registro complementa a continuidade e não altera as decisões de roteiro.

## Entrega desta etapa

Abrir pelo Finder `VALIDAR-INICIO.command`, ou no Terminal, na raiz:

```bash
bash VALIDAR-INICIO.command
```

Cena: `godot-3d/validacao/inicio.tscn`. Bancada separada, sem inimigos, história,
save ou gatilho de perseguição. Não é a reprodução final do mapa recebido.
Contém uma entrada aberta, corredor, esquina, sala lateral, mesa, armário e porta
física. Dimensões propostas para testar: corredor com 3 m livres, vão de porta
de 1,4 m, paredes de 3,2 m. A escala deve ser avaliada jogando antes de replicar.

- WASD/mouse: andar/olhar; Shift: correr; Espaço: abrir/fechar porta próxima.
- Tab: comparar ombro direito/esquerdo. R: voltar à entrada.
- F2: alternar entre explorar e prévia parada de animações existentes.
- `[` / `]`: escolher clipe. Os primeiros alternam corrida capturada/procedural,
  caminhada fonte/adaptada, esquiva fonte/procedural e gancho fonte/adaptado.
- F3: comparar iluminação ambiente fria/amarelada. Ainda não é filtro de vídeo.
- Esc: liberar/capturar mouse. Fechar a janela encerra o teste.

A câmera compartilhada do protótipo também passou a usar ombro na exploração
livre. Distância inicial de 2,1 m, deslocamento lateral de 0,48 m e ombro direito
são parâmetros provisórios. Após suavizar a posição, outra varredura impede a
câmera de voltar para trás de uma parede. Fuga e frestas continuam em primeira
pessoa. Não houve alteração de combate, clipes ou GLB.

## Relações do mapa que orientam a próxima construção

Fonte: `docs/referencias/mapa-escola-felipe.png`, inspecionada visualmente.

1. Depósito/esportes junto do pátio a céu aberto e refeitório, à direita do desenho.
2. Primeiro cultista distante no corredor descrito por Felipe como “do pátio pro
   enf1 e cont1”. Essa descrição prevalece sobre interpretação incerta dos rótulos.
3. Busca da bolsa no terceiro de Informática, segundo andar acima do “2 infor”
   do canto superior esquerdo. Escada ao lado da quadra, que fica à esquerda.
4. Descer e se aproximar do pátio de química, na parte superior do desenho.
   Sem linha de visão do ritual a partir do corredor superior.
5. Vídeo manual e saída pulando o portão 1, na parte inferior. Perseguição depende
   de alerta efetivamente espalhado; reconhecimento isolado não basta.

Não foram fixados metros para toda a planta, encontros, esconderijos ou atalhos.
A bancada testa dimensões antes dessa aplicação, sem inventar novas salas do roteiro.

## Inventário e seleção de animações

Há 25 FBX em `arte/mixamo`, 43 clipes no GLB e seis na biblioteca exclusiva do
protótipo. Nomes diferentes podem ser recortes da mesma fonte: não são 43 ações
independentes aprovadas. Inventário reproduzível, sem modificar recursos:

```bash
work/ferramentas/godot/Godot.app/Contents/MacOS/Godot --headless --path godot-3d --script res://tools/inventariar_animacoes.gd
```

Relatório em `work/inventario-animacoes.json`: nomes, durações, trilhas e loops.

| Ação | Material existente a avaliar | Critério antes de integrar |
|---|---|---|
| Corrida | `Running` / `correr` e `prototype/run` | Apoio dos pés, inclinação, deslocamento e controle; hoje o jogo usa a versão procedural |
| Caminhar/parar/girar | `Start_Walking`, `Pivot`, `Running_To_Turn` | Separar entrada, ciclo, parada e giro; não tratar clipe inteiro como ciclo |
| Guarda/defesa | `Ready_Idle`, `Blocking`, `Body_Block` | Postura coerente e reação no contato |
| Golpes | `Hook_Punch`, `Punching_1`, `Fist_Fight_A` e recortes | Preparação/ativo/recuperação, alcance real e emendas sem salto |
| Esquivas | `Dodging`, `Esquiva_2`, `prototype/slip` | Diferenciar tronco/deslocamento, evitar braços/pernas incoerentes |
| Queda/levantar | `Sweep_Fall`, `Dying`, `Getting_Up` | Orientação, chão e encaixe da pose final/inicial |
| Derrubadas/finalizações | `Brutal_Assassination*`, `Hell_Slammer_A` | Exigem avaliar/adaptar vítima e espaço; nomes não provam animação em par |
| Agachar, parkour, arrastar, ferramentas | Sem conjunto validado | Pesquisar/adaptar ações próprias; não substituir por gesto incompatível |

A prévia parada não mede sincronização entre duas pessoas nem aprova contato.
Felipe não precisa modelar ou animar. Falas continuam a ser fornecidas por ele.

## Frentes seguintes e limites desta entrega

- **Level design:** aplicar as dimensões testadas ao blockout das conexões do mapa;
  preservar área inicial sem povoamento inimigo indiscriminado e combate opcional.
- **Animações:** selecionar/adaptar o primeiro conjunto coeso e só depois integrar
  estados/transições. Combos, fôlego por spam e ações em par ainda não implementados.
- **Modelos:** Miguel original preservado. Cultistas/perseguidor ainda provisórios;
  selecionar uma base humanoide compatível, aparência, fonte/licença e custo antes
  de baixar/incorporar arte externa. Perseguidor com silhueta forte e rosto descoberto.
- **Cenário:** validar circulação antes de acabamento escolar, texturas e objetos.
- **Filtros:** a comparação de paleta é inicial. Gravação antiga, velas vermelhas,
  contraste e leitura precisam de tratamento próprio; sem ruído/blur para ocultar defeitos.
- **Desempenho:** manter 960×540, Compatibility, sem MSAA/sombras dinâmicas. A captura
  opcional não serve de benchmark. Nenhum novo número de FPS ativo é alegado aqui.
- **Limpeza:** nenhuma exclusão. Executável em `work/ferramentas`, fontes, fotos,
  GLB e histórico preservados. Tamanho de disco não é custo de execução.

## Skills consultadas e pesquisa

Leaderboard consultado antes do CLI. Pesquisas: `godot animation`, `level design`
e `retargeting`. Esta última retornou bastante marketing e não fundamentou seleção.

Já estavam instaladas as skills pertinentes do repositório comunitário
[gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills):
[level-design](https://skills.sh/gamedev-skills/awesome-gamedev-agent-skills/level-design)
(9,7 mil instalações no resultado consultado) e
[godot-animation](https://skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-animation)
(8,3 mil). API do GitHub consultada: 6.463 estrelas. Popularidade não substitui
revisão; instruções lidas localmente. Também usadas `camera-systems` e
`godot-3d-essentials`. Nenhuma instalação adicional, compra ou download de assets.

As skills citam 4.7, mas o executável confirmado é Godot 4.5.1. Conferida a
[API de varredura de formas da versão 4.5](https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate3d.html)
antes do ajuste de câmera. Engine não atualizada.

## Verificação

Suíte existente executada nesta etapa: **39 testes passaram, zero falhas**.
Ela protege comportamento da revisão 2, inclusive aspectos históricos que ainda
precisam ser substituídos pelo roteiro recente; passar não significa capítulo novo pronto.

Teste dedicado de câmera/cena/porta/prévia: `res://tests/validacao_inicial_test.gd`:
**15 passaram, zero falhas**, executados também com OpenGL Compatibility real no
Mac (log em `work/validacao-testes.log`, sem erros). Na rodada headless anterior,
o backend Dummy emitiu duas mensagens de material nulo ao encerrar; elas não
apareceram na execução gráfica. A suíte antiga emitiu aviso de objetos remanescentes
na saída. Não foi feita limpeza de recursos da revisão anterior nesta etapa.

Captura opcional só do viewport: `res://tools/capturar_validacao.gd`, gravada em
`work/validacao-inicial.png`. Não lê desktop e não roda no lançador normal.

Backup da câmera anterior em `work/revisoes/inicio-camera-20261101-225111/`.
SHA-256 dos dois originais `miguel_animado.glb`, preservados:
`3badb61b532b27447a6e46d230643b4aab2f3db04a8e5ad884baf78313b21c5d`.
