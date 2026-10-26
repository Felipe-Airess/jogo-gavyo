# Direção deste protótipo

Projeto novo; superfície principal é a partida de teclado. Entrada: abrir o jogo, Enter, experimentar movimento e contato. Sucesso: cinco acertos distintos no boneco. Recuperação: Esc pausa, R reinicia. Na tela compacta mantemos a mesma ação via teclado; toque ainda não é suportado e isso é informado.

Prioridade visual: personagem e alvo, chão caminhável, vida/treino, comandos. Informações de renderer e FPS ficam no HUD de desenvolvimento; detalhes de implementação ficam no README. Temperamento: escola vazia, fim de tarde, humor seco em objetos institucionais. Sem cartões, marketing ou ornamentação neon.

Base escolhida pelo usuário: Phaser 3 + Canvas, JavaScript e HTML/CSS mínimos. Referências conceituais informadas: Scott Pilgrim, LISA, Mother 3. Não se copiaram elementos gráficos desses jogos.

Riscos principais: placeholder ser confundido com arte final; profundidade parecer uma plataforma; hitbox trocar de lado no meio do soco; escala fracionária borrar pixels; teste em máquina atual ser confundido com benchmark no T400. A documentação e as verificações tratam esses pontos.

Verificar antes de mudar arte ou controles: âncora dos pés, continuidade de poses, facing em ataque, profundidade do contato, legibilidade a 1×, foco de teclado, pausa ao perder foco, reinício e ausência de requisições externas. Não acrescentar outros personagens sem ampliar o escopo explicitamente.
