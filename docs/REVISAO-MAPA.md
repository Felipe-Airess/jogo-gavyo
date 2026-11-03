# Revisão do mapa cinza — Felipe

02/11/2026 · Godot 4.5.1 Compatibility · branch `feat/prototipo-terror-terceira-pessoa`.

**Aguardando aprovação. Responda na seção “Resposta de Felipe” deste arquivo.**
A grade e a história atual foram preservadas. Não foi acrescentada decoração.
Esta revisão desenha a rota solicitada; não implementa seus novos objetivos.

## Plantas renderizadas do jogo

Os PNGs vêm da cena `capitulo1/main.tscn`, renderizada pelo Godot. Norte fica para cima.
Tetos, personagens e o outro andar ficam ocultos apenas na instância da captura;
as portas são abertas nela. Nomes, números e linhas são sobreposições de revisão.
Abra os arquivos originais para ler as salas pequenas do térreo em resolução completa.

### Térreo — salas e áreas

![Térreo renderizado, com nomes e números das salas](revisao-mapa/terreo.png)

### Superior — salas e corredor

![Superior renderizado, com nomes e números das salas](revisao-mapa/superior.png)

## Rota nova para aprovação

**A: 3º Informática → B: escada → C: refeitório → D: salinha/cochilo → E: cozinha → F: sala com celular/bolsa → G: gravação do ritual → H: fuga.**

![Rota no superior: A até B](revisao-mapa/superior-rota.png)

![Rota no térreo: B até H, com F pendente](revisao-mapa/terreo-rota.png)

| Marca | Local desenhado | Situação |
| --- | --- | --- |
| A | Sala 28, 3 Informática, superior | Início solicitado. Hoje Miguel começa na sala 08. |
| B | Escada existente, junto ao pátio de química | Os dois desenhos mostram os extremos da mesma escada. |
| C | Refeitório/auditório, parte leste do pátio | Ponto de passagem proposto. |
| D | Sala 08, Materiais de esportes | Referência atual do cochilo; confirmar se esta é a salinha desejada. |
| E | Sala 18, Cozinha | Ambiente existe; móveis necessários ainda faltam. |
| F | **Sala a definir por Felipe** | Hoje bolsa/celular ficam na sala 28, antes da escada. O pedido não identifica a nova sala. |
| G | Ponto atual de gravação, junto ao acesso do pátio de química | Mantido como referência. |
| H | Passagem e portão 1, ao sul | Fuga atual usa transposição do portão; não é uma porta comum. |

Linhas contínuas seguem caminhos calculados na geometria existente, com portas abertas.
Azul: A–B e B–C; laranja: C–D; roxo: D–E; verde: G–H.
O tracejado laranja E–F–G é **somente uma ligação de roteiro**, não um trajeto físico:
F está fora da planta para não atribuir uma sala sem sua decisão.
A direção pode ser lida pela ordem A–H e pelas pontas das linhas.

O jogo ainda começa em Materiais de esportes, exige buscar a bolsa em 3 Informática,
depois gravar o ritual e fugir. A nova ordem não substituiu esse fluxo nesta entrega.

## Salas numeradas

Números iguais aos das imagens. “Vazia” significa sem móveis ou itens específicos;
piso, paredes e porta continuam presentes. As portas comuns começam fechadas,
abrem com Espaço e **não têm tranca implementada**. Bloco baixo `%` é bloqueio genérico,
não bancada ou mesa aprovada. Não foram acrescentados móveis para esta revisão.

1. **3 Contabilidade — térreo:** vazia; sem tranca.
2. **2 Informática — térreo:** vazia; sem tranca.
3. **Laboratório de química — térreo:** um bloco baixo e alicate; sem tranca.
4. **Informática 1 — térreo:** vazia; sem tranca.
5. **Laboratório de matemática — térreo:** um bloco baixo e régua; sem tranca.
6. **Biblioteca — térreo:** vazia, sem estantes; sem tranca.
7. **2 Contabilidade · oeste — térreo:** armário de esconderijo; sem tranca.
8. **Materiais de esportes — térreo:** início atual e armário; sem superfície para deitar; sem tranca.
9. **Laboratório Informática 1 — térreo:** vazio; sem tranca.
10. **Laboratório de contabilidade — térreo:** vazio; sem tranca.
11. **Laboratório Informática 2 — térreo:** vazio; sem tranca.
12. **Sala de música — térreo:** vazia; sem tranca.
13. **2 Enfermagem — térreo:** vazia; sem tranca.
14. **Estoque da cozinha — térreo:** vazio; sem tranca.
15. **Laboratório de hardware — térreo:** dois blocos baixos, empanado e chave de fenda; sem tranca.
16. **Laboratório de enfermagem — térreo:** vazio; sem tranca.
17. **Coordenação — térreo:** vazia; sem tranca.
18. **Cozinha — térreo:** um bloco baixo e faca; sem bancada/mesa identificadas; sem tranca.
19. **Banheiro dos professores — térreo:** vazio, sem louças; sem tranca.
20. **Planejamento dos professores — térreo:** vazio; sem tranca.
21. **Banheiro masculino — térreo:** vazio, sem louças; sem tranca.
22. **Sala dos professores — térreo:** vazia, planta em L ao redor das salas 23/24; sem tranca.
23. **2 Contabilidade · sul — térreo:** vazia; sem tranca.
24. **1 Contabilidade — térreo:** vazia; sem tranca.
25. **Secretaria — térreo:** vazia; sem tranca.
26. **Banheiro feminino — térreo:** vazio, sem louças; sem tranca.
27. **3 Enfermagem — superior:** vazia; sem tranca.
28. **3 Informática — superior:** mesa da bolsa/celular atuais, um bloco baixo e empanado; sem tranca.

