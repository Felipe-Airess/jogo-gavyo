# Revisão independente — Claude

Estado: **roteiro preparado; revisão não executada**.

Revise a branch `feat/godot-combat-poc`, exclusivamente a POC e suas configurações
novas. Não altere Phaser, não mescle o PR e não recomende migração integral sem
comparação em aparelho real. Leia `AGENTS.md` e `godot-poc/README.md`; o usuário
autorizou a engine alternativa apenas nesta pasta isolada.

## Parecer esperado

1. Arquitetura: separação modelo/desenho, passo fixo, determinismo, custo da cópia
   do atlas, reprodutibilidade do instalador e exportação Linux/Web sem threads.
2. Bugs: contatos nos dois sentidos, paredes, aproximação, golpes simultâneos,
   guarda de frente/esgotamento, interrupção por reação, golpe único, dano antes
   do contato, reset durante ataque, perda de foco e toque cancelado.
3. Combate: preparação legível, comprometimento ao errar, janela entre jab/direto,
   fôlego, duração das reações e hitstop, alcance visual versus caixas. Considere
   o viés explícito de resolver jogador antes de rival no mesmo tick.
4. Arte: conferir original, pivôs e espelhamento com Caixas ligado; não confundir
   reação antiga ou recuo sem arte própria com limitação da engine. Não substituir
   arte faltante por ações incompatíveis.
5. Mobile: 2–3 dedos, segurar botão sem spam, arrastar para fora, interrupção do
   navegador, retrato/paisagem, legibilidade, tamanhos e alcance dos controles.
6. Ambiente: criar Codespace pelo celular, aguardar exportação, abrir porta 8060
   privada no celular e no PC; reiniciar ambiente e refazer build após edição.

Para cada achado, informar gravidade, arquivo/linha, como reproduzir, resultado
observado, resultado esperado e correção mínima recomendada. Distinguir bug,
limitação declarada e preferência de balanceamento. Rodar os testes Godot e
revisar evidências de navegador; registrar o que foi efetivamente testado.

Entregar parecer: manter só como experimento / corrigir e reavaliar / ampliar a
POC, com razões. O usuário continua decidindo a sensação do combate e a arte.
