# Miguel v2 — revisão do modelo, 02/11/2026

Branch `feat/modelo-miguel`. **Proposta para Felipe avaliar; não está no jogo.**
O modelo aprovado continua intacto e é o único usado pelo jogo:
`arte/miguel_animado.glb` e `godot-3d/miguel_animado.glb`, SHA-256
`3badb61b532b27447a6e46d230643b4aab2f3db04a8e5ad884baf78313b21c5d`
(conferido depois de todo o trabalho). O atlas aprovado
`arte/texturas/miguel_uniforme.png` também não foi alterado.

## Abrir primeiro

- [Rosto: foto × aprovado × v2](rosto.png) (frente, 3/4, perfil, nuca)
- [Corpo: foto × aprovado × v2](corpo.png) (frente, lado, costas, 3/4)
- [Na resolução do jogo](jogo.png) (160 px de altura, ampliado sem suavizar)
- [Poses extremas 1](deformacao-1.png) e [2](deformacao-2.png): aprovado × v2 no mesmo quadro
- Diagnóstico só do aprovado: [rosto](rosto-antes.png), [corpo](corpo-antes.png), [jogo](jogo-antes.png)

## Diagnóstico do aprovado (renders em `antes/`)

| # | Problema | Evidência |
|---|---|---|
| 1 | Orelhas grandes e de abano (alvos 0,50/0,65/0,80) | rosto de frente/3/4; nas fotos são médias e próximas da cabeça |
| 2 | Olhos quase fechados, íris pequena e clara, muito branco | close dos olhos; nas fotos a íris é quase preta e ocupa a fenda |
| 3 | Perfil achatado: nariz sem projeção, lábios à frente do nariz, queixo recuado | perfil |
| 4 | Pescoço comprido (+0,25 de altura) | frente e perfil |
| 5 | Cabelo em "capacete": aba reta e alta nos lados e na nuca, sem franja | nuca, perfil, 3/4 |
| 6 | Mancha pontilhada na raiz do nariz: pele dobrada pelo encaixe do rosto (triângulos sobrepostos) | close; QA localizou z≈1,65 m, x≈0,01 |
| 7 | Punhos sempre fechados (herança do jogo de luta) | todas as vistas |
| 8 | Camisa branca mais clara que a foto (239 × 213 sRGB, na exposição em que a pele bate) — a "camisa estourada no escuro" da passagem | medição em `frente.png` |
| 9 | 61.688 triângulos e atlas 1024×2048 para um personagem: pesado para celular | `qa-antes.json` |
| 10 | Roupa com pesos copiados do vértice mais próximo: axila e gancho esticam até 54× ao abrir braço/perna | `deformacao/antes/deformacao.json` |
| 11 | QA: 2 pares coplanares (z-fighting), 215 pares de faces costas com costas, resíduo interno de 21 vértices | `qa-antes.json` |

Já estavam certos e foram mantidos: cor da pele (render 185,148,133 × fotos
≈187,147,130), cor do jeans (76,101,130 × mediana da foto 65,94,125),
silhueta do corpo, uniforme, calça, tênis e encaixe frontal do rosto.

Correção do diagnóstico: o "Icosphere" que aparece ao importar os GLB **não
está no arquivo**. O importador glTF do Blender cria esse objeto para exibir
os ossos. Os dois GLB têm uma única malha, `Miguel`.

## O que mudou no v2 (`arte/miguel_v2.py`)

O gerador reaproveita a cadeia aprovada (`miguel_referencia` → `miguel_humano`,
uniforme, calça, tênis, alvo de rosto) e troca só as partes acima. `--base`
reconstrói o aprovado sem mudanças: 61.690 triângulos, diferença média de
0,43/255 no render de frente. É o controle de que a cadeia reproduz o aprovado.

1. Orelhas: 0,05/0,15/0,15 (tamanho/abertura/asa).
2. Olhos: pálpebra de cima sobe até 3,2 mm e a de baixo desce até 1,2 mm, com
   1,5 mm de folga do globo. Íris maior (31°) e escura. Sobrancelhas: os mesmos
   polígonos medidos na foto, mais grossos e escuros.