Áreas não numeradas: pátio de química com ritual; quadra coberta; corredor aberto;
estacionamento de bicicletas; rampa; pátio a céu aberto; refeitório/auditório com
blocos de mesas; passagem para o portão 1; área de saída; corredor superior.
São nomes de áreas abertas, não dez salas adicionais. O inventário extraído está em
[`ambientes.json`](revisao-mapa/ambientes.json).

## Comparação com o desenho de Felipe

Referência: [mapa-escola-felipe.png](referencias/mapa-escola-felipe.png).

| Parte | O que bate | O que difere ou precisa confirmar |
| --- | --- | --- |
| Norte/oeste | 3 Contabilidade e 2 Informática ao lado do pátio de química; laboratório de química a leste. | Medidas e proporções não foram validadas: o desenho não fornece escala. |
| Faixa da quadra | Quadra a oeste, salas de Contabilidade/Enfermagem, corredor aberto e bicicletas próximos. | Geometria foi convertida em grade; conferir larguras e comprimentos nas imagens. |
| Faixa norte do pátio aberto | Informática 1, matemática e biblioteca na sequência. | Interior continua sem mobiliário específico. |
| Laboratórios centrais | Informática 1/2 e hardware entre bicicletas e pátio aberto. | Conferir dimensões; nomes do jogo distinguem Informática 1 da sala 04. |
| Leste | Refeitório/auditório, sala de esportes, estoque e cozinha presentes. | **Música e laboratório de Contabilidade estão invertidos:** desenho traz música primeiro; jogo traz sala 10 antes da 12. |
| Sul | Coordenação, Contabilidade 2/1, professores, secretaria e passagem ao portão 1 presentes. | Banheiros masculino/feminino ficam um acima do outro no jogo; desenho indica feminino à direita. |
| Escada/superior | Dois ambientes de terceiro ano acima do bloco de Contabilidade/Informática. | Desenho coloca acesso abaixo da faixa noroeste; jogo coloca o lance dentro do conjunto do pátio de química. Confirmar acesso e ordem das salas 27/28. |
| Saídas | Portão 1 e passagem longitudinal presentes. | **Portão 2 para carros, à direita no desenho, não está implementado.** |
| Cochilo e bolsa | Sala de esportes é o começo atual, como anotado no desenho. | Pedido novo começa em 3 Informática; salinha e nova sala da bolsa precisam ser confirmadas. |

## Conferência dos espaços necessários

### Cozinha

![Cozinha existente: bloco baixo com faca, sem bancada nem mesa](revisao-mapa/cozinha.png)

**Existe:** sala 18 com paredes, porta e um bloco baixo com a faca.
**Falta:** bancada de cozinha e mesa reconhecíveis como volumes separados.
O bloco único não demonstra os dois móveis pedidos.

### Salinha do cochilo

![Sala de esportes existente: armário, sem apoio para deitar](revisao-mapa/salinha.png)

**Existe:** sala 08, usada pelo começo atual, com porta e armário.
**Falta:** estante e bancada/superfície para deitar. Confirmar se o cochilo continua nesta sala.

### Quinas e paredes para esconder

**Existem:** paredes opacas, quinas, blocos baixos e armários no mapa atual.
A captura mede oclusão pelo mesmo `visible_between()` do jogo, entre pontos a 1,5 m
de altura. Quatro pares de células tiveram visão bloqueada por quinas:
`(19,10)–(22,7)`, `(28,16)–(31,13)`, `(45,19)–(48,16)`, `(45,23)–(48,20)`.
Isso prova cobertura nesses pontos, não invisibilidade em toda a rota.
Os testes existentes também passaram para cobertura e acesso às duas rotas do pátio.

**Pendências de revisão:** decidir F e D, depois conferir a cobertura do trajeto definitivo;
confirmar os acessos da escada, ordem das salas do leste, banheiros e segundo portão.
Nenhuma dessas pendências foi resolvida alterando a grade nesta entrega.

## Como passear no mapa

1. Abra `JOGAR-PROTOTIPO.command`, ou rode o comando abaixo na raiz do projeto.
2. Pressione **F9**: aparece `PASSEIO DEBUG`, sem cultistas, participantes do ritual ou perseguidor.
3. **WASD** move, mouse olha, **Shift** corre, **Ctrl** agacha. **Espaço** abre/fecha portas próximas.
4. **F3** alterna o filtro para facilitar a inspeção. **Esc** pausa.
5. **F9** sai e retoma o checkpoint. A entrada também retoma o checkpoint; o passeio não salva progresso.

```bash
GODOT=work/ferramentas/godot/Godot.app/Contents/MacOS/Godot
"$GODOT" --path godot-3d res://capitulo1/main.tscn
```

F9 funciona só em debug. Miguel conserva colisão com paredes, portas e escada;
não é voo nem passagem através de paredes. Coleta de itens, esconderijo, ritual,
perseguição e objetivos ficam suspensos. A inspeção não executa a fuga pelo portão.
Não houve ajuste de ossos, animações, iluminação do jogo ou decoração.

## Resposta de Felipe

Preencha aqui; a aprovação ainda não foi dada.

- [ ] Aprovo o mapa atual, com as ressalvas escritas abaixo.
- [ ] Quero corrigir antes de aprovar.
- Sala do celular/bolsa (F): número/nome **________**; ou nova sala em **________**.
- Salinha do cochilo (D): manter sala 08? **________**; se não, qual? **________**.
- Escada: manter acesso atual ou mover para onde? **________**.
- Ordem das salas 10/12, banheiros, salas 27/28 e portão 2: **________**.
- Correções de paredes, portas, nomes, tamanhos e rota: **________**.
- Data e observações: **________**.

