# Gavião — continuidade da reformulação

> **02/11/2026 — integração solicitada por Felipe:** o lançador principal agora
> abre `godot-3d/capitulo1/main.tscn`. Mapa, ambientação, roteiro, câmera e combate
> integrados para avaliação posterior. Estado, controles, validação e limites em
> [README do capítulo](../godot-3d/capitulo1/README.md). O texto abaixo conserva
> a passagem anterior; não confundir o estado da revisão 2 com o capítulo atual.

> **Etapa iniciada em 01/11/2026, após “vamos começar”:** ver
> [ETAPA-INICIAL-VALIDACAO.md](ETAPA-INICIAL-VALIDACAO.md).
> Bancada separada em `VALIDAR-INICIO.command`, inventário de animações e câmera
> sobre ombro também na exploração livre. Modelos/clipes originais preservados;
> nenhuma exclusão. O restante abaixo distingue decisões e estado anterior.

Atualizado em 01/11/2026, depois do mapa e das últimas reclamações de Felipe.

## Leia primeiro e respeite o escopo

Felipe quer continuar este projeto em outro chat sem perder as decisões.
Esta passagem prepara documentação e um plano; **não autoriza iniciar a
implementação, baixar/comprar assets ou apagar arquivos**. A última orientação
foi guardar por enquanto. No novo chat, respeitar o pedido que Felipe fizer:
se mandar implementar uma etapa, isso autoriza aquela etapa, sem perguntar de novo.

Não repetir o questionário já respondido. Não avançar para planejar o capítulo 2.
Não recomeçar o projeto nem trocar de engine. Não tratar toda a lista como promessa
de uma única entrega. Explicar limitações reais, sobretudo animações sincronizadas
e desempenho. Não obrigar Felipe a modelar/animar: ele contribui com desenhos,
referências, falas e avaliação jogando.

## Fontes e ordem de leitura

1. `/Users/felipe/MEMORIA.md` e `AGENTS.md` do projeto.
2. Este documento: entrada e resumo do estado atual.
3. [DECISOES-RODADA-3.md](DECISOES-RODADA-3.md): registro detalhado das respostas.
4. [Mapa original de Felipe](referencias/mapa-escola-felipe.png): inspecionar a imagem.
5. [REFORMULACAO-TERROR-COMBATE.md](REFORMULACAO-TERROR-COMBATE.md): decisões anteriores
   ainda válidas onde não foram substituídas. Há trechos históricos contraditórios.
6. [README do protótipo](../godot-3d/prototipo/README.md) e
   [DESEMPENHO-PROTOTIPO.md](DESEMPENHO-PROTOTIPO.md): implementação existente.
7. [Técnica dos personagens](TECNICA-PERSONAGEM-3D.md): antes de trabalhar em modelos.

**Decisões posteriores prevalecem.** Especialmente: câmera sobre o ombro;
Miguel acorda SEM celular; ritual no pátio de química; vídeo, não foto;
perseguição condicional ao alerta espalhado; saída pulando o portão 1;
checkpoint restaura o alerta salvo; fôlego pune apenas spam.
O registro detalhado preserva algumas formulações anteriores como histórico;
não executar essas formulações contra os refinamentos posteriores.

## Objetivo e reclamações atuais

Reformular level design, animações, modelos inimigos, cenário, câmera e filtros
com qualidade e sem voltar aos travamentos. Felipe considera as animações toscas:
quer movimentos pensados para a ação, inclusive pesquisar prontos quando viáveis.
Não considera suficiente apenas ajustar loops/velocidade. Quer limpeza do projeto
e câmera próxima sobre o ombro. Inspeção feita; nenhuma limpeza ou mudança de
gameplay foi realizada nesta rodada.

Referências: impacto/encaixe dos jogos UFC, gore de Hotline Miami, ambiente de
terror cotidiano próximo de Fears to Fathom. Escola brasileira inspirada na
Joaquim Antônio Albano, Fortaleza, com adaptações para jogar. Personagens e
cenários 3D, textura de jogo antigo, imagem legível. Não retornar à pixelização
extrema que Felipe rejeitou.

