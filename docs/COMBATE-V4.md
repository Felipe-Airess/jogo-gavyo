# Combate 0.4 — integração jogável

Sorriso usa os quadros completos da folha enviada pelo usuário. A cena carrega `battle.mjs`, `sprite-player.mjs` e `ragdoll.mjs`; o antigo animador por peças do protagonista está fora da cena.

## Movimento e compromisso

A velocidade acelera até 49 pixels/s andando ou 88 correndo. Ao soltar a corrida, desacelera gradualmente e entra em frenagem. As fases de locomoção acompanham a distância percorrida; a posição no mundo não reinicia ao fechar um ciclo.

Cada golpe tem preparação, contato e recuperação. O avanço fica incorporado à posição real, sem voltar à origem. Um pesado errado acrescenta perda de equilíbrio e impede outro ataque durante essa recuperação. O leve errado recupera sem tropeço obrigatório.

## Contato e sequência

A caixa ativa do punho/pé é separada da colisão dos pés. Uma varredura entre posições reduz contatos perdidos durante a extensão. A interseção com cabeça ou tronco, mais o alinhamento em profundidade, determina a região. O bloqueio frontal intercepta o golpe nos braços, sem dano ao tronco/cabeça e sem recuo.

J inicia o soco. Após contato no corpo, a postura do alvo abre a cabeça para o direto; após cabeça, o próximo golpe pode desequilibrar. Cada continuação exige novo comando após confirmar contato, com tolerância curta para recuperação. Não há fila automática de três golpes. A terceira região continua dependendo da geometria, não de uma ordem imposta.

Frente+J dá um pesado, trás+J vira e golpeia, baixo+J dá um golpe baixo; K chuta. As direções são relativas ao olhar. O golpe tem no máximo um contato por execução.

## Clinch e partes

G exige proximidade e abertura por atordoamento, tronco comprometido ou guarda rompida. Durante um acerto, G pode aguardar a recuperação; também é aceito na pausa do impacto. Os corpos se aproximam progressivamente. A pega dura até 1,5 segundo, G solta e J/K aplica uma joelhada por comando. Três joelhadas ou tronco esgotado encerram a pega em queda.

| Região | Resistência | Consequência ao esgotar |
|---|---|---|
| Cabeça | 70 | Desmaio e queda sem levantar automaticamente |
| Tronco | 80 | Cede e protege barriga; perde combate |
| Braços | 60 | Perde guarda e contra-ataques |

As barras são independentes por alvo. Bloqueios retiram 12 dos braços; não transferem dano oculto às outras regiões. R reinicia tudo.

O ragdoll simplificado pertence aos manequins: vínculos, gravidade, piso, amortecimento e impulso próximo ao contato. O protagonista preserva os desenhos inteiros.

## Limite artístico

O clinch ainda usa uma pose de guarda aproximada; as mãos segurando o pescoço não têm desenho dedicado. A joelhada adapta a preparação do chute. Frenagem, tropeço e reverso também reutilizam poses. Essas adaptações permitem testar as regras, mas precisam de novos desenhos para atingir a naturalidade pretendida. Não se deformou o protagonista para fabricar intermediários. Os manequins continuam sendo arte procedural de treino.
