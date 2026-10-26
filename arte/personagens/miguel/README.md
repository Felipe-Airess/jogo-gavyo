# Miguel — primeiro lote

Foram integradas somente as duas folhas enviadas pelo usuário, preservadas em
`fontes/`: 10 quadros de idle e 16 de guarda. As fotos pessoais de referência
não fazem parte do repositório.

`python scripts/prepare-miguel.py` (Python 3 + Pillow) prepara
`assets/miguel.png` e `assets/miguel.json`. Recorta as figuras, separa o fundo
claro e o rabisco de revisão, preenche a máscara interior da polo e reduz por
nearest-neighbor. Não gera desenhos nem interpola articulações.

Célula 128×96, pivô (64,88), aproximadamente 70 pixels em pé e 66 na guarda
mais alta, comparados à guarda de Sorriso. A escala é uniforme por folha:
as poses mais baixas da segunda linha continuam mais baixas. Os limites do
recorte e as escalas ficam registrados no JSON. Alguns tênis/cabelos já chegam
ao limite das folhas originais; não foi inventado conteúdo fora desses limites.

Miguel aparece no corredor como observador. O seletor **Miguel** alterna idle
e guarda. Os quadros avançam só durante o jogo e reiniciam ao trocar de pose ou
reiniciar o treino. Não há colisão, golpes, reações, locomoção ou uso das poses
de Sorriso para simular ações ainda não entregues.
