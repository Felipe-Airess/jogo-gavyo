# Passagem para o Claude — 02/11/2026

## Repositório e entrada

- Repositório: `Felipe-Airess/jogo-gavyo`.
- Branch desta entrega: `feat/prototipo-terror-terceira-pessoa`.
- Cena atual: `godot-3d/capitulo1/main.tscn`.
- Entrada específica para o Claude: `CLAUDE.md`. Vinte skills locais pertinentes
  foram copiadas integralmente, com scripts e referências, para `.claude/skills/`.
  Não dependem da pasta pessoal `.agents` do Mac para serem lidas na nuvem.
- Leia `AGENTS.md`, `docs/CONTINUAR-NOUTRO-CHAT.md`, `docs/DECISOES-RODADA-3.md`,
  `docs/referencias/mapa-escola-felipe.png` e `godot-3d/capitulo1/README.md`.
- Os trechos antigos sobre Phaser, 2.5D e revisão 2 são históricos. Não reiniciar
  o projeto nem trocar a engine. Godot **4.5.1 Compatibility**, Mac Intel Iris.

## Pedido mais recente e forma de trabalhar

Felipe pediu integrar o mapa inteiro, ambientação e as frentes do ponto de partida
antes de avaliar. Não voltar a pedir feedback de uma pequena sala de teste como
condição para continuar. Depois pediu subir tudo e documentar para trocar de agente.
O capítulo integrado foi produzido, mas Felipe **ainda não avaliou essa entrega**.
Não transformar testes automatizados em aprovação estética ou de diversão.
Não repetir decisões já respondidas. Falas de Miguel serão fornecidas por Felipe;
não inventar falas aprovadas. O capítulo 2 continua para depois.

## O que fizemos

1. Lemos memória/instruções, documentação e mapa. Conferimos conflitos históricos
   dando preferência às decisões posteriores.
2. Criamos uma bancada em `godot-3d/validacao/`, com lançador
   `VALIDAR-INICIO.command`, comparação de ombros, paleta e prévia de clipes.
3. Corrigimos a câmera compartilhada: ombro também sem alvo travado; colisão após
   suavizar para não atravessar paredes ao virar uma esquina.
4. Inventariamos 25 FBX, 43 clipes no GLB e seis movimentos da biblioteca provisória.
   Buscamos skills com `find-skills`; utilizamos as locais já instaladas. Não houve
   compra, login Mixamo nem novo download de animações/modelos externos.
5. Implementamos `capitulo1/`, reutilizando a base de movimento/colisões da revisão 2,
   que foi preservada em `prototipo/`.
6. Construímos a planta a partir do desenho: 29 ambientes nomeados, quadra, pátio,
   blocos, salas, escada, andar superior e dois portões. Escala adaptada, não medição
   arquitetônica real. Portas abertas e subida da escada foram verificadas fisicamente.
7. Integramos bolsa, celular posterior à bolsa, vídeo por enquadramento, checkpoints
   com alerta salvo, rota discreta e rota com perseguição, revelação e salto do portão 1.
8. Integramos ataques encadeados, pesado, fadiga por comandos extras, contato medido,
   ação ajoelhada no chão, pegada/derrubada FK e contextos de parede/armário/mesa.
9. Substituímos os inimigos de segmentos/cápsulas por malha humanoide derivada em
   memória, cabeça própria, roupas e três estilos. Perseguidor maior e sem máscara.
10. Acrescentamos exploração, ferramentas interrompíveis, arrastar corpos, distrações,
    sangue/vestígios, suspeita, chamadas, memória, procura e portas arrombáveis.
11. Integramos cenário escolar, luzes, velas, ave no pentagrama, filtro leve, sons
    provisórios e montagem final da casa/quarto, sem desenvolver gameplay do ato 2.
12. Mudamos o lançador principal e `project.godot` para o capítulo integrado.

## Rodada Claude — 02/11/2026 (reformulação para terror)

Felipe jogou e avaliou: animações quebradas, escola sem sentido, visual claro e
chapado, combate ruim. **Decisão dele:** o jogo é uma história de terror, não um jogo
de luta. Miguel empurra, foge e se esconde. Isto substitui as decisões de combate
anteriores (combos, pesado, derrubada, finalização, arrastar corpo).

Feito nesta rodada (testes: capítulo 43, base 39, validação 15, percurso 7/7):

- Corrida: `Running` é uma arrancada, não um ciclo; em loop, Miguel "recomeçava a
  correr" a cada 1,6 s. Agora a arrancada toca uma vez e emenda em `prototype/run`.
