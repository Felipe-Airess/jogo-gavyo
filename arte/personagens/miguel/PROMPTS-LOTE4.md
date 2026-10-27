# Miguel — super prompt do lote 4

Como usar: abra uma conversa nova no ChatGPT, anexe `base-aprovada.png` e
`KIT-REFERENCIA.png`, cole o **CABEÇALHO** inteiro e depois **um** bloco de
animação. Uma animação por pedido. Se sair errado, responda só com o número do
quadro e o que corrigir (não peça a folha inteira de novo).

Vocabulário escolhido para não travar nas diretrizes: tudo é "luta esportiva
de videogame", "parceiro de treino", sem sangue, sem ferimento, sem dor
exagerada. Sangue, faísca e poeira o jogo desenha por cima.

---

## PROMPT ÚNICO (todas de uma vez, mesma conversa)

Uma imagem com tudo não funciona (400+ quadros: o gerador funde, pula e
encolhe quadros). A consistência vem de gerar tudo **na mesma conversa**, com
o mesmo cabeçalho. Cole o bloco abaixo, depois o CABEÇALHO e depois todas as
seções 1–17 de uma vez, numa mensagem só.

```
STRICT MODE. The attached MASTER image is the official model of Miguel. Follow this prompt to the letter: every rule, every frame count, every frame description, in the exact order written. Do not interpret creatively, do not simplify, do not add or remove frames, poses, effects, backgrounds, text or characters. Copy the MASTER exactly: same face, hair, clothes, colors, proportions, outline and pixel size. If a rule cannot be followed, say which one before drawing instead of ignoring it. Any sheet that breaks a rule is wrong and must be redrawn.

I am giving you the full production list for one character. Read everything first. Then work like a sprite artist on a production line:
- Generate ONE sprite sheet per image, in the order of the list (sheet 1 = section 1, and so on; sections with A/B/C or PAIR = one sheet per letter/side).
- Before each image, write one line: "Sheet X of Y: <name>, N frames".
- Generate ALL sheets in this same reply, one image after another, without stopping to ask. If you hit a limit, stop after a complete sheet and continue from the next one when I type "continue". When I type "fix N: <note>", redraw only that sheet with the fix.
- Every sheet must follow the SHEET FORMAT and CHARACTER rules exactly, and must look like it was drawn by the same artist on the same day as the reference images and as the previous sheets of this conversation: same head size, same proportions, same palette, same outline. Compare with the reference before drawing.
- Never change the character design between sheets.
Before sheet 1, draw one single cell of Miguel in fighting guard (128x96, magenta) copied from the MASTER as the style anchor, and compare every sheet against the MASTER and the anchor.
After each sheet, write a 1-line checklist: frames = N (as requested), magenta background, faces right, same scale, matches MASTER. If any item is no, redraw that sheet before moving on.
```

---

## CABEÇALHO (colar sempre)

```
Pixel art sprite sheet for a 2D side-view sports fighting video game (stylized, like classic 16-bit arcade fighting games). No blood, no injuries, no gore: this is a sport/martial-arts animation.

INSPIRATIONS (for MOTION, TIMING and POSES only, never for the character's look): the readable anticipation, contact and recovery poses of Street Fighter III: 3rd Strike; the punchy street-brawl combos, grabs and throws of Streets of Rage 4 and River City Girls; the clinch, ground-and-pound and realistic MMA strikes of EA Sports UFC; the weight and stumbling hit reactions of Sifu. Miguel's design, colors and pixel style come ONLY from the MASTER image.

CHARACTER: Miguel, the same boy from the attached reference images. Keep EXACTLY: curly dark-brown hair volume, skin tone, white short-sleeve polo shirt with green band at the bottom and green collar details, light-blue jeans, grey/white sneakers. Same head size, same body proportions, same outline thickness and same color palette as the reference. Do not redesign him.

SHEET FORMAT (mandatory):
- One single horizontal row of cells, numbered 1..N in small text ABOVE each cell (outside the cell).
- Each cell is exactly 128 x 96 pixels, flat pure magenta background (#FF00FF), no gradients, no floor, no shadow, no motion lines, no effects, no text inside cells.
- Character faces RIGHT in every cell.
- Character size: 66 pixels tall in fighting guard, the same scale in every cell.
- Ground line is invisible but fixed: the sole of the planted foot always touches y = 88 inside the cell. The body's balance point stays near x = 64 unless the animation says it travels.
- Hard pixel edges, no anti-aliasing, no blur, maximum 48 colors.
- Draw ONLY the frames I list, in this order, one pose per cell. Do not add, merge or skip frames.
- Foot rule: a foot that is on the ground must stay on the same pixel in consecutive frames until the text says it lifts.
```

---

## 1. Andar em guarda — frente (6 quadros, loop)

