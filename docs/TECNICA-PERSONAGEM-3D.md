# Técnica padrão: personagem 3D a partir de fotos

Padrão do projeto para criar os personagens do Gavião (Felipe foi o primeiro;
Miguel, Sorriso, Bola, Alessandro, Gelado, Caio, Natan vêm depois). Tudo roda na
nuvem, por script, sem ninguém mexer em 3D. Implementação de referência:
`arte/felipe_humano.py`, `arte/felipe_rosto.py`, `arte/felipe_cabelo.py`,
`arte/felipe_comparar.py`.

## Ideia em uma frase

Corpo base do MakeHuman (CC0) → **rosto deformado até bater com as fotos por
pontos** (MediaPipe, 478 pontos) e pelo contorno do perfil → cabelo, pele e
roupa medidos nas fotos → rig de 22 ossos com nomes do Mixamo → `.glb`/`.fbx`.

Não é escaneamento 3D (sem sensor de profundidade nem fotogrametria). O nome
técnico é **ajuste de malha por landmarks a partir de duas fotos**.

## 1. Fotos que o amigo precisa mandar

A qualidade do resultado depende mais disto do que do código.

| Foto | Como tirar | Para quê |
|---|---|---|
| Rosto de frente | olhando reto, expressão neutra, boca fechada, **de ~1 m** (não selfie de braço) | 478 pontos, sobrancelha, lábios, pele |
| Rosto de perfil (os dois lados) | cabeça reta, **parede lisa e clara atrás** | contorno de nariz, boca e queixo |
| Rosto 3/4 | para conferir | comparação |
| Cabelo de cima e de trás | | volume do cabelo |
| Vídeo girando no lugar | corpo inteiro, câmera parada a ~3 m, fundo liso | silhueta do corpo e do cabelo sem distorção |
| Roupa esticada no chão | de cima, bem iluminada, frente e costas | estampa da camiseta |
| Altura, peso, se luta descalço | texto | escala e físico |

Regras: luz forte e difusa (janela, sem sombra dura no rosto); cabelo sem
boné; sem óculos; testa visível ou franja natural. **Selfie de perto engana:**
no Felipe ela encolheu o cabelo ~20% na altura e ~27% na largura e aumenta o
nariz. Use selfie só para alinhar pontos do rosto; tamanhos vêm das fotos de
longe. Salvar em `arte/referencias/<nome>/` com um `LEIA-ME.txt`.

## 2. Passo a passo

Ambiente (uma vez por sessão):
```bash
python3 -m venv ~/venv && ~/venv/bin/pip install bpy pillow numpy scipy scikit-image mediapipe
apt-get install -y libegl1 libgl1-mesa-dri   # (apt-get update antes, se falhar)
curl -o ~/face_landmarker.task https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task
export FACE_LANDMARKER=~/face_landmarker.task
```

Para um personagem novo, copie os três `felipe_*.py` para `<nome>_*.py` e troque
caminhos de fotos e parâmetros.

1. **Corpo** (`<nome>_humano.py`): `ALTURA`, `MACRO` (idade, peso, músculo,
   etnia do MakeHuman), `FORMA` só para o corpo (ombro, quadril, pescoço).
   Não tente acertar o rosto por `FORMA`: foi o erro do Miguel.
2. **Rosto** (`<nome>_rosto.py`), rodar 3 vezes e conferir:
   ```bash
   python arte/felipe_rosto.py --zerar --sem-perfil   # 1ª passada, só frente
   python arte/felipe_rosto.py --sem-perfil           # 2ª e 3ª: o desvio cai (2,7 → 0,8 mm)
   python arte/felipe_rosto.py                        # passada com o perfil
   python arte/felipe_rosto.py --checar DIR           # não grava: foto | modelo | sobreposição
   ```
   Grava `<nome>_rosto.target.gz`, `_rosto_pintura.json`, `_fotos_alinhamento.json`.
3. **Cabelo** (`<nome>_cabelo.py`): `MIOLO = "fatias"` (silhuetas das fotos por
   fatia, camada mínima no topo). Ajustes: `ALTURA_LADO`, `TOPO_MIN`, `EXPOENTE`.
4. **Pele**: medir a mediana das bochechas (pontos 50, 280, 205, 425, 101, 330
   do MediaPipe) em várias fotos e pôr em `PELE` (linear). O render usa
   exposição +1,38 para a cor na imagem bater com a foto.
5. **Roupa**: peças separadas cortadas da pele (`fazer_camiseta`, `fazer_short`),
   estampa recortada da foto da roupa e projetada.
6. **Comparar e exportar**:
   ```bash
   python arte/felipe_humano.py -- --render DIR
   python arte/felipe_comparar.py DIR corpo.png && python arte/felipe_comparar.py --rosto DIR rosto.png
   python arte/felipe_humano.py -- --glb arte/<nome>_boneco.glb --fbx arte/<nome>_boneco.fbx
   ```
7. **Testar o rig** com as animações já baixadas:
   ```bash
   python arte/miguel_mixamo.py -- --fbx arte/mixamo --humano <nome>_humano.py --previa DIR
   ```

## 3. Como funciona o encaixe do rosto

1. Renderiza a cabeça do modelo de frente e roda o **mesmo detector** no render
   e na foto. Como o ponto nº *i* é o mesmo nos dois, as correspondências saem
   automáticas, sem marcar nada à mão. Cada ponto do render vira um ponto da
   malha (raio da câmera até a pele).
2. Alinha a foto ao modelo (escala, giro, posição; Procrustes, mínimos quadrados).
3. Deslocamento de cada ponto = foto − modelo; **espelhado** (rosto simétrico).
4. Espalha nos vértices com pesos gaussianos (σ 12 mm, some a 35 mm); globos
   oculares só transladam.
5. Perfil: contorno do rosto contra a parede (foto) × contorno do render. Alinha
   pela **raiz do nariz, ponta do nariz e lábio** (o queixo não serve: pode ser
   recuado ou ter barba) e corrige a profundidade da faixa do meio do rosto.
6. Grava tudo como um **alvo de forma** igual aos do MakeHuman. Rodar de novo
   acumula; `--zerar` recomeça.

## 4. Como deixar bom (checklist)

- **Sempre comparar lado a lado** com as fotos (frente, 3/4, perfil e corpo
  inteiro) e mostrar ao dono do personagem antes de dizer que ficou bom.
- Use números, não só o olho: desvio da frente < 1 mm, perfil < 2 mm; pele com
  diferença de no máximo ~15 por canal (sRGB) das fotos.
- Confira as máscaras do cabelo (`felipe_cabelo.py --mascaras DIR`) antes de
  culpar o código.
- Veja também na resolução do jogo (reduza o render). Silhueta e cor contam mais.
- Teste as poses extremas (chute, joelhada, levantar do chão) antes de entregar.

## 5. Erros que já cometemos

- Rosto só por sliders do MakeHuman: fica genérico (Miguel).
- Medir tamanho de cabelo em selfie: encolhe. Use os quadros do vídeo.
- Cruzar silhuetas de vistas que discordam deixa o cabelo quadrado ou com "aba".
- Topo da malha base tem vértices a ~2 cm: amostre pontos nas **faces**, não só
  nos vértices, senão aparece pele no topo.
- Cards de cachos espetadas ficaram feias (`--cards`, desligado).
- Cílios em geometria e brincos: tentados e descartados pelo Felipe.
- Detector no perfil: não acha bem queixo nem ponta do nariz; use o contorno.
- Em `bpy` 5.x importe `bpy` antes de `bmesh`. Aviso "EGL_BAD_MATCH" é inofensivo.
