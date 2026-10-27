# Miguel — super prompt do lote 4

Como usar: abra uma conversa nova no ChatGPT, anexe `base-aprovada.png` e
`KIT-REFERENCIA.png`, cole o **CABEÇALHO** inteiro e depois **um** bloco de
animação. Uma animação por pedido. Se sair errado, responda só com o número do
quadro e o que corrigir (não peça a folha inteira de novo).

Vocabulário escolhido para não travar nas diretrizes: tudo é "luta esportiva
de videogame", "parceiro de treino", sem sangue, sem ferimento, sem dor
exagerada. Sangue, faísca e poeira o jogo desenha por cima.

---

## PROMPT ÚNICO v2 (todas de uma vez, mesma conversa)

Reescrito depois da 1ª geração (27/10). Fraquezas observadas e como o prompt
ataca cada uma:

| Fraqueza da 1ª geração | Resposta no prompt |
| --- | --- |
| Tudo numa imagem, com títulos dentro | Uma imagem por animação, sem texto dentro da imagem |
| Andar = quadros quase iguais | Medidas em "pés" e "cabeças", teste de silhueta, diferença obrigatória |
| Correr virou trote/largada | Silhueta de cada quadro descrita e lista de proibições |
| Pixels em px ignorados | Medidas relativas ao corpo, não em pixels |
| Vira de frente / de costas sozinho | "Câmera de perfil travada", proibido girar se não estiver escrito |
| Numeração pulada ou repetida | Contar em voz alta antes e conferir depois |
| 340 mil cores, borda suave, sombra rosa | Paleta limitada, sem degradê, sem sombra, sem brilho |

Cole o bloco abaixo, depois o CABEÇALHO e depois as seções, numa mensagem só,
com o MASTER anexado.

```
STRICT MODE. The attached MASTER image is the official model of Miguel. Follow this prompt to the letter. Do not interpret creatively, do not simplify, do not "improve".

KNOWN MISTAKES FROM YOUR PREVIOUS ATTEMPT — DO NOT REPEAT THEM:
1. You put all animations in ONE big image with titles inside. WRONG. Each animation is its OWN separate image. No titles, no labels, no text inside the image except the small frame numbers above the cells.
2. Your walking frames were almost identical. WRONG. Consecutive frames must look clearly different: if I covered the numbers, a person must be able to put the frames in order by looking at the feet.
3. Your run became a jog and a crouching start. WRONG. Follow the silhouette described for each frame.
4. The character turned to face the camera or turned his back. WRONG. The camera is locked in PROFILE (side view) in every frame. He never shows his chest or back to the camera unless the text explicitly says "turns his back".
5. Frame numbers were skipped or repeated (5,5 / no 5 / 10,10). WRONG. Before drawing, write the list of frame numbers you will draw; after drawing, count the cells.
6. Soft shading, gradients, glow and pink shadows under the feet. WRONG. Flat pixel-art colors only, no shadows, no glow, no smudges on the background.

WORKFLOW:
- First draw one single cell: Miguel in fighting guard copied from the MASTER (style anchor).
- Then generate the animations in the listed order, one image each, all in this reply, one after another. Before each image write: "Animation X of Y: <name>, N frames: 1,2,3...N". After each image write: "Check: N cells counted / side view in all / magenta only / same scale as anchor". If a check fails, redraw that image before moving on.
- If you reach a limit, stop after a complete image; I will type "continue".
- When I type "fix X: <note>", redraw only animation X.
- Never change the character design between images. Compare each image with the MASTER and the anchor before drawing the next.
```

---

## CABEÇALHO v2 (colar sempre)

