# Reformulação das animações do GAVIÃO

Objetivo: reconstruir as animações em partes para ficarem bonitas, legíveis e fluidas, mantendo o mesmo Sorriso entre todos os movimentos. Esta produção é 2D.

Cada lote será mostrado para revisão antes de sua integração ao jogo. Aparência aprovada e animação em revisão são estados diferentes: produzir o lote não significa aprovação automática de sua qualidade.

| Ordem | Lote | Conteúdo | Estado |
| --- | --- | --- | --- |
| 1 | Base + idle | Modelo corporal, guarda em ¾, cabelo preto, pele clara, uniforme e respiração. | Aprovado pelo usuário: “Ficou top vamos pra proxima etapa”. |
| 2 | Locomoção | Andar, correr, largada, freada, giro, abaixar, permanecer e levantar do agachamento. | Candidato entregue em `02-LOCOMOCAO`, em revisão. |
| 3 | Socos + chutes | Soco baixo prioritário; jab/corpo, cruzados, pesado, reverso, impulso, chutes e ligações. | Desenhos aceitos; 13 sequências com ritmo revisto, integradas no treino 0.7.0. |
| 4 | Defesa + reações | Guarda, absorção, parry por braço, respostas, impactos localizados, cansaço, tropeço e quedas. | Pedido detalhado em [PEDIDO-LOTES-4-5.md](PEDIDO-LOTES-4-5.md) (26/10/2026); aguardando desenhos. |
| 5 | Clinch + chão | Cotovelada prioritária; pega, sustentação, arrasto, soco, joelho, soltura, derrubada, levantar, três ações no chão e limpeza das mãos. | Clinch com dois atores no mesmo pedido; aguardando desenhos. |
| 6 | Extras do guia | Uppercut, gancho adicional, teep, golpes curtos fora do clinch, recuo/contra-ataque, rasteira, empurrão, ação adicional no chão e gestos de personalidade. | Por último, após a base e a biblioteca principal. |

O escopo detalhado continua em `GAVIAO-SPRITES-PARA-OUTRO-AGENTE/GUIA-DE-ANIMACOES.md`, na pasta outputs. Aqui ele é uma lista de produção; não representa mecânicas adicionais já implementadas.

Regras comuns: uma escala por modelo, proporções preservadas, pivôs explícitos, membros completos, contatos coerentes, transições e tempos próprios. Não deformar o corpo inteiro para preencher quadros nem usar 30 desenhos como obrigação universal.

Celular: o usuário pediu apenas a avaliação de viabilidade neste momento. Adaptação dos comandos por toque, endereço remoto e hospedagem do jogo ficam adiados. Envio do projeto ao GitHub foi autorizado após concluir o lote 3; isso não significa habilitar publicação jogável ou aprovar automaticamente a arte.

Atualização de escopo: o usuário solicitou depois a primeira build mobile. A build 0.7.0 inclui controles de toque, treino com dois alvos e preparação para acesso pelo GitHub Pages. A orientação anterior de adiar mobile deixou de valer.
