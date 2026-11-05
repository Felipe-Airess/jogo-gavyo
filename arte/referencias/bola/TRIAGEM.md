# Triagem visual preliminar — Bola

03/11/2026. **Triagem visual e MediaPipe concluídos. Modelo ainda em construção.**

As 45 fotos foram extraídas do arquivo fornecido por Felipe, preservadas e
abertas em três folhas de contato. Todas têm resolução 960 × 1280. A nota abaixo
é uma avaliação visual de utilidade (0–5), não um score de reconhecimento ou erro facial. A coluna MediaPipe contém
as estimativas de pose e abertura da boca medidas na retomada.

## Execução local retomada

A instalação concluiu na retomada. OpenCV baixado por HTTPS e SHA-256 verificado
com PyPI; NumPy 1.23.5, SciPy 1.10.1, scikit-image 0.21.0, Pillow 10.4.0 e
OpenCV 4.5.5 importados. O módulo nativo MediaPipe é incompatível com macOS 11,
então foi usada a opção HTTP local já prevista em `felipe_rosto.py`:
MediaPipe FaceLandmarker WebAssembly, CPU, com o mesmo `face_landmarker.task`,
executado em Chrome local. Nenhuma foto foi enviada a servidor remoto.
São 45/45 fotos processadas, 25 com rosto detectado. Perfis puros e costas
continuam sendo avaliados por contorno/silhueta; ausência de landmarks não
significa que a foto é inútil. Pose estimada não é calibração fotogramétrica.
Dados completos em `mediapipe-triagem.json`; não são medidas de erro do modelo.

## Inventário

“Direita/esquerda” abaixo indica para onde o rosto aponta **na imagem**, não o
lado anatômico. Fotos do rosto não foram classificadas como selfies de braço:
a distância da câmera não foi informada. Por cautela, retratos próximos só
servirão ao alinhamento dos pontos; as proporções vêm das fotos mais distantes.