3. Perfil: nariz com mais profundidade e ponta levemente para cima; lábios
   menos volumosos e recuados; queixo mais presente.
4. Pescoço com altura neutra (0).
5. Cabelo refeito. Nasce da pele, com linha recortada a cada ~3 mm (couro
   subdividido): franja de cachos na testa, têmporas cheias, costeleta, alto
   das orelhas coberto e nuca descendo em "V" como na foto `cabeca_costas`.
   A espessura cai para 5 mm na borda (sem aba). Relevo de cachos maiores e
   pontas castanhas.
6. Mãos semiabertas (dedos 32–54°, polegar 14°), como nas fotos; continuam
   servindo para segurar celular e lanterna.
7. Raiz do nariz desdobrada por suavização local; resíduos internos removidos
   por tamanho; cós da calça recolhido 4 mm sob a camisa (z-fighting nas costas).
8. Pesos da camisa e da calça suavizados e normalizados (6 passadas).
9. Branco do uniforme ajustado à foto: atlas e gola/carcela ≈213–216 sRGB.
10. Orçamento: 25.592 triângulos (corpo 13.000, camisa 3.600, calça 2.198,
    tênis 1.798, cabelo 5.000); atlas 512×1024. GLB animado 4,97 MB (era 12,7 MB).

Contrato preservado para o jogo: os mesmos 22 ossos com os mesmos nomes e a
mesma hierarquia (Hips … RightToes, usados por `capitulo1/*.gd` e pelos FBX do
Mixamo), uma malha `Miguel`, materiais na mesma ordem (0 = cor por vértice,
1 = uniforme; o cultista de `ator.gd` depende disso), um único atributo de
cor e altura do corpo de 1,76 m (com o cabelo, 1,81 m).

## Verificação

| Medida | Aprovado | v2 |
|---|---:|---:|
| Triângulos | 61.688 | 25.592 |
| Textura | 1024×2048 | 512×1024 |
| GLB animado | 12,7 MB | 4,97 MB |
| QA `blender-asset-qa` (perfil game), modelo em repouso | — | **passa, 0 erros** (`qa-depois-repouso.json`) |
| QA do GLB animado importado (1º quadro posado) | 2 pares coplanares | 3 pares coplanares |
| Faces costas com costas | 215 pares | 27 pares |
| Ações | 43 | 43, mesmas durações |
| Diferença de direção dos ossos nas 43 ações | — | máx. 2,9°; quadril < 6 mm (`animacoes-comparadas.json`) |

Deformação, mesmo quadro nos dois (pior quadro de cada ação). A medida é o
alongamento das arestas maiores que 2 mm: o pior caso e a % fora de 0,5–1,8×.

| Ação | Aprovado pior / % | v2 pior / % |
|---|---:|---:|
| Kicking | 34,8× / 1,06 | 9,0× / 0,79 |
| Armada | 49,9× / 1,28 | 12,6× / 0,95 |
| Knee_Jab | 28,5× / 0,97 | 7,3× / 0,51 |
| Getting_Up | 17,0× / 0,86 | 6,3× / 0,83 |
| Sweep_Fall | 54,3× / 0,72 | 14,3× / 0,59 |
| Running | 52,5× / 0,94 | 13,4× / 0,75 |
| Brutal_Assassination | 19,3× / 0,77 | 5,1× / 0,64 |
| Hook_Punch | 26,6× / 0,90 | 6,1× / 0,59 |
| Look_Over_Shoulder | 14,2× / 0,63 | 3,8× / 0,29 |
| Blocking | 48,3× / 0,91 | 12,2× / 0,55 |

## Limites honestos (o que ainda não está bom ou não foi medido)

- Não foi testado no Godot nem no celular; o FPS no aparelho não foi medido.
  O ganho de desempenho é uma estimativa pela contagem de triângulos e pelo
  tamanho da textura.
