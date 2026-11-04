# QA técnico — Bola (revisão parcial)

O validador de malha passou. A fidelidade visual ainda não foi aprovada; ver RESULTADO.md.

| Peça | Triângulos | Sem peso | Mais de 4 influências | Normais inconsistentes |
|---|---:|---:|---:|---:|
| Bola | 18060 | 0 | 0 | 0 |
| FardaPolo | 58432 | 0 | 0 | 0 |
| Calca | 2588 | 0 | 0 | 0 |
| Tenis | 17260 | 0 | 0 | 0 |
| Cabelo | 6000 | 0 | 0 | 0 |
| GolaPolo | 256 | 0 | 0 | 0 |

Total: 102596 triângulos. Rig: 22 ossos. Nenhum erro no perfil game da skill.

## Avisos preservados

- 19 pares de faces internas opostas da malha MakeHuman e 14 pares entre pele/cabelo: invisíveis nas vistas abertas; aceitos provisoriamente nesta revisão, sem declarar a geometria final otimizada.
- Dois componentes do tênis classificados como encerrados: peças dos dois pés, vistas de frente/lado/costas e em movimento. Não são objetos flutuantes no relatório.
- Gola e peças de roupa têm bordas abertas intencionais; perfil game permite bordas abertas.
- A inspeção numérica de costuras via Rust/MCP não foi executada. Não declarar distância de costura ou ausência de toda interpenetração medida.

As folhas random.png e wire.png foram geradas pelo helper da skill e abertas. A adaptação para Blender 3.6 remove somente image_settings.media_type (ausente nessa versão) e reduz a espessura de visualização dos fios para malhas densas. Nenhum critério numérico foi relaxado.

GLB e FBX estáticos reimportados em cenas vazias: 22 ossos, 6 peças, cores e UVs preservados. O GLB de inspeção com os três clipes também foi reimportado: 22 ossos, três ações, desvio de escala dos ossos menor que 0,000002. Folhas em ../rig-exportado/. Isso comprova estrutura e escala, não identidade facial ou desempenho no Godot.