- Clique esquerdo = empurrão: derruba sem ferir; o cultista levanta e chama ajuda
  (espalha alerta). Repetir só cansa. Cultista agarra em vez de socar; soltar-se
  exige apertar Q/clique direito 4 vezes; a faca solta na hora.
- Código do combate antigo removido do capítulo (base `prototipo/` intacta).
- Filtro retrô (pixelização, paleta com pontilhado, vinheta) em
  `capitulo1/gravacao.gdshader`; F3 alterna. Ambiente escuro com névoa.
- Luzes: o cenário era fundido em uma malha por material no mapa inteiro; no
  Compatibility cada malha recebe poucas luzes, então lâmpadas e lanterna eram
  ignoradas. Agora lotes por região de 12 m. Lanterna sai da mão de Miguel.
- REC validava pelo ombro e gravava pela cabeça: cancelava sozinho no vão da porta.
- Portas do capítulo abrem para dentro (a folha trancava corredores).
- Postos de cultistas: um ficava a 0,5 m do checkpoint 2 e outro via a entrada do
  pátio. Checkpoint só salva sem cultista alerta/vendo por perto.
- Cultista calmo não faz parkour (ficava preso tentando pular mesas).
- `scripts/testar-percurso.sh`: percurso contínuo com física real do acordar ao
  portão (`--real` liga a percepção dos inimigos, só registra).
- `godot-3d/tools/capturar_vistas.gd`: capturas no Linux com `xvfb-run`.
  Antes/depois em `docs/verificacao-20261102/reformulacao/`.

Ainda ruim / próximo:

1. **Level design.** O mapa é o desenho copiado em escala literal: corredores longos e
   vazios (~50 s andando só até a escada). Refazer usando o desenho como mapa de
   ligações, com espaços menores, esconderijos e linhas de visão quebradas.
2. Empurrão e agarrão usam clipes de soco existentes (`direto`, gancho). Precisam de
   animações próprias.
3. Camisa de Miguel fica estourada no escuro; revisar material.
4. HUD ainda mostra EMPANADOS/FACA de forma "jogo de luta"; simplificar.
5. Felipe ainda não avaliou esta rodada.

Fotos da escola: `docs/referencias/escola-fotos/` (quadra coberta, lab de
hardware, pátio de química, pátio principal, auditório). Paleta e mobiliário do
cenário seguem essas fotos.

No Linux: Godot 4.5.1 em `/tmp/claude-0/godot/` (baixar de novo numa sessão nova).

## Rodada Claude — 02/11/2026, parte 2 (escala real, celular, ritual atento)

Decisões de Felipe nesta parte (não regredir):
- **Escala real**: 0,12 m por pixel do desenho (sala ~8×6 m). O mapa estava pequeno.
- **Labs de Informática 1, 2 e hardware** abrem para o **pátio aberto**, ao lado do
  Informática 1. **Corredorzinho** entre hardware e coordenação leva a **2 e 1
  Contabilidade**. Biblioteca, lab de matemática e Informática 1 de frente ao pátio.
- **Auditório é um palco elevado no refeitório** (avisos); porta da biblioteca logo
  atrás. Não é sala.
- Ritual **já acontece** na subida; Miguel passa escondido. Cultistas do ritual
  percebem devagar (em transe); agachado/sombra da escada protege; velas, lanterna e
  correr expõem. Notado → alerta espalhado.
- Combate de terror: empurrão (FK com as duas mãos) e agarrão do cultista (FK);
  clipes gerados em `capitulo1/acoes.gd`, não captura nova.

Feito (testes: capítulo 46, base 39, toque 10, percurso rota 7/7, percurso pátio 8/8):
- Controles de toque (`capitulo1/toque.gd`), build web (`scripts/exportar-web.sh`),
  publicação via PR Felipe-Airess/jogo-gavyo#16 em `/capitulo1/` do Pages.
- Retrô por SubViewport de baixa resolução (funciona na web; o shader de tela sumia).
- Web: sons/fontes carregados como recurso importado (antes falhavam na exportação).
- HUD de terror; ritmo inicial com três sinais de inquietação; dica de agachar.
- Fotos 1–8 aplicadas (auditório, quadra com rede/tabelas/cobogó, colunas do pátio,
  entrada com caminho verde, portão de grade, faixa laranja e placa).

Level design refeito pelas skills: ver `docs/LEVEL-DESIGN-CAPITULO1.md` (métricas,
duas rotas, ritmo, postos, testes em `tests/capitulo1_nivel_test.gd`).

Pendências reais:
1. Felipe testar no celular e no PC; desempenho real só em aparelho (nuvem desenha na CPU).
2. Percurso a pé ficou ~3 min (escala real). Avaliar jogando se precisa de atalhos.
3. Salas fora do caminho ainda simples; interior dos labs pode ganhar mais itens.
4. Clipes FK de empurrão/agarrão são provisórios; trocar por captura quando houver.

