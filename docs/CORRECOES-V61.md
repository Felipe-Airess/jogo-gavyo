# Correções 0.6.1

- Fôlego: custos de golpes aproximadamente pela metade (arredondados para cima, mínimo 3); repouso recupera 36/s, recuperação de ataques 14/s; corrida gasta 0,8/s e arrasto 0,6/s.
- Tropeço por erro: exige golpe sem contato e reserva de até 6 pontos após pagar o custo. Com energia, o erro recupera normalmente. Bloqueio não é erro no vazio. O golpe de impulso ainda pode derrubar ambos quando conecta, conforme a mecânica anterior.
- Recorte: os desenhos da corrida não respeitavam a grade fixa da fonte. A nova extração segue a silhueta inteira com conectividade diagonal, preservando joelho, canela e tênis. O primeiro quadro recuperou 111 pixels visíveis no atlas. Nenhuma silhueta de corrida ultrapassa sua célula de destino.
- Pele: uma paleta clara neutra comum foi transferida para os quadros existentes. A referência de cor foi editada com a ferramenta integrada de imagens; a aplicação determinística preservou posições e poses. Os manequins não receberam a paleta do Sorriso.

Assets ativos: assets/sorriso-v61.png e assets/sorriso-v61.json. Paleta: assets/skin-palette.json. As versões anteriores foram preservadas. Revisão visual: revisao-v61.png. Referência editada: references/sorriso-pele-clara-v61-referencia.png. Diagnóstico de recorte e cores: recorte-paleta-v61.json.

Validação: 76 testes de lógica/integração; verificação de seis grupos no navegador em browser-test-v61.json. O teste de navegador prepara estados controlados para verificar erro com/sem energia e usa o teclado para a corrida. Não mede naturalidade artística nem desempenho no T400.

## Prompt da referência de cor

Modo: image_gen integrado, edição 2D. Entrada: references/sorriso-contexto-v6-fonte.png.

COLOR CORRECTION ONLY of this exact transparent 8 columns x 6 rows pixel sprite sheet. Sorriso is a FAIR WHITE young man: change ONLY the exposed skin in every face, neck, hand, arm to a consistent pale neutral peach palette, avoid orange/tanned/brown skin. Suggested base #efcbb7, highlight #f8e1ce, mid-shadow #c89a87, deep skin shadow #906858. Keep black curly hair absolutely black. Preserve exactly every pose, silhouette, cell layout, existing dimensions, transparent alpha, all clothing colors, all limb lengths and anatomy. Do not redraw motion, resize figures, alter costumes or add text. This is palette correction across the existing sprites. All skin should match the same fair neutral character throughout. Transparent background with no halos.
