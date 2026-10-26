# Escala, combinações e clinch — 0.4.2

25/10/2026. Pedido: corrigir tamanhos entre sprites, diferenciar combinações de soco/chute e permitir que o clinch abra guarda e sustente vários golpes.

## Escala e apoio

A avaliação anterior apenas por altura total foi insuficiente. Uma postura com joelhos dobrados e pernas abertas tem altura menor mesmo com cabeça, tronco e membros do mesmo tamanho. Comparar apenas os limites da silhueta havia deixado a família complementar maior em relação às poses de luta originais.

O atlas atual é `sorriso-padronizado.png/.json`. Os 138 desenhos foram preservados. A calibração compara referências de cabeça e tronco, mantendo um fator comum por família: a arte original é ampliada em 1,25; o Sorriso complementar mantém seu tamanho; os manequins separados recebem 1,2 para se aproximarem do parceiro dos quadros de contato. Não se aumenta cada pose agachada até a altura de uma pose em pé, nem se esticam membros isoladamente.

Célula 128×96, raiz (64,88). Essa é uma margem transparente de empacotamento, não a altura obrigatória da figura. Jogador e alvo usam a mesma configuração de origem. O preparo e o renderer preservam nearest-neighbor. Os marcadores de mão/pé e de cabeça/pescoço/quadril acompanham as escalas aplicadas. Comparação visual: `padronizacao-v42.png`.

As duas fontes ainda possuem pequenas diferenças de traço e desenho que redimensionamento não transforma em arte idêntica. Não foi gerada uma nova folha nesta revisão.

## Combinações mistas

| Entrada | Resultado |
|---|---|
| J, depois K durante o soco | Recolhimento do braço, preparação e chute alto |
| K, depois J durante o chute | Recolhimento da perna e retorno de soco |
| J após contato confirmado | Continuação que aproveita a região atingida e a abertura |

As duas misturas têm receitas próprias de quadros de mais de uma faixa, durações, contato e avanço. Não passam por idle entre os golpes. O chute alto reutiliza a faixa própria de chute alto, diferente do chute frontal isolado. O retorno usa a faixa de combo.

Uma única continuação pode ser preparada, inclusive durante a preparação do primeiro golpe. Não há fila automática de uma sequência inteira. O gesto misto também pode completar quando o primeiro golpe erra, mas cada contato ainda exige alcance e profundidade. Um mesmo golpe causa no máximo um contato. As caixas de chutes ativos usam os marcadores de pé da arte.

## Clinch

G de perto não exige mais ferir antes o adversário. A entrada dura 240 ms e abre guarda intacta. Desgasta 18 dos braços, sem dano automático a cabeça/tronco. A defesa fica suspensa enquanto preso; depois de soltar, pode retornar se os braços ainda funcionam.

Os primeiros 70 ms mantêm os atores separados enquanto se aproximam; só então entram os quadros pareados. Isso reduz o salto de posição ao trocar a figura independente pelo parceiro desenhado no quadro de contato.

J/K aplica uma joelhada por comando, com 10 de dano no tronco. Removido o limite fixo de três: são oito a partir de tronco cheio, ou menos se ele já estava ferido. Cada acerto renova 700 ms da pega, até o máximo de 4 segundos; o tempo inicial é 3,2 segundos. Parar deixa escapar, G solta e o tronco esgotado encerra a pega em queda. Um golpe pode preparar o próximo após o contato, sem acumular cliques para dezenas de golpes automáticos.

## Verificação

35 testes aprovados, zero falhas. Incluem os marcadores do atlas real, combos mistos nos dois sentidos, ausência de dano remoto, entrada de clinch, guarda intacta, mais de três golpes, continuidade da pega, preparação de uma próxima joelhada e saída por tempo/G/tronco esgotado.

Quinze verificações no navegador: Canvas 320×180 e alvos independentes, movimento/frenagem, sequência por regiões, J→K, K→J, erro pesado, giro, bloqueio sem recuo, braços comprometidos, G abrindo guarda, quatro e oito golpes no mesmo clinch, clinch após contato, tronco cedendo, pausa/debug e página estreita. Relatório detalhado: `browser-test-v42.json`; gravação: `combate-v42.webm`.

As capturas de chute alto, retorno de soco, joelhada e alvo cedendo foram inspecionadas, além da comparação de escala. O navegador carregou o atlas padronizado, sem o rig antigo, sem erros de execução e sem suavização na auditoria do canvas. Resultados de regras não equivalem a aprovação artística final. O ThinkPad T400 continua sem medição física; gravação/automação também interferem nas leituras de FPS e memória.
