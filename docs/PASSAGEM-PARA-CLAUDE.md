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

No Linux: Godot 4.5.1 em `/tmp/claude-0/godot/` (baixar de novo numa sessão nova).

## Arquivos importantes

| Arquivo | Papel |
|---|---|
| `capitulo1/game.gd` | Fluxo, combate, alerta, checkpoints e interações |
| `capitulo1/escola.gd` | Planta, escala, salas, geometria, objetos e agrupamento visual |
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
  acima do “2 infor”. Escada junto da quadra.
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