## Capítulo 1 e mapa confirmados

- Miguel é monitor de educação física, brincalhão e medroso. Saiu para almoçar,
  deixando bolsa e celular na sala. Dormiu no depósito de materiais/esportes
  junto do pátio aberto/refeitório. Acorda à noite sem celular.
- Ouve barulho e vê de longe um cultista indo para dentro pelo corredor que
  Felipe descreve como “do pátio pro enf1 e cont1”. Percebe perigo, não o chama.
  Todos os cultistas são desconhecidos. O culto usa a escola há tempos; ele não sabe.
- Inimigos inicialmente a partir desse corredor, mudando de posição se Miguel
  chamar atenção. Não povoar a área inicial inteira de inimigos por padrão.
- Precisa pegar a bolsa na sala do terceiro de Informática, no segundo andar,
  acima do “2 infor” do mapa. Escada do lado da quadra. Não enxerga o ritual de cima.
- Recupera a bolsa, desce e se aproxima de mansinho do pátio de química.
  Ritual NÃO fica no pátio do refeitório onde ele acorda.
- Cultistas aclamam a entidade com uma ave gavião no meio de um pentagrama e
  anunciam o fim dos tempos. Destino/estado da ave não definido: não inventar sacrifício.
- Jogador enquadra manualmente e grava VÍDEO. Só tenta contatar os amigos depois
  de sair da escola. Não inventar impedimento por falta de sinal.
- Se nenhum cultista conseguiu reconhecê-lo E espalhar o alerta antes, pode
  filmar e sair sem perseguidor. Suspeita, corpos e sangue só intensificam a busca.
  Reconhecer Miguel sem conseguir avisar também não habilita perseguição.
- Alerta espalhado dura até o fim da tentativa; despistar não apaga a consequência,
  mas inimigos não passam a conhecer magicamente a posição dele. Resposta distante
  ao chamado e movimentação pela escola comunicam que o aviso se espalhou.
- Na rota com alerta espalhado, um cultista o encontra durante a gravação e chama
  o perseguidor. Esse chamado específico inicia a cena, sem chance de interrompê-lo.
  Não atribuir descoberta ao flash e não tornar a perseguição obrigatória.
- Após alguns segundos, apresentação: pés → Miguel em terceira pessoa gravando
  → faca → Miguel gravando → rosto descoberto e bizarro → Miguel paralisa.
  Celular continua registrando; planos externos de Miguel são montagem do jogo.
  Depois controle para fugir em PRIMEIRA PESSOA.
- Perseguidor é um cultista grande e forte com faca, não a entidade. Não enfrentável.
  Correr ou esconder, quebrando linha de visão primeiro. Som e frestas ajudam a
  avaliar o risco. Portas fechadas compram tempo; ele insiste até arrombar.
- Parkour contextual por botão explorando; automático ao passar perto na fuga.
  Mesas, bancos, obstáculos baixos, plataformas baixas, vãos agachados e beiradas.
  Perseguidor demora em alguns obstáculos e contorna outros.
- Miguel sai PULANDO O PORTÃO 1. Não precisa abrir/destrancar o portão. No fim
  pode-se ver o perseguidor voltando para avisar o culto da fuga com a gravação.
- Checkpoints: recuperar a bolsa; antes de se aproximar do ritual. Restauram
  estado do alerta salvo. Não acrescentar checkpoint da perseguição como aprovado.
- Depois da saída, Miguel envia provas aos amigos. “Capítulo 1 concluído”.
  Plano distante da casa de Felipe → corte para quarto: Bola jogando videogame,
  Felipe na rede conversando. Notificação; inicialmente não acreditam no amigo
  brincalhão, depois chega o vídeo e ficam chocados/dispostos a investigar.
  Fecha ato 1. Bola e Felipe são muito amigos de Miguel. Ato/capítulo 2 fica para depois.

## Sistemas já escolhidos — preservar

- Até dois inimigos, só um atacando por vez; segundo não interrompe sequência/
  finalização. Se tenta cercar/bloquear saída enquanto espera ainda está aberto.
