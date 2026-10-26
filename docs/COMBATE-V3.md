# GAVIÃO 0.3 — movimento, combo e queda

O estilo e a pele clara definidos pelo usuário continuam como referência. A mudança responde a três problemas da versão 0.2: poucas poses com mudanças bruscas, repetição do mesmo soco e alvo sem deslocamento real.

## Jogar

- **J, J, J:** jab, direto e gancho. Toque novamente durante a preparação/recuperação para registrar o próximo golpe. Manter J apertado não dispara repetição automática.
- **K:** chute independente, também utilizável como finalização depois de um soco.
- **Shift + direção + J:** ataque com avanço.
- Continue usando WASD/setas, Shift, Esc, R, F2 e H.

Os golpes leves empurram sem desmontar o alvo; Sorriso dá um pequeno passo durante o ataque para acompanhar. Gancho e chute lançam o corpo. A sequência continua exigindo proximidade, lado correto e alinhamento no corredor. Para atingir o alvo lançado, é preciso acompanhá-lo e acertar enquanto seu torso ainda está à altura do golpe. Depois de cair, ele se levanta automaticamente. Há contador de sequência e melhor combo da sessão.

## Animação

O atlas de poses da 0.2 não é mais a animação principal. Um atlas pequeno de **12 partes reutilizáveis** preserva cabeça, camisa, braços, pernas e tênis. As articulações são interpoladas continuamente; braços e pernas mantêm os comprimentos. Os pés apoiados compensam a distância percorrida durante a passada. Antecipação, contato e recuperação de cada golpe usam curvas próprias. Não há mistura transparente de duas imagens, troca de retrato, geração de arte durante a partida ou dependência adicional.

O atlas carregado é `assets/sorriso-rig.png` (128×96) com descrições em `assets/sorriso-rig.json`. A composição ocorre em um canvas pequeno de 96×80, com nearest-neighbor, desenhado na tela lógica de 320×180. O arquivo maior `sorriso-rig-fonte.png` é fonte de edição e não é carregado na partida. O atlas v2 foi preservado para comparação histórica.

É uma animação por recortes articulados. Pode precisar de refinamento manual de silhueta e poses; não equivale a animação tradicional desenhada quadro a quadro.

## Contato e combo

| Golpe | Preparação | Janela ativa | Duração | Passo | Knockback inicial | Efeito |
|---|---:|---:|---:|---:|---:|---|
| Jab | 58 ms | 58–102 ms | 205 ms | 4 px | 55 px/s | Stagger |
| Direto | 76 ms | 76–132 ms | 255 ms | 7 px | 72 px/s | Stagger maior |
| Gancho | 106 ms | 106–170 ms | 355 ms | 8 px | 115 px/s | Lançamento |
| Chute | 116 ms | 116–192 ms | 405 ms | 5 px | 165 px/s | Lançamento maior |
| Avanço | 74 ms | 74–134 ms | 295 ms | 14 px | 90 px/s | Aproximação + stagger |

O knockback tem velocidade e desaceleração. Cada golpe só pode acertar uma vez; o lado fica travado durante o ataque. O comando seguinte pode permanecer no buffer por 230 ms; as janelas de encadeamento são diferentes para cada golpe. Pausas de impacto de 16–36 ms dão peso sem a pausa uniforme de 45 ms da primeira versão. A interface mostra o golpe atual e a sequência real de contatos, não só o número de teclas.

## Ragdoll

O boneco de treino agora é articulado. Cabeça, tronco, braços e pernas seguem **11 pontos e 11 vínculos**, com gravidade, impulso, contato com o piso, amortecimento e limites laterais. A simulação Verlet roda em passos de 1/120 s, com sete iterações de restrições por passo, somente durante a queda. Depois de 1,75 s, o corpo inicia uma recuperação de 440 ms. Esc pausa inclusive a simulação. R recria o estado inicial.

Trata-se de ragdoll 2D simplificado do alvo, não física 3D ou um motor completo de personagens. Não há colisões entre membros, anatomia com limites angulares detalhados ou interação com móveis. Gelado, Bola e Alice seguem fora do protótipo. Sorriso mantém sua reação de dano controlada; o ragdoll foi aplicado ao alvo para testar os combos.

## Código e verificação

- `combat.mjs`: golpes, buffer, avanço, hitstun, knockback, combo e contato.
- `animation.mjs`: poses contínuas e solução das articulações.
- `character.js`: composição do Sorriso com as mesmas partes em todos os quadros.
- `ragdoll.mjs`: pontos físicos, vínculos, gravidade e piso.
- `dummy-view.js`: desenho do boneco seguindo os pontos.

`npm test` cobre combate, comprimentos das articulações, apoio dos pés e recuperação física. O teste no navegador usa os controles reais, comprova três acertos encadeados, deslocamento, voo, pausa, recuperação, chute e ataque com avanço. Capturas e vídeo: `poses-v3.png`, `combo-v3.png`, `chute-ragdoll-v3.png`, `colisoes-v3.png`, `compacto-v3.png` e `combo-v3.webm`. Relatório: `browser-test-v3.json`.

A leitura de FPS é da máquina local com captura de vídeo ativa. O ThinkPad T400 continua sem medição física neste ambiente.
