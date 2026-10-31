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

## Ideias aprovadas pelo Felipe (31/10)
**Golpes interligados**
- Cada golpe com 3 fases marcadas na animação: preparação → ativo (caixa ligada) → recuperação.
- Janela de emenda no começo da recuperação, só se o golpe tocou (acerto ou bloqueio);
  aperto antecipado guardado ~150 ms; golpe que erra não emenda (paga a recuperação).
- Tabela de emendas por personagem (identidade: Felipe curto e pesado → agarrão;
  Miguel soco → chute; Sorriso sequências rápidas e fracas).
- Mistura de 2–3 quadros entre animações ao emendar (sem voltar à guarda).

**Agressividade / impacto**
- Pausa no impacto (50–100 ms, maior no pesado); reação na direção do golpe.
- Pressão: quem ataca avança, quem apanha recua; parede pune o encurralado.
- Clinch como mini-luta (joelhada, soco curto, empurrar na parede, jogar no chão; escapar).
- Fôlego: atacar cansa e abre a guarda.

**Design**
- Luta e exploração no mesmo mundo (duelo 1×1 vira modo extra).
- Menos golpes, bem feitos: 6–8 por personagem + clinch, agarrão e esquiva.
- Habilidade de exploração por personagem (Felipe empurra/arromba, Miguel pula/sobe,
  Sorriso passa em lugar apertado, Bola alcança alto) → voltar a fases antigas.
- Trocar de personagem a qualquer hora após desbloquear; vida separada.
- Inimigos da escola/bairro (valentão, turma do fundão, inspetor).
- Tom: piada interna dos amigos + luta séria e pesada.

## Teste de desempenho no MacBook Pro 2014 (31/10)
`godot-3d/bench` (artifact "Teste 3D Gavião"), navegador dentro do Claude, com
Mixamo, YouTube e outro jogo 3D abertos: **11 Miguels HD (~27 mil faces cada),
sombra ligada, 640×360 → 29–30 FPS estáveis**. Conclusão: o 3D pixelado é viável
nessa máquina. Uma luta tem 2–4 personagens; alvo de jogo: 60 FPS em 320×180 ou
426×240. Medir de novo fora do navegador (export macOS) quando houver protótipo.

## Felipe ("Bungas") — referências recebidas (31/10)
`arte/referencias/felipe/`: 12 ângulos do corpo (vídeo girando), 18 fotos (rosto em
todos os ângulos, cabelo de cima e de trás, camiseta e short esticados), índices do
vídeo e tempos. Dados: **1,72 m, 72 kg, luta descalço**; camiseta preta da banda
Death (*Scream Bloody Gore*: logo vermelho na frente e nas costas, arte da capa na
frente), short preto. Cabelo preto cacheado volumoso (mais alto e cheio que o do
Miguel), sobrancelha grossa, cavanhaque ralo no queixo, pulseira no pulso.
Obs.: a arte da camiseta é de banda real; para o jogo publicado, considerar uma
estampa inspirada (mesmo clima, sem copiar logo/capa).
