# GAVIÃO — visão do jogo (anotado em 30/10/2026, conversa com o Felipe)

Documento vivo: guarda as decisões e ideias para as próximas rodadas.
Leia junto com `AGENTS.md`, `arte/MIXAMO-ESTUDO.md` e `arte/ANIMACAO-MIGUEL.md`.

## Rumo técnico combinado
- **3D "disfarçado" (2.5D):** bonecos e cenário 3D no Godot, câmera fixa de lado,
  movimento num plano só (esquerda/direita, pular, subir), renderizado em baixa
  resolução (~320×180) sem suavização = cara de pixel art (Dead Cells / Fears to Fathom).
- **Todos os personagens no mesmo esqueleto do Mixamo** (Y Bot/X Bot de base ou modelo
  nosso rigado lá): qualquer animação serve em qualquer personagem.
- **Hitbox presa nos ossos** (punho, pé, joelho) e **marcador de contato na animação**;
  acaba a hitbox tirada de pixel.
- Máquina do Felipe: **MacBook Pro meados de 2014** → Godot 4 modo Compatibility,
  cena leve; medir FPS no protótipo antes de prometer. Alvo antigo: ThinkPad T400.
- O Felipe não tem experiência com 3D: ele **não mexe em 3D**. Fases são desenhadas
  como **mapa de texto/imagem de blocos** e um script gera o 3D.

## Estrutura do jogo
- Passar fases e **desbloquear um personagem do Gavião a cada fase**.
- Cada fase é um **lugar**; a 1ª é a **escola**; a de trabalho inicial será a
  **casa do Felipe** (ele manda planta e fotos).
- Mecânicas além da luta: **abrir porta, pular obstáculo, subir na parede**, pegar objeto.
- História ainda em aberto (a ideia "Alice sequestrada" foi **descartada por enquanto**).

## Personagens (o Gavião)
| Nome | Físico / estilo |
|---|---|
| **Felipe** (autor do jogo) | estatura média, mais largo e mais forte |
| **Sorriso** | franzino, um pouco mais baixo que o Felipe |
| **Miguel** | atlético, um pouco mais alto (modelo HD já existe: `arte/miguel_humano.py`) |
| **Bola** | esguio |
| Alessandro | a definir |
| Gelado | a definir |
| Caio ("Passa-Marcha") | a definir |
| Natan | a definir |
| coadjuvantes | a definir |
Cada um deve ter **jeito de lutar e habilidade própria** (ex.: força, agilidade, alcance).

## Combate — o que o Felipe quer
- **Agressividade**: luta pegada, de perto; **clinch** (agarrar, segurar, joelhada,
  arremessar) é prioridade de sensação. Já existe no duelo 2D (`m5_clinch*`); no 3D
  vira animação em par sincronizada.
- Tempos de golpe, hitbox e coesão entre personagens são o problema nº 1 a resolver.

## Próximos passos
1. Protótipo 2.5D: Miguel andando, pulando, abrindo porta, subindo em caixa; rival
   Y Bot; golpes com hitbox nos ossos; clinch básico.
2. Fase de teste em blocos → fase da casa do Felipe (planta + fotos).
3. Animações a pedir no Mixamo: Head Hit, Big Head Hit, Stomach Hit, Kidney Hit,
   Knocked Out, Getting Up (de costas), Throw, Low Kick, Front Kick, Boxing idle,
   Walking Backwards, Injured Idle, Running reto, Jump, Running Jump, Climbing,
   Opening Door.
