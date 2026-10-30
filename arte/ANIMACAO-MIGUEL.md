# Animações do Miguel: o que está errado e como fazer certo

Este documento explica por que as animações 3D atuais saem tortas e define o
método para refazê-las (no Blender, pelo ChatGPT/qualquer IA ou à mão), usando o
modelo `arte/miguel_humano.py`.

## 1. Os erros que vimos

| Sintoma | Causa no nosso código |
| --- | --- |
| No chute o braço entorta para trás, cotovelo invertido | IK do braço com polo (`cL`/`cR`) mal posicionado: o solver acha a outra solução e dobra o cotovelo ao contrário. |
| Perna "do Exorcista" (joelho/pé virado para trás) | IK da perna com polo do joelho (`jL`/`jR`) fixo atrás do corpo; quando o quadril gira 80° no chute, o polo fica do lado errado e o joelho vira. |
| Pé ao contrário de lado | Pé preso a uma rotação no mundo enquanto o quadril gira. |
| Corpo duro, reto, pose sem força | Poses descritas por números soltos (posições de mão/pé em metros) e não por pose de verdade; interpolação suave entre elas. |
| Começo atrasado (queda parada e depois despenca) | Amostramos a curva suave do 3D nos mesmos instantes do 2D. |
| Reação quase invisível | Ângulos pequenos demais; falta exagero. |

Resumo: o problema não é o boneco, é **como a pose é construída**. IK com polo
fixo + interpolação suave + valores pequenos.

## 2. Regras (seguir sempre)

1. **FK nos golpes, IK só para pé apoiado.** Braço e perna que golpeiam são
   girados osso a osso (FK). IK só no pé que está no chão, para ele não escorregar.
2. **Polo do joelho sempre à frente do joelho, na direção dos dedos do pé**; polo
   do cotovelo sempre atrás e para fora do cotovelo. Se usar IK, o polo acompanha a
   rotação do quadril (filho do quadril), nunca fixo no mundo.
3. **Limites de articulação** (nunca passar):
   - joelho e cotovelo: dobram só para um lado, 0° a 150°, nunca negativo;
   - quadril (coxa): -30° para trás a 120° para a frente, abertura lateral até 70°;
   - ombro: até 170° para cima, 50° para trás;
   - coluna: até 35° de torção somando Spine+Chest+UpperChest; pescoço até 45°.
4. **Animar por poses-chave** (o que jogos de luta fazem):
   - cada golpe tem 3 a 5 poses: guarda → antecipação → contato → recuperação → guarda;
   - a pose de **contato é segurada** 2 a 4 quadros; a antecipação, 2 a 3;
   - entre poses use 1 a 2 quadros de transição, **sem interpolação suave**
     (no Blender: interpolação *Constant* ou *Linear*);
   - golpe rápido (jab): pouca antecipação; golpe pesado: antecipação longa.
5. **Corpo inteiro participa:** soco começa no pé de trás, gira quadril, depois
   tronco, depois ombro e por último o punho. Chute circular gira o pé de apoio
   90° (calcanhar para o alvo), inclina o tronco para trás e o braço do mesmo
   lado desce para equilibrar (não vai para trás em ângulo estranho).
6. **Silhueta:** a pose tem de ser lida só pelo contorno, visto **de lado**
   (é a câmera do jogo). Membro que golpeia nunca fica escondido atrás do tronco.
7. **Exagero:** base 30% mais aberta que o real, torção maior, reação de cabeça
   de 25° a 40°, não 10°.
8. **Guarda do Miguel** (fotos `guarda_lado*.jpg`): punhos juntos na frente do
   rosto, cotovelos baixos e para dentro, ombros encolhidos, joelhos dobrados,
   pé esquerdo à frente, peso no meio.

## 3. Pipeline recomendado (tudo na nuvem, sem PC potente)

1. **Pose-guia:** gerar no ChatGPT/IA uma folha de poses-chave por golpe (imagem),
   usando o prompt da seção 4 e anexando `arte/renders/miguel_corpo_comparacao.png`.
   Serve de referência de pose, não de sprite final.
2. **Pose no 3D:**
   - Opção A (recomendada, grátis, no navegador): **Mixamo** (mixamo.com) — sobe o
     `.glb`/`.fbx` do Miguel, ele faz o rig automático e tem centenas de animações de
     luta feitas com captura de movimento (jab, cross, hook, roundhouse, knee,
     hit reaction, knockdown, get up). Baixe em FBX "without skin", 30 fps.
   - Opção B: **Cascadeur** (versão grátis) para ajustar poses com física.
   - Opção C: aqui no Claude Code (cloud): eu aplico as poses-chave por FK com os
     limites acima e renderizo.
3. **Retarget para o nosso rig** (`Hips, Spine, Chest, UpperChest, Neck, Head,
   Left/Right Shoulder, UpperArm, LowerArm, Hand, UpperLeg, LowerLeg, Foot, Toes`):
   os nomes já seguem o padrão humanoide do Godot/Mixamo, então o mapeamento é 1:1.
4. **Sprites:** `arte/miguel_sprites.py` renderiza de lado, sem anti-aliasing, e
   gera atlas + marcadores. Mudança necessária: escolher **as poses-chave** do
   clipe (não amostrar a curva) e segurar o quadro de contato.
5. **Conferir:** folha de comparação 2D × 3D e checklist da seção 5 antes de ir
   para o jogo.

## 4. Prompt para o ChatGPT (folhas de pose)

Ver `arte/PROMPT-ANIMACOES-GPT.txt`.

## 5. Checklist por animação

- [ ] Cotovelo e joelho dobram para o lado certo em todos os quadros.
- [ ] Pé de apoio não escorrega e aponta para onde o corpo gira.
- [ ] Contato segurado 2–4 quadros; antecipação visível.
- [ ] Silhueta legível de lado; o membro do golpe está fora do tronco.
- [ ] A mão que não golpeia volta para a guarda (rosto).
- [ ] Duração e quadro de contato iguais aos do clipe 2D (`assets/miguel.json`).
