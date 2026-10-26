# Guia de animação — Sorriso / GAVIÃO

Rodada dedicada à arte. As listas distinguem material atual, substituições necessárias e sugestões futuras. Não implementar mecânicas novas apenas porque há uma sugestão de animação neste documento.

## 1. Antes de multiplicar os desenhos

Fixar um único modelo corporal: altura em pé, tamanho da cabeça, volume do cabelo, ombros, tronco, braços e pernas. Usar a mesma orientação de combate em ¾ para idle, deslocamento e ataques. Um idle relaxado frontal pode existir como outra ação, com uma transição própria; não deve substituir a guarda de combate por acidente.

Sorriso é um jovem de pele clara, cabelo preto cacheado com volume inclusive nas laterais/orelhas/nuca, polo branca com verde/amarelo, jeans e tênis claros. Não fazer cabelo marrom, laterais raspadas ou mudar o rosto entre folhas. Não copiar os textos e rabiscos da ficha para as imagens de gameplay.

Primeiro lote recomendado: **pose de guarda, idle de combate, soco baixo no corpo e cotovelada**, acompanhados de uma corrida curta para comparar proporções. São os problemas apontados pelo usuário. Usar esse lote como base visual dos demais movimentos.

## 2. Quantidade de quadros e duração

O jogo desenha a tela com seu próprio ritmo; o número de desenhos da animação é outra coisa. Trinta desenhos não garantem movimento humano, e reproduzir todos com a mesma duração pode tirar o peso do contato. Preparação, extensão, impacto e recuperação podem ter tempos diferentes.

| Tipo | Faixa inicial de desenhos distintos | Duração inicial para experimentar |
| --- | --- | --- |
| Idle de combate | 8–16 | 0,8–1,4 s, em ciclo |
| Caminhada/corrida | 12–16 por ciclo | 0,55–0,9 s, depois casar à distância |
| Largada, freada, giro | 6–12 por ação | 0,12–0,32 s |
| Jab e soco curto | 8–12 | 0,22–0,38 s |
| Direto/cruzado, gancho no corpo | 10–16 | 0,28–0,48 s |
| Golpe pesado e chute elaborado | 12–20 | 0,4–0,65 s |
| Parry/deflexão | 4–8 por braço | 0,08–0,16 s, resposta separada |
| Reação curta a golpe | 6–12 | 0,12–0,32 s |
| Queda e levantar | 16–30 por ação | 0,5–1,1 s |
| Agarrão, saída e finalização longa | 16–30 por ação | 0,5–1,1 s |
| Limpar mãos e gestos ociosos | 20–30 | 0,9–1,6 s |

Essas são estimativas de autoria para revisão, não mudanças já aplicadas ao jogo. Se quiser produzir 30 quadros mestres para um golpe, entregar os quadros com tempos e permitir selecionar só os necessários. Não alongar a ação, não repetir quase a mesma pose para completar 30 e não deformar membros para inventar intermediários. Exemplo de escala: 50 animações × 30 desenhos = 1.500 desenhos, antes das reações do adversário e variações de braço.

## 3. Golpes que já existem no código

As tiras em `05_GOLPES_NO_JOGO` mostram a seleção efetiva. Alguns nomes do código são históricos e não descrevem bem o gesto atual.

