# Capítulo 1 integrado

02/11/2026. Iniciado por pedido de Felipe para integrar o mapa e a ambientação
antes de avaliar. A revisão 2 e a bancada de validação continuam preservadas.

Na raiz do projeto:

```bash
bash JOGAR-PROTOTIPO.command
```

Enter começa. O lançador principal e `project.godot` agora abrem
`res://capitulo1/main.tscn`. Não abre a sala isolada de testes.

## O que está integrado

- **02/11 (parte 3): o mapa agora vem de texto** — `capitulo1/mapa/terreo.txt` e
  `superior.txt` (1 caractere = 1 m), montado com um kit modular cinza num GridMap.
  É um bloqueio cinza aguardando aprovação de Felipe; ver `capitulo1/mapa/LEIA-ME.md`.
  A escola anterior por coordenadas está em `capitulo1/referencia/`.
- Planta baseada em `docs/referencias/mapa-escola-felipe.png`: blocos norte/sul,
  quadra, refeitório/pátio aberto, laboratórios, biblioteca, administração,
  banheiros, sala de esportes, escada e andar superior. Portas físicas nas salas.
  Medidas adaptadas para circulação; não é levantamento arquitetônico da escola real.
- Bolsa no terceiro de Informática, acima do segundo; ritual separado no pátio
  de química. A visão do ritual pelo corredor superior é bloqueada.
- Miguel acorda sem celular. Recuperar a bolsa libera celular/lanterna e salva
  checkpoint. Outro checkpoint antes do ritual. Alerta salvo/restaurado.
- Vídeo manual por enquadramento: V abre a visão da lente e grava mantendo o ritual
  enquadrado. A gravação é um evento do jogo, não exportação de um arquivo de vídeo.
- Rota discreta sem perseguidor; perseguição apenas após reconhecimento e chamado
  concluído. Suspeita, sangue e corpos não ativam essa condição.
- Apresentação do perseguidor: pés, Miguel gravando, faca, Miguel, rosto, paralisação;
  fuga em primeira pessoa. Saída pulando o portão 1, sem destrancá-lo.
- Encerramento do ato 1 com envio da prova e montagem da casa/quarto: Bola no
  videogame e Felipe na rede. Sem missão ou gameplay do capítulo 2.
- Ombro na exploração/combate, colisão de câmera, lock-on e troca de alvo. Frestas
  e fuga em primeira pessoa; filmagem usa câmera de lente para Miguel não tapar a imagem.
- Corrida capturada existente, golpes medidos por membro/instante de contato,
  sequência de ataques, pesado ao segurar, um comando guardado e fadiga só por extras.
  Dano interrompe ação. Defesa verifica proximidade dos antebraços ao golpe.
- Q tenta uma pegada e derrubada com chaves FK próprias, sem IK de braço ou troca
  por um chute. Reação do alvo e queda coordenadas. Contextos de parede, metal/armário
  e mesa para alvo vulnerável; enquadramento próprio e contato inicial obrigatório.
- Ação no chão usa o clipe ajoelhado existente; Q tenta finalização de vulnerável.
  Até dois cultistas participam, um ataca por vez; outro não interrompe a sequência.
- Cultistas com malha humanoide e roupas, três variações de cor/comportamento,
  cabeça própria/capuz e perseguidor maior, rosto descoberto. Não usa o rosto de
  Miguel como inimigo. Originais GLB preservados.
- Suspeita gradual, patrulhas, memória da última visão, exame de corpos, busca,
  chamados interrompíveis, arrombamento de portas e busca em esconderijos próximos
  da última posição conhecida. Sem conhecimento contínuo da posição escondida.
- Corpos arrastáveis e sangue persistente; objetos arremessáveis como distração,
  repetição leva a investigar a origem. Esquiva solta a carga.
- Ferramentas temáticas com uso demorado, interrompível e retomável; sem ruído
  atraindo inimigos. Valores/usos iniciais para testar, sem criar trancas novas.
