# Lote 1 — proposta de base e idle

**Estado: aprovado pelo usuário, antes da integração.** A primeira entrega desta reformulação é somente a aparência-base e o idle de combate. A locomoção e os golpes vêm nos lotes seguintes; os extras do guia ficam por último.

## Ver o resultado

- Prévia interativa: http://127.0.0.1:4180 . Se o servidor estiver fechado, abra `INICIAR-PREVIA.cmd` e mantenha a janela em execução.
- `base-fonte.png`: pose-base no tamanho da fonte, para conferir rosto, cabelo e figurino.
- `base.png`: a mesma pose em célula lógica 128×96; é exatamente o primeiro quadro do ciclo.
- `base-ampliada.png`: ampliação por nearest-neighbor.
- `folha-idle.png`: os 12 quadros com nomes fora das células, para revisão.
- `idle-previa.gif`: prévia animada ampliada, em ciclo.
- `idle-atlas.png`, `idle.json` e `quadros/`: arquivos preparados para futura integração, sem legendas embutidas.

## Direção deste candidato

Guarda de combate em ¾ para a direita; pele clara de tom neutro; cabelo preto cacheado, com volume nas laterais; polo branca com gola/punhos verdes, faixas nos ombros, painel inferior verde e detalhe amarelo; jeans e tênis claros. A pose de combate substitui a ideia de voltar ao antigo idle frontal entre os golpes.

O ciclo tem 12 desenhos e duração proposta de 1,64 segundo. O movimento pretendido é uma respiração pequena em guarda, com base estável. A reprodução lenta e o avanço de um quadro ajudam a conferir continuidade; a folha estática sozinha não comprova fluidez.

## Preparação e limites

Os desenhos foram produzidos com a ferramenta integrada de imagens: uma proposta de pose, correção de paleta e uma folha de idle derivada. As fontes selecionadas e os prompts estão em `fontes/` e `PROMPTS.txt`.

A pose-base deste lote foi extraída do primeiro quadro da folha de idle. A imagem maior de direção, em `fontes/pose-direcao-cor.png`, registra a etapa anterior de criação; não é uma segunda pose-base para alternar durante o ciclo.

Na exportação, todas as silhuetas usam **a mesma escala**, definida pelo primeiro quadro. A preparação aplica apenas translação do desenho completo para registrar o apoio, sem esticar ou deformar pernas, braços ou cabeça. As 12 silhuetas terminam na linha lógica y=88. A célula é 128×96, pivô (64,88), personagem aproximadamente 66 pixels de altura. `medidas.json` registra posição, volume e diferenças entre quadros.

Existem pequenas variações de contorno e sombreamento na fonte gerada. Este lote ainda precisa da avaliação visual do usuário; medidas de escala e apoio não equivalem a aprovação artística ou a garantia de animação final. O próximo lote deve usar a base que for aceita nesta revisão.

## Conferir nesta revisão

1. Rosto, volume do cabelo, pele e uniforme representam o mesmo Sorriso da referência?
2. A guarda em ¾ serve de base para deslocamento e ataques?
3. O apoio parece firme no ciclo normal e na reprodução lenta?
4. O movimento é uma respiração discreta, com corpo sólido e sem parecer borracha?

## Interface e verificação

A página é uma ferramenta de revisão de arte: comparação entre base e ciclo, pausa, quadro anterior/próximo, velocidade, fundo e guias de apoio. Em tela estreita, os painéis ficam empilhados e a ampliação é limitada ao espaço disponível. A reprodução pausa quando a página fica oculta.

O relatório `verificacao.json`, quando presente, registra leitura dos arquivos, funcionamento dos controles, decodificação do GIF e integridade das células. Essa verificação técnica não substitui a revisão de aparência e movimento.