| ID atual | Função no jogo | Problema/pedido para a arte |
| --- | --- | --- |
| `jab` | Soco rápido no corpo | Tornar a preparação, o contato e a retração claros; distinguir jab na cabeça de soco no tronco. |
| `cross` | Cruzado aproveitando abertura | Girar quadril/ombro; preservar proporções e o braço que atua. |
| `drive` | Golpe pesado que carrega o alvo | Antecipação curta, extensão com apoio e continuação de peso; saídas para acerto/erro/guarda. |
| `low` | Soco baixo no corpo | **Refazer prioritariamente.** Não é um soco apontado para o chão; mirar barriga/plexo com joelhos e quadril participando. |
| `reverse` | Golpe para trás com mudança de direção | Giro, transferência de apoio, golpe e guarda no novo lado. |
| `kick` | Chute circular atual | O ID é antigo; o desenho atual não é o antigo chute frontal. Definir altura de alvo de forma legível. |
| `lowKick` | Chute na perna | Giro de apoio, canela/pé em trajetória coerente, recolhimento antes de pousar. |
| `comboKick` | Soco seguido de chute alto | Hoje costura faixas distintas. Criar ligação contínua do braço recolhendo para o quadril e a perna entrando. |
| `stepPunch` | Chute seguido de soco | Recolher a perna, pousar com base e transferir peso ao soco. |
| `rush` | Soco de impulso correndo | Avanço corporal, contato que acompanha o alvo, soltura e queda/recuperação correspondentes. |
| `clinchPunch` | Soco curto no clinch | Uma mão mantém a pega; a outra golpeia curto. Não soltar os dois braços a cada soco. |
| `clinchElbow` | Cotovelada no clinch | **Refazer prioritariamente.** Cotovelo é a superfície de contato, antebraço dobrado, mão perto do próprio rosto. |
| `knee` | Joelhada no tronco durante clinch | Pé de apoio firme, joelho sobe, perna permanece dobrada e retorna. |
| `clinchFinish` | Puxar para baixo, golpear e derrubar | Separar pegar/puxar, contato e soltar. Completar o gesto após a queda, sem salto para guarda. |
| `counterStraight` | Resposta à cabeça com um braço livre | Separar deflexão de contra-ataque e manter continuidade. |
| `counterLeft` | Resposta com o outro braço | Desenhar realmente o outro braço; não virar o personagem inteiro para simular isso. |
| `counterBody` | Resposta no tronco | Altura e trajetória diferentes da resposta à cabeça. |
| `counterBodyLeft` | Resposta no tronco com braço oposto | Precisa de identidade de braço e altura; hoje reaproveita arte. |
| `groundPunch` | Soco no alvo caído | Criar ação própria de agachar/ajoelhar, contato e levantar; hoje reaproveita o golpe de queda do clinch. |
| `groundKick` | Chute no alvo caído | Pé chega ao ponto de contato no chão; recolhimento e recuperação próprios. |
| `groundStomp` | Pisada | Elevar joelho, descer o pé, absorver e retirar; não parecer só outra pose de chute. |

## 4. Biblioteca de ataques recomendada

### Núcleo a refazer/padronizar

| Animação proposta | Papel | Situação |
| --- | --- | --- |
| `jab_head` | Soco rápido da mão da frente na cabeça | Separação visual nova em relação ao soco no corpo atual. |
| `jab_body` | Entrada rápida no tronco | Evolução do `jab` atual. |
| `cross_head` | Soco da mão traseira na cabeça | Evolução do `cross`. |
| `cross_body` | Direto da mão traseira no tronco | Variação a desenhar; não só trocar a região de dano. |
| `hook_body` | Gancho curto na barriga/plexo | Substituição prioritária de `low`. |
| `overhand_heavy` | Golpe pesado descendente | Evolução do pesado, com compromisso e continuação. |
| `reverse_strike` | Golpe após virar para ameaça atrás | Revisão do reverso atual. |
| `running_punch` | Soco que entra com o corpo | Revisão do impulso, com contato e soltura. |
| `low_kick` | Atacar apoio/perna | Já há base. |
| `round_kick_body` | Circular médio no tronco | Definir gesto e altura. |
| `round_kick_head` | Circular alto | Diferenciar elevação do quadril e alcance. |
| `clinch_punch` | Soco curto mantendo uma pega | Já há base, refazer consistente. |
| `clinch_elbow` | Cotovelada horizontal curta | Revisão prioritária. |
| `clinch_knee` | Joelhada mantendo a pega | Já há base. |
| `clinch_knockdown` | Puxada/golpe e soltura | Já há base provisória. |
| `counter_head_left/right` | Resposta com braço livre | Duas atuações de braço; podem compartilhar a mesma lógica. |
| `counter_body_left/right` | Resposta no tronco com braço livre | Duas atuações, altura diferente. |
| `ground_punch`, `ground_kick`, `ground_stomp` | Três ações no chão | Separar as três coreografias e suas entradas/saídas. |

### Bons acréscimos depois do núcleo