- Combate agressivo: botão ataque continua sequência, rápidos e pesados,
  segurar prepara pesado. Q tenta derrubada a qualquer momento, podendo resistir.
  Trocação também derruba. No chão continuar batendo ou finalizar. Não exigir
  uma esquiva perfeita para qualquer ataque funcionar.
- Esquiva curta sem direção, deslocamento com direção; contra-ataque continua
  proposta principal a testar. Avançados exigem precisão e recompensam sobretudo força.
- Fôlego só pune spam: um próximo comando pode ficar guardado, cliques extras
  acumulam fadiga. Recuperar parando de atacar, andando/defendendo sem precisar afastar.
- Contato real e animação coesa, bloqueio com reação/som, golpe errado deixa exposto,
  tomar golpe interrompe Miguel. Sem mãos teleportadas para fingir contato.
- Cultistas combinam defesa/esquiva e respostas, comuns com estilos legíveis.
  Dano por postura/corpo, sem barras de inimigos. Aviso discreto com movimento/som.
- Importantes: fintas apenas para enganar esquiva, esperar golpe verdadeiro,
  sem contra-ataque nessa sequência. Feridos ficam agressivos sem erros/brechas extras.
- Cultista pode provocar/r rir ao conseguir contra-ataque, sem criar brecha pela fala.
- Derrubado pode levantar e pedir ajuda; golpe antes de terminar interrompe o chamado
  comum. Ao identificar Miguel inicialmente tenta lidar sozinho. Continua rondando
  ao perder visão. Suspeita gradual antes do reconhecimento, sem virar instantaneamente.
- Finalizações com enquadramentos e contexto de paredes/armários/mesas.
  Stealth pelas costas mais demorado; se percebe aproximação pode virar/agarrar,
  com chance de escape. Reação ao ser encontrado num esconderijo ainda aberta.
- Inimigos trabalham, conversam e fazem rituais, examinam corpos, procuram embaixo
  de mesas/armários. Aparências e movimentos diferenciam perigo e personalidade.
- Arrastar corpo, sangue deixa rastro. Corpos/sangue/móveis quebrados persistem
  ao revisitar e intensificam vigilância/patrulhas, sem ativar perseguição final.
- Objetos encontrados podem ser arremessados para distrair, sem estoque de distrações
  nem atordoamento por acertar. Repetir faz procurar origem. Soltar carga para defender.
- Ferramentas temáticas dentro das salas, várias utilidades. Essenciais duram;
  desgaste pode ficar em armas improvisadas. Uso visível, demorado, interrompível
  e retomável; ruído de ferramenta não atrai inimigos. Sem trancas/barricadas novas.
- Todas as salas acessíveis como intenção. Rampas, janelas, livros, mesas são
  elementos a desenvolver. Não confundir com visita obrigatória a todas.
- Sombras ajudam furtividade, velas expõem. Celular/lanterna sem bateria, luz
  denuncia, só disponível após bolsa. Não acrescentar observação por porta entreaberta.
- Objetivos curtos, avisos de interação perto e olhando, indicador de vigilância
  só ao suspeitar crescendo até reconhecer. Ataque fora da tela indica direção/som.
- Ambiente escuro VISÍVEL, gravação antiga amarelada e azul-escuro; velas vermelhas
  no culto. Sem filtro que destrua leitura ou volte à baixa resolução rejeitada.
- Câmera sobre ombro explorando/lutando, colisão em espaços apertados; lock-on,
  troca/destravar. Fuga/frestas primeira pessoa. Não aplicar sobre ombro a todos os modos.
- Movimentação imediata, animação acompanha sem controle pesado. Mãos apoiam em
  paredes/mesas sem parar. Ferimentos de Miguel só visuais/sons, sem debuff motor.
- Empanados curam parcialmente ao longo de tempo, tantos quanto encontrar. Dano
  cancela sem consumir; valores existentes no código são provisórios.
- Faca de escape só para agarrão do perseguidor, fica presa/consumida. Sem ela, morte.
- Sons diferentes por impacto; respiração/ambiente depois da luta. Grilos/culto,
  sem adicionar música por padrão. Sustos com tremor e som desconfortável,
  variações menores após morrer, alterações sutis ao revisitar, sinais do ser antigo.
