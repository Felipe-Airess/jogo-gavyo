# Gavião — entrada para o Claude

Leia primeiro `AGENTS.md` e `docs/PASSAGEM-PARA-CLAUDE.md`. A passagem registra
o que foi feito, testes executados, limites reais e próximos trabalhos.
Depois leia `docs/CONTINUAR-NOUTRO-CHAT.md`, `docs/DECISOES-RODADA-3.md`, o mapa
`docs/referencias/mapa-escola-felipe.png` e `godot-3d/capitulo1/README.md`.

Branch: `feat/prototipo-terror-terceira-pessoa`. Cena atual:
`godot-3d/capitulo1/main.tscn`. O mapa vem de `godot-3d/capitulo1/mapa/*.txt`
(grade ASCII, 1 m por caractere; ver `LEIA-ME.md` ali). Bloqueio cinza aguardando
aprovação de Felipe: não decorar antes. Godot **4.5.1 Compatibility**, sem atualizar engine.
No Mac: `bash JOGAR-PROTOTIPO.command`. No Linux, instalar o executável Godot
4.5.1 Linux e definir `GODOT` para os scripts de teste; não usar o `.app` do Mac.

As skills pertinentes estão versionadas em `.claude/skills/`, com scripts e
referências locais. Leia o `SKILL.md` da frente em uso. Algumas citam Godot 4.7;
confira APIs contra 4.5.1. Skills não instalam Blender, MCPs, Python ou modelos
automaticamente. Se um backend não existir, registre a limitação e use o caminho
local disponível, sem declarar a ferramenta instalada ou um asset aprovado.

Felipe prefere português brasileiro e trabalho em entregas integradas. Não repetir
perguntas respondidas. Não recomeçar o projeto, não pedir avaliação de sala isolada
como condição de progresso. A integração ainda não foi avaliada por ele.
Preservar modelos originais, decisões e histórico. Falas de Miguel serão dadas
por Felipe. Não inventar falas aprovadas nem planejar gameplay do capítulo 2.

A memória pessoal `/Users/felipe/MEMORIA.md` é exclusiva do Mac. Na nuvem, use a
documentação deste repositório para o contexto do Gavião; não bloquear o trabalho
por ausência daquele arquivo nem inventar histórico.
