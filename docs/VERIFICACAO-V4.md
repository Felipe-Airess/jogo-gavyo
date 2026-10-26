# Verificação 0.4 — 25/10/2026

`npm test`: 25 testes aprovados, zero falhas. Cobrem movimento em diferentes cadências, frenagem, erro pesado, combo confirmado, rejeição de cliques antecipados, direções, regiões e profundidade, um contato por golpe, bloqueio, braços esgotados, consequências de cabeça/tronco, alvos independentes, clinch, entrada na pausa do impacto, joelhadas, tempo de pega, impulso localizado e reinício.

## Navegador com o jogo real

Edge 156.0.4314.42, Canvas 320×180, teclado, assets servidos localmente. Dez verificações aprovadas em `browser-test-v4.json`:

- Dois alvos com resistência independente.
- Corrida e desaceleração residual na parada.
- Soco no tronco, direto na cabeça e terceiro golpe desequilibrando.
- Pesado errado avança e entra em tropeço.
- Cinco bloqueios esgotam braços sem deslocar alvo nem ferir cabeça/tronco.
- Braços esgotados impedem contra-ataques.
- Clinch após contato e três joelhadas até esgotar tronco.
- Recuperação para postura de dor no tronco; segundo alvo preservado.
- Pausa e alternância de debug.
- Página com largura 390 sem rolagem horizontal; o jogo continua exigindo teclado.

Zero erros de execução registrados. O navegador carregou `sorriso-quadros.png` e não carregou o rig antigo. Auditoria de 47.734 desenhos no canvas registrou zero usos de suavização. Célula efetiva: 96×80.

Gravação: `combate-v4.webm`. Imagens: `combo-v4.png`, `guarda-v4.png`, `clinch-v4.png`, `tronco-v4.png`; inspecionadas visualmente. A captura de clinch confirma aproximação e representação provisória, não uma pega final desenhada.

A leitura final durante automação/gravação foi aproximadamente 49 FPS e 11,4 MB de heap JavaScript. É uma amostra local, não benchmark nem garantia para o ThinkPad T400. A máquina alvo ainda não foi medida.

## O que os testes não certificam

Naturalidade artística, anatomia realista, desenho das mãos prendendo o pescoço e qualidade final de frenagem/tropeço/joelhada. Essas ações ainda usam adaptações da folha existente. O ragdoll dos manequins é simplificado. Relatórios V3/V031 preservados são históricos.
