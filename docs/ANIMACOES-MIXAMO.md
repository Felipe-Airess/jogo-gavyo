# Animações refeitas com Mixamo — lista de download e plano

Pedido de Felipe: refazer as animações com o Mixamo, sem reaproveitar as baixadas
antes, com loop certo, sem erro de ciclo, e cuidando de como o Miguel interage
com o cenário e com os inimigos.

O Mixamo exige login Adobe e o site é bloqueado na nuvem. **Felipe baixa** os
arquivos; o Claude importa, confere e integra. Ninguém pede senha.

Skills usadas: `godot-animation-tree-mastery`, `godot-animation-player`,
`godot-state-machine-advanced`, `game-dev-combat-animation` (método de testes
quadro a quadro), `godot-animation`.

## Como baixar (igual para todos)

1. Em mixamo.com, use o personagem do Miguel já enviado. Se não houver, envie
   `godot-3d/miguel_animado.glb` exportado como FBX, ou use o **Y Bot**. O
   esqueleto é o mesmo padrão Mixamo e eu faço o retarget.
2. Em cada animação: **Format FBX Binary**, **Skin: Without Skin**,
   **Frames per Second: 30**, **Keyframe Reduction: none**.
3. **In Place ligado** em tudo que anda ou corre em ciclo. Sem In Place, o boneco
   sai do lugar e o loop dá tranco.
4. Não mexa em "Trim". Para os ciclos, deixe "Overdrive" no padrão.
5. Salve com nomes simples (`andar.fbx`, `correr.fbx`…) numa pasta e mande o
   zip, ou ponha em `godot-3d/capitulo1/animacoes/mixamo/`.

Os nomes abaixo são **termos de busca** no Mixamo. Os títulos exatos variam;
escolha o que melhor bater com a descrição.

## Lista

### Movimento (ciclo, In Place)
| Arquivo | Buscar | Observação |
|---|---|---|
| parado.fbx | "breathing idle" ou "nervous idle" | parado inquieto |
| olhar_em_volta.fbx | "look around" | variação do parado |
| andar.fbx | "walking" | ciclo, In Place |
| andar_tras.fbx | "walking backwards" | ciclo, In Place |
| correr.fbx | "running" | **o ciclo, não "run start" nem "run to stop"** |
| agachado_parado.fbx | "crouch idle" | |
| agachado_andar.fbx | "crouched walking" ou "sneak walk" | ciclo, In Place |
| abaixar.fbx | "standing to crouch" | transição |
| levantar.fbx | "crouch to stand" | transição |

### Cenário
| Arquivo | Buscar | Uso |
|---|---|---|
| acordar.fbx | "sitting idle" + "sit to stand" | abertura |
| abrir_porta.fbx | "open door" ou "opening" | portas |
| pegar.fbx | "picking up" (objeto na mesa) | bolsa, itens |
| celular.fbx | "texting" ou "talking on phone" ou "taking photo" | gravar o ritual |
| espiar.fbx | "peek" ou "look around corner" | fresta e entrada da escada |
| pular_obstaculo.fbx | "jump over" ou "vault" | mesas e bancos |
| escalar.fbx | "climbing" ou "climb over wall" | portão 1 |
| escada_subir.fbx | "climbing stairs" (In Place) | escada |
| escada_descer.fbx | "descending stairs" (In Place) | escada |

### Inimigos e confronto
| Arquivo | Buscar | Uso |
|---|---|---|
| empurrar.fbx | "push" ou "shove" (curto, as duas mãos) | empurrão do Miguel |
| ser_empurrado.fbx | "stumble backwards" ou "knocked down" | cultista caindo |
| levantar_chao.fbx | "getting up" | cultista se levanta |
| agarrar.fbx | "grab" ou "zombie attack" (braços à frente) | agarrão do cultista |
| ser_agarrado.fbx | "struggle" ou "being grabbed" | Miguel preso |
| soltar.fbx | "break free" ou "shove" | se soltar |
| apanhar.fbx | "hit reaction" | dano |
| morrer.fbx | "dying" | morte |
| cultista_andar.fbx | "walking" lento ou "zombie walk" leve | patrulha (In Place) |
| cultista_correr.fbx | "running" | caça (In Place) |
| cultista_procurar.fbx | "searching" ou "look around" | busca |
| ritual.fbx | "praying" ou "kneeling" | figuras do ritual |
| perseguidor_faca.fbx | "stabbing" ou "knife attack" | perseguidor |

## O que o Claude faz quando os arquivos chegarem

1. **Importação limpa:** retarget para o esqueleto do Miguel (BoneMap humanoide),
   uma AnimationLibrary nova. As animações antigas ficam fora, sem apagar
   histórico.
2. **Loop certo, provado por teste**, para cada ciclo:
   - pose do último quadro ≈ pose do primeiro;
   - quadril sem degrau na emenda;
   - pés sem escorregar: a velocidade do jogo casa com o passo do clipe;
   - um teste falha se um clipe de arrancada for usado como ciclo (o bug da
     corrida antiga).
3. **Máquina de estados (AnimationTree):**
   - parado ↔ andar ↔ correr, com blend pela velocidade;
   - agachado;
   - ações únicas (abrir porta, pegar, empurrar), que voltam sozinhas ao
     estado de movimento;
   - fim das trocas manuais de clipe a cada quadro.
4. **Interação com o cenário:**
   - cada porta, mesa da bolsa, portão e armário ganha um **ponto de encaixe**
     (posição + direção);
   - o Miguel desliza até ele antes da animação, para a mão bater na maçaneta,
     na bolsa ou na grade;
   - eventos no clipe abrem a porta e somem a bolsa no quadro do contato.
5. **Interação com inimigos (ações em dupla):**
   - empurrão e agarrão alinham os dois personagens a uma distância fixa;
   - o efeito (cair, prender) acontece no quadro de contato;
   - pelo método do `game-dev-combat-animation`, testes quadro a quadro na
     malha: mão encosta no alvo no quadro certo, braço não estica, um corpo
     não atravessa o outro.
6. **Verificação visual:** folha de quadros de cada animação, e de cada
   interação vista da câmera do jogo, antes de dar por pronto.