## Reprodução das imagens

```bash
GODOT=work/ferramentas/godot/Godot.app/Contents/MacOS/Godot
"$GODOT" --path godot-3d --script res://tools/revisar_mapa.gd
```

O script modifica somente a instância temporária para enxergar cada andar.
Não grava os arquivos da grade. As seis imagens foram abertas e conferidas:
salas nomeadas, linhas visíveis, detalhe da cozinha com um único bloco e salinha sem superfície para deitar.

## Testes — saídas completas

Executados em Godot `4.5.1.stable.official.f62fdbde1`. A suíte inclui nove testes novos
do F9: entrada, inimigos/colisões, movimento real, proteção contra agarrão, perseguidor,
pressão, coleta, saída e retomada do checkpoint. Nenhum teste altera pose de osso.
As saídas abaixo são integrais, inclusive avisos existentes de animação e diagnósticos de percurso.

<details>
<summary>bash scripts/testar-capitulo1.sh</summary>

```text
Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS F9 abre passeio direto do menu em debug
PASS passeio oculta inimigos/ritual e remove colisões e áreas de acerto
PASS Miguel anda com input e física normais no passeio
PASS inimigo próximo não detecta nem agarra no passeio
PASS passeio não gera perseguidor
PASS pressão fica desligada no passeio
PASS passeio não coleta bolsa nem inicia roteiro
PASS F9 sai e restaura os inimigos do checkpoint
PASS saída retoma o checkpoint sem salvar o passeio
CAPITULO1_PASSEIO: 9 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS sem caça não há tensão ou pressão residual
PASS alerta salvo sozinho não liga pressão sem caçador
PASS busca longe mantém tensão baixa, mesmo sem visão
PASS tensão usa recurso marcado provisório, carregado por load
PASS proximidade aumenta pressão e reforço dos passos pesados
PASS reforço chega ao emissor 3D dos passos novos
PASS respiração acelera e cresce quando caçador chega perto
PASS tremor óptico é perceptível e limitado a 4,5 mm
PASS pressão não move o corpo de Miguel
PRESSAO longe=0.200 perto=0.962 reforco_passo=4.58 dB tremor=0.00421 m
PASS fim da última caça apaga tensão após retorno suave
PASS respiração volta ao perfil normal
PASS câmera volta ao repouso
PASS vídeo sem alerta não cria perseguidor
PASS alerta sem vídeo mantém o gatilho existente da apresentação
PASS perseguidor nasce só após alerta, no posto 8, mantendo sete comuns
PASS gatilho não cria um segundo perseguidor
PASS perseguidor sozinho sustenta a pressão da fuga
PASS pausa silencia pressão e respiração
PASS checkpoint limpa pressão e perseguidor
CAPITULO1_PRESSAO: 19 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
AUDIO_RECURSOS carregados=376/376
PASS todos os 376 áudios do pacote carregam por load e têm duração
PASS três sons sem equivalente continuam carregando como recursos
PASS cada som referenciado pelo jogo possui recurso e medição
AUDIO_NIVEL pico_decodificado_com_ganho=-9.00 dBFS
PASS decodificação independente confirma pico dos sons usados
PASS ganho medido limita pico individual a -9 dBFS antes dos buses
PASS Master tem um limitador de segurança com teto -1 dBFS
PASS mapa real distingue azulejo e cimento
PASS lance real da escada seleciona pedra/concreto
PASS passos variam sem repetir o mesmo arquivo imediatamente
PASS troca de piso muda o banco de passos
PASS escada recebe ressonância curta própria
PASS passos do cultista são 3D, seguem o corpo e chegam a 10 m
PASS Miguel tem alcance de 7 m; comum tem timbre mais pesado
PASS perseguidor tem passos próprios mais graves e espaciais
PASS grito real do cultista usa voz fornecida e alcance de 10 m
PASS porta toca abertura e fechamento ao mudar estado
PASS armário toca rangido e fecho
PASS bolsa toca manuseio somente no contato confirmado
PASS portão toca contato metálico durante escalada
PASS agarrão toca impacto e roupa no corpo correto
PASS agarrão muda perfil da respiração provisória preservada
PASS cada acerto e conclusão do minigame têm som
PASS seta errada toca erro e falha
PASS prazo esgotado também toca falha
PASS respiração normal fica ativa em exploração
PASS corrida muda ritmo e volume da respiração
PASS deslocamento físico dispara passos pelo piso no process do jogo
PASS parado não repete passos
AUDIO_MIX pico_master=-19.94 dBFS
PASS mistura simultânea permanece abaixo de -1 dBFS
PASS pausa silencia respiração
CAPITULO1_AUDIO: 30 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS visão real detecta Miguel em área aberta
PASS ser visto interrompe a caminhada e inicia aviso
PASS cultista permanece parado durante 0,4 s
PASS após pausa, grita e começa perseguição
PASS grito espalha o alerta
PASS perseguição usa 3,0 m/s
PASS perseguição toca corrida original
CACA_CORRIDA deslocamento=1.0000 m em 0.333 s velocidade=3.000 clipe=novo/Sprint
PASS deslocamento físico confirma 3,0 m/s
PASS visão contínua não repete grito a cada quadro
PASS parede bloqueia visão real
PASS perdeu visão: vai ao último local visto, sem rastrear posição oculta
PASS busca de 60 s começa ao chegar ao último ponto
PASS perder visão não encerra busca em poucos segundos
PASS caça anda entre pontos e olha em volta com o corpo
PASS pontos de busca pertencem à região lembrada
PASS busca continua antes dos 60 s
PASS após 60 s sem visão, volta ao posto
PASS retorno lento a 0,8 m/s para o posto original
PASS chegada ao posto retoma patrulha
PASS somente quem viu entrar conhece o armário
PASS esconderijo oculta Miguel mesmo de quem lembra onde entrou
PASS testemunha abre a folha do armário
PASS viu entrar: tira Miguel do armário e abre minigame
PASS extração mantém separação entre corpos
PASS não viu a entrada: não conhece o armário
PASS sem testemunha: ronda por perto sem abrir nem agarrar
PASS perseguidor ronda perto, mas não abre armário cuja entrada não viu
CACA_VANTAGEM miguel=1.45 m/s variacao_distancia=-1.550 m
PASS Miguel andando perde distância
CACA_VANTAGEM miguel=3.80 m/s variacao_distancia=0.800 m
PASS Miguel correndo ganha distância
PASS vários caçadores escolhem lados distintos de Miguel
PASS cerco mantém cápsulas separadas, sem empilhar
PASS cerco abandona desvio bloqueado por parede e mantém aproximação
CACA_CERCO menor_distancia=0.7624 m destinos=3
CAPITULO1_CACA: 32 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS agarrão oferece sequência direcional
PASS encostar no cultista comum abre o minigame
PASS primeiro agarrão: 3 setas, 3,0 s
PASS sequência contém somente quatro direções válidas
PASS corpos separados em aproximadamente 0,6 m
PASS os dois ficam de frente
PASS agarrão mantém corpos sem atravessar
PASS segurar tecla, soltá-la ou apertar Q não resolve a sequência
PASS pausa suspende prazo do minigame
PASS sequência correta solta Miguel e atordoa cultista
PASS acerto faz recuo curto de 30 cm pela física
PASS acerto concede 1,5 s de vantagem
PASS atordoamento dura pelo menos 1,99 s
PASS atordoamento termina após 2 s
PASS vantagem impede agarrão imediato de outro cultista
PASS segundo agarrão: 4 setas, 2,7 s
PASS uma seta errada causa tela preta por 1,5 s
PASS input não pula os 1,5 s de tela preta
PASS erro retorna automaticamente ao checkpoint
PASS checkpoint preserva crescimento por agarrão nesta partida
PASS tempo esgotado também falha sem input
PASS tempo esgotado volta ao checkpoint
PASS crescimento: +1 seta/-0,3 s, máximo 7 e mínimo 1,5 s
PASS sorteio produz sequências diferentes
PASS gancho do futuro item evita agarrão comum e consome uso
PASS faca antiga não substitui o item futuro nem pula minigame
PASS perseguidor agarra; item não o finaliza nem é consumido
PASS perseguidor respeita raio maior sem atravessar Miguel
PASS acerto também atordoa perseguidor por 2 s
PASS perseguidor retoma caça vivo após atordoamento
APROX comum distancia=0.58000242710114 active=true
PASS cultista aproxima pela física até encostar, sem parar a 1,05 m
APROX perseguidor pos=(200.0, 0.000836, 200.66) estado=grab_hold distancia=0.66000419855118 active=true
PASS perseguidor aproxima pela física até encostar, sem parar a 0,83 m
PASS celular mostra quatro setas com alvos de pelo menos 64 px
PASS entrada no minigame solta analógico e mostra sequência
PASS toque acerta a sequência; setas somem ao soltar
PASS seta errada no celular também falha
PASS falha por toque também restaura checkpoint
CAPITULO1_ESCAPE: 37 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
TRANSICAO velocidade=1.45 agachado=false salto_medido=0.0755 m
PASS troca de locomoção usa crossfade real da máquina
TRANSICAO velocidade=3.80 agachado=false salto_medido=0.1627 m
PASS troca de locomoção usa crossfade real da máquina
AVISO amplitude da pose original/transição supera 8 cm; não limitar ossos
TRANSICAO velocidade=0.00 agachado=false salto_medido=0.0871 m
PASS troca de locomoção usa crossfade real da máquina
AVISO amplitude da pose original/transição supera 8 cm; não limitar ossos
TRANSICAO velocidade=1.05 agachado=true salto_medido=0.0944 m
PASS troca de locomoção usa crossfade real da máquina
AVISO amplitude da pose original/transição supera 8 cm; não limitar ossos
TRANSICAO velocidade=0.00 agachado=true salto_medido=0.0622 m
PASS troca de locomoção usa crossfade real da máquina
TRANSICAO velocidade=1.45 agachado=false salto_medido=0.0777 m
PASS troca de locomoção usa crossfade real da máquina
PASS arestas: 0,15 s no plano e 0,20–0,25 s em ações/escada
ORIGINAL Miguel clipe=novo/Walk certo=180/180 avanca=180/180 erro_pos=0.0000001 erro_rot=0.0000001 apoio=168 deriva=0.1248 m
PASS Miguel: clipe correto avança sem congelar
PASS Miguel: todos os ossos coincidem com as trilhas originais
AVISO Miguel: deriva/contato original registrado; nenhuma correção de pose
ORIGINAL Miguel clipe=novo/Sprint certo=180/180 avanca=180/180 erro_pos=0.0000001 erro_rot=0.0000001 apoio=14 deriva=0.1077 m
PASS Miguel: clipe correto avança sem congelar
PASS Miguel: todos os ossos coincidem com as trilhas originais
AVISO Miguel: deriva/contato original registrado; nenhuma correção de pose
ORIGINAL Miguel clipe=novo/Crouch_Fwd certo=180/180 avanca=180/180 erro_pos=0.0000001 erro_rot=0.0000001 apoio=134 deriva=0.1807 m
PASS Miguel: clipe correto avança sem congelar
PASS Miguel: todos os ossos coincidem com as trilhas originais
AVISO Miguel: deriva/contato original registrado; nenhuma correção de pose
ORIGINAL cultista clipe=novo/Walk certo=180/180 avanca=180/180 erro_pos=0.0000001 erro_rot=0.0000001 apoio=173 deriva=0.1248 m
PASS cultista: clipe correto avança sem congelar
PASS cultista: todos os ossos coincidem com as trilhas originais
AVISO cultista: deriva/contato original registrado; nenhuma correção de pose
ORIGINAL cultista clipe=novo/Sprint certo=180/180 avanca=180/180 erro_pos=0.0000001 erro_rot=0.0000001 apoio=14 deriva=0.1077 m
PASS cultista: clipe correto avança sem congelar
PASS cultista: todos os ossos coincidem com as trilhas originais
AVISO cultista: deriva/contato original registrado; nenhuma correção de pose
ORIGINAL cultista clipe=novo/Crouch_Fwd certo=180/180 avanca=180/180 erro_pos=0.0000001 erro_rot=0.0000001 apoio=134 deriva=0.1807 m
PASS cultista: clipe correto avança sem congelar
PASS cultista: todos os ossos coincidem com as trilhas originais
AVISO cultista: deriva/contato original registrado; nenhuma correção de pose
ESCADA_ORIGINAL sobe=true corre=false clipe=novo/Ascending_Stairs correto=129/129 avanca=129/129 erro=(0.0, 0.0)
PASS escada: captura correta, em movimento
PASS escada: pose original fora do crossfade
ESCADA_ORIGINAL sobe=true corre=true clipe=novo/Running_Up_Stairs correto=129/129 avanca=129/129 erro=(0.0, 0.0)
PASS escada: captura correta, em movimento
PASS escada: pose original fora do crossfade
ESCADA_ORIGINAL sobe=false corre=false clipe=novo/Descending_Stairs correto=129/129 avanca=129/129 erro=(0.000001, 0.0)
PASS escada: captura correta, em movimento
PASS escada: pose original fora do crossfade
ESCADA_ORIGINAL sobe=false corre=true clipe=novo/Descending_Stairs correto=129/129 avanca=129/129 erro=(0.000001, 0.0)
PASS escada: captura correta, em movimento
PASS escada: pose original fora do crossfade
PASS câmera ignora corpo de cultista na camada 2
PASS câmera colide com cenário da camada 1
PASS cultista junto da lente fica oculto
PASS cultista volta a aparecer ao se afastar da lente
PASS oclusão não revela Miguel na câmera em primeira pessoa
PASS esquiva continua desativada
CAPITULO1_MOVIMENTO: 33 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASS APIs executadas no Godot 4.5.1
PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
AMOSTRA Miguel andando: tempo=180/180 clipe=novo/Walk 180/180 pose=[180, 180, 180, 180] velocidade=1.450 m/s distancia=4.350 m
PASS Miguel andando: tempo avança em todos os quadros por 3 s
PASS Miguel andando: cadência casa velocidade real com passada medida
PASS Miguel andando: clipe ativo novo/Walk
PASS Miguel andando: pose do clipe varia sem congelar
PASS Miguel andando: velocidade real 1.45 m/s
AMOSTRA Miguel correndo: tempo=180/180 clipe=novo/Sprint 180/180 pose=[180, 180, 180, 180] velocidade=3.800 m/s distancia=11.400 m
PASS Miguel correndo: tempo avança em todos os quadros por 3 s
PASS Miguel correndo: cadência casa velocidade real com passada medida
PASS Miguel correndo: clipe ativo novo/Sprint
PASS Miguel correndo: pose do clipe varia sem congelar
PASS Miguel correndo: velocidade real 3.80 m/s
AMOSTRA Miguel agachado: tempo=180/180 clipe=novo/Crouch_Fwd 180/180 pose=[180, 180, 180, 180] velocidade=1.050 m/s distancia=3.151 m
PASS Miguel agachado: tempo avança em todos os quadros por 3 s
PASS Miguel agachado: cadência casa velocidade real com passada medida
PASS Miguel agachado: clipe ativo novo/Crouch_Fwd
PASS Miguel agachado: pose do clipe varia sem congelar
PASS Miguel agachado: velocidade real 1.05 m/s
AMOSTRA cultista patrulhando: tempo=180/180 clipe=novo/Walk 180/180 pose=[180, 180, 180, 180] velocidade=1.450 m/s distancia=4.350 m
PASS cultista patrulhando: tempo avança em todos os quadros por 3 s
PASS cultista patrulhando: cadência casa velocidade real com passada medida
PASS cultista patrulhando: clipe ativo novo/Walk
PASS cultista patrulhando: pose do clipe varia sem congelar
PASS cultista patrulhando: velocidade real 1.45 m/s
AMOSTRA cultista perseguindo Miguel: tempo=180/180 clipe=novo/Sprint 180/180 pose=[180, 180, 180, 180] velocidade=3.000 m/s distancia=9.000 m
PASS cultista perseguindo Miguel: tempo avança em todos os quadros por 3 s
PASS cultista perseguindo Miguel: cadência casa velocidade real com passada medida
PASS cultista perseguindo Miguel: clipe ativo novo/Sprint
PASS cultista perseguindo Miguel: pose do clipe varia sem congelar
PASS cultista perseguindo Miguel: velocidade real 3.00 m/s
ACAO novo/PickUp_Table: duracao=0.833 ultimo=0.817 quadros=51 congelados=0 retorno=Locomocao locomocao=true
PASS novo/PickUp_Table: clipe certo e tempo avança
PASS novo/PickUp_Table: toca até o fim
PASS novo/PickUp_Table: volta sozinho para parado
PASS novo/PickUp_Table: andar retoma sem novo play
ACAO novo/Interact: duracao=2.000 ultimo=1.983 quadros=121 congelados=0 retorno=Locomocao locomocao=true
PASS novo/Interact: clipe certo e tempo avança
PASS novo/Interact: toca até o fim
PASS novo/Interact: volta sozinho para parado
PASS novo/Interact: andar retoma sem novo play
ACAO novo/Chest_Open: duracao=1.367 ultimo=1.350 quadros=83 congelados=0 retorno=Locomocao locomocao=true
PASS novo/Chest_Open: clipe certo e tempo avança
PASS novo/Chest_Open: toca até o fim
PASS novo/Chest_Open: volta sozinho para parado
PASS novo/Chest_Open: andar retoma sem novo play
ACAO novo/ClimbUp_1m: duracao=0.667 ultimo=0.650 quadros=41 congelados=0 retorno=Locomocao locomocao=true
PASS novo/ClimbUp_1m: clipe certo e tempo avança
PASS novo/ClimbUp_1m: toca até o fim
PASS novo/ClimbUp_1m: volta sozinho para parado
PASS novo/ClimbUp_1m: andar retoma sem novo play
PASS bag: aproximação livre aceita
CONTATO bag: erro=0.0000 m estado=interaction
INTERACAO bag: clipe=true ultimo=0.817 estado=idle pendente=false
PASS bag: mão toca alvo no quadro do evento (9 cm)
PASS bag: ação completa antes de sair
PASS bag: ação termina sem congelar
PASS bolsa: efeito confirmado no contato
PASS door: aproximação livre aceita
CONTATO door: erro=0.0000 m estado=interaction
INTERACAO door: clipe=true ultimo=1.983 estado=idle pendente=false
PASS door: mão toca alvo no quadro do evento (9 cm)
PASS door: ação completa antes de sair
PASS door: ação termina sem congelar
PASS porta: abriu no contato
PASS hide: aproximação livre aceita
CONTATO hide: erro=0.0000 m estado=interaction
INTERACAO hide: clipe=true ultimo=1.350 estado=idle pendente=false
PASS hide: mão toca alvo no quadro do evento (9 cm)
PASS hide: ação completa antes de sair
PASS hide: ação termina sem congelar
PASS armário: entrou após terminar o gesto
PASS gate: aproximação livre aceita
CONTATO gate: erro=0.0000 m estado=interaction
CONTATO grade: erro=0.0000 m
INTERACAO gate: clipe=true ultimo=1.983 estado=idle pendente=false
PASS gate: mão toca alvo no quadro do evento (9 cm)
PASS gate: ação completa antes de sair
PASS gate: ação termina sem congelar
PASS portão: alcançou o outro lado
PASS portão: escalada completa
PASS portão: mão toca grade no evento da escalada
ESCADA subir: clipe=novo/Ascending_Stairs certo=511/511 tempo=511/511 apoio=375/511
PASS subir: clipe correto na escada
PASS subir: tempo avança
APOIO subir: fixo=67/69 maior_desvio=0.0232 m
AVISO subir: apoio varia no clipe original; nenhuma correção de ossos aplicada
AVISO subir: pés originais não encaixam em todos os pisos visuais
ESCADA descer: clipe=novo/Descending_Stairs certo=671/671 tempo=671/671 apoio=43/671
PASS descer: clipe correto na escada
PASS descer: tempo avança
APOIO descer: fixo=0/0 maior_desvio=0.0000 m
AVISO descer: apoio varia no clipe original; nenhuma correção de ossos aplicada
AVISO descer: pés originais não encaixam em todos os pisos visuais
PASS Descending_Stairs original intacto; repetições usam crossfade
PASS Stunned não é usado em loop
CAPITULO1_ANIMACAO: 70 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS mapa contempla os blocos e todas as salas nomeadas
PASS salas têm portas físicas e acessos
PASS Miguel começa sem celular
PASS bolsa fica no andar superior
PASS ritual separado do pátio onde acorda
PASS sete comuns ocupam os postos da grade
PASS ciclo novo de corrida importado
PASS corrida seleciona estado próprio com crossfade
PASS corrida contínua não reinicia arrancada
RITUAL_VISTO_DE_CIMA []
PASS andar superior não permite observar o ritual
BLOCKED_DOORS []
PASS todas as portas abertas têm vãos desobstruídos
PASS abertura integrada sem pular para sala de testes
PASS recuperar bolsa salva primeiro checkpoint
PASS checkpoint da bolsa guarda ausência de alerta
PASS restauração recupera alerta salvo, permitindo nova rota discreta
PASS segundo checkpoint antes de se aproximar do ritual
FRAME_RITUAL true (-15.5, 0.0, -25.5) 4.19999980926514
PASS ritual pode ser enquadrado manualmente no térreo
PASS REC só começa se a visão da lente enquadra o ritual
PASS rota discreta grava e continua sem perseguidor
PASS alerta espalhado habilita apresentação do perseguidor
PASS perseguição não cria checkpoint adicional
PASS controle da perseguição em primeira pessoa
PASS saída pula o portão, sem abri-lo
PASS transposição termina fora da escola
PASS encerramento mostra o quarto e os amigos
PASS chamado concluído espalha alerta
PASS derrubado levanta antes de tentar chamar ajuda
PASS chamado tem preparação interrompível
PASS sem travar alvo de luta
PASS sem finalizações na interface
PASS dano cancela cura sem consumir item
ESCADA_DESEMBOCA Pátio de química
PASS escada sai do pátio de química
PASS escada não sai da quadra
STAIR_RESULT (-31.34985, 3.400054, -23.72624)
STAIR_CONTACT @StaticBody3D@607 (0.0, 1.0, 0.0) (-31.0, 3.35, -24.0)
STAIR_CONTACT @StaticBody3D@607 (0.0, 1.0, 0.0) (-31.0, 3.35, -24.0)
PASS subir a escada alcança corredor superior com colisão real
PASS caixa da escada não deixa ver o ritual
PASS entrada da escada permite espiar o ritual
CAPITULO1_TEST: 36 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASS as duas grades são lidas sem erro
TAMANHO terreo=101x85 superior=31x15
PASS acordar, ritual, checkpoint 2 e bolsa aparecem uma vez cada
PASS sete postos comuns, perseguidor condicional e portão marcados
PASS cada nome da legenda marca exatamente um lugar
PASS portas em pares DD
VAZAMENTOS []
PASS térreo fechado: não se sai para fora do mapa
SEM_ACESSO []
PASS todas as salas e áreas do térreo são alcançáveis
PASS pé da escada e ritual no mesmo térreo andável
PASS uma escada no térreo
PASS topo da escada chega ao patamar (piso em cima, vão embaixo)
PASS sobre a escada o andar de cima é vão (sem laje na cabeça)
PASS kit tem parede, porta, janela gradeada, canto, coluna, pisos, meia-parede, telhado e degrau
KIT_FORA_DO_MODULO []
PASS peças de 2 m com pivô na base
PASS MeshLibrary salva em dia (tools/gerar_kit.gd)
PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS montagem sem avisos do mapa
PAREDE_SEM_COLISAO [] PISO_COM_COLISAO []
PASS toda célula # tem colisão
PASS célula de piso . fica livre a 1,5 m
GRIDMAP celulas=3836 colisores=374
PASS geometria do kit no GridMap e colisão mesclada
CAPITULO1_MAPA: 18 passed, 0 failed

Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS pátio aberto alcança o pátio de química
PASS rota norte funciona sozinha (sul bloqueada)
PASS rota sul funciona sozinha (norte bloqueada)
PASS de onde Miguel acorda até o pátio de química
PASS do pátio de química até o portão 1
PASS vão das portas comporta Miguel
POSTOS_SEM_ESCONDERIJO []
PASS sete postos, todos com esconderijo a até 10 m
POSTO 1 celula=(38, 41) abrigo_por_caminho=4.62 m
POSTO 2 celula=(39, 25) abrigo_por_caminho=3.50 m
POSTO 3 celula=(45, 9) abrigo_por_caminho=7.33 m
POSTO 4 celula=(44, 22) abrigo_por_caminho=5.50 m
POSTO 5 celula=(72, 34) abrigo_por_caminho=5.21 m
POSTO 6 celula=(88, 32) abrigo_por_caminho=4.62 m
POSTO 7 celula=(31, 17) abrigo_por_caminho=5.33 m
POSTO 8 celula=(46, 14) abrigo_por_caminho=2.62 m
PASS oito postos têm caminho de até 10 m até um esconderijo
PASS grade tem sete comuns e um posto condicional, sem perseguidor inicial
PASS rota norte desvia dos oito postos ocupados
PASS rota sul desvia dos oito postos ocupados
PASS postos ocupados não bloqueiam caminho obrigatório nem fuga
TRECHOS_VIGIADOS_SEM_COBERTURA []
PASS trechos vigiados das rotas têm cobertura a cada ~5 m
PASS ritmo em dente de serra com clímax no fim
PONTOS_EM_SOLIDO []
PASS pontos de roteiro em chão livre
CAPITULO1_NIVEL: 15 passed, 0 failed

```