## Rodada Claude — 02/11/2026, parte 3 (mapa em grade ASCII + kit modular)

Felipe avaliou o mapa por coordenadas como ruim e pediu nova estratégia
(`docs/ESTRATEGIA-MAPA.md`). Feito:

- **Mapa como texto**: `godot-3d/capitulo1/mapa/terreo.txt` e `superior.txt`,
  1 caractere = 1 m, legenda no topo. Felipe edita o texto; o jogo monta.
- **Kit modular** cinza em `capitulo1/mapa/kit.gd` (peças de 2 m, pivô na base),
  MeshLibrary salva em `kit_blockout.meshlib`. GridMaps separados para piso,
  estrutura e telhado (uma peça por célula).
- **Montador** `capitulo1/mapa/escola_grade.gd`: GridMap + colisão mesclada +
  portas + escada + armários + pontos da história vindos das marcas do texto
  (@ $ * + 1–4 G &). Mantém a interface que `game.gd` usava.
- `capitulo1/nivel.gd` agora em células: rotas, gargalos, pontos de roteiro,
  itens, ferramentas. Postos vêm do texto.
- Escola antiga movida para `capitulo1/referencia/` (não carregada).
- Checkpoint salvo sobe para versão 4 (posições antigas não valem no mapa novo).
- Exportação web inclui `capitulo1/mapa/*.txt` (conferido com `--export-pack`).
- Ferramentas: `tools/exportar_planta.gd` + `scripts/desenhar-planta.py` (planta
  de cima com colisão real por cima), `tools/capturar_vistas.gd` (revisão clara
  ou `jogo`), `tools/capturar_kit.gd`, `tools/gerar_kit.gd`.

Decisões aplicadas no texto: escala real; labs de frente ao pátio aberto;
corredorzinho até 2 e 1 Contabilidade; palco no refeitório com a porta da
biblioteca logo atrás; escada fechada no pátio de química (entrada por vão);
ritual no pátio de química; passagem estreita do refeitório até o portão 1;
quadra coberta sem acesso à escada.

Pontos para Felipe confirmar (estão no texto, fácil de trocar):
1. Sala de cima sobre o 3 Contabilidade está como **3 Enfermagem** (como no
   desenho). O código antigo a chamava de "3 Contabilidade · superior".
2. Faixa coberta diante de 3 Contabilidade / 2 Informática liga a quadra ao
   corredor aberto. A escada só se alcança pelo pátio de química.
3. Há um terceiro caminho do pátio aberto até o pátio de química: refeitório →
   passagem do portão → corredor sul.
4. Área de saída (vegetação) a oeste da passagem, acessível por uma abertura.

Testes (Linux, Godot 4.5.1): capítulo 47, mapa 18 (novo), nível 10, protótipo
39, toque 10, validação 15; percurso rota 7/7 (166 s), pátio 8/8 (suspeita
máxima 0,69), furtivo 7/7. No furtivo o robô anda em pé pela rota norte e o ritual o
nota (o modo é só observação). Testes não substituem Felipe jogando.

**Bloqueio cinza aguardando aprovação de Felipe. Não decorar antes.**

### Correções de Felipe sobre o bloqueio (02/11, mesma parte 3)

Felipe olhou a planta e mandou um esboço em perspectiva do pátio/refeitório. Aplicado:
- Pátio de química 3 m mais fundo para o norte (as salas vizinhas não mudaram).
  A grade ganhou 3 linhas no topo; todos os pontos em células subiram 3 linhas.
- Pátio aberto é **concreto** (sem azulejo); a calçada coberta junto às salas fica.
  No bloqueio o concreto agora é liso (só azulejo e paredes mostram a grade de 1 m).
- Pátio e refeitório **sem parede**: separados por um relevo baixo (`=`, 8 cm,
  passa-se por cima). Colunas da cobertura do refeitório junto ao relevo.
- Palco do auditório: mais alto (0,8 m) e menor (6×3 m).
- Do esboço: lab de contabilidade logo depois da sala de esportes; trocado com a
  sala de música (confirmar).
- **Cores para a decoração (depois da aprovação)**: a maior parte das paredes é
  verde ou amarela, inclusive no pátio de química. O bloqueio continua cinza.

