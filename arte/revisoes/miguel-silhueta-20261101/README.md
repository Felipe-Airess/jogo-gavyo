# Miguel — tronco, calça e tênis, 01/11/2026

[Corpo antes/depois](comparacao-corpo.png) ·
[Tronco antes/depois](comparacao-tronco.png) ·
[Tênis antes/depois](comparacao-tenis.png) ·
[Três vistas](tres-vistas.png) · [GLB revisado](miguel-previa.glb)

Continua a versão de `../miguel-roupa-20261101/`, atendendo à revisão do
tronco quadrado, calça e tênis. Os renders antes/depois usam a mesma câmera
e dois sóis de estúdio; o renderizador agora remove as luzes anteriores
antes de montar o estúdio, evitando duplicá-las ao reabrir um `.blend`.

## Revisão

- **Tronco:** o tubo de raio constante foi substituído por um perfil com
  cintura suave e folga sobre o quadril. A largura foi reduzida sem voltar
  a uma camisa colada; a barra tem profundidade para cobrir a calça.
- **Calça:** afunilamento abaixo dos joelhos, barra ajustada ao tênis,
  pequenas dobras nos joelhos/tornozelos e costuras laterais. A cor do jeans
  foi medida na foto `corpo_frente2.jpg`, em pixels azuis da região inferior;
  não é uma medição de albedo físico sob iluminação controlada.
- **Tênis:** nova malha com sola estratificada, cabedal, abertura do
  tornozelo, cadarços e curva roxa lateral contínua. As posições e o
  comprimento usam as juntas existentes de tornozelo/pé; o acabamento é
  estilizado a partir das fotos, não um escaneamento do calçado.
- Dois fragmentos isolados de pele nos tornozelos (15 e 18 vértices), antes
  escondidos pelo tênis antigo, foram removidos para não atravessarem a roupa.

Geradores: `arte/miguel_uniforme.py` (camisa/render) e
`arte/miguel_calca_tenis.py` (jeans/calçado), integrados por
`arte/miguel_referencia.py`. Não houve ajuste do rosto nesta rodada.

## Find-skills

Skill selecionada, instalada e usada:
**[blender-modeling](https://www.skills.sh/roble3/cc-blender-skill/blender-modeling)**,
de [RobLe3/cc-blender-skill](https://github.com/RobLe3/cc-blender-skill).
Catálogo: cerca de 2,6 mil instalações; GitHub: 136 estrelas na consulta.
É uma skill comunitária. Aplicação nesta revisão: edição por bmesh,
montagem de malhas, fechamento de detalhes e conferência de normais.

```bash
npx skills add roble3/cc-blender-skill --skill blender-modeling -g -y --agent codex
```

Também foram aplicadas as skills já instaladas de referências, comparação,
UV/texturas e QA. Execução por Blender portátil 3.6.23 em background,
conforme o ambiente documentado nas revisões anteriores.

## Conferências

- **QA da malha aprovado, zero erros:** sem cintilação ou partes flutuantes
  detectadas; sem faces degeneradas, UVs vazias ou vértices sem pesos.
- **31.415 vértices de trabalho / 61.688 triângulos**, dois materiais,
  rig de 22 ossos. A versão anterior tinha 66.641 triângulos. Sem medição
  de FPS nem teste no Godot nesta rodada.
- **GLB de 3.349.300 bytes**, com a textura embutida; reimportado para
  verificar cores, 22 ossos e pesos normalizados com até quatro influências.
  A reimportação tem 41.146 vértices pelas separações do formato exportado.
- **Cabeça preservada:** comparação dos 10.512 vértices acima de 1,54 m
  confirmou posições idênticas à versão anterior. O hash do alvo de rosto
  está registrado em `cabeca-preservada.json`.
- Inspeção visual de seis poses amostradas por animação de
  [soco](poses/Punching_1.png), [chute](poses/Kicking.png) e
  [levantar](poses/Getting_Up.png). Isso não garante ausência de toda
  interpenetração em cada quadro de todas as animações.

Avisos aceitos para a prévia (`qa-depois.json`):

- **12,03% de sobreposição UV:** intencional no mapeamento projetado da
  textura de cor; mapas de luz, normal ou AO exigiriam um UV separado.
- **250 pares de faces internas costas com costas:** contatos de peças
  sobrepostas, incluindo cadarços sobre o cabedal, e fechamentos internos.
  Mantidos como detalhes do modelo; não há z-fighting detectado.

As aberturas de roupa e calçado são permitidas no perfil `game`; o QA
não declara a malha estanque para impressão.

## Reproduzir na raiz do projeto

```bash
bash scripts/blender-mac.sh -P arte/miguel_referencia.py -- --render arte/revisoes/miguel-silhueta-20261101/depois --blend work/miguel-silhueta.blend
bash scripts/blender-mac.sh work/miguel-silhueta.blend -P arte/miguel_revisar.py -- --saida arte/revisoes/miguel-silhueta-20261101 --exportar-previa
bash scripts/blender-mac.sh -P arte/miguel_testar_uniforme.py -- --saida arte/revisoes/miguel-silhueta-20261101/poses
bash scripts/blender-mac.sh -P arte/miguel_conferir_exportacao.py -- --pasta arte/revisoes/miguel-silhueta-20261101 --modelo work/miguel-silhueta.blend --anterior work/miguel-uniforme.blend
```

Prévia local na branch `arte/miguel-referencia-fotos`; sem substituir o
personagem integrado ao jogo nem publicar o resultado.