```
Pixel art sprite animation for a 2D side-view sports fighting video game. No blood, no injuries, no gore: this is a sport/martial-arts animation.

INSPIRATIONS (for MOTION, TIMING and POSES only, never for the character's look): the readable anticipation, contact and recovery poses of Street Fighter III: 3rd Strike; the punchy combos, grabs and throws of Streets of Rage 4 and River City Girls; the clinch, ground strikes and realistic MMA strikes of EA Sports UFC; the weight and stumbling hit reactions of Sifu. Miguel's design, colors and pixel style come ONLY from the MASTER image.

CHARACTER: Miguel, exactly as in the MASTER: curly dark-brown hair volume, skin tone, white short-sleeve polo shirt with green band at the bottom and green collar details, light-blue jeans, grey/white sneakers. Same head size, proportions, outline and palette. Do not redesign him.

IMAGE FORMAT (mandatory):
- One image per animation. One single horizontal row of N equal cells, small frame number ABOVE each cell, nothing else written anywhere.
- Each cell 128 x 96 pixels. Background flat pure magenta #FF00FF in the whole image, no floor, no shadow, no motion lines, no dust, no effects.
- Real pixel art: hard pixel edges, no anti-aliasing, no gradients, no soft shading, no glow, at most 48 colors in the whole image.
- Character faces RIGHT, camera locked in profile (side view) in every cell.
- Same scale in every cell and every image: in fighting guard he is about 2/3 of the cell height, the soles of his feet always on the same invisible ground line near the bottom of the cell, his hips near the horizontal center of the cell.

MEASUREMENTS: use the body as the ruler, not pixels. "1 foot" = the length of his sneaker. "1 head" = the height of his head.

MOTION RULES:
- Consecutive frames must be visibly different. Exaggerate the key pose of each frame.
- A foot planted on the ground stays exactly in the same place until the text says it lifts.
- Never spin, turn around, face the camera or show the back unless the text says so.
- FAR arm and FAR leg (away from the camera) always one shade darker than the near ones, so left and right are readable in every frame.
- First and last frame of every loop/attack = the guard pose of the MASTER (except falls).
```

## 1. Andar em guarda — frente (6 quadros, loop)

```
ANIMATION: walking forward in fighting guard (boxer's step-drag), loop, 6 frames.
Fists up at the chin in ALL frames. Left foot is the front foot. Normal stance width = 2 feet between the heels.
1. Guard: heels 2 feet apart, both feet flat.
2. Front foot LIFTED clearly off the ground (toe up, knee bent), moving forward. Back foot flat.
3. Front foot lands 1 foot further forward: WIDE stance, heels 3 feet apart. Body leaning slightly forward.
4. Back foot LIFTED clearly (heel up, knee bent), being dragged forward. Front foot flat, did not move.
5. Back foot still in the air, close to normal distance.
6. Back foot lands: heels 2 feet apart again, same pose as frame 1.
Silhouette test: frame 3 is the widest stance, frames 2 and 4 each show ONE foot in the air. If frames look the same, it is wrong.
```

## 2. Andar em guarda — trás (6 quadros, loop)

```
ANIMATION: walking backward in fighting guard, loop, 6 frames. Fists up at the chin in ALL frames.
1. Guard: heels 2 feet apart.
2. BACK foot LIFTED clearly, moving backward. Front foot flat.
3. Back foot lands 1 foot further back: WIDE stance, heels 3 feet apart.
4. FRONT foot LIFTED clearly, being pulled back. Back foot flat, did not move.
5. Front foot still in the air.
6. Front foot lands: heels 2 feet apart, same pose as frame 1.
Silhouette test: frame 3 widest; frames 2 and 4 each show one foot in the air, a different foot each.
```

## 3. Correr (8 quadros, loop)

```
ANIMATION: full sprint, side view, loop, 8 frames. NOT a jog, NOT a crouching start, NOT a walk.
Whole body leans forward (like falling forward) in every frame. Hands are loose fists, NOT in guard. Elbows bent like an L. Arms swing opposite to legs: when the left leg is forward, the right arm is forward.
1. CONTACT: right heel touches the ground 1 foot in front of the hips, right leg almost straight. Left leg behind, knee bent, left foot in the air behind. Left arm forward, right arm back. Silhouette: a wide upside-down V.
2. DOWN: right foot flat under the hips, right knee bent, body at its lowest. Left heel kicked up high behind, near the buttocks.
3. PASSING: right leg under the body pushing; left knee swinging forward past the right knee.
4. FLIGHT: BOTH FEET OFF THE GROUND. Left thigh high in front (knee at hip height), right leg stretched behind. Body at its highest. Silhouette: a running split in the air.
5. CONTACT, opposite legs: left heel touches ground in front, right leg behind in the air. Right arm forward, left arm back.
6. DOWN, opposite legs: left foot flat, right heel kicked up behind.
7. PASSING, opposite legs.
8. FLIGHT, opposite legs: BOTH FEET OFF THE GROUND, right thigh high in front.
LEG ORDER (your previous run was wrong: frames 1-4 all had the same leg forward and frames 5-8 repeated the other half, arms frozen):
- FAR leg and FAR arm (the ones away from the camera) are drawn one shade DARKER than the near ones, in every frame, so the two legs can be told apart.
- Frames 1-4: the NEAR (lighter) leg is the one touching the ground in front; frames 5-8: the FAR (darker) leg touches the ground in front.
- Arms: frames 1-4 FAR arm forward, NEAR arm back; frames 5-8 NEAR arm forward, FAR arm back. The forward fist must change sides between frame 4 and frame 5.
- Frames 1 and 5 look like mirror images of each other's legs; same for 2/6, 3/7, 4/8.
FORBIDDEN: the same leg in front in all frames; both feet on the ground in the same frame; both legs straight; arms frozen; fists in guard; crouching start; upright posture.
```