</details>

<details>
<summary>bash scripts/testar-percurso.sh</summary>

```text
PERCURSO modo rota
PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS abertura termina sozinha pelo tempo do jogo
PERCURSO entrada da escada no pátio de química: abriu porta Materiais de esportes
PERCURSO entrada da escada no pátio de química: abriu porta Materiais de esportes
PERCURSO entrada da escada no pátio de química: abriu porta Materiais de esportes
PERCURSO entrada da escada no pátio de química: chegou em (-20.06296, 0.00084, -25.39881) após 47.5 s
PERCURSO pé da escada: chegou em (-23.6195, 0.000839, -25.91174) após 2.5 s
PERCURSO subir escada: chegou em (-29.50887, 3.162988, -25.99322) após 9.7 s
PERCURSO patamar: chegou em (-31.0251, 3.400026, -25.61745) após 1.8 s
PASS chega ao andar superior andando
PERCURSO corredor superior: chegou em (-31.36886, 3.400818, -24.08469) após 1.1 s
PERCURSO porta do 3 Informática: abriu porta 3 Informática
PERCURSO porta do 3 Informática: abriu porta 3 Informática
PERCURSO porta do 3 Informática: abriu porta 3 Informática
PERCURSO porta do 3 Informática: chegou em (-35.50769, 3.400835, -23.80811) após 3.9 s
PERCURSO dentro do 3 Informática: chegou em (-35.89462, 3.400835, -25.92384) após 1.5 s
PERCURSO mesa da bolsa: chegou em (-37.29144, 3.400836, -27.29523) após 1.4 s
PASS pega a bolsa após percurso contínuo
PERCURSO alerta=false fase=investigate
PERCURSO voltar à porta: chegou em (-36.40047, 3.400836, -26.9209) após 0.9 s
PERCURSO sair da sala: chegou em (-36.06891, 3.400834, -24.0886) após 2.0 s
PERCURSO corredor na volta: chegou em (-32.08984, 3.400835, -23.57599) após 2.8 s
PERCURSO patamar na volta: chegou em (-31.55513, 3.40018, -25.02456) após 1.3 s
PERCURSO topo da escada: chegou em (-30.40865, 3.400606, -25.74368) após 0.9 s
PERCURSO descer escada: chegou em (-24.59456, 0.378197, -25.97615) após 12.4 s
PASS desce ao térreo andando
PERCURSO abrigo no pé da escada: chegou em (-23.92224, 0.000841, -26.35091) após 1.7 s
PASS checkpoint antes do ritual alcançado andando
PERCURSO entrada da escada: chegou em (-20.93181, 0.00084, -25.6188) após 2.3 s
PERCURSO espiar da entrada da escada: chegou em (-23.17339, 0.00084, -25.5032) após 1.6 s
PERCURSO enquadra=true inimigos: idle d=32.2 aware=false susp=0.00, hunt d=19.0 aware=false susp=0.00, hunt d=15.7 aware=false susp=0.00, hunt d=19.9 aware=false susp=0.00, hunt d=50.7 aware=false susp=0.00, hunt d=63.2 aware=false susp=0.00, hunt d=8.6 aware=false susp=0.00
PERCURSO gravando=true t=0.0
PERCURSO gravando=true t=1.0
PERCURSO gravando=true t=2.0
PERCURSO gravando=true t=3.0
PERCURSO gravando=false t=4.0
PASS grava o ritual em sequência contínua
PERCURSO alerta=false fase=investigate perseguidor=false
PERCURSO portão 1: abriu porta Sala dos professores
PERCURSO portão 1: abriu porta Sala dos professores
PERCURSO portão 1: abriu porta Sala dos professores
PERCURSO contato Chao pai=@Node3D@3 normal=(0.0, 1.0, 0.0) em (25.74676, 0.0, 41.1067)
PERCURSO contato Chao pai=@Node3D@3 normal=(0.0, 1.0, 0.0) em (25.75245, 0.0, 41.11554)
PERCURSO contato Chao pai=@Node3D@3 normal=(0.0, 1.0, 0.0) em (25.75319, 0.0, 41.11671)
PERCURSO estado=interaction escondido=false agachado=false fase=investigate
PERCURSO portão 1: TRAVOU em (25.75319, 0.00084, 41.11671) (alvo (26.0, 0.0, 41.5), faltam 0.5 m)
PASS pula o portão e chega ao encerramento
PERCURSO tempo de jogo total 187.2 s, mortes 0
PERCURSO distância do checkpoint 2 ao cultista mais próximo (posição inicial): 8.25 m
CAPITULO1_PERCURSO[rota]: 7 passed, 0 failed
PERCURSO alerta=false ritual_notou=false sighting=false
```

