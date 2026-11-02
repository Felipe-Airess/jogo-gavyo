# Nova estratégia para o mapa (02/11/2026)

Felipe avaliou: o mapa continua ruim. O caminho até aqui gerou a escola inteira
por coordenadas soltas no código (`capitulo1/escola.gd`, retângulos do desenho ×
escala), e isso não chegou a um resultado bom. Felipe pediu para mudar a
estratégia, pesquisando o que a comunidade recomenda para fazer mapa com IA.

## O que a pesquisa indica

1. **Kit modular em grade fixa + GridMap/MeshLibrary.** É o caminho mais citado
   para geometria limpa e consistente. As peças são múltiplos de uma unidade (ex.:
   2 m): parede, parede com porta, parede com janela gradeada, canto, coluna,
   piso de azulejo, piso de cimento, meia-parede de azulejo, telhado e degrau.
   Cada peça tem o pivô na base e colisão própria.
   Fontes: [skill godot-3d-world-building](https://github.com/thedivergentai/Game-Dev-Agentic-Skills/blob/main/skills/godot-3d-world-building/SKILL.md),
   [kit modular no Blender](https://gamineai.com/courses/build-stylized-3d-environment-art-blender/lessons/lesson-3-modular-kit-planning-blender),
   [relato com GridMap](https://itch.io/post/7039042).
2. **Mapa como texto em grade.** A IA edita grade de texto muito melhor do que
   coordenadas soltas, e Felipe consegue ler e corrigir direto. Um arquivo
   ASCII por andar, em que cada caractere é uma célula de 1 m (ex.: `#` parede,
   `D` porta, `W` janela, `.` piso interno, `,` cimento externo, `C` coluna,
   `S` escada, `T` árvore), é convertido para GridMap por um script.
3. **Decalcar a planta**, a partir de imagem de vista de cima, em escala, como
   faz o fluxo de arquitetura no Blender:
   [planta no Blender](https://gachoki.com/turn-a-2d-image-into-a-3d-building-in-blender/),
   [vídeo](https://www.youtube.com/watch?v=Xb4ddBuiTU0).
   Ou desenhar a planta em editor de nível (TrenchBroom + func_godot).
4. **IA com controle do editor e verificação por imagem.** Exemplos:
   [Claude-GoDot-MCP](https://github.com/PiMPStudios/Claude-GoDot-MCP),
   [godot-mcp-skills](https://github.com/PooDoge/godot-mcp-skills),
   [godogen](https://github.com/matthias-scale/godogen),
   [Blender MCP: limites](https://www.mindstudio.ai/blog/claude-blender-mcp-real-world-performance).
   Todos insistem em capturas a cada passo e em playtest.
5. **Bloqueio aprovado antes de decorar.** O laço é: blockout cinza → planta de
   cima + capturas → aprovação de Felipe → só então materiais e objetos
   ([guia](https://best-games.io/blog/codex-claude-code-blender-mcp-game-development-guide)).

## Plano proposto para o novo chat

1. Criar o kit modular (peças de 2 m) como cenas e MeshLibrary.
2. Escrever `godot-3d/capitulo1/mapa/terreo.txt` e `superior.txt` em grade ASCII
   de 1 m, a partir do desenho de Felipe, das fotos e das correções registradas
   em `docs/LEVEL-DESIGN-CAPITULO1.md` e `docs/PASSAGEM-PARA-CLAUDE.md`.
3. Script que lê o ASCII e monta o GridMap, os colisores, as portas e os
   esconderijos. Os pontos da história (acordar, bolsa, escada, ritual, portão)
   vêm de letras marcadas no ASCII.
4. Gerar a planta de cima e capturas, e mostrar a Felipe o ASCII e a planta
   **antes** de decorar. Ele corrige o texto direto.
5. Manter os testes existentes: percurso, nível, ritual, toque.

## O que não mudar

Decisões de história e de jogo em `docs/PASSAGEM-PARA-CLAUDE.md` e
`docs/LEVEL-DESIGN-CAPITULO1.md` (escada no pátio de química, ritual em
andamento, empurrão/agarrão, controles de toque, retrô por SubViewport etc.).
A escola atual fica como referência até o mapa novo substituí-la.

## Estado da publicação

A `main` tem só a primeira versão do capítulo (PR #16). O PR #17 com a versão
mais recente aguardava merge quando esta estratégia foi registrada.