## 4. Arrancada (5) e freada (5)

```
ANIMATION A: run start from guard, 5 frames.
1. Guard. 2. Lowers hips, leans forward, arms drop from guard. 3. Back foot pushes, front knee drives forward. 4. First running stride (like run frame 4, both feet in the air). 5. Same as run frame 5 (so it connects to the run loop).
ANIMATION B: run stop, 5 frames.
1. Same as run frame 1. 2. Front foot plants far ahead with the heel, front leg straight, torso leans BACKWARD (shoulders behind the hips, like pulling a brake). 3. Back foot comes forward, knees bent, arms come up. 4. Wide braking stance, almost stopped. 5. Fighting guard (same as reference guard).
```

## 5. Bloqueio alto (6)

```
ANIMATION: high block, side view (NOT facing the camera), 6 frames.
1. Guard. 2. Both forearms rise in front of the face, elbows tight to the ribs, chin down. 3. Full cover: forearms vertical in front of the face, eyes visible between them. 4. Impact absorbed: whole body pushed 2 px back, back knee bends a little, feet stay planted. 5. Same as 3. 6. Back to guard.
```

## 6. Reação leve na cabeça (5)

```
ANIMATION: light hit reaction to the head (sport sparring, no injury), 5 frames. Feet do not move. Camera stays in profile: only the HEAD turns, the body never faces the camera.
1. Guard. 2. Head turns away (to the left), chin up a little, guard opens slightly. 3. Head and shoulders 4 px back, eyes closed. 4. Coming back, fists rising. 5. Guard.
```

## 7. Reação forte na cabeça (7)

```
ANIMATION: strong hit reaction to the head, 7 frames. He keeps facing RIGHT in all frames (pushed backward, not turned around).
1. Guard. 2. Head snaps back hard, arms fly open. 3. Torso leans back 15 degrees, back foot steps back 8 px. 4. Front foot slides back to follow. 5. Stumbling, knees bent, arms low. 6. Raising guard. 7. Guard, 8 px further back than frame 1.
```

## 8. Reação no corpo (6)

```
ANIMATION: hit reaction to the stomach, 6 frames. Feet planted.
1. Guard. 2. Body folds forward at the waist, elbows drop to protect the ribs. 3. Most folded: head lower by 6 px, back rounded. 4. Starting to straighten, still elbows low. 5. Almost upright. 6. Guard.
```

## 9. Reação na perna (6)

```
ANIMATION: hit reaction to the front thigh, 6 frames.
1. Guard. 2. Front knee buckles inward, body drops 4 px. 3. Weight shifts to the back leg, front foot barely touching. 4. Front foot plants again. 5. Straightening. 6. Guard.
```

## 10. Queda de costas (6) + deitado (2) + levantar (7)

```
ANIMATION A: falling backward (sport knockdown), 6 frames.
1. Strong hit pose (head back, arms open). 2. Feet slide forward, body falls back at 45 degrees. 3. Buttocks touch the ground. 4. Back hits the ground, legs up a little. 5. Lying on the back, head on the LEFT side of the cell, feet on the right. 6. Still lying, relaxed.
ANIMATION B: lying on the back, loop, 2 frames: chest rises 1 px and goes down. Head on the left.
ANIMATION C: getting up to guard, 7 frames.
1. Lying (same as B). 2. Rolls to one side, one elbow on the ground. 3. Sitting, one hand on the ground. 4. One knee on the ground, other foot planted. 5. Pushing up with the legs. 6. Standing, fists rising. 7. Guard (exact reference guard).
```

## 11. Chute alto (12)