| Movimento | Por que vale produzir | Condição |
| --- | --- | --- |
| Gancho horizontal na cabeça | Completa direto → cruzado → gancho, com giro próprio. | Novo golpe/animação; precisará de integração posterior. |
| Uppercut | Dá uma resposta curta de baixo para cima quando muito próximo. | Novo; não confundir com o soco baixo no tronco. |
| Chute frontal de empurrão / teep | Cria espaço e contrasta com os circulares. | O atlas guarda um chute frontal antigo, mas o comando K atual usa outra arte. |
| Joelhada fora do clinch | Opção curta quando os personagens estão próximos sem pega. | Nova seleção contextual e arte própria. |
| Cotovelada fora do clinch | Alternativa curta em distância fechada. | Nova; produzir depois da cotovelada básica funcionar visualmente. |
| Passo lateral ou recuo com contra-ataque | Acrescenta posicionamento às respostas. | Não existe como mecânica completa; exige desenho e código depois. |
| Rasteira | Varia a forma de atacar o apoio e derrubar. | Nova; requer regras para evitar queda automática em todo contato. |
| Empurrão de duas mãos | Espaçamento e oportunidade de reposicionar. | Nova; usar função tática diferente do teep. |
| Cotovelada descendente no chão | Quarta ação no chão, com outra postura. | Opcional, depois das três atuais estarem boas. |

Giros acrobáticos, chutes saltados e dezenas de finalizações ficam para uma etapa posterior. A prioridade é que os golpes tenham funções e silhuetas diferentes. Muitos nomes com o mesmo desenho não aumentam a variedade percebida.

## 5. Animações sem ataque que precisamos ter

| Grupo | Entregas | Estado atual |
| --- | --- | --- |
| Postura | Idle de combate em ¾; opcional idle relaxado e ligação entre os dois. | Idle atual precisa ser unificado. |
| Locomoção | Andar, correr, largada, freada e giro de direção. | Há material, com diferentes folhas/estilos. |
| Distância curta | Passo para trás mantendo guarda; ajuste lateral curto. | Não há biblioteca dedicada completa. |
| Abaixar | Entrada, permanência e saída do agachamento. | Existe faixa antiga; não há conjunto integrado completo. |
| Defesa | Levantar guarda, sustentar, absorver impacto, baixar guarda. | Guarda atual é limitada e reaproveitada. |
| Parry | Deflexão com braço esquerdo e com direito, saídas e respostas separadas. | Existem receitas, não uma biblioteca final completa. |
| Impacto recebido | Reagir à cabeça, ao tronco e à perna, sem sair sempre para a mesma pose. | Sorriso usa hurt genérico; o manequim tem reações separadas provisórias. |
| Compromisso | Recuperar apoio após acerto, guarda e erro; tropeço cansado. | Hoje há reaproveitamento de poses. |
| Cansaço | Respiração cansada e volta à guarda. | Reaproveita idle. |
| Queda | Cair para frente, para trás e de lado; estado no chão. | Há quedas antigas/receitas, sem biblioteca final específica para todas as situações. |
| Levantar | Apoiar mão/joelho, erguer e recuperar guarda, conforme orientação. | Reaproveitamento limitado. |
| Pega | Aproximar, alcançar, fechar clinch, sustentar, andar levando/puxando, soltar. | Entrada/sustentação/saída ainda reaproveitam quadros; caminhada existe. |
| Falha de pega | Estender e recolher os braços quando não alcança o alvo. | Não há arte dedicada. |
| Escape | Adversário rompe a pega; Sorriso recupera a base. | Não há conjunto próprio. |
| Sangue nas mãos | Olhar a mão, limpar nos jeans, voltar à guarda, saída interrompida. | Há sequência, pode ser unificada com o novo modelo. |
| Secundárias | Olhar para os lados, ajeitar o uniforme/cabelo, gesto curto de personalidade. | Opcionais; produzir depois da base. |

Sangue acumulado deve ser uma camada/estado das mãos; não redesenhar toda a biblioteca para cada nível de sujeira. O chão e a sombra devem ser separados do sprite.

## 6. Reações do adversário e ações com dois atores

Produzir também um alvo neutro de referência com: guarda, bloqueio, guarda cedendo, impacto na cabeça, corpo dobrando, perna cedendo, queda nas três orientações, chão, levantar e posturas do clinch. Esses desenhos servem para conferir o contato, sem criar agora os personagens narrativos.

No clinch, parry, soco que carrega e ação no chão, entregar jogador e adversário **em arquivos separados**, sincronizados. Uma imagem final contendo os dois juntos não permite trocar o adversário sem refazer tudo. Pode existir uma prévia composta para revisar a coreografia.

Marcar ponto da mão e do alvo em cada fase; manter o contato até a soltura. Se há mudança de apoio ou queda, os dois atores devem mostrá-la no mesmo instante. Reação localizada deve começar na postura atingida, sem saltar primeiro para uma pose em pé.

## 7. Ligações que evitam o efeito de troca de figurinha