- Descobertas sobretudo por cenas. Cenas obrigatórias protegidas, mundo continua,
  olhar livre/movimento limitado, até o fim; não aplicar proteção à exploração geral.
- Tutorial aos poucos nas primeiras situações. Falas de Miguel serão fornecidas
  por Felipe; não inventar como texto aprovado.

## Estado técnico real e limites

Projeto `/Users/felipe/Projetos/jogo-gavyo`; Godot 4.5.1 Compatibility.
Branch observada `feat/prototipo-terror-terceira-pessoa`; conferir antes de trabalhar.
Muitos arquivos novos/modificados ainda não commitados. Preservar trabalho existente.
Cena `godot-3d/prototipo/main.tscn`, coordenador `game.gd`, `actor.gd`, `camera.gd`,
`school.gd`, `door.gd`, `hud.gd`. `school.gd` atual NÃO reproduz o mapa recebido.

O protótipo jogável ainda é revisão 2: uma esquiva/um contra-ataque derruba o
cultista; não implementa os combos/fôlego novos. Abertura ainda mostra celular
na mão, contrariando o novo roteiro; deve mudar quando implementar. Novos modelos,
mapa, vídeo, alerta condicional, cenas e câmera sobre ombro ainda não implementados.

`miguel_animado.glb` é o modelo aprovado: preservar original. `motions.tres` e
`tools/preparar_movimentos_prototipo.gd` são provisórios; corrida/esquiva/sentar
foram gerados/adaptados, não são boas capturas novas já aprovadas. Soco usa gancho
medido, sem SkeletonIK3D. Não mascarar defeito com blend, aceleração ou IK puxando mão.

MacBook Pro 2014 Intel Iris, macOS 11.7.11. Perfil leve 960×540, sem MSAA/sombras
dinâmicas, limite 60 FPS. Última amostra ativa registrada: ~39,24 FPS, p95 30,61ms;
não prometer 60 FPS pelo limite configurado nem usar pausa como benchmark.

Jogar: `bash "/Users/felipe/Projetos/jogo-gavyo/JOGAR-PROTOTIPO.command"`.
QA: `TESTAR-PROTOTIPO.command` opcional, captura extra custa desempenho.
Último relato de validação: 39 testes passaram em `scripts/testar-prototipo.sh`;
não tratar como resultado de testes executados no chat novo. Métricas normais em
`work/prototipo-desempenho*.json`. QA só vê viewport do jogo, não desktop.
Lançamentos gráficos por ferramentas falharam no sandbox; Felipe executa no Terminal.

Inspeção de espaço em disco: projeto ~2,5GB; `work` ~1,7GB, incluindo ferramentas
~981MB; `godot-3d` ~58MB, dos quais `web` ~40MB. São medidas de disco, NÃO custos
de FPS. Godot portátil em `work/ferramentas` é necessário ao launcher. Não apagar
como lixo junto com QA antigo. Arte/fotos/GLB/fontes e histórico não são descartáveis.

## Skills e estratégia recomendada para o próximo chat

Skills locais já disponíveis em `/Users/felipe/.agents/skills/`:

| Frente | Skills a ler quando executar essa frente |
|---|---|
| Planta, circulação, encontros, tensão | `level-design` |
| Seleção de modelos/texturas/licenças/coerência | `create-game-assets` |
| Adaptar/produzir modelos e revisar | `blender-modeling`, `blender-asset-qa` |
| Clips e transições no jogo | `godot-animation` |
| Ajustes de movimento e ações em par | `blender-animation` |
| Ombro, lock-on, colisão e modos | `camera-systems` |
| Iluminação/filtro | `godot-3d-essentials`, `godot-shaders` |
| Colisões, contato e resposta | `godot-physics`, `physics-tuning`, `game-feel` |
| Percepção, alerta e comportamento | `game-ai` |
| Medir e otimizar | `performance-optimization` |