```
ANIMATION: roundhouse kick to the head height, 12 frames. Contact on frame 6.
1. Guard. 2. Weight shifts to the front (left) foot. 3. Left foot pivots on the ball, heel turns forward. 4. Right knee rises to chest height, pointing forward. 5. Hips turn, right leg starts to extend. 6. CONTACT: right leg fully extended, the instep at the height of the opponent's FACE/CHIN (the same height as his own mouth), NOT above the head, body leaning back to the left, arms protecting the face. 7. Same as 6, slightly further. 8. Leg folds back, knee high in front, he still faces right. 9. Knee comes down. 10. Right foot lands behind in stance. NO spin, he never turns his back in this kick. 11. Back to stance. 12. Guard.
The supporting left foot stays on the same pixel in frames 2-10.
```

## 12. Jab com passo (8) e direto com passo (9)

```
ANIMATION A: stepping jab, 8 frames, contact frame 4.
1. Guard. 2. Front foot lifts and moves forward while the left fist starts to extend. 3. Front foot lands 10 px ahead, arm 3/4 extended. 4. CONTACT: left arm fully extended at chin height, shoulder covering the chin. 5. Arm retracting. 6. Back foot slides forward 10 px. 7. Guard stance. 8. Guard (body 10 px further forward than frame 1).
ANIMATION B: stepping cross, 9 frames, contact frame 5: same idea with the RIGHT hand, hips and shoulders rotating, back heel lifting, travel 12 px.
```

## 13. Gancho (9), jab no corpo (8), uppercut (9), cotovelada (8)

```
ANIMATION A: left hook to the head, 9 frames, contact 5. Elbow at shoulder height, forearm horizontal, fist travels in an arc from the side (NOT straight forward). Front foot pivots on the ball. 1 guard, 2-3 shoulder loads back, 4 arm swinging, 5 CONTACT fist in front of the chin line with the arm bent 90 degrees, 6-8 return, 9 guard.
ANIMATION B: jab to the body, 8 frames, contact 4. Knees bend so the head goes 8 px lower; left arm extends straight at stomach height.
ANIMATION C: uppercut, 9 frames, contact 5. Knees dip, right fist comes from the hip upward, palm facing him, ends at chin height in front of the body.
ANIMATION D: elbow strike, 8 frames, contact 4. Short range: right elbow swings horizontally at head height, fist near his own ear.
```

## 14. Esquivas (6 e 8), aparo (8), grogue (6)

```
ANIMATION A: lean back dodge, 6 frames. Feet planted; torso leans back 20 degrees, head 8 px back, guard stays up, then returns.
ANIMATION B: slip to the side + counter, 8 frames, contact 6. Head moves down and to the left, then the right fist counters straight (like a cross).
ANIMATION C: parry + counter, 8 frames, contact 5. Left open hand slaps a punch aside to the left (frames 2-3), right hand counters straight (frames 4-5), back to guard.
ANIMATION D: dazed, loop, 6 frames. Guard low at chest height, knees soft, body sways 2 px left and right, eyes half closed. Feet stay planted.
```

## 15. Clinch e arremesso (folhas em PAR)

