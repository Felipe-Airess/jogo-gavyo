# Passagem para o GPT — Gavião, capítulo 1 (02/11/2026)

Repositório `Felipe-Airess/jogo-gavyo`. Godot **4.5.1 Compatibility**; não
atualize a engine. Responda a Felipe em português brasileiro. Antes de mexer,
leia `CLAUDE.md`, `docs/PASSAGEM-PARA-CLAUDE.md` e `docs/LEVEL-DESIGN-CAPITULO1.md`.
Não invente falas de Miguel nem gameplay do capítulo 2.

## Branches

| Branch | O que tem |
|---|---|
| `feat/prototipo-terror-terceira-pessoa` | jogo principal: mapa novo em grade, animações baixadas, controles de toque |
| `feat/modelo-miguel` | proposta do Miguel v2 (cópia separada, ainda não aprovada) |
| `main` | site (GitHub Pages); só tem a 1ª versão do capítulo (PR #16). O PR #17 traz a versão anterior ao mapa novo |

## 1. Mapa (pronto em bloqueio cinza, aguardando aprovação de Felipe)

- **Grade em texto:** `godot-3d/capitulo1/mapa/terreo.txt` e `superior.txt`
  (1 caractere = 1 m). A legenda está em `godot-3d/capitulo1/mapa/LEIA-ME.md`.
- **Montagem:** `capitulo1/mapa/escola_grade.gd` monta a grade com o kit
  modular (`kit.gd`, peças de 2 m).
- **Planta e capturas:** `docs/verificacao-20261102/mapa-grade/`.
- **Felipe já fez correções.** **Não decorar** antes de ele aprovar. Depois,
  decorar seguindo as fotos de `docs/referencias/escola-fotos/`.

## 2. Modelo do Miguel v2 (proposta, branch `feat/modelo-miguel`)

- O modelo é `arte/miguel_v2_animado.glb` (25,6 mil triângulos; o antigo tinha
  61,7 mil), com os mesmos 22 ossos.
- O antes/depois está em `arte/revisoes/miguel-v2-20261102/` (README e
  imagens).
- O original aprovado (`arte/miguel_animado.glb`) não foi alterado. Só troque
  o modelo no jogo depois que Felipe aprovar o v2.

## 3. Animações — sua tarefa principal

Arquivos (todos na branch principal):
- `godot-3d/capitulo1/animacoes/quaternius/UAL1.glb` e `UAL2.glb`: 86
  animações, CC0. O retarget já está configurado nos `.import` com
  `mapa_ossos_quaternius.tres` (padrão Unreal → perfil humanoide do Godot).
  O que cobre e o que falta está em `quaternius/LEIA-ME.md`.
- `godot-3d/capitulo1/animacoes/mixamo/`: Ascending_Stairs, Descending_Stairs,
  Running_Up_Stairs, Crouch_To_Stand, Walking_Backwards, Stunned, Sweep_Fall
  (FBX do Mixamo, esqueleto do Y Bot).
- O plano completo está em `docs/ANIMACOES-MIXAMO.md`.

O que fazer:
1. **Esqueleto comum.** Importe o Miguel (e os cultistas, que usam o mesmo
   modelo) com BoneMap para o perfil `SkeletonProfileHumanoid` e rest fixer
   (overwrite axis, fix silhouette). Importe os FBX do Mixamo do mesmo jeito.
   Os ossos do Miguel já têm os nomes do perfil (`Hips`, `LeftUpperArm`…). Sem
   isso, braços e pernas podem sair torcidos.
2. **Máquina de estados.** Troque as chamadas manuais de `anim.play()` em
   `capitulo1/ator.gd` e `prototipo/actor.gd` por uma AnimationTree:
   - parado ↔ andar ↔ correr, com blend pela velocidade;
   - agachado;
   - ações únicas que voltam sozinhas ao movimento;
   - subir/descer escada.
3. **Loop provado por teste:**
   - último quadro ≈ primeiro;
   - quadril sem degrau;
   - pé sem escorregar (velocidade do jogo casada com o passo do clipe).
   O bug antigo: o clipe "Running" era uma arrancada tocada em loop.
4. **Interações:**
   - ponto de encaixe em portas, mesa da bolsa, armários e portão;
   - evento no quadro de contato;
   - empurrão (Push / Hit_Knockback / Sweep_Fall / LayToIdle) e agarrão
     (Zombie_* / Stunned) alinhando os dois personagens.
5. **Ainda faltam do Mixamo** (pedir a Felipe): agachar, espiar, agarrar,
   ser agarrado, se soltar, olhar em volta procurando, facada.

Skills úteis em `.claude/skills/`:
- `godot-animation-tree-mastery`
- `godot-animation-player`
- `godot-state-machine-advanced`
- `game-dev-combat-animation` (testes quadro a quadro)

## Testes (rodar antes de entregar)

No Linux, instale o Godot 4.5.1 e defina `GODOT`:
- `scripts/testar-capitulo1.sh`
- `scripts/testar-prototipo.sh`
- `scripts/testar-percurso.sh` (e `--patio`)
- `tests/capitulo1_nivel_test.gd`
- `tests/capitulo1_mapa_test.gd`
- `tests/capitulo1_toque_test.gd`

Web/celular: `scripts/exportar-web.sh` gera a build. A publicação é por PR
para a `main`, na pasta `capitulo1/`.
