# GAVYO — laboratório Godot 4

**28/10/2026 — migração nativa jogável.** A cena principal agora é `game.tscn`:
menu com **Duelo 1×1** (Sorriso/Miguel, IA calmo/firme/difícil, rounds, tempo) e
**Corredor de treino** (reação/guarda/sparring). Regras em GDScript conferidas
contra o Phaser por replays tick a tick (`tests/duel_trace_test.gd`,
`tests/corridor_trace_test.gd`). A POC antiga continua em `main.tscn`.
Estado de cada sistema: [MIGRACAO-NATIVA.md](docs/MIGRACAO-NATIVA.md).

Controles: setas/WASD andam, J soco, K chute, G agarra, L defende, Shift corre,
Esc pausa, F2 caixas, B sangue, N som, M menu (pausado), R reinicia. Controle de
videogame: direcional/analógico, A soco, B chute, X agarra, RB/RT defende, LB corre,
Start pausa. Toque: direcional e botões na tela, com vários dedos.

Prova de conceito isolada, sem migração do Phaser. Godot **4.5.1**, GDScript,
renderer Compatibility, export Web sem threads. Combate lateral 2D, não uma
simulação completa de MMA nem um protótipo 3D. Não altera a publicação Pages atual.

## Fazer tudo pelo celular