Fotos novas de Felipe (`docs/referencias/escola-fotos/refeitorio-colunas.jpg`,
`patio-varanda.jpg`). Aplicado: colunas do refeitório na própria linha do
relevo, a cada 3 m; calçadas cobertas do pátio (norte, oeste, sul) com relevo
na beira entre as colunas. Para a decoração: paredes amarelas em cima, azulejo
branco embaixo (inclusive nas colunas), portas e janelas verdes, telhado de
telha com beiral, cadeiras de plástico brancas empilhadas no refeitório.
Testes: capítulo 47, mapa 18, nível 10; rota 7/7 (162 s); pátio 8/8.

Testes depois das correções: capítulo 47, mapa 18, nível 10; percurso rota 7/7
(163 s), pátio 8/8 (suspeita máx. 0,69). Furtivo (só observação): o ritual nota o
robô (anda em pé) e o perseguidor o pega na fuga; sem a parede, o pátio e o
refeitório viraram uma área aberta só, com mais visão.

## Arquivos importantes

| Arquivo | Papel |
|---|---|
| `capitulo1/game.gd` | Fluxo, combate, alerta, checkpoints e interações |
| `capitulo1/mapa/` | Mapa em grade ASCII, kit modular, montador (ver LEIA-ME.md) |
| `capitulo1/referencia/escola_coordenadas.gd` | Escola anterior por coordenadas (só referência) |
| `capitulo1/ator.gd` | Variações humanoides, poses e movimentos |
| `capitulo1/acoes.gd` | Geração das chaves FK da pegada/derrubada |
| `capitulo1/camera.gd` | Cenas, lente de gravação e enquadramento contextual |
| `capitulo1/encerramento.gd` | Casa, quarto, rede e personagens da montagem final |
| `capitulo1/hud.gd` | Objetivos e controles da versão atual |
| `capitulo1/qa.gd` | Ponte opcional de captura apenas do jogo |
| `capitulo1/assets/MANIFESTO.md` | Proveniência e limites dos recursos |
| `tests/capitulo1_test.gd` | Testes da integração |

Os caminhos da tabela são relativos a `godot-3d/`.

## Decisões que não podem regredir

- Miguel acorda sem celular. Bolsa no terceiro de Informática, no andar superior,
  acima do “2 infor”. **Escada no pátio de química** (foto de Felipe), fechada em
  caixa de parede; a quadra não dá acesso à escada. Porta do 2 Informática abre
  para o pátio de química.
- O ritual **já está acontecendo** quando Miguel precisa subir: ele atravessa o
  pátio escondido pela passagem junto à parede sul. Da entrada da escada dá para
  espiar (e gravar); do patamar e do corredor de cima, não.
- Checkpoint 2 fica no pé da escada, dentro da caixa (abrigo antes do ritual).
- Ritual no pátio de química; não no refeitório. Não se vê o ritual do andar superior.
- Ave real no pentagrama; destino não definido. Não inventar sacrifício/morte da ave.
- Vídeo manual. Contato com amigos só depois de sair; não inventar falta de sinal.
- Perseguição exige reconhecimento e alerta efetivamente espalhado. Suspeita,
  corpos e sangue não bastam. Checkpoint restaura o alerta salvo.
- Chamado comum pode ser interrompido; chamado da cena final na rota alertada não.
- Perseguidor é cultista forte com faca, não a entidade; não enfrentável.
- Fuga/frestas em primeira pessoa; exploração/combate sobre ombro.
- Saída pulando portão 1. Sem checkpoint adicional da perseguição como aprovado.
- Fôlego pune spam extra, não cada ataque. Até dois inimigos, um atacando por vez.
- Sem mãos teleportadas para conseguir acerto. Sem dano motor persistente por ferimento.
- Sem novas trancas/barricadas, bateria de lanterna ou música padrão.

## Verificação já executada

- 42 testes do capítulo, 39 da base preservada e 15 de câmera passaram: **96**.
- Câmera e lançador conferidos com OpenGL real no Mac; sem erro de script na rodada final.
- Há aviso de objetos remanescentes na saída de algumas execuções headless.
- Exploração ativa, sem captura extra/QA, três segundos por trecho:
  pátio 59,93 FPS; corredor 41,48; química 58,08; superior 60,00.
  São amostras curtas, não garantia de 60 FPS constante nem benchmark completo de combate.
- Evidências selecionadas estão em `docs/verificacao-20261102/`.
- Originais Miguel preservados (SHA-256):
  `3badb61b532b27447a6e46d230643b4aab2f3db04a8e5ad884baf78313b21c5d`.

## O que falta fazer / revisar

1. Avaliar a versão inteira jogando com Felipe: percurso, orientação, tensão,
   conforto de câmera, ritmo e leitura. A aprovação anterior era do Miguel original,
   não do acabamento novo.
