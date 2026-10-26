# Movimento e peso — versão 0.5

25/10/2026. Pedido atendido nesta iteração: corrida refeita, mais quadros, golpes com recuperação e compromisso, sangue, chute no chão, golpe em corrida com queda, chute circular e dano nas pernas. A cena continua em Phaser 3.90 com Canvas 320×180.

## O diagnóstico

A corrida anterior mostrava apenas seis poses e lia uma distância acumulada que também recebia avanços de ataque. Não havia descrição suficiente dos apoios para acertar a cadência. A correção não foi aumentar a velocidade de reprodução: entrou uma fonte dedicada com doze poses, contador próprio de corrida, fases por distância e correção limitada de apoio.

Os socos permitiam recomeçar sem uma recuperação obrigatória entre sequências. A 0.5 limita a cadeia comum a três ações, conserva uma única continuação e exige recuperar apoio depois. Fôlego impede repetir indefinidamente ações pesadas. Não sorteia falhas em contatos válidos.

## Métodos e pesquisa

- [Documentação oficial de animações do Phaser](https://docs.phaser.io/phaser/concepts/animations): distingue quadros, duração e velocidade de reprodução. A lógica local usa fases explícitas para manter contatos sincronizados; elevar FPS sozinho não cria desenhos intermediários.
- [Relato de jitter no fórum do Phaser](https://phaser.discourse.group/t/sprite-jitter-noticable-in-doc-examples/5322) e [outro relato envolvendo arredondamento/câmera](https://phaser.discourse.group/t/roundpixels-is-causing-jittering-with-cameras-main-startfollow/11880): são pistas de investigação, em versões antigas. Não provam a causa no nosso código. Foram mantidos arredondamento coerente, Canvas e a auditoria visual; não se adotou uma configuração antiga como solução universal.
- [Jonathan Cooper, princípios de animação aplicados a jogos](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games): preparação, reação e continuidade após impacto ajudam a transmitir massa, com janelas de retorno do controle. Nesta versão isso se traduz em contato ativo explícito, recuperação e golpe corrido que não pode parar imediatamente.
- [Onion-skin oficial do Aseprite](https://www.aseprite.org/docs/onion-skinning/) e [fluxo de animação](https://www.aseprite.org/docs/animation): ver quadros vizinhos é o método indicado para revisar manualmente apoio, arco e proporção. A ferramenta não foi instalada nem comprada. É uma referência para o acabamento artístico futuro.

Conclusão de implementação: as limitações observadas não exigem trocar o motor. Precisam de uma sequência de desenhos coerente, distância/tempo corretos, contatos legíveis e estados de apoio. Trocar o motor não produziria esses desenhos por si só.

## O que mudou

| Ação | Comportamento atual |
|---|---|
| Correr | Doze poses, relógio separado, passada de 96 px, apoio/passage/voo; offsets limitados a 3 px |
| Direto/cruzado | Seis poses por golpe, contato e recuperação explícitos |
| Sequência comum | Até três ações; recuperação final de 420 ms não aceita cliques novos |
| Golpe isolado | Também recupera, inclusive ao errar; fôlego por ação |
| Circular | Faixa de doze poses, contato no pé desenhado |
| Baixo + K em pé | Chute na perna, dano exclusivo nas pernas, passa sob guarda alta |
| Perna esgotada | Queda e incapacidade de levantar automaticamente |
| Shift + J com velocidade | Conserva impulso, leva massa junto; ao conectar lança o alvo e derruba Sorriso |
| Corrido bloqueado/errado | O alvo não é arrastado pelo bloqueio; Sorriso ainda perde equilíbrio |
| Baixo + K perto de caído | Animação distinta, contato na cabeça desenhada; não alcança alvo remoto ou em voo |
| Finalização | Marca `dead`, impede levantar; R restaura o treino |
| Sangue | Pixels/pequenas marcas temporárias, sem efeito em bloqueio; B desliga |
| Variação | Massa, resistência ao desequilíbrio, duração de queda e intervalos de resposta; semente reproduzível |

Os alvos seguem como manequins de treino. Sangue e finalização demonstram a mecânica e apresentação; não foram implementados outros personagens da narrativa. Não há chance aleatória de morte instantânea nem contato que erra por sorteio.

## Arte e extração

Ferramenta integrada de geração de imagens. Fontes preservadas:

- `references/sorriso-corrida-v5-fonte.png`: corrida dedicada, doze poses em duas linhas de seis.
- `references/sorriso-acoes-v5-fonte.png`: fonte editorial das ações.
- `SPRITES-PROMPTS-V5.txt`: prompts finais de ambas as gerações.

O atlas `assets/sorriso-v5.png/.json` tem 210 células 128×96: 138 quadros anteriores e 72 recortes novos, em seis faixas. A fonte editorial veio com quadros extras, uma pose de chute invertida e duas silhuetas encostadas na queda. A preparação seleciona doze por faixa, exclui o erro e isola as silhuetas. Também remove guias e rótulos, preserva o chão das fases aéreas e calibra por faixa. O emblema azul e a perna erguida não devem ser usados como raiz; há correções explícitas de cintura nos casos ambíguos.

Os novos quadros são desenhos inteiros. Não são interpolados deformando os membros. Pequenas diferenças de traço, proporção e transição permanecem: são quadros-chave gerados, não uma animação final revisada manualmente. Os registros da geração são fontes para editar, não um atlas pronto para recortar às cegas.

## Evidência e limites

46 testes de regras aprovados. Cobrem a corrida em 30/60 quadros, relógios independentes, recuperação contra spam, partes do corpo, pernas, golpe corrido, bloqueio, finalização por contato visível, profundidade, aleatoriedade reproduzível e limites de sangue, além do combate existente.

Onze verificações de navegador aprovadas em `browser-test-v5.json`: Canvas, doze quadros reais de corrida, recuperação contra spam, sangue, circular, pernas/queda, finalização sem levantar, ambos caindo no corrido, opção de sangue/reset, debug/pausa e largura 390 sem rolagem horizontal. Zero erros e zero desenhos com suavização na auditoria. Gravação: `peso-v5.webm`. Capturas de corrida, queda conjunta, chute no chão e finalização foram inspecionadas.

A amostra de FPS durante gravação/automação variou e terminou próxima de 30. Não é benchmark do ThinkPad T400. Partículas são limitadas a 48, marcas a 24; não há dependência nova de runtime.

A física de queda é simplificada; o desenho segue a trajetória sem coincidir os membros com cada vínculo. O ponto da cabeça para finalização/debug acompanha o quadro deitado, evitando usar um nó invisível como alvo. O contra-ataque do manequim ainda não possui uma faixa própria de ataque. Não há som. A naturalidade final exige avaliação visual e retoque manual dos intermediários — testes de estado não certificam essa qualidade.
