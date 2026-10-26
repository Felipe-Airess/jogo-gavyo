# Verificação do protótipo 0.3 — 25/10/2026

**18 testes aprovados, zero falhas**, executados por `npm test`. Cobrem movimento/limites, contato e facing, interrupção por dano, comando antecipado, sequência jab–direto–gancho, knockback dos dois lados, chute, avanço, recuperação do alvo, saída após sobreposição, estabilidade do corpo, comprimento dos membros e apoio dos pés.

Rodada final no Edge 156.0.4314.42, com Canvas 2D forçado, GPU desabilitada e captura de vídeo do canvas ativa. Interações realizadas por teclado no navegador, sem alterar as regras para produzir acertos:

- Andar e correr, com articulações atualizadas continuamente.
- Três J consecutivos produziram jab, direto e gancho; três contatos e melhor combo 3.
- O alvo saiu de x=242 para x≈265 no início do lançamento e continuou se deslocando.
- Trajetória observada ao longo dos quadros confirma subida, gravidade e queda; onze pontos físicos se articulam.
- Esc congela os pontos físicos e a câmera; Enter continua.
- O alvo cai e se recupera automaticamente; K produz lançamento independente.
- Corrida + J executa avanço; H testa dano; R restaura vida, posição, alvo e combo.
- F2 mostra colisões e vínculos do corpo articulado.
- Janela de 390 pixels sem rolagem horizontal.
- Nenhum erro JavaScript ou pedido de rede externo. O blob usado pelo carregador do atlas pertence ao servidor local.

Leitura final: **57,94 FPS**, cerca de **20,61 MB de heap JS**, com gravação de vídeo e ferramentas de teste ativas. Foram auditadas **24.720 chamadas de desenho** do canvas do jogo e da composição do Sorriso: zero com suavização. Atlas carregado: 12 partes + quadro-base, composição 96×80. O arquivo de arte carregado tem aproximadamente 5,5 KB; as fontes maiores ficam fora da carga da partida.

Esses valores são uma amostra local, não um benchmark sustentado ou medição no ThinkPad T400. Heap JS não representa a memória total do navegador. O ragdoll é simplificado: piso, paredes laterais e vínculos de distância, sem autocontato nem limites anatômicos detalhados. O alvo é de treino e não possui IA de combate. A animação por recortes ainda pode receber refinamento artístico.

Evidências: `browser-test-v3.json`, `combo-v3.webm`, `poses-v3.png`, `prototipo-v3.png`, `combo-v3.png`, `chute-ragdoll-v3.png`, `colisoes-v3.png` e `compacto-v3.png`.
