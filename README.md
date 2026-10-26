# GAVIÃO 0.7.0 — primeiro treino mobile

Sorriso em um corredor escolar, com dois manequins de treino e controles para navegador de computador ou celular. Gelado, Bola e Alice permanecem fora desta build.

## Jogar

Endereço da publicação: https://Felipe-Airess.github.io/jogo-gavyo/ . No celular, abra em um navegador atual e toque em **Jogar**. A paisagem deixa o direcional e os golpes nas laterais da cena. Não é preciso instalar aplicativo. A primeira interação permite liberar o áudio.

No computador, execute `npm start` ou abra `INICIAR.cmd`. Node.js 18+ é necessário apenas para esse servidor local; não há pacotes a instalar. O endereço local é http://127.0.0.1:4173 . Não abra `index.html` por `file://`.

## Comandos

| No celular | No teclado | Ação |
| --- | --- | --- |
| Direcional | WASD / setas | Mover e ajustar a posição no corredor |
| Segurar Correr + direção | Shift + direção | Correr |
| Soco | J | Direto no corpo; continuações dependem do contato |
| Frente + Soco | Frente + J | Golpe pesado |
| Trás + Soco | Trás + J | Virar e golpear |
| Baixo + Soco | Baixo + J | Soco baixo no corpo |
| Cima + Soco | Cima + J | Jab na cabeça |
| Correr + baixo + Soco | Shift + baixo + J | Direto no tronco |
| Chute | K | Circular médio |
| Baixo / cima + Chute | Baixo / cima + K | Chute na perna / circular alto |
| Soco → Chute / Chute → Soco | J → K / K → J | Ligações mistas, sem repetir a primeira ação inteira |
| Segurar Defender | Segurar L | Guarda; pressionar perto do contato permite aparar |
| Agarrar | G | Clinch próximo; novamente solta |
| Correr + Soco com velocidade | Shift + J com velocidade | Soco de impulso, com comprometimento do corpo |
| Pausa / Reiniciar | Esc / R | Pausar ou reiniciar o treino |

Use dois ou três dedos para combinar direção, corrida, defesa e golpe. Segurar Soco não gera ataques automáticos. Comandos são limpos ao pausar, trocar de aplicativo ou cancelar o toque. O botão **Toque** permite mostrar os controles mesmo em uma sessão remota que se identifique como computador.

No clinch, Soco, baixo + Soco e Chute mantêm as variações existentes. Correr + Soco derruba e solta; o direcional arrasta o alvo. Perto de um caído, Soco, baixo + Chute e Correr + Chute usam as três ações de chão. Defesa, clinch, reações, chão e limpeza ainda usam parte da arte anterior, até os próximos lotes.

## Ritmo e treino

Os treze golpes do lote 3 usam seus novos desenhos. Preparação, contato e recuperação foram alongados: direto no corpo de 340 para 553 ms, soco baixo de 400 para 684 ms, pesado de 555 para 920 ms e circular médio de 535 para 889 ms. O impacto ainda é curto e possui pausa própria. Essa mudança afeta a animação e o instante das colisões, não apenas a velocidade de uma prévia.

As combinações começam no recolhimento da primeira ação. A região atingida nas continuações depende do ponto que realmente toca o alvo; um alvo dobrado pode receber na cabeça um chute que passaria pelo tronco se estivesse em pé. A guarda continua desgastando braços e impedindo o carregamento normal. Um golpe produz um contato, com recuperação e gasto de fôlego.

O seletor **Treino** oferece Reações, Defesa do alvo e Combate. Cada manequim tem barras independentes de cabeça, tronco, braços e pernas. Colisões e FPS continuam disponíveis para revisão. A primeira build usa os manequins existentes, sem introduzir personagens narrativos.

## Build e fontes

`npm run build` cria `build/`, com aproximadamente 4,3 MB de arquivos: jogo estático, atlas combinado, Phaser, servidor local opcional e manifesto de integridade. `npm run serve:build -- --port=4175` permite testar esse pacote isoladamente. O ZIP da release contém somente os arquivos necessários para jogar, não todo o histórico de arte.

O repositório guarda código, testes e [lotes de arte](arte/reformulacao/PLANO.md). A base e o idle do lote 1, a locomoção do lote 2 e os ataques do lote 3 estão no atlas da build. Reações e ações antigas foram preservadas onde a reformulação ainda não foi produzida. Os PNGs originais e os prompts permanecem nos lotes.

Mantivemos Phaser 3.90, `Phaser.CANVAS`, resolução lógica 320×180 e nearest-neighbor. Não há React, Electron, requisito de WebGL ou dependência de execução adicional. No celular, a ampliação CSS se ajusta ao espaço disponível; o desenho lógico permanece 320×180.

## Verificação e limites

`npm test` executa os testes históricos e o novo perfil de combate/toque. A versão foi verificada em Chromium com viewport mobile e eventos reais de toque via CDP, incluindo mover e atacar juntos, aproximação, dano no alvo, guarda sustentada, cancelamento, pausa e retrato/paisagem. Os relatórios de navegador estão em `docs/browser-test-*-070.json` no repositório.

Isso não equivale a teste em aparelho físico nem a medição no ThinkPad T400. Alguns desenhos e retrações ainda podem exigir polimento depois de jogar. A arte de defesa, clinch e chão permanece provisória.

Referências de implementação: [entrada no Phaser](https://docs.phaser.io/phaser/concepts/input) e [publicação no GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
