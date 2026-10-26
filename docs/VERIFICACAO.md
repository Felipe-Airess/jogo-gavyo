# Verificação — 25/10/2026

Este é o histórico das versões 0.1/0.2. Para a versão 0.3 com combo e ragdoll, consulte `COMBATE-V3.md` e `browser-test-v3.json`.

## Regras de jogo

`npm test`: **6 testes aprovados, 0 falhas**. Cobertura: velocidade de corrida, diagonal normalizada, limites, preparação/contato/recuperação do golpe, um acerto por ataque, facing travado, golpe esquerdo, erro por distância/profundidade/lado, colisão com boneco e possibilidade de contornar, reação ao dano, invulnerabilidade e reinício.

## Navegador real

Teste automatizado no Microsoft Edge em modo headless com GPU desabilitada. Canvas verificado em 320×180 e renderer tipo 1 (Canvas). Nenhuma requisição fora do servidor local. Nenhum erro JavaScript na rodada concluída.

Verificações de interação:

- Entrada por Enter; idle, walk, run, attack e hurt.
- Cinco socos independentes concluem o treino; cada golpe só soma uma vez.
- Aproximação dos dois lados e socos à esquerda e à direita.
- F2 alterna as colisões; H reduz vida e exibe hurt.
- Esc congela a posição; Enter continua; R restaura vida, posição e boneco.
- Janela de 390×844 sem rolagem horizontal, canvas de 320×180.
- Janela de 1280×900: canvas ampliado para 960×540 (3×).
- Suavização desativada nas texturas geradas em execução, além da configuração pixelArt/antialias do jogo.

O relatório de máquina em `browser-test.json` contém a versão do navegador, FPS pontual, dimensões, flag de suavização, erros e todas as URLs requisitadas. O FPS é uma leitura da execução local, não um benchmark sustentado nem uma previsão de desempenho no T400. A memória registrada é somente o heap JavaScript, não o consumo total do navegador.

Na rodada final com o Sorriso v2: Edge 156.0.4314.42, leitura de **59,86 FPS**, cerca de **9,05 MB de heap JS**, **6.780 chamadas de desenho de imagem auditadas e zero com suavização**. As seis texturas de jogo/HUD verificadas estavam com filtro nearest. O teste reavaliou os estados e controles após a troca de arte. Conferiu também que o PNG real de 256×256 foi carregado, os quadros têm 64×64 e a origem é (0.5,0.9375). A URL blob do carregador é local e não representa acesso externo.

## Revisão visual

Capturas atualizadas: `prototipo.png`, `colisoes.png`, `tela-compacta.png`, `sorriso-v2-preview.png`. Conferidos cachos volumosos, polo branca/verde/amarela com painel verde inferior e faixa diagonal, pele clara em rosto e membros conforme correção do usuário, silhueta mais alongada e pés alinhados. Revisadas as poses no jogo e em ampliação de 4×. O boneco de treino permanece fixo no plano de jogo; sua reação é apenas visual. A revisão técnica não substitui a aprovação artística do usuário.

Durante a verificação foram corrigidos toques curtos entre quadros e o filtro das texturas Canvas geradas pelo Phaser. O script de navegador passou a soltar os controles no próprio quadro da posição desejada, evitando ultrapassar o alvo por atraso da automação. Sessões de teste anteriores foram encerradas.

## Limites

Não testado fisicamente no ThinkPad T400/Intel GM45/Core 2 Duo P8600/4GB. Não testado em todos os navegadores ou em versões antigas. A ficha agora está acessível e foi usada; não houve acesso às fotos originais separadas. As animações ainda são uma primeira adaptação gerada e precisam de refinamento artístico e aprovação de semelhança. Sem áudio, toque, IA de inimigos ou personagens adicionais.
