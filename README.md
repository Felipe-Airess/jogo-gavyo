# Gavião

Jogo de terror em terceira pessoa, em Godot **4.5.1 (Compatibility)**, ambientado
numa escola. O foco atual é o **capítulo 1**, jogável no PC e no celular.

- **O que fazer agora:** [`docs/TIMELINE.md`](docs/TIMELINE.md)
- **Estado e decisões:** [`docs/PASSAGEM-PARA-CLAUDE.md`](docs/PASSAGEM-PARA-CLAUDE.md)
  e [`docs/TESTE-FELIPE-20261102.md`](docs/TESTE-FELIPE-20261102.md)
- **Mapa:** grade em texto em `godot-3d/capitulo1/mapa/` (ver o `LEIA-ME.md` dali)

## Jogar

No Mac: `bash JOGAR-PROTOTIPO.command`.

## Testar

Defina `GODOT` com o executável do Godot 4.5.1 e rode:

```bash
bash scripts/testar-capitulo1.sh
```

```bash
bash scripts/testar-percurso.sh
```

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `godot-3d/capitulo1/` | o capítulo 1 |
| `godot-3d/prototipo/` | base que o capítulo usa por baixo (não apagar) |
| `arte/` | modelos e fontes (o Miguel original é `arte/miguel_animado.glb`) |
| `docs/` | documentação atual |
| `.claude/skills/` | skills usadas pelas IAs |