- Guarda → jab → cruzado, continuando o apoio do golpe anterior.
- Soco → circular: braço recolhe enquanto o quadril prepara a perna.
- Circular → direto: perna recolhe, pé pousa, corpo transfere peso ao soco.
- Golpe pesado acertado → contato acompanhando o alvo → soltura.
- Golpe pesado no vazio → continuação do gesto → recuperar apoio.
- Golpe bloqueado → absorver o contato → recolher, sem reação de acerto limpo.
- Corrida → freada → guarda; giro sem trocar a direção instantaneamente em velocidade alta.
- Parry → resposta com braço livre → guarda.
- Clinch sustentado → soco/cotovelo/joelho → pega novamente; finalizador → soltar e completar o gesto.

Não é preciso desenhar todas as combinações possíveis. Usar algumas poses de ligação compatíveis de quadril, mãos e apoio. Decidir essas poses antes de criar dezenas de sequências.

## 8. Especificação de exportação

- Resolução do jogo: 320×180. Célula atual de sprite: **128×96**, pivô no chão em **(64,88)**. A célula não é o tamanho do corpo: o personagem em pé ocupa aproximadamente 60–68 pixels de altura, conforme a postura. Fixar proporções pelo modelo, não esticando cada silhueta para a mesma altura.
- Orientação base: direita em ¾, com identificação do braço dianteiro/traseiro. Espelhar para olhar à esquerda é diferente de desenhar um golpe com o outro braço.
- PNG RGBA com transparência real, sem fundo preto, halos, linhas, textos, rótulos ou sombra embutida. Ampliação por nearest-neighbor; sem suavização.
- Não recortar mãos, cabelos, joelhos ou tênis. Deixar margem para todo o movimento; se uma ação não couber, informar a necessidade de adaptar a célula. Não diminuir somente aquele quadro ou apertar uma perna para caber.
- Pivô e escala constantes por animação/modelo. Durante voo, o pé pode subir no quadro: não alinhar cada quadro pelo pé mais baixo e apagar o salto.
- Arquivos por ação, por exemplo `hook_body/hook_body_000.png`, `001.png` etc. Nomes de ação devem ser estáveis. Uma animação por folha final, com grade exata; folhas de revisão podem ter legendas fora da área dos quadros.
- Entregar também fonte editável quando houver, como `.aseprite`, e PNG+JSON exportado. JSON deve registrar quadro, duração em ms, pivô, fase, marcadores de mãos/cotovelos/joelhos/pés, apoio e deslocamento do corpo quando aplicável. Não inventar coordenadas de contato que o desenho não ocupa.
- Identificar preparação, contato, continuação e recuperação. Marcadores de contato não substituem colisões do jogo; eles permitem posicioná-las corretamente depois.
- Ao desenhar 30 quadros, não montar tudo em uma tira excessivamente comprida: pode usar grade 6×5, com a mesma célula, numeração apenas na prévia. Preservar a ordem no JSON.

## 9. Conferência antes da entrega

Comparar idle, corrida, soco baixo e cotovelada lado a lado na mesma escala. Conferir cabeça, cabelo, pele, comprimento dos membros e figurino. Depois revisar em reprodução e com onion skin, observando pés, quadril e trajetória das mãos. Uma folha estática bonita não prova continuidade de movimento.

No soco baixo: a mão deve alcançar o tronco, o quadril deve participar e a outra mão proteger. Na cotovelada: o cotovelo deve chegar primeiro e a mão permanecer recolhida. No idle: a pose não deve mudar para outro corpo, orientação ou uniforme quando começa a andar/golpear.

Nas ações duplas, revisar alinhamento com o alvo de referência. Nas entradas/saídas, conferir se existe uma pose compatível com o movimento anterior. Não preencher falhas de desenho com deformação do sprite inteiro.

## Fontes da orientação

As faixas numéricas e a organização desta biblioteca são propostas específicas para GAVIÃO. O princípio de priorizar poses-chave e tempos bem escolhidos, em vez de apenas acrescentar desenhos, é explicado por Mariel Cartwright, animadora principal de Skullgirls: https://media.gdcvault.com/gdcchina14/presentations/833784_MarielCartwright_PowerfulAndEffective_EN.pdf

Formatos de exportação e organização de folhas: documentação oficial do Aseprite, https://aseprite.org/docs/sprite-sheet/ . O jogo pode receber PNG+JSON; não é necessário trocar de motor para preparar essas animações.
