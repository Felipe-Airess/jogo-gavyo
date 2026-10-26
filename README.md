# GAVIÃO — protótipo 0.6.1

## Rodada atual de arte

As novas animações estão em [arte/reformulacao](arte/reformulacao/PLANO.md), separadas da versão jogável para revisão. O lote 1 contém a base e o idle aprovados; o lote 2 contém locomoção; o lote 3 entrega treze sequências de socos/chutes e suas ligações. Consulte o [lote 3](arte/reformulacao/03-SOCOS-CHUTES/README.md) para folhas, fontes, prompts, tempos e limitações. Para ver sua prévia local, execute `node arte/reformulacao/03-SOCOS-CHUTES/servidor.cjs` e abra http://127.0.0.1:4182 . Não é necessário instalar pacotes.

O jogo ainda exige teclado. Uma adaptação para navegador de celular é viável, mas controles de toque e acesso por endereço remoto foram adiados a pedido do usuário. O envio ao GitHub não publica automaticamente um jogo acessível pelo telefone. Não há GitHub Pages ou túnel habilitado por este trabalho.

Treino jogável com Sorriso e dois manequins em um corredor escolar. Esta versão acrescenta contato que carrega o alvo, parry com resposta contextual, variações no clinch, arrasto, três ações no chão e limpeza das mãos. Gelado, Bola e Alice não estão implementados.

## Jogar

Abra **INICIAR.cmd**, ou execute `npm start` nesta pasta. Node.js 18+ e um navegador de desktop são necessários. Não é preciso instalar pacotes para jogar.

Endereço: **http://127.0.0.1:4173/?v=ajustes-061**. Se uma versão antiga estiver aberta, recarregue a página. Para servir sem abrir outra janela, use `npm run serve`. Ctrl+C encerra o servidor. O jogo não deve ser aberto por file://. Phaser e assets estão incluídos; não precisa de internet durante a partida.

## Controles

| Comando | Ação |
| --- | --- |
| Enter / Esc | Entrar, pausar e continuar |
| WASD / setas | Mover |
| Shift + direção | Correr; soltar provoca freada curta |
| J | Soco; continuação depende do contato e da abertura anterior |
| Frente + J | Golpe pesado com avanço e contato que carrega |
| Trás + J | Virar e golpear para trás |
| Baixo + J | Soco no corpo |
| K | Chute circular |
| Baixo + K | Chute na perna; perto de caído, chute no chão |
| J → K / K → J | Combinações mistas com transições próprias |
| Shift + J com velocidade | Soco de impulso; pode derrubar ambos |
| G de perto | Entrar no clinch, abrindo a guarda; novamente solta |
| J no clinch | Soco curto na cabeça |
| Baixo + J no clinch | Cotovelada |
| K no clinch | Joelhada no tronco |
| Shift + J no clinch | Puxar para baixo, golpear e soltar em queda |
| Direções no clinch | Arrastar devagar; consome a duração da pega |
| L segurado | Defender pela frente |
| L no instante do contato | Aparar no modo Combate; segurar não renova a janela |
| J após aparo | Responder com o braço livre; baixo + J procura o tronco |
| J perto de caído | Soco no chão |
| Shift + K perto de caído | Pisada |
| Parado após sujar as mãos | Limpar; mover, defender ou atacar interrompe |
| F2 / R / B / H | Colisões / reiniciar / sangue / dano de teste |

O botão **Som** liga ou desliga o áudio. A primeira interação libera o som no navegador. Teclado necessário; não há controles por toque.

## Correções 0.6.1

Custos de fôlego reduzidos aproximadamente pela metade; recuperação de 36 pontos por segundo em repouso e 14 durante recuperação de ataques. Corrida gasta 0,8 ponto por segundo. Tropeço só ocorre ao errar usando a última reserva; golpes defendidos não provocam tropeço. O soco de impulso ainda pode derrubar ambos quando conecta.

A corrida foi recortada pela silhueta inteira, preservando a perna que ultrapassava a divisão da folha. O atlas usa uma paleta compartilhada de pele clara, aplicada sem alterar as poses. Comparação dos quadros: [revisao-v61.png](docs/revisao-v61.png).

## Ritmo e contato

Há uma única continuação preparada por golpe. Acertar, errar e ser bloqueado têm consequências diferentes. Não existe mais uma trava universal depois da terceira ação: alcance, recuperação, guarda e fôlego limitam as sequências. Repetir a tecla durante recuperação não cancela o compromisso do movimento. Tropeçar por erro exige terminar o golpe com o fôlego no fim (até 6 pontos). Com energia, um erro usa recuperação normal; uma defesa não conta como golpe no vazio.

