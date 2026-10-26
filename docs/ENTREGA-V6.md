# GAVIÃO 0.6 — entrega

Implementação em 2D, mantendo Phaser 3.90, Canvas e 320×180. Nenhuma biblioteca de execução foi adicionada.

## Escolhas

- Contato: ligação curta dos atores durante golpes selecionados; velocidade de saída aplicada depois. Dano no jogador interrompe a ligação sem deixar o alvo preso.
- Combo: uma continuação por vez; condições de contato, guarda, erro, recuperação e fôlego substituem a trava universal de três ações.
- Parry: janela de 115 ms, resposta de 620 ms, braço livre escolhido conforme o ataque recebido, entrada antecipada durante a deflexão.
- Clinch: atores desenhados separadamente; soco curto, cotovelada, joelhada e golpe para derrubar; movimento lento e duração consumida pelo arrasto. As caixas precisam alcançar a região atingida.
- Chão: soco, chute e pisada, com seleção contextual, alcance e profundidade obrigatórios.
- Sangue: estado por mão, desenho nos marcadores e limpeza interrompível após repouso. Desligar sangue oculta os efeitos.
- Corrida: oito poses escolhidas, largada/freada e relógio por distância. Escala fixa por fonte, sem deformação de membros.
- Som: passos, impacto, guarda e aparo sintetizados localmente; botão para silenciar.

## Evidência

`npm test` cobre 68 casos de lógica e integração dos dados de arte. A verificação no navegador cobre dez grupos de ações; resultado, revisão carregada e configuração gráfica em `browser-test-v6.json`. As imagens com sufixo `-v6.png` registram momentos do jogo; `folha-contexto-v6.png` mostra os novos quadros. Testes automatizados não certificam qualidade de animação.

Os cenários de navegador usam preparação determinística dos alvos e eventos de teclado dentro da página para preservar o tempo dos comandos; não representam uma medição de habilidade humana nem uma sessão no T400.

## Limites visuais

As folhas antigas e novas ainda têm diferenças de desenho e algumas transições reaproveitam poses. O manequim arrastado usa postura provisória. O ragdoll não articula a textura de cada membro; a queda combina quadros com trajetória física. Mãos e pontos de apoio usam metadados, incluindo calibrações explícitas onde a leitura automática escolheu o ponto errado. O áudio é provisório.

Referências, prompts e correções de recorte estão em `SPRITES-PROMPTS-V6.txt`. As folhas anteriores foram preservadas para comparação. Não foi exigida modelagem 3D.

Não houve benchmark no ThinkPad T400. O FPS do registro pertence ao computador que executou a verificação, com renderização Canvas; não deve ser interpretado como previsão para a máquina alvo.