1. Abra a [branch do protótipo](https://github.com/Felipe-Airess/jogo-gavyo/tree/feat/godot-combat-poc).
2. Toque em **Code → Codespaces → … → New with options**. Selecione a branch
   `feat/godot-combat-poc`, configuração **GAVYO · Godot remoto**, máquina de 2 cores.
   O arquivo da configuração é `.devcontainer/godot-poc/devcontainer.json`.
3. Aguarde a preparação: Godot, templates, testes e exportação acontecem na máquina
   remota, não no telefone. O primeiro preparo baixa um pacote grande de templates.
4. Na aba **Ports / Portas**, abra **Jogar GAVYO Godot (8060)**. O endereço HTTPS
   gerado funciona no celular e no PC, autenticados na mesma conta GitHub. A porta
   permanece privada por padrão. Salve esse endereço depois de criar o Codespace.
5. Para atualizar a prévia após editar, rode no terminal web:

   ```bash
   bash godot-poc/tools/build_web.sh
   ```

   Recarregue a aba do jogo. Para retomar o servidor se necessário:
   `bash godot-poc/tools/start_preview.sh`.

Pare o Codespace quando terminar. Fechar a aba não para a máquina remota.
Há franquias e possíveis cobranças de computação e armazenamento conforme a conta:
[documentação de uso](https://docs.github.com/en/codespaces/troubleshooting/troubleshooting-included-usage).
Não há necessidade de instalar Godot no celular. O editor de código fica no navegador;
esta configuração não disponibiliza a interface gráfica do editor Godot.

**Atualização de acesso — 28/10/2026:** autorização Codespaces concluída. Ambiente
ativo: [GAVYO Godot](https://github.com/codespaces/gavyo-godot-w6pjv7j5j7pcg5g7).
[Abrir a partida](https://gavyo-godot-w6pjv7j5j7pcg5g7-8060.app.github.dev), com login
na mesma conta GitHub. A build foi gerada dentro do Codespace e o servidor respondeu
HTTP 200. O ambiente para após 15 minutos sem uso; reabra o editor para retomá-lo.

O primeiro ambiente, com `---` no nome, foi parado: o domínio `github.dev`
interpretava essa sequência como endereço de empresa e redirecionava para um
host `ghe.com` inválido. Não reutilize o link antigo. Use nomes como `GAVYO Godot`,
sem separadores de pontuação. O bootstrap agora instala Python e as dependências
de fontes ausentes na imagem base, e a configuração inclui diagnóstico por SSH.

## Jogar

| Ação | PC | Toque |
| --- | --- | --- |
| Andar | A/D ou setas esquerda/direita | `<` / `>` |
| Jab | J | Jab |
| Direto | K | Direto |
| Recuo rápido / esquiva por distância | Espaço | Recuo |
| Bloquear | Segurar L | Segurar Bloquear |
| Pausar | Esc | Pausar / Continuar |
| Reiniciar | R | Reiniciar |
| Ver caixas medidas | F2 | Caixas |

Dois dedos combinam movimento e defesa, ou movimento e início de golpe.
O golpe tem preparação, contato e recuperação: andar fica comprometido durante a
animação; segurar o botão não repete ataques. Soltar/cancelar toque, arrastar para
fora do botão ou perder foco limpa comandos. Perder foco também pausa a partida.
Retrato usa controles maiores em duas filas; paisagem amplia a luta.

## Regras e arte reaproveitada

- `scripts/combat.gd`: modelo independente, passo de 60 Hz; jab/direto, guarda,
  fôlego, recuo físico, empurrão, reações, pausa de impacto, nocaute e rival
  determinístico de treino. Testável sem abrir uma janela.
- `scripts/arena.gd`: desenho, teclado, identificação de cada dedo, pausa e HUD.
- `tools/prepare_assets.py`: copia o atlas original Sorriso e seleciona seis clipes,
  tempos, contatos, pivô e caixas existentes. O SHA-256 da fonte fica em
  `assets/combat.json`. O PNG não é redimensionado nem redesenhado.
- Reaproveita `r1_idle`, `r2_walk`, `r3_jab_head`, `r3_cross_head`, `block`, `hurt`.
  O rival é o mesmo Sorriso com modulação de cor, identificado como rival de treino;
  não representa Miguel ou outro personagem.
- Hitboxes de punho terminam na ponta medida; hurtboxes vêm dos marcadores por
  quadro. Marcador ausente não ganha coordenada inventada. Um golpe só toca uma vez.
- Guarda protege pela frente e consome fôlego; esgotado, o lutador perde proteção.
  Recuo não dá invulnerabilidade: funciona saindo do alcance e é limitado pela parede.

## Build automatizada e checagens

O workflow separado **Godot POC · Web** testa regras, exporta HTML/WASM e roda
checagens de navegador desktop, retrato e paisagem. Os artefatos de jogo e de QA
ficam na execução do Actions por 14 dias. Artefato para baixar não é hospedagem jogável.

Em Linux/Codespaces:

```bash
bash godot-poc/tools/install_godot.sh
bash godot-poc/tools/build_web.sh
python3 godot-poc/tools/serve.py
```

Com Godot 4.5.1 instalado em outro caminho, defina `GODOT=/caminho/godot`.
No Windows, use o executável Godot 4.5.1 com os templates correspondentes:

```powershell
python godot-poc/tools/prepare_assets.py
godot --headless --path godot-poc --editor --import --quit
godot --headless --path godot-poc --script tests/combat_test.gd
godot --headless --path godot-poc --export-release Web web/index.html
python godot-poc/tools/serve.py
```

A prévia local usa `http://127.0.0.1:8060/`. O servidor só expõe a pasta exportada.
Para QA no navegador, `tests/web_smoke.cjs` requer Playwright 1.56.1 e Chromium;
`PLAYWRIGHT_MODULE` permite apontar uma instalação existente. `?qa=1` habilita
um retrato somente de leitura do estado em `window.__GAVYO_QA`, usado para
validar entradas reais de teclado e toque, sem controlar as regras pelo JavaScript.

## Limites e decisão de continuidade

A aparência do idle/ataques já vem das fontes aceitas; a locomoção ainda estava em
revisão e guarda/reações usam a linhagem antiga. A nova engine não resolve isso.
Recuo rápido usa o idle transladado: faltam desenhos específicos de esquiva.
Não há passo em profundidade, chutes, clinch, chão, áudio, matchmaking ou migração
das regras completas do Phaser. Se ambos acertarem no mesmo passo, o jogador é
resolvido primeiro: trocas simultâneas ficam para revisão antes de ampliar o escopo.
Os ataques não têm buffer de combos ou cancelamento; é um recorte de viabilidade.

Web exige navegador com WebAssembly e WebGL 2.0. Não prometer compatibilidade com
o T400 nem equivalência ao Phaser Canvas. Não há medição em celular físico,
Safari/iOS ou hardware antigo nesta entrega.
[Requisitos e exportação Web do Godot](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html).

Codex implementa e reproduz os bugs. Claude revisa arquitetura, cenários de erro e
sensação do combate com o [roteiro de revisão](docs/REVISAO-CLAUDE.md).
Uma revisão externa não foi executada só por existir esse roteiro. Antes de decidir
qualquer migração: jogar no telefone real, comparar sensação/latência com o Phaser,
revisar as limitações de arte e registrar o parecer do Claude e do usuário.

Referências do ambiente remoto:
[portas privadas e prévias](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace),
[parar e retomar](https://docs.github.com/en/codespaces/developing-in-a-codespace/stopping-and-starting-a-codespace).
