# Triagem visual preliminar — Bola

03/11/2026. **Incompleta: o MediaPipe não foi executado.**

As 45 fotos foram extraídas do arquivo fornecido por Felipe, preservadas e
abertas em três folhas de contato. Todas têm resolução 960 × 1280. A nota abaixo
é uma avaliação visual de utilidade (0–5), não um score do MediaPipe, nem uma
medição de pose, nitidez ou erro facial. Não houve seleção automática de fotos.

## Bloqueio antes do detector

A instalação das dependências falhou no download do
`opencv-contrib-python==4.5.5.64`: `error: incomplete-download`, 28,0 de 55,9 MB,
após seis tentativas automáticas. O usuário determinou parar se algo não
instalasse. O log integral está em [DEPENDENCIAS-FALHA.txt](DEPENDENCIAS-FALHA.txt).
O MediaPipe nativo já presente também não importa neste macOS 11.7.11: seu binário
foi compilado para macOS 13. Não foi usado outro detector ou outra técnica.

## Inventário

“Direita/esquerda” abaixo indica para onde o rosto aponta **na imagem**, não o
lado anatômico. Fotos do rosto não foram classificadas como selfies de braço:
a distância da câmera não foi informada. Por cautela, retratos próximos só
servirão ao alinhamento dos pontos; as proporções vêm das fotos mais distantes.

