# Contrato de arte do Sorriso

## Versão 0.5 — usada pelo jogo

`sorriso-v5.png/.json`: 210 quadros em células 128×96, raiz (64,88). Os 138 anteriores são preservados; acrescenta seis faixas com doze quadros: `runFluid`, `boxingFluid`, `roundFluid`, `lowFluid`, `rushFluid`, `groundFluid`. Fontes completas e prompts estão em `docs/references` e `docs/SPRITES-PROMPTS-V5.txt`.

A corrida usa fonte dedicada, com chão comum por linha e preservação de voo. `runFluid.travel`/`stride` registram as fases de distância; `support` marca apoios. Não alimentar esse ciclo com avanços de ataque. `locomotion.mjs` mantém relógios separados e limita correção visual; não deformar membros para interpolar.

As demais fontes editoriais vieram com 13 poses por faixa e uma pose de chute para o lado errado. A preparação escolhe 12, exclui o erro e isola duas silhuetas encostadas da queda. Rótulos e linhas não entram no atlas. As raízes são verificadas na cintura, sem tomar o emblema azul ou a perna erguida como centro.

Mão/pé das ações novas têm marcadores. O finisher e o debug usam a cabeça desenhada do quadro deitado; o esqueleto de queda não é deformado para coincidir com cada pixel da ilustração. Mantém limitações de traço e intermediários das fontes geradas; a revisão manual com onion-skin é o caminho para acabamento final.

## Histórico — versão 0.4.2

`sorriso-padronizado.png` / `.json` são a fonte carregada. Conservam os 138 desenhos, com células 128×96 e raiz (64,88). A margem maior permite recalibrar a família original sem cortar cabelo ou pés.

A igualdade de altura da silhueta na 0.4.1 foi insuficiente. A calibração atual compara cabeça e tronco: família original ampliada em 1,25, Sorriso complementar preservado, manequim separado ampliado em 1,2 para se aproximar do parceiro nos quadros de contato. Não igualar uma postura agachada a uma em pé nem corrigir membros separadamente. Metadados `normalization` documentam os fatores. As duas fontes ainda são desenhos distintos, com pequenas diferenças de traço que escala sozinha não remove.

Os chutes possuem marcadores `foot` nos quadros originais, recalculados na escala nova; o contato ativo os usa. Cabeça/pescoço/quadril do manequim também são transformados na preparação. As combinações `comboKick` e `stepPunch` usam receitas de quadros de mais de uma faixa, sem retornar ao idle entre os dois golpes. Não são desenhos novos gerados nesta versão.

## Histórico — versão 0.4.1

`sorriso-integrado.png` / `.json` reúnem os 88 recortes originais e os 50 da folha complementar aprovada. Células 128×80, oito colunas, raiz (64,72). Os 16 pixels de margem adicional em cada lado não aumentam o personagem. A nova fonte tem escala única 56/120, inclusive nas poses baixas; não esticar as silhuetas para igualar a altura.

Faixas adicionais: `brakeMotion`, `heavyMotion`, `missMotion`, `reverseMotion`, `clinchMotion`, `kneeMotion`, `targetBody`, `targetHead`, `targetGuard`, `targetClinch`. As duas faixas pareadas preservam jogador e alvo juntos, evitando recortes nas mãos em contato. O alvo separado é ocultado durante o par. Os marcadores `pose` dos metadados seguem cabeça, pescoço e quadril do alvo e são usados nas hurtboxes. A direção base do giro e dos alvos é -1; as demais são +1.

As guias, os números e os rótulos da folha são removidos ao empacotar. A fonte intacta está em `docs/references/sorriso-complementar-aprovado-v1.png`. Quadros de queda seguem a trajetória física sem deformar o desenho por articulação; o contra-ataque do manequim ainda não possui faixa própria.

## Histórico — versão 0.4

`sorriso-quadros.png` e `sorriso-quadros.json` vêm da folha 34989.png enviada pelo usuário. A fonte integral está em `docs/references/sprites-enviados-34989.png`. São 88 desenhos completos em 14 faixas; células 96×80, oito colunas, raiz (48,72). O recorte remove rótulos, fundo e ruído de transparência. A escala comum e o chão de referência por faixa preservam a fase aérea; não normalizar cada desenho pelo pé mais baixo.

