# Miguel — lista de animações

Base obrigatória em todo pedido: mestra da guarda e do neutro, model sheet e as
regras salvas no ChatGPT. Formato: célula 128×96, pivô no chão (64,88), olhando
para a direita, guarda com ~66 px de altura, fundo magenta liso, sem efeitos.
Primeiro e último quadro de toda animação = guarda da mestra (exceto quedas).

"Avanço" é quanto o corpo anda para frente **dentro da folha** durante a
animação. O jogo mede pelos pés e move o sprite exatamente isso; o pé apoiado
não pode mudar de pixel enquanto estiver no chão.

## 1. Essenciais (sem isso não dá para lutar)

| # | Animação | Quadros | Contato | Avanço | Observação |
| --- | --- | --- | --- | --- | --- |
| 1 | Guarda respirando (loop) | 6 | — | 0 | Só ombros/peito sobem 1 px. Cabeça e pés parados. |
| 2 | Andar em guarda para frente (passo de boxe) | 6 | — | 1 passo (~14 px) | Pé da frente sai e pousa; depois o de trás acompanha. Substitui o lote 2. |
| 3 | Andar em guarda para trás | 6 | — | −1 passo | Pé de trás sai primeiro; o da frente acompanha. |
| 4 | Jab (mão da frente) | 8 | 4 | 0 | Volta pelo mesmo caminho. |
| 5 | Direto (mão de trás) | 9 | 5 | 0 | Gira quadril e ombro; calcanhar de trás sobe. |
| 6 | Jab com passo | 8 | 4 | ~10 px | Pé da frente avança junto com o soco; o de trás acompanha na volta. |
| 7 | Direto com passo | 9 | 5 | ~12 px | Avança no tempo do soco; termina em guarda à frente. |
| 8 | Chute circular no corpo | 12 | 6 | 0 | Pé de apoio gira; chute na altura do tronco. |
| 9 | Chute na perna | 10 | 5 | 0 | Canela na coxa do adversário. |
| 10 | Bloqueio alto (entrar, absorver, sair) | 6 | — | 0 | Braços fecham a cabeça; recua 2 px no impacto. |
| 11 | Reação leve na cabeça | 5 | — | −4 px | Cabeça vira para trás e volta. |
| 12 | Reação forte na cabeça | 7 | — | −8 px | Cabeça e tronco jogados; pé de trás recua. |
| 13 | Reação no corpo | 6 | — | −4 px | Dobra no tronco, cotovelo desce. |
| 14 | Reação na perna | 6 | — | −2 px | Joelho cede, recupera. |
| 15 | Queda de costas | 6 | — | −16 px | Do impacto ao chão; último quadro deitado. |
| 16 | Deitado (loop curto) | 2 | — | 0 | Respiração; cabeça do lado oposto ao adversário. |
| 17 | Levantar | 7 | — | 0 | Do chão à guarda. |

## 2. Importantes (combate fluido e "acompanhar" o adversário)

| # | Animação | Quadros | Contato | Avanço | Observação |
| --- | --- | --- | --- | --- | --- |
| 18 | Gancho de frente (cabeça) | 9 | 5 | 0 | Cotovelo alto, gira o pé da frente. |
| 19 | Gancho com passo | 9 | 5 | ~8 px | Para emendar depois do direto. |
| 20 | Jab no corpo | 8 | 4 | 0 | Joelhos dobram, cabeça desce. |
| 21 | Direto no corpo com passo | 9 | 5 | ~10 px | Entra baixo. |
| 22 | Uppercut | 9 | 5 | 0 | Sai de baixo; fecha sequência curta. |
| 23 | Chute circular alto | 12 | 6 | 0 | Cabeça. |
| 24 | Chute frontal (teep) | 9 | 5 | 0 | Empurra o adversário para longe. |
| 25 | Golpe pesado (overhand) | 12 | 6 | ~10 px | Carrega o corpo; erro deixa aberto. |
| 26 | Aparo + contra-ataque | 8 | 5 | ~6 px | Desvia com a mão da frente, responde com a de trás. |
| 27 | Grogue (cambaleando, loop) | 6 | — | 0 | Guarda baixa, joelhos moles. |
| 28 | Agarrar o braço e arremessar | 10 | 6 | ~6 px | Par com o 29. Pega o pulso, gira e joga. |
| 29 | Sendo arremessado | 10 | 6 | −20 px | Mesmo tempo do 28; termina deitado. |
| 30 | Soco no chão (martelo) | 8 | 4 | 0 | Ajoelhado ao lado da cabeça. |
| 31 | Chute/pisada no chão | 8 | 4 | 0 | Pé desce sobre o tronco. |
| 32 | Apanhando no chão | 4 | — | 0 | Deitado, corpo reage ao golpe. |

## 3. Bom ter

| # | Animação | Quadros | Observação |
| --- | --- | --- | --- |
| 33 | Esquiva para trás (lean) | 6 | Tronco recua, pés parados. |
| 34 | Esquiva lateral (slip) + contra | 8 | Cabeça sai da linha e responde. |
| 35 | Correr | 8 | Ciclo. |
| 36 | Arrancada e freada | 6 + 6 | |
| 37 | Clinch: pegar no pescoço | 6 | Par com 38. |
| 38 | Clinch: segurado resistindo | 6 | |
| 39 | Joelhada no clinch | 8 | Contato no 4. |
| 40 | Cotovelada | 8 | Curta distância. |
| 41 | Nocaute em pé (desaba) | 8 | Diferente da queda comum. |
| 42 | Provocar / limpar sangue da mão | 8 | Personalidade. |
| 43 | Vitória | 8 | Fim da luta. |

## Ordem de produção sugerida

1, 2, 3 → 4, 5, 6, 7 → 11, 12, 13 → 10 → 8, 9 → 14, 15, 16, 17 →
20, 21, 18, 19 → 28, 29, 30, 31, 32 → 26, 27 → resto.

Uma animação por pedido. Ao receber, o agente roda a limpeza técnica, extrai
marcadores (`scripts/extract-markers.py miguel`), mede o avanço pelos pés e
integra; nada é redesenhado em código.
