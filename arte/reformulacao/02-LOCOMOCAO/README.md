# Lote 2 — locomoção de Sorriso

**Candidato para revisão visual.** A base e o idle do lote 1 foram aprovados pelo usuário. Este lote tem sua própria prévia; a integração ao jogo vem após a revisão.

Abra http://127.0.0.1:4181 . Para iniciar novamente, execute `INICIAR-PREVIA.cmd` com Node instalado e mantenha a janela aberta.

## Movimentos

| Movimento | Quadros | Reprodução |
| --- | ---: | --- |
| Caminhada | 8 | Ciclo |
| Corrida | 12 | Ciclo |
| Largada | 8 | Uma vez |
| Freada | 8 | Uma vez |
| Giro para a esquerda | 8 | Uma vez |
| Abaixar | 8 | Uma vez |
| Agachado | 8 | Ciclo |
| Levantar | 8 | Uma vez |

São 68 posições nas oito sequências. A subida reutiliza os oito desenhos da descida em ordem inversa, com tempos próprios. Portanto são 60 desenhos distintos, sem contar a base de comparação. A tentativa de subida independente foi rejeitada porque alterava a proporção na entrada.

## Arquivos e revisão

- `folha-geral.png`: base aprovada ao lado de uma seleção de poses de cada sequência.
- `folha-*.png`: folhas completas ampliadas, com identificação fora das células.
- `run-previa.gif` e `walk-previa.gif`: ciclos ampliados para visualização.
- `*-atlas.png`: folhas transparentes sem legendas; `quadros/` contém os PNGs separados.
- `locomocao.json`: quadros, tempos, pivô, ordem, escala e fases propostas.
- `fontes/` e `poses/`: desenhos de origem e referências de ligação preservados.
- `*-medidas.json`: dimensões e limites dos recortes; `verificacao.json`: verificações técnicas.
- `PROMPTS.txt`: conjunto de prompts e modo de geração utilizado.

A prévia permite comparar, pausar, escolher quadro, reduzir a velocidade, mudar o fundo e exibir guias. As transições param no último quadro. “Chão em movimento” é uma referência visual de velocidade constante para caminhada/corrida; não é o movimento final do personagem no jogo nem uma comprovação automática de contato dos pés.

## Padronização e limites concretos

A pose aprovada do lote 1 foi a referência de aparência. As folhas usam pele clara, cabelo preto com volume lateral, polo escolar branca/verde/amarela, jeans e tênis claros. Os desenhos foram produzidos pela ferramenta integrada de imagens, com guias de poses 2D para a locomoção, e preparados em células de 128×96 com pivô (64,88).

Cada folha inteira recebe **uma única escala uniforme** e cada desenho completo recebe somente translação para registrar o apoio. Não há deformação de membros, interpolação de silhuetas ou redimensionamento independente por quadro. A referência de altura das poses de comparação é 66 pixels; a corrida inclinada usa contato de 60 pixels e o agachamento completo, 38. Isso não significa obrigar poses dobradas a terem a altura de uma pose em pé. Na corrida, a indicação de voo desloca o desenho completo acima da linha do chão.

O recorte procura silhuetas inteiras em vez de cortar a fonte em retângulos cegos. Essa escolha evita o antigo corte no joelho. Pixels vermelhos isolados e componentes desconectados de fundo são excluídos durante a preparação; as fontes originais permanecem preservadas.

**Pontos que ainda precisam de avaliação artística:** a corrida tem rotação do tronco e alternância de membros, mas a troca de braços e algumas passagens ainda podem parecer abruptas. Há pequenas variações de contorno, cabelo e dobras entre desenhos gerados. As extremidades das folhas de largada/freada são aproximações das poses de guarda/corrida, não cópias idênticas; não prometemos uma ligação sem salto antes de testar a montagem no jogo. A subida em ordem inversa já compartilha exatamente os desenhos e proporções da descida. Não foram acrescentados quadros artificiais por esticar o personagem.

Os testes verificam recortes, arquivos e controles; não certificam fluidez, anatomia ou semelhança por si só. O lote está disponível para revisão, sem atualizar o combate nem substituir os sprites da versão 0.6.1.

Depois desta revisão: socos e chutes. Defesa/reações e clinch/chão seguem depois. Os extras do guia ficam por último.