Ler cada SKILL.md ao usar. Algumas mencionam Godot 4.7: conferir APIs contra
4.5.1 instalado, sem atualizar engine por conta própria. Não é preciso instalar
mais pacotes só para começar. `find-skills` consultou catálogo; busca CLI sem
resultado útil no tempo disponível. Não houve auditoria suficiente para recomendar
pacotes externos novos, nem instalação. Skills orientam trabalho, não fornecem
automaticamente modelos/animações finalizados.

**Plano proposto, não implementação já autorizada:**

1. Conferir referências e dependências; separar executável, fontes e material
   de trabalho. Para limpeza, listar candidatos/referências e prever restauração;
   não apagar originais nem chamar ferramenta necessária de lixo. Medir custo real.
2. Fazer blockout fiel às relações do mapa e validar escala, corredores, escadas,
   portas e câmera sobre ombro em trecho representativo. Projeto atual é outra planta.
3. Montar lista de animações por ação e pesquisar fontes prontas antes de animar
   tudo do zero. Começar locomoção, paradas/giros, agachar, golpes, defesas, reação,
   esquivas, quedas/levantar. Validar no Miguel original em cópia, sem deformar corpo.
4. Comparar clipes por postura, pés apoiados, direção, deslocamento, duração,
   recuperação e transições. Um conjunto coerente vale mais que dezenas desconexas.
   Integrar com estados/blends de AnimationTree compatíveis com Godot 4.5.1.
5. Golpe/reação, derrubada, chão, stealth, arrastar e finalização precisam contatos
   e, em várias ações, animações em par. Clipes soltos não garantem encaixe. Adaptar
   em Blender quando viável; informar lacunas em vez de substituir por gesto incompatível.
6. Selecionar uma base humanoide de cultista, com rig compatível, e variações de
   roupa/rosto/textura; conferir fonte/licença e desempenho. Não escolher pack pago
   nem baixar modelos aleatórios como arte final sem avaliação. Perseguidor precisa
   silhueta forte e rosto descoberto bizarro; comuns uncanny sem deformar proporções.
7. Acabar um trecho representativo: cenário escolar, um cultista com boa movimentação,
   combate coerente, câmera e iluminação. Felipe avalia jogando antes de replicar.
8. Expandir a escola, sistemas de alerta, vídeo, rota discreta/perseguição e cenas.
   Validar cada etapa também em execução normal, sem captura extra de QA.

Filtros: começar por iluminação e paleta, então um pós-processamento discreto
para gravação antiga. Comparar ligado/desligado e medir no Mac. Não esconder
modelos/animações ruins com ruído, blur, escuridão ou tremor permanentes.

## Pesquisa inicial de animações prontas

Mixamo é candidato para locomoção e ações individuais, não promessa de cobrir
finalizações específicas. FAQ oficial da Adobe confirma gratuidade com Adobe ID
e uso de personagens/animações em jogos pessoais/comerciais sem royalties:
https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html

Verificar disponibilidade dos clipes concretos e licença ao selecionar; não
presumir download automatizado ou acesso à conta do usuário. Já existe material
em `arte/mixamo` a inventariar antes de buscar duplicatas.

Transições e estados em Godot 4.5:
https://docs.godotengine.org/en/4.5/tutorials/animation/animation_tree.html

## Pendências reais sem repetir decisões

- Posições precisas de encontros, esconderijos, ferramentas, atalhos e cenas no mapa;
  lista de usos/ferramentas, escala e duração da exploração. Mapa já fornecido.
- Sequências concretas de golpes e animações; segundo inimigo enquanto espera;
  reação ao descobrir Miguel escondido. Valores ajustar jogando.
- Aparência final de cenários/cultistas/perseguidor; lado/distância do ombro;
  tratamento visual exato e orçamento de desempenho.
- Interface discreta e operação/enquadramento do vídeo (gravação manual já escolhida).
- Falas de Felipe para Miguel e montagem fina das cenas. Não planejar capítulo 2 agora.

O próximo agente deve dizer que leu, resumir o ponto de partida sem refazer a
entrevista e seguir a etapa que Felipe solicitar, preservando o resto dos acordos.