- Mesas/bancos, plataforma baixa, beirada e vão agachado; parkour contextual na
  exploração e automático na fuga. Posturas de apoio de mão por FK/proximidade.
- Luz fria/amarelada, velas vermelhas, superfícies molhadas e filtro discreto de
  gravação antiga. Sem baixa resolução extrema, ruído forte ou tremor permanente.
- Grilos/culto, impactos distintos, respiração depois da luta e susto ambiental.
  Sem música padrão; nenhuma fala de Miguel foi inventada.

## Controles

| Comando | Ação |
|---|---|
| WASD / mouse | Mover / olhar |
| Shift / Ctrl | Correr / agachar |
| Espaço | Porta, item, ferramenta, esconderijo, parkour |
| Clique esquerdo / segurar | Atacar/continuar / pesado |
| Clique direito | Esquiva curta; com direção, deslocamento |
| Q | Tentar derrubada; no chão, finalização de vulnerável |
| Meio / rodinha | Travar/destravar / trocar alvo |
| E | Comer empanado |
| V / L | Vídeo / lanterna após recuperar a bolsa |
| G / T | Arrastar/soltar corpo / arremessar objeto carregado |
| F / F3 | Fresta / comparar filtro ligado e desligado |
| Esc / R na pausa ou morte | Pausar / retomar checkpoint |

## Validação e limites

```bash
bash scripts/testar-capitulo1.sh
bash scripts/testar-prototipo.sh
```

A suíte nova verifica relações do mapa, portas abertas desobstruídas, escada
com a cápsula real, bolsa/checkpoints/alerta, vídeo e duas rotas, portão, golpes
por contato, ação no chão, pegada e contextos de finalização. A suíte antiga
protege a revisão 2 preservada; seus testes não aprovam o roteiro novo.

Verificação desta entrega: **42 testes do capítulo + 39 da revisão preservada +
15 de câmera passaram**. Câmera também executada com OpenGL real no Mac. Há aviso
de objetos remanescentes ao encerrar algumas execuções headless; não foi registrado
erro de script na rodada final.

Amostras finais de exploração ativa (3 segundos por trecho, sem captura/QA,
Intel Iris, limite configurado de 60):

| Trecho | FPS médio | Quadro p95 |
|---|---:|---:|
| Pátio | 59,93 | 16,67 ms |
| Corredor | 41,48 | 24,04 ms |
| Química | 58,08 | 19,05 ms |
| Superior | 60,00 | 16,67 ms |

Esses números descrevem trechos curtos, não certificam o capítulo inteiro nem
permitem comparar ganho percentual com a planta anterior.

Revisões visuais locais em `work/capitulo1-*.png`, `work/cena-*.png`.
Desempenho sem captura extra: `work/capitulo1-desempenho.json`, obtido com
`res://tools/percorrer_capitulo.gd`. Uma amostra curta não promete FPS constante
na partida inteira. Godot 4.5.1 Compatibility, perfil leve mantido.

Esta é a versão integrada para avaliação, com arte e movimentos ainda sujeitos
a acabamento. Pegada, recebimento do alvo, parkour, apoio, ferramenta e cenas
incluem animação autoral/procedural; não são novas capturas de movimento finalizadas.
O encerramento usa o Felipe existente e uma representação provisória de Bola,
sem apresentar esse modelo como identidade aprovada. A casa é um cenário de cena,
não reprodução comprovada da casa real. As falas de Miguel continuam pendentes.

Fontes/arquivos originais e ferramentas preservados. Nenhuma limpeza destrutiva,
publicação, compra ou login externo. Backup inicial em
`work/revisoes/capitulo1-20261101-231445/`.

QA opcional: `TESTAR-PROTOTIPO.command`. Captura apenas viewport próprio,
em `work/capitulo1-qa`; comandos limitados em `command.json` e estado em
`state.json`. Não acessa desktop nem executa comandos de sistema.