| Arquivo | Categoria | Nota / observação visual | MediaPipe |
| --- | --- | --- | --- |
| `IMG-20261103-WA0000.jpg` | Rosto de frente; roupa | 4/5 visual: retrato próximo para landmarks; não usar para dimensionar cabeça/cabelo. | 478 pontos; yaw -1.3°, pitch -0.3°, roll -1.2°; olhos 272 px; boca/olhos 0.003. |
| `IMG-20261103-WA0001.jpg` | Rosto de frente; roupa | 4/5 visual: retrato próximo para landmarks; não usar para dimensionar cabeça/cabelo. | 478 pontos; yaw -0.5°, pitch 0.4°, roll -2.1°; olhos 255 px; boca/olhos 0.002. |
| `IMG-20261103-WA0002.jpg` | Rosto de frente; roupa | 4/5 visual: retrato próximo para landmarks; não usar para dimensionar cabeça/cabelo. | 478 pontos; yaw -0.1°, pitch -0.5°, roll -0.5°; olhos 259 px; boca/olhos 0.002. |
| `IMG-20261103-WA0003.jpg` | Rosto de frente; roupa | 3/5 visual: rosto frontal, mas olhar desviado; confirmar orientação pelo detector. | 478 pontos; yaw 3.9°, pitch 0.3°, roll -2.8°; olhos 254 px; boca/olhos 0.002. |
| `IMG-20261103-WA0004.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | 478 pontos; yaw 50.3°, pitch 0.5°, roll -2.4°; olhos 131 px; boca/olhos 0.005. |
| `IMG-20261103-WA0005.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | 478 pontos; yaw 14.4°, pitch -1.0°, roll -3.9°; olhos 242 px; boca/olhos 0.013. |
| `IMG-20261103-WA0006.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | 478 pontos; yaw 53.9°, pitch 1.8°, roll 0.3°; olhos 122 px; boca/olhos 0.035. |
| `IMG-20261103-WA0007.jpg` | 3/4 voltado à esquerda da imagem; cabelo; roupa | 4/5 visual: contravista útil; não é um perfil lateral puro de perto. | 478 pontos; yaw -31.8°, pitch -4.3°, roll 4.3°; olhos 192 px; boca/olhos 0.038. |
| `IMG-20261103-WA0008.jpg` | 3/4 voltado à esquerda da imagem; cabelo; roupa | 4/5 visual: contravista útil; não é um perfil lateral puro de perto. | 478 pontos; yaw -16.4°, pitch -1.3°, roll 3.2°; olhos 257 px; boca/olhos 0.008. |
| `IMG-20261103-WA0009.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | 478 pontos; yaw 31.2°, pitch -2.6°, roll -4.0°; olhos 202 px; boca/olhos 0.007. |
| `IMG-20261103-WA0010.jpg` | Corpo de frente; farda; calça; cabelo | 4/5 visual: referência de proporção de longe; conferir corte dos pés. | 478 pontos; yaw -3.8°, pitch -8.4°, roll -0.5°; olhos 81 px; boca/olhos 0.058. |
| `IMG-20261103-WA0011.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | 478 pontos; yaw 24.6°, pitch -0.9°, roll 3.3°; olhos 234 px; boca/olhos 0.013. |
| `IMG-20261103-WA0012.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | 478 pontos; yaw 11.1°, pitch -7.5°, roll -4.7°; olhos 82 px; boca/olhos 0.015. |
| `IMG-20261103-WA0013.jpg` | Perfil voltado à direita da imagem; cabelo; roupa | 4/5 visual: contorno de nariz, lábio e queixo contra fundo claro; útil para profundidade. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0014.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0015.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 2/5 para encaixe: expressão sorrindo; útil para conferência, não como frente neutra. | 478 pontos; yaw 23.5°, pitch 1.6°, roll 2.9°; olhos 232 px; boca/olhos 0.003. |
| `IMG-20261103-WA0016.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0018.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0019.jpg` | Perfil voltado à direita da imagem; cabelo; roupa | 4/5 visual: contorno de nariz, lábio e queixo contra fundo claro; útil para profundidade. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0020.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0021.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0022.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0023.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | 478 pontos; yaw 39.3°, pitch -2.9°, roll -3.4°; olhos 172 px; boca/olhos 0.003. |
| `IMG-20261103-WA0024.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0025.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0026.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0027.jpg` | Perfil voltado à direita da imagem; cabelo; roupa | 4/5 visual: contorno de nariz, lábio e queixo contra fundo claro; útil para profundidade. | 478 pontos; yaw 53.0°, pitch 6.2°, roll 13.6°; olhos 131 px; boca/olhos 0.028. |
| `IMG-20261103-WA0028.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0029.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0030.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0031.jpg` | Rosto de frente; roupa | 3/5 visual: rosto frontal, mas olhar desviado; confirmar orientação pelo detector. | 478 pontos; yaw 0.6°, pitch -0.7°, roll 0.1°; olhos 277 px; boca/olhos 0.012. |
| `IMG-20261103-WA0032.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0033.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0034.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0035.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | 478 pontos; yaw 38.5°, pitch 3.1°, roll 5.4°; olhos 181 px; boca/olhos 0.023. |
| `IMG-20261103-WA0036.jpg` | Corpo de lado/3/4 voltado à esquerda da imagem; roupa; cabelo | 4/5 visual: contravista do corpo; rosto pequeno para ajuste milimétrico. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0037.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0038.jpg` | Corpo de lado/3/4 voltado à esquerda da imagem; roupa; cabelo | 4/5 visual: contravista do corpo; rosto pequeno para ajuste milimétrico. | Sem rosto detectado (vista de costas/perfil ou rosto pequeno). |
| `IMG-20261103-WA0039.jpg` | 3/4 voltado à esquerda da imagem; cabelo; roupa | 4/5 visual: contravista útil; não é um perfil lateral puro de perto. | 478 pontos; yaw -46.5°, pitch 2.1°, roll 4.2°; olhos 131 px; boca/olhos 0.054. |
| `IMG-20261103-WA0040.jpg` | Corpo de lado/3/4 voltado à esquerda da imagem; roupa; cabelo | 4/5 visual: contravista do corpo; rosto pequeno para ajuste milimétrico. | 478 pontos; yaw -36.0°, pitch 7.1°, roll -7.1°; olhos 62 px; boca/olhos 0.018. |
| `IMG-20261103-WA0041.jpg` | Corpo de frente; farda; calça; cabelo | 5/5 para corpo: pés e tênis visíveis; queixo levantado, não serve como frente neutra do rosto. | 478 pontos; yaw -4.6°, pitch -14.6°, roll -2.0°; olhos 83 px; boca/olhos 0.011. |
| `IMG-20261103-WA0042.jpg` | Corpo de frente; farda; calça; cabelo | 4/5 visual: referência de proporção de longe; conferir corte dos pés. | 478 pontos; yaw -15.5°, pitch -0.9°, roll -8.0°; olhos 92 px; boca/olhos 0.004. |
| `IMG-20261103-WA0043.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | 478 pontos; yaw 32.9°, pitch -1.5°, roll 3.0°; olhos 203 px; boca/olhos 0.019. |
| `IMG-20261103-WA0044.jpg` | Corpo de frente; farda; calça; cabelo | 4/5 visual: referência de proporção de longe; conferir corte dos pés. | 478 pontos; yaw -4.6°, pitch 2.0°, roll -4.7°; olhos 85 px; boca/olhos 0.005. |
| `IMG-20261103-WA0045.jpg` | Corpo de frente; farda; calça; cabelo | 5/5 para corpo: pés e tênis visíveis; queixo levantado, não serve como frente neutra do rosto. | 478 pontos; yaw -1.8°, pitch -16.9°, roll -0.3°; olhos 84 px; boca/olhos 0.005. |

## Escolhidas

Cópias idênticas aos originais em `escolhidas/` (nomes padronizados); seleção
cruza as medições com a inspeção visual, não depende de um score único.

- `rosto_frente.jpg`: WA0002 — yaw −0,14°, pitch −0,45°, roll −0,55°,
  boca fechada, distância entre cantos externos dos olhos 259 px.
- `rosto_perfil_direita.jpg`: WA0013 — perfil visual puro para contorno;
  sem landmarks confiáveis, como esperado. Conferir também WA0019/WA0027.
- `rosto_34_direita.jpg`: WA0043 — yaw 32,9°, conferência independente.
- `rosto_34_esquerda.jpg`: WA0039 — contravista, yaw −46,5°.
- `corpo_frente.jpg`: WA0045 — corpo e tênis completos; queixo elevado,
  portanto não usar para encaixar os pontos do rosto.
- `corpo_frente_neutra.jpg`: WA0044 — câmera mais distante, olhos/cabeça
  naturais; principal escala relativa de cabelo/cabeça, junto das vistas laterais.
- `corpo_perfil_direita.jpg`: WA0018; `corpo_perfil_esquerda.jpg`: WA0036.
- `corpo_costas.jpg`: WA0030; `cabelo_costas.jpg`: WA0025.

## Lacunas e impacto

- Há corpo inteiro de frente, incluindo os tênis. Várias vistas de lado e de
  costas cortam os pés: o volume traseiro do calçado teria confirmação limitada.
- O perfil esquerdo de perto não está tão lateral quanto as vistas direitas.
  Há vistas esquerdas de corpo, mas o rosto é menor; a contravista facial ficaria
  menos validada. Não apresentar perfil inferido como medido.
- Não há foto dedicada do topo do cabelo. Volume superior precisaria ser
  inferido entre frente/perfis/costas e declarado como menos verificado.
- Não há farda esticada no chão; gola, faixas e estampas aparecem vestidas com
  dobras/perspectiva. A reprodução exigiria corrigir essa projeção e comparar.
- Não encontrei foto totalmente inútil: as vistas sem rosto ainda servem para
  cabelo, silhueta ou farda. Isso não significa que todas servem para landmarks.
- O pacote não contém WA0017. Os 45 arquivos presentes foram preservados;
  não houve exclusão na extração.

Índices abertos para esta triagem:
[01](../../revisoes/bola/indice-01.jpg),
[02](../../revisoes/bola/indice-02.jpg),
[03](../../revisoes/bola/indice-03.jpg).