Direto/cruzado, soco no corpo, pesado e contra-ataques aproveitam aberturas diferentes. As misturas soco → chute e chute → soco preservam seus desenhos de ligação. O contato usa caixas ativas e varredura entre poses; não causa dano fora do alcance ou da mesma faixa do corredor.

Nos golpes com carregamento, os atores avançam juntos durante um intervalo curto, mantendo a distância do contato. Só então o alvo recebe a velocidade de saída ou cai. A ligação respeita as bordas e pode ser interrompida por dano no jogador. Guarda válida desgasta braços e impede o arrasto.

## Parry e clinch

No seletor **Combate**, o alvo avisa antes de atacar. Apertar L até 115 ms antes do contato permite aparar. A abertura de resposta dura 620 ms; um sinal junto ao personagem indica essa oportunidade. O braço que defendeu determina o braço da resposta. Há uma memória curta para J apertado durante a própria deflexão. L segurado mantém defesa comum e não produz aparos repetidos automaticamente.

O clinch tem entrada, duração limitada e golpes com seus próprios intervalos ativos. Soco curto e cotovelo atingem cabeça; joelho atinge tronco. Acertos renovam a pega; parar ou ficar sem fôlego permite escapar. Arrastar reduz sua duração mais depressa. Shift + J baixa a postura do alvo antes do contato e solta na pancada; Sorriso completa o gesto antes de recuperar a guarda.

## Regiões e ações no chão

As barras de cada alvo são independentes: **C** cabeça, **T** tronco, **B** braços e **P** pernas. Cabeça esgotada causa nocaute, tronco cede, braços deixam de sustentar guarda/ataque e pernas esgotadas provocam queda. Bloqueio preserva cabeça e tronco e desgasta os braços; não protege pelas costas nem intercepta chute baixo com uma guarda alta.

As três ações no chão exigem alvo já caído, alcance e alinhamento; a caixa precisa tocar a cabeça. Não funcionam como dano remoto nem finalizam alguém ainda voando. Um finalizado não levanta até reiniciar.

## Apresentação e limites

A corrida usa oito poses novas, largada e freada, distância própria e apoio dos pés com correção limitada. A velocidade do desenho acompanha a distância percorrida. Oito poses escolhidas substituem o ciclo anterior de doze; aumentar a contagem, sozinho, não corrigia sua continuidade.

Socos confirmados acumulam sangue por mão. Depois de repousar, Sorriso usa uma sequência de limpeza; a sujeira diminui durante a ação e um comando pode interrompê-la. B oculta os efeitos. Partículas e marcas continuam limitadas.

Os novos sprites foram produzidos com a ferramenta integrada de imagens, recortados e calibrados em escala fixa por fonte. A paleta de cabelo escuro foi ajustada para preto/carvão. O atlas atual é `assets/sorriso-v61.png` + `.json`; as fontes anteriores foram preservadas. A folha de integração é [folha-contexto-v6.png](docs/folha-contexto-v6.png), e os prompts/fontes estão em [SPRITES-PROMPTS-V6.txt](docs/SPRITES-PROMPTS-V6.txt).

Ainda é arte de protótipo: diferenças de desenho permanecem entre folhas antigas e novas; o alvo usa poses provisórias, especialmente durante o arrasto. Não há esqueleto visual completo nem animação física de cada membro. A volta à guarda e algumas combinações reaproveitam desenhos. Os sons são impactos e passos sintéticos provisórios. Não são animações ou áudio finais de produção.

## Tecnologia e verificação

Phaser 3.90, JavaScript, **Phaser.CANVAS**, 320×180, ampliação inteira e nearest-neighbor. Sem React, Electron, WebGL obrigatório ou nova dependência de execução. Som curto gerado localmente pela Web Audio API; nenhum serviço externo.

Execute **npm test**. Há testes de contato, carregamento, interrupções, bordas, defesa, parry, respostas por braço, clinch, arrasto, dano regional, chão, limpeza, entrada e equivalência de movimento a 30/60 quadros. Os testes de navegador estão registrados em [browser-test-v6.json](docs/browser-test-v6.json), quando concluídos.

Os testes de lógica não comprovam naturalidade artística. O ThinkPad T400 ainda precisa de medição real; FPS observado em outro computador não é promessa para esse hardware.

## Trocar assets

As imagens ficam em células 128×96, raiz (64,88). As durações e regras dos novos golpes ficam em `src/context-moves.mjs`; seleção de desenhos em `src/sprite-player.mjs`; marcadores e índices ficam no JSON. Preserve escala, pivô, orientação e os marcadores de mãos/pés ao substituir quadros. Não recorte uma ficha de apresentação como se fosse uma sequência pronta para animar.