- O pior alongamento restante (≈12–14×) é a axila da camisa ao levantar o
  braço: some sob a manga nos renders, mas pode aparecer de perto.
- O cabelo é procedural, inspirado nas fotos; não é reconstrução por fatias de
  silhueta como o do Felipe. As fotos laterais são 3/4 com fundo ocupado, e não
  serviram para medir a silhueta.
- Os ajustes de olho, nariz e lábio foram feitos olhando as fotos, não por um
  novo encaixe de pontos (MediaPipe não foi instalado nesta sessão). A medida
  frontal do rosto não foi refeita.
- O QA do GLB animado acusa 3 pares coplanares no 1º quadro posado (o aprovado
  acusa 2). Em repouso, o v2 passa limpo.
- A semelhança e o gosto são de Felipe: nenhum número aqui substitui o aval dele.

## Ambiente e reprodução (Linux/nuvem)

O tarball oficial do Blender foi **bloqueado pela rede** (`download.blender.org`
e espelho → 403 do proxy). Usei o **módulo oficial `bpy` 5.2.3 LTS do PyPI**
(Blender sem interface), mais `libegl1 libgl1-mesa-dri` para o EEVEE. Nenhum
MCP de Blender estava disponível. O recorte de clipes do pacote aprovado
(`miguel_publicar_animacoes.recortar`) usa `Action.fcurves`, que não existe no
Blender 5.x. O publicador do v2 tem uma versão equivalente na API de slots.

```bash
python3 -m venv ~/venv && ~/venv/bin/pip install bpy pillow numpy scipy scikit-image
apt-get install -y libegl1 libgl1-mesa-dri
~/venv/bin/python arte/miguel_v2.py -- --glb /tmp/v2.glb          # só o modelo
~/venv/bin/python arte/miguel_v2_publicar.py                      # arte/miguel_v2_animado.glb (+43 ações)
R=arte/revisoes/miguel-v2-20261102
~/venv/bin/python arte/miguel_v2_vistas.py -- --glb arte/miguel_animado.glb --saida $R/antes
~/venv/bin/python arte/miguel_v2_vistas.py -- --glb arte/miguel_v2_animado.glb --saida $R/depois
~/venv/bin/python arte/miguel_v2_folha.py $R
~/venv/bin/python arte/miguel_v2_qa.py -- --glb arte/miguel_v2_animado.glb --json $R/qa-depois.json
~/venv/bin/python arte/miguel_v2_deformacao.py -- --glb arte/miguel_v2_animado.glb --saida $R/deformacao/depois
~/venv/bin/python arte/miguel_v2_deformacao.py -- --glb arte/miguel_animado.glb --saida $R/deformacao/antes --quadros $R/deformacao/depois/quadros.json
~/venv/bin/python arte/miguel_v2_conferir_animacoes.py -- arte/miguel_animado.glb arte/miguel_v2_animado.glb $R/animacoes-comparadas.json
```

Os quadros avulsos de deformação não foram versionados (regeneráveis); as
folhas e os JSON ficam.

## Para colocar no jogo (só depois do aval do Felipe)

Copiar `arte/miguel_v2_animado.glb` sobre `godot-3d/miguel_animado.glb` e
`arte/miguel_v2_animacoes.json` sobre `godot-3d/miguel_animacoes.json`,
reimportar e rodar os testes do capítulo. Guardar o aprovado com o SHA-256
acima antes de trocar.

Skills usadas: `blender-character-workflow` (contrato, deformação, reimportação),
`reference-to-3d` e `multiview-fit-loop` (comparar com as fotos e repetir; seis
passadas no cabelo, três nos olhos), `blender-modeling`, `blender-asset-qa`
(`qa_check.py` real, portão obrigatório) e `create-game-assets` (orçamento).
`anthropic-skills:blender-image-to-3d` não foi necessária, porque o modelo
partiu da cadeia existente e não de imagem para 3D do zero.
