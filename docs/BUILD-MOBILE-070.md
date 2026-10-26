# Build 0.7.0 — objetivo e verificação

O usuário aprovou os desenhos do lote 3 e pediu golpes menos instantâneos, uma build de treino com toque e envio ao GitHub. Isso substitui a orientação anterior de adiar mobile.

UI/UX — projeto existente; superfície de jogo, não painel. Manter a atmosfera escolar e a área de jogo. A ação principal é entrar no treino e combinar direção, soco, chute, corrida e defesa sem teclado. Em retrato, controles abaixo da cena; em paisagem, direcional e ações nas laterais. Não cobrir a área jogável com botões. Usar alvos de pelo menos 44 pixels e limpar comandos em pausa, troca de aplicativo e cancelamento de toque. Não depender de tela cheia, áudio ou orientação bloqueada para jogar.

Preservar Phaser CANVAS, resolução lógica 320×180, nearest-neighbor e ausência de dependências de execução novas. A primeira build mantém reações, clinch e chão anteriores até os lotes correspondentes de arte. O teste de desempenho no T400 continua pendente.

Verificação prevista: entrada simultânea por toque, defesa/corrida sustentadas, ataque apenas na borda do toque, liberação ao pausar, golpes com colisão nas poses corretas, alvos independentes, tamanhos de tela e URL publicado. Testes históricos e testes do novo perfil têm funções diferentes; os tempos antigos não são o contrato da nova build.