</details>

<details>
<summary>$GODOT --headless --path godot-3d -s res://tests/capitulo1_nivel_test.gd</summary>

```text
Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASSO_MEDIDO Walk ciclo=1.333 s passo=1.274 m nativo=0.956 m/s
PASSO_MEDIDO Sprint ciclo=0.667 s passo=2.335 m nativo=3.503 m/s
PASSO_MEDIDO Crouch_Fwd ciclo=2.000 s passo=1.279 m nativo=0.640 m/s
PASSO_MEDIDO Walking_Backwards ciclo=0.967 s passo=1.215 m nativo=1.257 m/s
PASSO_MEDIDO Ascending_Stairs ciclo=1.367 s passo=0.450 m nativo=0.329 m/s
PASSO_MEDIDO Running_Up_Stairs ciclo=0.600 s passo=0.363 m nativo=0.605 m/s
PASSO_MEDIDO Descending_Stairs ciclo=0.933 s passo=0.264 m nativo=0.283 m/s
PASSO_MEDIDO Roll ciclo=1.467 s passo=3.256 m nativo=2.220 m/s
PASS pátio aberto alcança o pátio de química
PASS rota norte funciona sozinha (sul bloqueada)
PASS rota sul funciona sozinha (norte bloqueada)
PASS de onde Miguel acorda até o pátio de química
PASS do pátio de química até o portão 1
PASS vão das portas comporta Miguel
POSTOS_SEM_ESCONDERIJO []
PASS sete postos, todos com esconderijo a até 10 m
POSTO 1 celula=(38, 41) abrigo_por_caminho=4.62 m
POSTO 2 celula=(39, 25) abrigo_por_caminho=3.50 m
POSTO 3 celula=(45, 9) abrigo_por_caminho=7.33 m
POSTO 4 celula=(44, 22) abrigo_por_caminho=5.50 m
POSTO 5 celula=(72, 34) abrigo_por_caminho=5.21 m
POSTO 6 celula=(88, 32) abrigo_por_caminho=4.62 m
POSTO 7 celula=(31, 17) abrigo_por_caminho=5.33 m
POSTO 8 celula=(46, 14) abrigo_por_caminho=2.62 m
PASS oito postos têm caminho de até 10 m até um esconderijo
PASS grade tem sete comuns e um posto condicional, sem perseguidor inicial
PASS rota norte desvia dos oito postos ocupados
PASS rota sul desvia dos oito postos ocupados
PASS postos ocupados não bloqueiam caminho obrigatório nem fuga
TRECHOS_VIGIADOS_SEM_COBERTURA []
PASS trechos vigiados das rotas têm cobertura a cada ~5 m
PASS ritmo em dente de serra com clímax no fim
PONTOS_EM_SOLIDO []
PASS pontos de roteiro em chão livre
CAPITULO1_NIVEL: 15 passed, 0 failed
```

</details>

### Integridade da grade

Comparação SHA-256 com `HEAD` anterior à revisão (`11b14db`): arquivos idênticos.

- `terreo.txt`: `8ed547e63a76966f45d5440d1120c044eed6956985276169863154dd1755498f`.
- `superior.txt`: `0a27b82e55e39ef2ee933d114caa0a3e1f5e3b709677278d6f858b565b4c88dc`.
