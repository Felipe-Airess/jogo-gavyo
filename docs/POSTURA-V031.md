# Postura mais firme — 0.3.1

O usuário aprovou a direção do combo/knockback, mas apontou que Sorriso parecia mole e deformável. A correção mantém a arte, os golpes e a física do alvo, alterando a estrutura da animação controlada do protagonista.

- Coluna rígida de 17 pixels, com inclinação limitada a aproximadamente nove graus. Cabeça acompanha a base do pescoço, em vez de flutuar independentemente.
- Braços com rotações definidas por ação e limites de flexão do cotovelo. Foram removidos os alvos livres de IK dos braços, que podiam atravessar a linha do ombro e inverter a aparência da dobra.
- Joelhos com flexão entre quatro e 140 graus. As pernas mantêm comprimentos fixos; os pés de apoio ficam dentro do alcance real.
- Passada com braços em oposição às pernas. A corrida tem apoio mais curto e fase aérea, sem obrigar o corpo a se agachar tanto para alcançar uma passada longa.
- Tronco mais estável, guarda mais alta e chute separado em recolhimento do joelho, extensão e retorno.
- Cada recorte tem pivôs medidos nas pontas reais da peça. A escala é uniforme e constante; as peças não são esticadas separadamente em largura e altura a cada quadro.
- Transições com duração definida de 32–90 ms. A pose segue a curva diretamente após a transição; não há o atraso contínuo de um filtro elástico entre todos os valores.

O ragdoll continua somente no alvo lançado. Sorriso usa uma animação comandada e limitada, não um corpo físico solto. O resultado permanece uma animação por recortes e pode receber refinamento artístico; os testes validam estrutura e comportamento, não substituem a avaliação visual do usuário.

Validação: 22 testes de combate e animação. A rodada de navegador e a gravação desta revisão ficam em `browser-test-v31.json` e `postura-firme.webm`; as poses e capturas têm sufixo `v31`.

Rodada concluída no Edge 156.0.4314.42: sequência de três contatos, knockback, chute, queda, recuperação, pausa, reinício, dano e tela compacta aprovados. Zero erros JavaScript e zero pedidos externos. Foram auditados 23.778 desenhos do jogo/composição, todos sem suavização; leitura de 59,36 FPS nesta máquina com gravação ativa. Não é um benchmark do T400.
