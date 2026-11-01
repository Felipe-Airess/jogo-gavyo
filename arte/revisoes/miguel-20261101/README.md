# Miguel — prévia ajustada às fotos, 01/11/2026

Branch: `arte/miguel-referencia-fotos`. O modelo usado pelo jogo foi preservado.
Esta é uma versão para revisão visual, não um personagem final aprovado.

## Abrir primeiro

- [Foto, antes e depois](comparacao-rosto.png)
- [Corpo em três vistas](comparacao-corpo.png)
- [Modelo GLB de revisão](miguel-previa.glb) — 3,2 MiB, uma malha e rig de 22 ossos.
- [Soco](rig-mixamo/Punching_1.png), [chute](rig-mixamo/Kicking.png) e
  [levantar](rig-mixamo/Getting_Up.png) com as animações existentes do Mixamo.
- [Sobreposição frontal](medidas-depois/rosto_frente.png),
  [máscara frontal](medidas-depois/front_mask_overlay.png) e [topologia](qa-wire.png).

## O que mudou

`arte/miguel_referencia.py` reaproveita o corpo, a roupa e o rig existentes.
O novo `arte/miguel_rosto.py` usa o encaixe por pontos de `felipe_rosto.py`,
com arquivos próprios do Miguel. Foram feitas quatro passadas globais.
Pele, lábios e cabelo usam medianas medidas em quatro fotos, com conversão
sRGB → linear registrada em `arte/miguel_cores_fotos.json`.
Sobrancelhas e lábios seguem os polígonos detectados na referência.

Correções da malha: pesos limitados aos quatro ossos de maior influência e
normalizados; atlas UV para peças geradas; triangulação dos n-gons;
remalhamento do cabelo para eliminar sobreposição; globos oculares recuados
2 mm para eliminar o contato quase coplanar com as pálpebras.

## Verificação e limites

| Medida | Antes | Depois |
|---|---:|---:|
| Desvio médio dos pontos na projeção frontal alinhada | 5,79 mm | 1,06 mm |
| IoU do contorno facial frontal detectado | 86,7% | 94,9% |
| Erros no QA da malha | 3 categorias | 0 |
| Vértices com mais de quatro influências | 657 | 0 |
| Faces com UV de área zero | 23.904 | 0 |

Resultado: 32.996 vértices, 39.370 faces / 65.545 triângulos, um material,
22 ossos. A exportação foi reimportada para conferir rig, pesos e cores;
os relatórios estão em `exportacao.json` e `reimportacao.json`.
Na reimportação do GLB, a malha tem 43.660 vértices e os mesmos 65.545
triângulos; os 32.996 vértices acima são da malha de trabalho no Blender.
O retargeting existente produziu as três folhas de animação, inspecionadas
visualmente. Não houve teste no Godot nem medição de FPS nesta rodada.

O contorno frontal passou nos limites de IoU ≥90%, centro ≤1,5% e tamanho
≤3%. A meta de desvio médio ≤1 mm ainda não passou (1,06 mm). Esse número
é um erro de projeção após alinhamento, não precisão 3D nem garantia de
semelhança. As fotografias têm perspectiva e diferenças de pose/iluminação.
Perfis disponíveis são principalmente 3/4, com fundo ocupado e mão no queixo:
não foram tratados como silhuetas ortográficas. Perfil, olhos, orelhas e
cabelo ainda precisam de refinamento visual. O cabelo mantém o desenho
procedural original, com cor e geometria corrigidas; não foi reconstruído
fio a fio a partir das fotos. Corpo e roupa não foram refeitos do zero.

Dois avisos de QA foram aceitos nesta prévia, com registro explícito:

- 24 pares de faces internas costas com costas: não há cintilação detectada;
  preservadas para não remover fechamentos de peças sem revisar a costura.
- Uma ilha de 21 vértices totalmente encerrada na região da cintura:
  resíduo interno coberto pela roupa, sem parte flutuante externa detectada.

Esses resíduos podem ser removidos numa limpeza posterior. A malha tem
425 arestas de borda; o perfil `game` permite peças abertas e não declara
o personagem estanque para impressão. Ver `qa-antes.json`, `qa-depois.json`
e `validacao-fotos.json` para os dados completos.

## Skills usadas

Instaladas globalmente em `~/.agents/skills/`, disponíveis para descoberta
nas próximas mensagens:

- **reference-to-3d** (`RobLe3/cc-blender-skill`): inventário com hashes,
  fontes e limites em `reference_manifest.json`; construção guiada por fotos.
- **multiview-fit-loop** (mesma origem): comparar, medir e corrigir; a rotina
  bbox/IoU foi adaptada a NumPy/Pillow em `arte/miguel_validar_fotos.py`.
  A validação quantitativa é frontal; não se declara ajuste multivista completo.
- **blender-asset-qa** (`EL4CTEO/blender-skills`): `qa_check.py` e
  `review_shots.py` executados de fato. Única adaptação de API nas folhas:
  `image_settings.media_type` não existe no Blender 3.6.

## Reproduzir no Mac

Blender 3.6.23 portátil em `work/ferramentas/`, montado sob demanda em
`/private/tmp/gavyo-blender-3.6`; sem instalação em Aplicativos. Dependências
Python isoladas em `work/venv-modelo`. Nenhum servidor MCP Blender estava
disponível; foram usados scripts de Blender em background, com dois threads.
Os binários nativos de MediaPipe 0.10.14/0.10.9 não carregam no macOS 11;
o detector usado é MediaPipe Tasks Vision 0.10.14 WASM no Chrome headless,
servido em loopback. Fotos e renders são processados localmente.

Na raiz do projeto, mantenha o detector aberto num terminal:

```bash
node scripts/face-landmarks-web.mjs
```

Em outro terminal:

```bash
# Só medir: não altera o alvo de forma.
bash scripts/blender-mac.sh -P arte/miguel_rosto.py -- --checar arte/revisoes/miguel-20261101/medidas-depois
# Renderizar a versão ajustada.
bash scripts/blender-mac.sh -P arte/miguel_referencia.py -- --render arte/revisoes/miguel-20261101/depois --blend work/miguel-depois.blend
# QA e GLB de revisão (a exportação exige QA aprovado).
bash scripts/blender-mac.sh work/miguel-depois.blend -P arte/miguel_revisar.py -- --exportar-previa
work/venv-modelo/bin/python arte/miguel_validar_fotos.py
```

Para **nova passada**, use `miguel_rosto.py -- --debug DIRETORIO`; acumula
sobre o alvo existente. Faça backup do alvo primeiro. `--zerar` recomeça.
O detector é encerrado com Ctrl+C; não foi instalado como serviço.
