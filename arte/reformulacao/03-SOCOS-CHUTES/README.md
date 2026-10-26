# Lote 3 — socos e chutes

**Desenhos aceitos pelo usuário; ritmo revisto para a build 0.7.0.** Treze sequências usam a pose aprovada de Sorriso como referência. Os desenhos e seus tempos revistos agora são usados no treino 0.7.0. A primeira exportação deste lote foi entregue separada do jogo; esta integração foi pedida depois da avaliação dos sprites.

## Ver e conferir

Abra http://127.0.0.1:4182 . Para reiniciar o servidor, execute `INICIAR-PREVIA.cmd` com Node instalado. A prévia mostra a base ao lado do golpe, câmera lenta, escolha de quadro, guias de apoio e sobreposição do desenho anterior. Cada golpe para no último quadro. Use Reiniciar para vê-lo novamente.

`folha-geral.png` compara poses de todas as sequências; `folha-*.png` mostra cada ação completa. `*-atlas.png`, `quadros/` e `golpes.json` são os arquivos para futura integração. As fontes PNG selecionadas permanecem em `fontes/`; os prompts estão em `PROMPTS.txt`. A criação usou a ferramenta integrada de imagens, sem modelagem 3D.

Os GIFs de soco baixo e soco → chute repetem a ação para demonstração. Essa repetição não representa permissão para cancelar a recuperação ou atacar sem intervalo no jogo.

| Sequência | Desenhos selecionados | Função visual |
| --- | ---: | --- |
| Soco baixo no corpo | 12 | Braço dobrado, quadril e joelhos participando |
| Jab na cabeça | 12 | Direto curto na linha alta |
| Jab no tronco | 12 | Entrada com abaixamento da postura |
| Cruzado na cabeça | 12 | Rotação do ombro e quadril |
| Cruzado no tronco | 12 | Rotação com base mais baixa |
| Soco pesado descendente | 15 | Preparação, arco e continuação |
| Giro e golpe para trás | 12 | Guarda direita, giro, contato à esquerda e guarda esquerda |
| Soco de impulso | 16 | Passada, entrada com o corpo e recuperação |
| Chute na perna | 12 | Apoio, giro, extensão e recolhimento |
| Circular no tronco | 16 | Câmara do joelho, extensão e recolhimento |
| Circular alto | 16 | Câmara alta e contrapeso do tronco |
| Soco → chute | 16 | Recolhimento do braço preparando o quadril |
| Chute → soco | 16 | Recolhimento e pouso da perna antes do direto |

São 179 quadros selecionados. No pesado, uma pose de preparação que se repetia no meio do gesto foi retirada: a folha de origem tem 16 desenhos, a exportação usa 15. A última célula do atlas fica vazia; não é um quadro da animação. A folha de soco → chute foi redistribuída para separar desenhos que encostavam na origem.

## Escala, apoio e tempos

Células lógicas de 128×96, pivô (64,88), ampliação nearest-neighbor. Cada fonte usa uma escala uniforme baseada na pose de comparação em guarda de aproximadamente 66 pixels. Uma pose dobrada, inclinada ou com a perna levantada pode ter outra altura sem mudar o tamanho do modelo. Não há ajuste de escala por quadro, deformação de membros nem interpolação artificial de silhuetas.

Os desenhos completos são transladados para registrar o apoio. Nos golpes plantados para a direita, o registro usa a região visível do tênis traseiro; nos giros e combinações, o quadril. Este registro ajuda a revisão, mas não equivale a captura de movimento nem comprova que o pé esteja perfeitamente imóvel durante todas as rotações.

Preparação, contato, continuação e recuperação têm tempos próprios. `active` e `contactFrames` no JSON indicam **poses propostas para contato durante a revisão**. A primeira exportação não incluía hitboxes integradas; a build 0.7.0 deriva marcadores dos pixels e verifica os contatos no treino. `contactMarker` permanece nulo: os pontos exatos de mão, cotovelo e canela precisam ser marcados junto ao adversário e validados antes de alterar as colisões do jogo. Não foram inventadas coordenadas em lugares que o desenho não ocupa.

## Limitações que precisam de revisão visual

As folhas geradas têm pequenas variações de contorno, cabelo, dobras e posição de mãos. Jab e cruzado precisam de uma conferência cuidadosa da identidade do braço que golpeia; nomes diferentes não bastam para garantir essa distinção em todas as poses. Algumas retrações ainda passam rapidamente da extensão à guarda. O modo lento e a sobreposição deixam esses pontos visíveis.

O soco de impulso deste lote contém apenas Sorriso. Para testar carregamento e soltura com peso, será preciso sincronizá-lo com as reações do alvo da etapa seguinte; este lote não entrega uma animação de dois atores pronta. As entradas e saídas aproximam a guarda aprovada, mas ainda precisam ser montadas com o idle no jogo para conferir continuidade.

Os testes técnicos conferem PNGs, transparência, limites, escala e controles. Não certificam anatomia, fluidez ou aprovação artística. Ver `verificacao.json`.

## Próximas etapas e celular

Depois da revisão: defesa e reações; depois clinch/chão, incluindo cotovelada; por último os extras do guia. Não foram acrescentadas mecânicas com base apenas nesta lista.

É possível adaptar o protótipo web para testar no navegador do celular. Ainda seriam necessários comandos de toque e um endereço que o telefone alcance. `127.0.0.1` aponta para o próprio aparelho. A pedido do usuário, **controles móveis, túnel, hospedagem pública e publicação do jogo ficaram adiados**. Enviar o código ao GitHub não habilita automaticamente um endereço jogável.

## Revisão de ritmo 0.7.0

Por pedido do usuário, os tempos das fases aumentaram em aproximadamente 60–80%, com mínimo de 35 ms por desenho. `authoringDuration` preserva o tempo anterior e `timingRevision` identifica a revisão. A prévia mostra a ação completa; durante o jogo, as ligações mistas começam no recolhimento (quadro 5), pois o primeiro contato já aconteceu. Os GIFs foram atualizados.