| Arquivo | Categoria | Nota / observação visual | MediaPipe |
| --- | --- | --- | --- |
| `IMG-20261103-WA0000.jpg` | Rosto de frente; roupa | 4/5 visual: retrato próximo para landmarks; não usar para dimensionar cabeça/cabelo. | **Não executado** |
| `IMG-20261103-WA0001.jpg` | Rosto de frente; roupa | 4/5 visual: retrato próximo para landmarks; não usar para dimensionar cabeça/cabelo. | **Não executado** |
| `IMG-20261103-WA0002.jpg` | Rosto de frente; roupa | 4/5 visual: retrato próximo para landmarks; não usar para dimensionar cabeça/cabelo. | **Não executado** |
| `IMG-20261103-WA0003.jpg` | Rosto de frente; roupa | 3/5 visual: rosto frontal, mas olhar desviado; confirmar orientação pelo detector. | **Não executado** |
| `IMG-20261103-WA0004.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | **Não executado** |
| `IMG-20261103-WA0005.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | **Não executado** |
| `IMG-20261103-WA0006.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | **Não executado** |
| `IMG-20261103-WA0007.jpg` | 3/4 voltado à esquerda da imagem; cabelo; roupa | 4/5 visual: contravista útil; não é um perfil lateral puro de perto. | **Não executado** |
| `IMG-20261103-WA0008.jpg` | 3/4 voltado à esquerda da imagem; cabelo; roupa | 4/5 visual: contravista útil; não é um perfil lateral puro de perto. | **Não executado** |
| `IMG-20261103-WA0009.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | **Não executado** |
| `IMG-20261103-WA0010.jpg` | Corpo de frente; farda; calça; cabelo | 4/5 visual: referência de proporção de longe; conferir corte dos pés. | **Não executado** |
| `IMG-20261103-WA0011.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | **Não executado** |
| `IMG-20261103-WA0012.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | **Não executado** |
| `IMG-20261103-WA0013.jpg` | Perfil voltado à direita da imagem; cabelo; roupa | 4/5 visual: contorno de nariz, lábio e queixo contra fundo claro; útil para profundidade. | **Não executado** |
| `IMG-20261103-WA0014.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | **Não executado** |
| `IMG-20261103-WA0015.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 2/5 para encaixe: expressão sorrindo; útil para conferência, não como frente neutra. | **Não executado** |
| `IMG-20261103-WA0016.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | **Não executado** |
| `IMG-20261103-WA0018.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | **Não executado** |
| `IMG-20261103-WA0019.jpg` | Perfil voltado à direita da imagem; cabelo; roupa | 4/5 visual: contorno de nariz, lábio e queixo contra fundo claro; útil para profundidade. | **Não executado** |
| `IMG-20261103-WA0020.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | **Não executado** |
| `IMG-20261103-WA0021.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | **Não executado** |
| `IMG-20261103-WA0022.jpg` | Corpo de lado/3/4 voltado à direita da imagem; roupa; cabelo | 4/5 visual: silhueta do tronco e cabelo de longe; pés incompletos. | **Não executado** |
| `IMG-20261103-WA0023.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | **Não executado** |
| `IMG-20261103-WA0024.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | **Não executado** |
| `IMG-20261103-WA0025.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | **Não executado** |
| `IMG-20261103-WA0026.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | **Não executado** |
| `IMG-20261103-WA0027.jpg` | Perfil voltado à direita da imagem; cabelo; roupa | 4/5 visual: contorno de nariz, lábio e queixo contra fundo claro; útil para profundidade. | **Não executado** |
| `IMG-20261103-WA0028.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | **Não executado** |
| `IMG-20261103-WA0029.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | **Não executado** |
| `IMG-20261103-WA0030.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | **Não executado** |
| `IMG-20261103-WA0031.jpg` | Rosto de frente; roupa | 3/5 visual: rosto frontal, mas olhar desviado; confirmar orientação pelo detector. | **Não executado** |
| `IMG-20261103-WA0032.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | **Não executado** |
| `IMG-20261103-WA0033.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | **Não executado** |
| `IMG-20261103-WA0034.jpg` | Corpo de costas/3/4 de costas; farda; cabelo | 4/5 visual: costas da farda e largura do corpo; parte inferior dos pés cortada. | **Não executado** |
| `IMG-20261103-WA0035.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | **Não executado** |
| `IMG-20261103-WA0036.jpg` | Corpo de lado/3/4 voltado à esquerda da imagem; roupa; cabelo | 4/5 visual: contravista do corpo; rosto pequeno para ajuste milimétrico. | **Não executado** |
| `IMG-20261103-WA0037.jpg` | Cabelo de trás/3/4 de trás; costas da farda | 4/5 visual: contorno da nuca e estampa traseira; não fornece landmarks frontais. | **Não executado** |
| `IMG-20261103-WA0038.jpg` | Corpo de lado/3/4 voltado à esquerda da imagem; roupa; cabelo | 4/5 visual: contravista do corpo; rosto pequeno para ajuste milimétrico. | **Não executado** |
| `IMG-20261103-WA0039.jpg` | 3/4 voltado à esquerda da imagem; cabelo; roupa | 4/5 visual: contravista útil; não é um perfil lateral puro de perto. | **Não executado** |
| `IMG-20261103-WA0040.jpg` | Corpo de lado/3/4 voltado à esquerda da imagem; roupa; cabelo | 4/5 visual: contravista do corpo; rosto pequeno para ajuste milimétrico. | **Não executado** |
| `IMG-20261103-WA0041.jpg` | Corpo de frente; farda; calça; cabelo | 5/5 para corpo: pés e tênis visíveis; queixo levantado, não serve como frente neutra do rosto. | **Não executado** |
| `IMG-20261103-WA0042.jpg` | Corpo de frente; farda; calça; cabelo | 4/5 visual: referência de proporção de longe; conferir corte dos pés. | **Não executado** |
| `IMG-20261103-WA0043.jpg` | 3/4 voltado à direita da imagem; cabelo; roupa | 4/5 visual: boa referência independente de volume do rosto e cabelo. | **Não executado** |
| `IMG-20261103-WA0044.jpg` | Corpo de frente; farda; calça; cabelo | 4/5 visual: referência de proporção de longe; conferir corte dos pés. | **Não executado** |
| `IMG-20261103-WA0045.jpg` | Corpo de frente; farda; calça; cabelo | 5/5 para corpo: pés e tênis visíveis; queixo levantado, não serve como frente neutra do rosto. | **Não executado** |

## Candidatas visuais, ainda sem aprovação do detector

Não foram copiadas para `escolhidas/`: a seleção pedida depende de rodar MediaPipe
em todas as fotos e comparar orientação/expressão/resolução efetiva do rosto.

- Frente: WA0000/WA0001/WA0002; comparar pose e boca fechada com o detector.
- Perfil para contorno: WA0013/WA0019/WA0027, voltadas à direita da imagem.
- 3/4: WA0011/WA0035/WA0043; contravista WA0039.
- Corpo de frente e tênis: WA0041/WA0045; usar WA0042/WA0044 para farda e proporções.
- Corpo de lado: WA0018/WA0020 e WA0036/WA0038.
- Costas: WA0028/WA0030/WA0032; cabelo de trás WA0025/WA0033.

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