```
ANIMATION: walking forward in fighting guard (boxing shuffle step), loop, 6 frames.
Both fists stay up near the chin THE WHOLE TIME (they never drop). Torso slightly turned, left foot in front.
1. Guard stance, feet shoulder-width, both feet flat.
2. Front (left) foot lifts 3 px and slides forward.
3. Front foot lands 14 px further forward; back foot still planted -> wide stance.
4. Back (right) foot lifts 3 px and starts to follow.
5. Back foot slides forward, almost back to normal width.
6. Back foot lands; same stance as frame 1 but the whole body is 14 px further forward.
Head height changes at most 1 px. Arms do not swing.
```

## 2. Andar em guarda — trás (6 quadros, loop)

```
ANIMATION: walking backward in fighting guard, loop, 6 frames. Fists up the whole time.
1. Guard stance.
2. Back (right) foot lifts 3 px and moves back.
3. Back foot lands 14 px further back; front foot still planted -> wide stance.
4. Front foot lifts 3 px.
5. Front foot slides back.
6. Front foot lands; stance as frame 1, whole body 14 px further back.
```

## 3. Correr (8 quadros, loop) — atenção, foi o que mais saiu errado

```
ANIMATION: running cycle, side view, loop, 8 frames. This is a real sprint, not a jog and not a walk.
Body leans forward about 10 degrees for the whole cycle. Fists loose (not in guard), elbows bent at 90 degrees, arms swing OPPOSITE to the legs (left leg forward = right arm forward). Head bobs: lowest on frames 2 and 6, highest on frames 4 and 8.
1. CONTACT: right foot touches ground ahead of the hips (heel/midfoot), right leg almost straight; left leg behind, knee bent, left foot off the ground. Left arm forward, right arm back.
2. DOWN: right foot flat under the hips, right knee bent (body lowest); left knee coming forward, left foot high behind near the buttocks.
3. PASSING: right leg pushing, under the body; left knee passes the right knee, left foot at right-knee height.
4. UP / FLIGHT: right foot pushes off and leaves the ground (toe last); left thigh high and forward; BOTH FEET IN THE AIR, body highest.
5. CONTACT (mirror of 1): left foot touches ground ahead of hips; right leg behind, knee bent. Right arm forward, left arm back.
6. DOWN (mirror of 2): left foot flat, left knee bent; right foot high behind.
7. PASSING (mirror of 3).
8. UP / FLIGHT (mirror of 4): both feet in the air.
The supporting foot on frames 1-3 must stay on the same ground pixel while the body moves over it; same for frames 5-7. Each full cycle moves the body about 110 px (the game moves the sprite; inside the cells keep the hips near x = 64).
Do NOT draw both legs straight, do NOT draw both feet on the ground at the same time, do NOT draw a walking pose.
```

## 4. Arrancada (5) e freada (5)

```
ANIMATION A: run start from guard, 5 frames.
1. Guard. 2. Lowers hips, leans forward, arms drop from guard. 3. Back foot pushes, front knee drives forward. 4. First running stride (like run frame 4, both feet in the air). 5. Same as run frame 5 (so it connects to the run loop).
ANIMATION B: run stop, 5 frames.
1. Same as run frame 1. 2. Front foot plants far ahead, body leans BACK, heel skids. 3. Back foot comes forward, knees bent, arms come up. 4. Wide braking stance, almost stopped. 5. Fighting guard (same as reference guard).
```

## 5. Bloqueio alto (6)

```
ANIMATION: high block, side view (NOT facing the camera), 6 frames.
1. Guard. 2. Both forearms rise in front of the face, elbows tight to the ribs, chin down. 3. Full cover: forearms vertical in front of the face, eyes visible between them. 4. Impact absorbed: whole body pushed 2 px back, back knee bends a little, feet stay planted. 5. Same as 3. 6. Back to guard.
```

## 6. Reação leve na cabeça (5)

```
ANIMATION: light hit reaction to the head (sport sparring, no injury), 5 frames. Feet do not move.
1. Guard. 2. Head turns away (to the left), chin up a little, guard opens slightly. 3. Head and shoulders 4 px back, eyes closed. 4. Coming back, fists rising. 5. Guard.
```

## 7. Reação forte na cabeça (7)

```
ANIMATION: strong hit reaction to the head, 7 frames.
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
1. Guard. 2. Weight shifts to the front (left) foot. 3. Left foot pivots on the ball, heel turns forward. 4. Right knee rises to chest height, pointing forward. 5. Hips turn, right leg starts to extend. 6. CONTACT: right leg fully extended, shin/instep at the height of the TOP of his own head (about 60-64 px above the ground), body leaning back to the left, arms protecting the face. 7. Same as 6, slightly further. 8. Leg folds back, knee high. 9. Knee comes down. 10. Right foot lands behind. 11. Back to stance. 12. Guard.
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