O jogo seleciona esses desenhos em `src/sprite-player.mjs`; tempos, contato e avanço ficam em `src/battle.mjs`, caminhos e origem em `src/assets.js`. O protagonista não é montado com peças articuladas. Não esticar torso, pernas ou braços para criar intermediários.

Frenagem, tropeço, reverso, clinch e joelhada adaptam quadros existentes e precisam de arte dedicada. No clinch a guarda representa a pega, sem desenho específico de mãos prendendo o pescoço. A joelhada utiliza a preparação do chute. Mecânicas funcionais não significam animações finais aprovadas.

## Histórico — versão 0.3

`sorriso-rig.png` (128×96) e `sorriso-rig.json` contêm 12 peças reutilizáveis: cabeça, torso, braços/antebraços, coxas/canelas e tênis, com lados próximo/distante separados. `sorriso-rig-fonte.png` é a fonte maior de edição, gerada a partir da arte clara aceita como estilo pelo usuário. A cena atual não carrega esses arquivos.

Os nomes no atlas são `head`, `torso`, `upperNear`, `foreNear`, `upperFar`, `foreFar`, `thighNear`, `shinNear`, `shoeNear`, `thighFar`, `shinFar`, `shoeFar`. Os recortes PNG têm transparência e não incluem rótulos, sombras ou efeitos. Os pivôs ficam em `src/character.js`, as articulações e curvas em `src/animation.mjs`, e o resultado é composto em 96×80 com raiz em (48,74). Todos os desenhos e transformações usam nearest-neighbor.

Preservar pele clara em todas as áreas expostas e o padrão da polo. A cabeça e a roupa são reutilizadas entre estados; não gerar um novo rosto para cada golpe. Para alterar duração ou contato, atualizar as regras em `combat.mjs` junto com a curva visual correspondente. Detalhes: `docs/COMBATE-V3.md`. Prompt integrado: `docs/SPRITES-PROMPT-V3.txt`.

## Histórico — versão 0.2

O atlas usado anteriormente era `sorriso-v2.png`, criado com a ferramenta integrada de imagens a partir da ficha fornecida pelo usuário. A fonte maior é `sorriso-fonte.png`. Esses arquivos foram preservados para comparação. A ficha de referência foi preservada em `docs/references/sorriso-aprovado.jpg`; ela não foi recortada em animações.

Configuração anterior: 16 células de 64×64, grade 4×4, imagem de 256×256 com transparência; quinze poses utilizadas e uma pose reserva no índice 15. Raiz em (32,60), origem Phaser (0.5,0.9375), voltado para a direita. A extração técnica usava as silhuetas reais porque a geração não garantiu células regulares. Metadados: `sorriso-v2.json`.

Direção final de pele, definida pelo usuário: **branco, pele clara**, consistente em todas as áreas expostas. Conservar cachos escuros volumosos, polo branca com gola/punhos e terço inferior verdes, faixas amarelas nos ombros e na parte inferior, emblema azul, jeans folgado e tênis claros. Não adicionar coroas ou elementos do fundo da ficha ao personagem.

| Estado | Índices | Observação |
|---|---|---|
| idle | 0,1 | Respiração discreta; pés fixos |
| walk | 2,3,4,5 | Passadas alternadas |
| run | 6,7,8,9 | Passada maior e inclinação |
| attack | 10,11,12 | Preparação, extensão, recuperação |
| hurt | 13,14 | Reação simples ao dano |

A extensão do braço corresponde ao contato lateral. Não altere a silhueta para justificar hits fora do alcance. A caixa de contato representa os pés no plano do corredor; é desenhada nessa altura no debug. Ajustes de alcance pertencem a `combat.mjs` e precisam de novo teste, não de compensações de escala na arte.

A semelhança final e as animações ainda precisam de avaliação artística do usuário. Para mais quadros ou outra cadência, ajuste a seleção visual em `main.js`. Valide todos os estados, a âncora dos pés e ambos os lados. Os prompts e as correções estão em `docs/SPRITES-PROMPTS-V2.txt`.
