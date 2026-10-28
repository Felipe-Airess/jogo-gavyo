# Direção do jogo — decisões combinadas com o usuário (28/10/2026)

Nada disto está implementado ainda. É o que foi decidido em conversa para as
próximas rodadas no Godot. Leia antes de propor mudanças de jogo ou de arte.

## Onde está o jogo hoje

- Godot nativo em `godot-poc/` (branch `feat/godot-combat-poc`, PR #8): duelo 1×1
  e corredor de treino, regras iguais ao Phaser (replays em `tests/`).
- Publicado em https://felipe-airess.github.io/jogo-gavyo/godot/ (pasta `godot/`
  na `main`; republicar = exportar e copiar `web/index.*`). Phaser segue na raiz.
- Sessão de origem: notebook "Office Estagio 3". Godot 4.5.1 e templates web em
  `work/godot-tools/` (não versionado; baixar de novo no outro notebook).

## Direção de arte

- A intenção sempre foi **rotoscopia bizarra**. O pixel art "fofo" veio do
  ChatGPT e é **provisório**.
- Lutadores devem sair de **vídeos gravados pelo próprio usuário**: tirar fundo,
  baixar resolução, poucas cores, contorno que "ferve" entre quadros, poucos
  quadros por segundo — e, em **momentos aleatórios**, virar algo **fluido**,
  quase vídeo, sem explicação (choque estilo Smiling Friends).
- Não é o "rig" de recorte que o usuário rejeitou (girar pedaços do sprite).
- Humor: o usuário achou as sugestões de piada de escola "sitcom" demais. Pedir
  referências dele antes de propor humor.
- Teste sugerido: o vídeo `35905.mp4` (golpes do Miguel) num jab/direto nesse estilo.

## História, personagens e progressão

- Protagonistas: **Sorriso, Felipe, Gelado, Bola, Alessandro, Miguel, Passa Marcha**.
- Vários cenários com história (não um cenário só com ondas). A cada fase você
  conversa com um protagonista e **libera ele para jogar**.
- Progressão libera **golpes cada vez mais violentos**.
- **Diálogos em vídeo**: chegar perto de um personagem abre o vídeo real dele,
  sem fundo e pixelado, com as falas.
- **Interromper falando com soco**: durante a fala de quem não é protagonista,
  o soco corta a fala (reação gravada à parte; pode mudar o diálogo, começar
  briga, encher a agressividade). Protagonistas não podem ser interrompidos.
- **Conquistas** e **modo infinito** = briga de sobrevivência com nocaute
  (o usuário concordou em não ser "matança": o elenco são pessoas reais).
- Combinar com cada amigo antes de usar nome e vídeo dele.

## Barra de agressividade (substitui a "barra de ânimo")

Quanto maior: mais rápido, menos recuo, mais dano, menos fôlego gasto,
animações diferentes, e libera **finalizar** o oponente. **Contador de combo
pela agressividade.** Proposta (sem objeção do usuário):
- Sobe pressionando (acertos, limpos valem mais, andar para frente, encurralar,
  aparar); sobe pouco ao apanhar; cai ao recuar, ficar na guarda/parado e ao errar.
- 3 níveis: +5/10/15% velocidade, −15/30/50% recuo, +5/12/20% dano, −10/20/30% fôlego.
- Nível 3 piora a defesa (aparo mais curto, guarda gasta mais). Golpe limpo
  sofrido derruba um nível.
- Nível 3 + oponente grogue/no chão: finalização em par que encerra o round e
  zera a barra; janela curta de escape.
- Arte de fúria vem das gravações; até lá, shader avermelhado e efeitos.

## Reforma do 1×1 (o usuário acha o duelo "muito ruim": frente/trás e caixas)

Causas encontradas: caixas adivinhadas pela cor dos pixels (punho 6×6),
alcance que depende do desenho, andar lento sem passo rápido, trás+J = gancho
mistura recuar e atacar, defesa num botão separado, empurrão frágil.
Proposta aceita como direção:
- Caixas feitas à mão por quadro no editor do Godot, golpe um pouco maior que o membro.
- Faixas de alcance definidas por golpe (curto/médio/longo).
- Passo rápido e recuo rápido com dois toques; trás não escolhe golpe.
- Corpo de largura fixa; empurrão definido no acerto e na defesa.
- **Pendente de escolha do usuário:** segurar trás para defender (L vira aparo)
  ou manter L como defesa.
- Primeiro um protótipo só de regras para jogar; depois caixas no editor.

## Rodadas planejadas (ordem por impacto)

1. Sensação do golpe (vibração, squash, partículas, brilho, som em camadas).
2. Controle e resposta (golpe imediato, botões de toque configuráveis, fila visível).
3. Mecânicas (esquiva, agachar do Miguel, parede, barra de agressividade, levantar).
4. Editor de animação e caixas; importação das gravações.
5. Treino (lista de golpes, replay, boneco configurável, desafios).
6. Cenário e apresentação (luz, paralaxe, câmera dinâmica, vitória/derrota).
7. Plataformas e online (APK/Windows, luta online com rollback).

## Áudio

O usuário toca guitarra e faz beats: ele faz músicas, falas e vozes.
Plano: temas em loop OGG com **faixas separadas** (beat, baixo, guitarra base,
riff) que entram conforme a agressividade; vinhetas curtas (round, K.O.,
vitória, liberado); falas usando o som do próprio vídeo. Ele manda WAV/MP3;
a conversão e o ajuste de loop ficam conosco.

## Tamanho estimado do jogo completo

~110–130 MB de arquivos (motor web 38 MB fixo); download web ~70–90 MB com
compressão; APK ~80–120 MB. O que pesa: vídeos dos diálogos e música.
