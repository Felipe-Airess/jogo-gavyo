# Miguel — uniforme, 01/11/2026

[Comparação antes/depois](comparacao-uniforme.png) ·
[Corpo em três vistas](corpo-uniforme.png) ·
[GLB com o uniforme novo](miguel-previa.glb)

Continuação da prévia em `../miguel-20261101/`. O usuário reconheceu o Miguel
naquela versão e pediu melhorar a roupa. O alvo de rosto foi mantido; a
comparação dos 10.512 vértices acima de 1,54 m confirmou posições idênticas
entre os dois modelos de trabalho (`cabeca-preservada.json`).

## Roupa

- Camisa mais solta a partir do peito, barra reta e mangas um pouco maiores.
- Gola polo com duas pontas, carcela e dois botões em geometria, com pesos
  copiados do mesmo corpo e limitados a quatro influências.
- Textura própria de 1024 × 2048, com regiões separadas para frente/costas.
  Faixas dos ombros suavizadas, frisos verdes das mangas e diagonal amarela.
- Escudo e inscrição extraídos de `arte/referencias/miguel/camisa_frente.jpg`,
  recorte `(690, 965, 898, 1133)` na imagem de 1500 × 2000; correção de giro
  de 5°, remoção do tecido de fundo e inserção no painel frontal do atlas.
- Remoção de uma pequena ilha de pele interna à cintura, identificada pelo
  QA, que ficava isolada com o novo caimento.

Calça e tênis usam a geometria anterior. As alterações estão no gerador
`arte/miguel_uniforme.py`, chamado por `miguel_referencia.py`. A comparação
da roupa usa a mesma câmera e iluminação EEVEE para antes/depois. O render
anterior de rosto usava Workbench, portanto a iluminação entre as duas
rodadas não é idêntica; a geometria da cabeça foi conferida diretamente.

## Skill encontrada e aplicada

**[blender-uv-texturing](https://www.skills.sh/roble3/cc-blender-skill/blender-uv-texturing)**,
de [RobLe3/cc-blender-skill](https://github.com/RobLe3/cc-blender-skill):
cerca de 1,3 mil instalações; repositório com 136 estrelas na consulta.
Skill comunitária, instalada em `~/.agents/skills/blender-uv-texturing/`.

```bash
npx skills add roble3/cc-blender-skill --skill blender-uv-texturing -g -y --agent codex
```

Aplicação: material Principled com PNG sRGB, mapeamento frente/costas por
região do atlas, textura embutida no GLB e validação da exportação. Também
foram usados os fluxos de referência, comparação e QA já instalados.

## Conferências

- `blender-asset-qa`: **aprovado**, zero erros, sem partes flutuantes nem
  cintilação detectadas, sem UVs de área zero nem vértices sem pesos.
- Uma malha, dois materiais, 33.620 vértices no Blender, 66.641 triângulos,
  rig de 22 ossos. O aumento é de 1.096 triângulos sobre a prévia anterior.
- GLB reimportado para verificar os 22 ossos, pesos normalizados com até
  quatro influências e a imagem embutida. Dados em `exportacao.json`.
- Inspeção visual de seis poses amostradas para cada animação:
  [soco](poses/Punching_1.png), [chute](poses/Kicking.png),
  [levantar](poses/Getting_Up.png). Os FBX originais foram mantidos; a
  amostragem reduzida foi usada apenas no teste. Não é um teste no Godot.

Avisos aceitos, registrados em `qa-depois.json`:

- **12,24% de sobreposição UV:** intencional no mapeamento projetado de
  superfícies que compartilham o mesmo padrão. Adequado à textura de cor
  atual; para assar mapas de luz/normal/AO é necessário outro UV sem pilhas.
- **32 pares de faces internas costas com costas:** contatos internos e
  fechamentos preservados, sem cintilação detectada. A limpeza desses pares
  exige revisar as bordas das peças.
- **Uma ilha interna encerrada de 21 vértices**, no centro `[0, -0.026, 0.528]`:
  resíduo coberto pela calça, sem componente externo flutuante detectado.

## Reproduzir

O Blender portátil e o ambiente Python são os preparados na rodada anterior.
Não é necessário iniciar o detector facial para trabalhar só na roupa.

```bash
bash scripts/blender-mac.sh -P arte/miguel_referencia.py -- --render arte/revisoes/miguel-roupa-20261101/depois --blend work/miguel-uniforme.blend
bash scripts/blender-mac.sh work/miguel-uniforme.blend -P arte/miguel_revisar.py -- --saida arte/revisoes/miguel-roupa-20261101 --exportar-previa
bash scripts/blender-mac.sh -P arte/miguel_testar_uniforme.py
```

Saída para revisão na branch `arte/miguel-referencia-fotos`; o arquivo do
personagem integrado ao jogo ainda é o anterior.