Gerar as duas folhas de cada par na mesma conversa. Mesma quantidade de
quadros, mesmo quadro de contato. O parceiro é o adversário de treino
(anexar a referência dele, ou usar "a generic sparring partner in grey
t-shirt and dark pants" se não tiver).

```
PAIR A — arm drag throw, 10 frames each, contact frame 6.
Sheet 1 (Miguel): 1 guard, 2 left hand reaches forward at chest height, 3 grips the opponent's wrist, 4 steps in with the right foot and turns his back slightly, 5 pulls the arm across his body, 6 hips under the opponent, rotating, 7 pulling down, 8 opponent lands, Miguel kneels on one knee, 9 releases, 10 stands back in guard.
Sheet 2 (opponent being thrown, faces LEFT): 1 guard, 2-3 wrist grabbed, 4 pulled off balance forward, 5 feet lifting, 6 body horizontal in the air, 7 falling, 8 back on the ground, 9-10 lying.

PAIR B — collar tie and knee strikes, 8 frames each, contact frames 4 and 7.
Sheet 1 (Miguel): both hands behind the opponent's neck (muay thai clinch), pulls the head down, right knee rises to the stomach (4), knee down (5), pull again (6), knee again (7), back to clinch (8).
Sheet 2 (opponent): held by the neck, bends forward a little more on frames 4 and 7, hands on Miguel's arms.

PAIR C — throw into the locker, 10 frames each, contact 7. Miguel grabs both shoulders, turns and pushes the opponent backward; the opponent's back hits an invisible wall at the right edge of the cell on frame 7 and slides down to sitting on frames 8-10.
```

## 16. Golpes no chão (folhas em PAR)

```
PAIR D — mount, ground strikes (MMA sport style), loop 6 frames, contacts 3 and 6.
Sheet 1 (Miguel): kneeling on top, knees on both sides of the opponent's torso, alternating straight punches downward (left on 3, right on 6).
Sheet 2 (opponent): lying on the back under him, forearms covering the face, head turns a little on 3 and 6.

PAIR E — side position hammer fist, 8 frames, contact 4. Miguel on one knee beside the opponent's head, hand comes down like a hammer. Opponent lying, forearm covering.

PAIR F — ground kick, 8 frames, contact 4. Miguel standing next to the lying opponent, kicks the side of the torso with the instep (soccer-style). Opponent curls up on 4-5.

PAIR G — lift by the collar, 10 frames. Miguel bends, grabs the opponent's shirt collar with both hands, pulls him up to standing (frames 2-7), opponent ends in a dazed standing pose (frame 10). This restarts the fight sequence.
```

## 16B. Combos e finalizações (pressão total)

Cada combo é UMA folha contínua (o jogo usa como golpe único). Pares: duas
folhas, mesmo número de quadros, mesmos contatos.

```
COMBO 1 — jab, elbow, knee, 12 frames, contacts 3, 7, 11. Miguel alone. Jab at chin height (3), steps in, right elbow swings horizontally at head height (7), grabs with both hands at the opponent's shoulder height and drives the right knee up to chest height (11), back to guard (12).

COMBO 2 — body shots into uppercut, 14 frames, contacts 3, 6, 9, 12. Knees bent low: left hook to the stomach (3), right hook to the stomach (6), left hook to the stomach (9), explodes upward with a right uppercut, both feet leaving the ground slightly (12), lands in guard (14).

COMBO 3 — low kick into high kick, 14 frames, contacts 4 and 11. Right shin to the thigh at knee height (4), foot returns behind (6), immediately a right roundhouse to head height (11), lands in guard (14).

COMBO 4 — superman punch, 10 frames, contact 6. Fakes a knee with the right leg (2-3), kicks the leg back while jumping forward (4-5), right fist extends at head height in the air (6), lands 16 px forward (8), guard (10).

PAIR H — collar grab and three punches, 16 frames each, contacts 5, 8, 11 and push on 14.
Sheet 1 (Miguel): left hand grabs the opponent's shirt collar (2-3), right straight punches to the face (5, 8, 11) while still holding, pushes him away with both hands (14), guard (16).
Sheet 2 (opponent, faces LEFT): held by the collar, head snaps back on 5, 8 and 11, legs getting weaker each time, pushed away and falls on the back (14-16).

PAIR I — clinch headbutt, 8 frames, contact 5. Miguel holds both shoulders, pulls the opponent forward and hits forehead to forehead (5). Opponent's head snaps back, knees bend (6-8).

PAIR J — sweep, 8 frames, contact 4. Miguel drops low and sweeps the opponent's front foot with his right leg (4). Opponent's feet leave the ground, body horizontal (5-6), lands on the back (7-8).

PAIR K — suplex / body slam, 12 frames, contact 9. Miguel wraps both arms around the opponent's waist from the front (2-4), lifts him to shoulder height (5-7), slams him on his back (9), Miguel kneels next to him (10-12). Opponent: lifted, upside down at the top (7), flat on the back (9-12).

PAIR L — finisher on the ground, 16 frames, contacts 4, 7, 10, 13. Miguel jumps into mount (1-3) and throws alternating downward punches (4, 7, 10, 13), stands up and raises a fist (15-16). Opponent: covering, guard getting weaker on each hit, arms drop and he is knocked out lying flat (14-16).

PAIR M — soccer kick on the downed opponent, 9 frames, contact 5. Miguel runs two steps and kicks the side of the lying opponent's torso (5). Opponent rolls half a turn away (5-9).

PAIR N — standing knockout reaction (opponent only), 8 frames. Hit on the chin, eyes go blank, knees give out, falls face-first straight down, lying face down at the end.
```

## 16C. Golpes extras (arsenal completo)

```
MOVEMENT
- Quick dash forward, 5 frames: low lunge step, travels 24 px, ends in guard.
- Quick backstep, 5 frames: hop back 20 px, guard up.
- Turn around, 4 frames: from facing right to facing left in guard (frame 4 faces LEFT).
- Circle/feint, 6 frames: shoulder and front hand fake a jab without extending, feet planted.

PUNCHES
- Spinning backfist, 10 frames, contact 6: turns his back (3-4), right arm swings with the back of the fist at head height (6).
- Check hook while stepping back, 9 frames, contact 5: pivots on the front foot, body turns 45 degrees away, left hook.
- Lead uppercut to the body, 8 frames, contact 4.
- Hammer fist standing (downward), 8 frames, contact 5.
- Double punch 1-2 in one sheet, 10 frames, contacts 3 and 7.
- 1-2-3 (jab, cross, hook) in one sheet, 14 frames, contacts 3, 7, 11.

KICKS
- Teep (front push kick) to the stomach, 9 frames, contact 5: knee up, sole of the foot pushes straight forward, body leans back.
- Oblique kick to the front knee, 8 frames, contact 4: stomping sole at knee height.
- Calf kick, 9 frames, contact 5: shin hits the lower leg at 20 px above the ground.
- Switch kick (left leg roundhouse to the body after a quick stance switch), 11 frames, contact 6.
- Spinning back kick to the stomach, 12 frames, contact 7: turns his back, right heel thrusts straight back-to-forward.
- Axe kick, 11 frames, contact 6: leg rises straight above head height, heel comes down.
- Flying knee, 10 frames, contact 6: two running steps, jumps, right knee at head height in the air.
- Jumping front kick, 10 frames, contact 6.

DEFENSE AND COUNTERS
- Low block / leg check, 6 frames: front knee lifts and turns out to absorb a low kick.
- Body block, 6 frames: elbows down covering the ribs, slight crouch.
- Catch the kick + sweep (PAIR), 12 frames, contact 9: Miguel traps the opponent's kicking leg under his arm (4-6), sweeps the standing leg (9). Opponent: leg caught, hops, falls on the back.
- Duck under + body hook, 9 frames, contact 6: ducks 12 px low, comes up with a left hook to the body.
- Roll with the punch, 6 frames: head turns with the impact, then returns.

CLINCH / WALL
- Wall pin knees (PAIR), 10 frames, contacts 4 and 8: opponent's back against an invisible wall on the right edge, Miguel pins him with the left forearm on the chest and throws right knees to the body.
- Double-leg takedown (PAIR), 12 frames, contact 8: Miguel changes level, steps deep, grabs both legs behind the knees, lifts and drives the opponent to his back.
- Body lock and trip (PAIR), 12 frames, contact 8.
- Break the clinch: push with both hands, 6 frames.

GROUND
- Ground and pound from standing over the opponent's guard (PAIR), 8 frames, contacts 4 and 7.
- Elbows from mount (PAIR), loop 6 frames, contacts 3 and 6.
- Getting mounted: bucking the hips to escape (opponent side), 8 frames.
- Back roll recovery to guard, 7 frames.
- Kip-up (jump from the back to standing), 8 frames.

EXTRA REACTIONS
- Hit while blocking low, 5 frames.
- Blocked kick bounce (attacker), 6 frames: leg bounces off the guard, steps back.
- Bounce off the wall (back hits the right edge and rebounds forward), 8 frames.
- Spin-around reaction (hard hook turns him 3/4 around), 8 frames.
- Kneeling dazed (one knee down, trying to get up), loop 4 frames.
- Face-down knockout lying, loop 2 frames.
```

## 17. Bom ter

```
- Taunt: waves "come here" with the front hand, 8 frames.
- Wipe the mouth with the back of the hand, 8 frames.
- Victory: raises one fist, 8 frames.
- Defeat: down on both knees, head low, 6 frames.
- Crouch (4) + crouching punch (8, contact 4).
- Jump (6) + flying knee (10, contact 6).
```

## Ao receber (checklist do agente)

1. Contar quadros e conferir a numeração.
2. Comparar com a base: cabeça, altura da guarda 66 px, paleta, contorno.
3. Recortar (`scripts/miguel-lote3/recortar.py`), padronizar, alinhar pelo
   tronco e extrair marcadores.
4. Correr/andar: medir a passada pelos pés antes de integrar.
5. Pares: conferir que os quadros de contato coincidem.