2. Fazer uma passagem contínua do capítulo inteiro, sem teletransportes de teste,
   nas duas rotas. Os testes cobrem estados/trechos, não substituem esse playtest.
3. Refinar a abertura: a observação protegida do primeiro cultista atualmente é
   disparada ao aproximar-se do conector do pátio. Conferir a montagem com a
   descrição de Felipe de ouvir/sair pela porta, sem alterar a localização combinada.
4. Dar acabamento às animações: corrida usa captura existente; pegada e reação do
   alvo usam FK autoral/adaptação, e apoio, ferramenta, parkour e salto do portão têm
   poses procedurais. Não apresentar isso como um pacote novo de captura profissional.
5. Revisar ações em par e finalizações em diferentes paredes, mesas, cantos e espaços
   estreitos: contato inicial é verificado, mas testes não provam ausência de toda
   interpenetração de pele/membros em qualquer geometria.
6. Refinar modelos/cenário. Cultistas têm novas variantes simples; Bola é uma
   representação provisória sem identidade aprovada. A casa é um cenário genérico,
   não uma reconstrução comprovada da casa real de Felipe.
7. Auditar IA no mapa inteiro: navegação vertical, busca após perda de visão,
   descoberta de esconderijos, inspeção de vestígios, arrombamento e comportamento
   do segundo inimigo. Valores e algumas reações são iniciais, não decisões aprovadas.
8. Inimigos importantes com fintas e escalada específica de agressividade ainda
   precisam de conteúdo próprio; o perseguidor não é esse adversário combatível.
9. Ferramentas/usos e suas poses são escolhas iniciais de implementação. Revisar
   utilidade, interface e acesso sem criar bloqueios/trancas fora do combinado.
10. O vídeo é um estado narrativo com visão de lente/REC, não exportação de filme.
    Refinar operação/enquadramento e montagem. Falas de Miguel continuam pendentes.
11. Revisar sons ouvindo. WAVs e voz do culto são sintéticos/provisórios. Termos de
    distribuição da voz local não foram auditados; não publicar esses recursos como
    se já houvesse uma revisão de direitos. Sem gravação de microfone/clonagem de voz.
12. Medir percurso completo e combate no Mac, sem ponte QA. Depois otimizar o que
    for medido como gargalo. Tamanho em disco não comprova custo de FPS.
13. Reavaliar organização do coordenador grande após estabilizar comportamento.
    Não apagar fontes, fotos, histórico ou ferramentas necessárias ao lançador.

## Rodar em outra máquina / nuvem

No Mac de Felipe: `bash JOGAR-PROTOTIPO.command`; Enter começa.

No Claude em Linux, instalar Godot 4.5.1 para o ambiente e usar o executável Linux:

```bash
GODOT=/caminho/para/Godot_v4.5.1-stable_linux.x86_64 bash scripts/testar-capitulo1.sh
GODOT=/caminho/para/Godot_v4.5.1-stable_linux.x86_64 bash scripts/testar-prototipo.sh
```

Não usar o executável `.app` do Mac no Linux. Importar os recursos primeiro com
`Godot --headless --path godot-3d --import`. A pasta `.godot/` é cache regenerável.
O código e recursos necessários estão no Git. `work/` continua local: ferramentas
para Mac, arquivos de trabalho Blender, backups e QA; não é dependência oculta do
capítulo se GODOT apontar para um executável instalado no novo ambiente.


## Etapa 1 — minigame direcional (02/11/2026)

Agarrão comum/perseguidor agora abre sequência aleatória, com WASD/setas ou
quatro setas grandes no toque. Primeiro: 3 setas/3 s; cresce até 7 setas/1,5 s.
Acerto recua Miguel, atordoa agressor por 2 s e protege de agarrões por 1,5 s.
Erro/prazo: tela preta de 1,5 s e checkpoint automático.
[PROVISÓRIO: trocar pela cena de morte quando chegarem as animações].
A cena de morte e os demais itens da timeline continuam pendentes.

Estado isolado em `capitulo1/escape.gd`; integração em game/HUD/toque.
O gancho `finisher_item_available` evita só o agarrão comum, com uso único;
não há pickup nem finalização implementada. Perseguidor nunca é finalizado.
Q/clique direito/faca não pulam mais o escape. Nenhuma correção de ossos.
Detalhes e teste manual na última seção de `docs/TESTE-FELIPE-20261102.md`.

Validação: `scripts/testar-capitulo1.sh` passou (escape 37, movimento 33,
animação 70, capítulo 36, mapa 18, nível 10); toque 9/9 em eventos simulados;
`scripts/testar-percurso.sh` passou 7/7. Ainda falta avaliação de Felipe jogando.
