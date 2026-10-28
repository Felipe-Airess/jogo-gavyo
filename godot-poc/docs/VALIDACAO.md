# Validação da POC — 27/10/2026

## Estrutura confirmada antes da implementação

Repositório `Felipe-Airess/jogo-gavyo`, checkout limpo em `main`, base `63846d8`.
Phaser 3.90 em `src/`, arte em `assets/` e `arte/`, testes em `tests/`.
GitHub Pages existente publica `main:/`, sem workflow de deploy.
O texto inicial de `AGENTS.md` sobre PRs/branches estava defasado em relação ao Git;
as regras de arte e preservação continuam aplicadas. O pedido atual autoriza
Godot apenas como experiência isolada e prevalece sobre a regra histórica de engine.

Arquivos adicionados em `godot-poc/`, `.devcontainer/godot-poc/` e um workflow
independente. Nenhum arquivo original do Phaser foi editado ou apagado.

## Critérios da interface

Experimento em jogo existente. Público: autor e revisores, usando telefone e PC.
Objetos: dois lutadores, fôlego, dano, ações, estado da partida.
Entrada: abrir a prévia e aproximar-se do rival. Primeira decisão: distância e ação.
Sucesso: reconhecer preparação/contato/recuperação, defender e atacar sem comando preso.
Recuperação: pausar, continuar e reiniciar. Ação principal mobile: movimento com
ataque ou guarda em dois dedos. UI Godot nativa, texto em português e controles
simples; arte preservada. Riscos principais: toque cancelado, retrato com alvos
pequenos, leitura de dano, pivô espelhado e deslocamento entre sprite/caixas.
Retrato tem botões maiores em duas filas. Paisagem prioriza área da luta.

## Verificado localmente

- Godot oficial 4.5.1: importação, execução sem janela e exportação Web release.
- 21 verificações de combate, todas passando: contato após preparação, hit único,
  erro à distância, bloqueio/fôlego, ataque/esquiva exaustos, jab espelhado,
  recuo por distância, parede, separação dos corpos, KO/reset, marcador ausente
  e repetição determinística da IA.
- 207 testes existentes do Phaser passando; build Phaser 0.8.0 gerada com
  47 arquivos, 7.728.427 bytes. Não representa novo teste visual do Phaser.
- Build Godot: aproximadamente 41 MB sem compressão HTTP, substancialmente maior
  que o pacote Phaser. PNG reutilizado: 2.758.336 bytes, sem alterar os pixels.
- Edge/Chromium desktop 1280×720, mobile emulado 844×390 e 390×844: carga da
  exportação real, movimento no teclado, pausa e reinício; em mobile, dois dedos
  para guarda + movimento e jab + movimento, cancelamento sem comandos presos.
  Sem erros de script/renderização no console nas três sessões.
- Capturas inspecionadas visualmente: `desktop.png`, `landscape.png`, `portrait.png`.
  Corrigido deslocamento do sprite espelhado detectado na primeira inspeção.
  Relatório automatizado: `web-report.json`.

## Ainda não confirmado

Celular físico, Safari/iOS, latência em rede móvel, desempenho no T400,
reabertura após parada automática e revisão do Claude.

## Atualização remota — 28/10/2026

Autorização Codespaces concluída pelo usuário. Os workflows Linux de Web e
testes do Phaser passaram no Actions. Ambiente atual:
`gavyo-godot-w6pjv7j5j7pcg5g7`, com porta 8060 privada e parada após 15 minutos.
Build e as 21 verificações executadas dentro do Codespace; servidor HTTP 200.
Prévia carregada a partir do servidor remoto através de encaminhamento de porta
autenticado: desktop 1280×720, paisagem 844×390 e retrato 390×844 passaram em
carga, movimento, pausa/reset e multitouch, sem erros de console. Relatório:
`remote-web-report.json`. A captura desktop também foi inspecionada visualmente.
O endereço público da porta responde com
autenticação exigida, como esperado para uma porta privada; não exige tornar o
repositório ou a porta públicos.

Corrigidas duas falhas reais da primeira preparação: Python não instalado na
imagem base e biblioteca fontconfig ausente. Bootstrap instala esses pacotes e
fontes; diagnóstico remoto por SSH habilitado. Scripts shell preservam LF.
O primeiro nome continha `---` e o serviço redirecionava para um host de empresa
`ghe.com` inválido. Ambiente substituído por nome simples e o anterior parado,
sem apagar arquivos. Confirmado que o novo endereço redireciona para
`github.com/codespaces/...`, sem o host incorreto.

Não foi habilitada publicação Pages, modificado seu endereço ou feito merge.
