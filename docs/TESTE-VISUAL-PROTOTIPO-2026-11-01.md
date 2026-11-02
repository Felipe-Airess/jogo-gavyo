# Primeira revisão visual do protótipo — 01/11/2026

Execução nativa aberta por Felipe no Mac: Godot 4.5.1 Compatibility,
Intel Iris OpenGL. Captura da cena por viewport próprio e comandos de jogo
pela ponte local `--qa-inspect`; não houve acesso ao restante do desktop.
A captura não inclui a interface do CanvasLayer; texto/estado consultados em JSON.

## Percurso realmente exercitado

1. Iniciar e caminhar da sala de materiais até o pátio.
2. Aproximar por trás do primeiro cultista e executar a finalização furtiva.
3. Transpor o obstáculo do corredor por Espaço.
4. Travar no segundo cultista, provocar confronto, tentar esquiva, derrubar e
   finalizar no chão. Miguel ficou com 62 de vida: esta tentativa não demonstra
   uma esquiva perfeita e não foi classificada assim.
5. Entrar na sala de aula, pegar a faca e um empanado entre as carteiras.
6. Consumir o empanado; vida 62 → 100, estoque consumido.
7. Entrar/sair do armário; estado oculto confirmado e câmera inspecionada.
8. Alcançar a área ritual e acionar a perseguição.
9. Permitir a captura com faca: item consumido, lâmina visível no perseguidor,
   Miguel vivo com 100 de vida.
10. Correr de volta, atravessar automaticamente o obstáculo e chegar ao portão.
    Estado final `escaped`, posição aproximada (-0.515, 0, 14.143).

Registros e imagens numeradas em `work/prototipo-qa/revisao/`.
A execução foi deixada parada ao final, com comandos liberados.

## Defeitos encontrados e correções no código

- **Primeiro cultista morto continuava em pé.** `kill()` mudava o estado e o
  clipe, mas o laço ignorava os mortos antes de avaliar a pose. Morte agora
  aplica deitado sem blend, atualiza o rig, zera vida e oculta o aviso. O laço
  continua avaliando os corpos. Regressão mede altura real da cabeça (< 0,5 m).
- **Placas vistas pelo verso ficavam espelhadas.** Orientação das placas da
  sala de materiais e sala de aula invertida para o lado de aproximação.
- **Detecção de costas excessivamente próxima.** O atalho de visão em 360 graus
  começava a 1,2 m e ameaçava a finalização furtiva antes de tocar. Agora só
  vale a 0,62 m; a um metro, a orientação do cultista deve continuar contando.
- **Miguel ocultava o alvo.** Câmera travada recebe offset lateral e altura,
  com raio de colisão do pivô para não inserir o enquadramento numa parede.
- **Armário não parecia uma fresta.** A câmera estava perto demais da abertura.
  Foi recuada e o modelo de Miguel é ocultado só durante a visão interna,
  reaparecendo ao sair/restaurar. Regressão verifica passagem do raio central
  pela fresta e bloqueio pelo painel no raio superior.
- **Sala inicial sem o vermelho definido.** Adicionada uma vela na bancada;
  roupa dos cultistas ligeiramente clareada para leitura da silhueta.

## Limites da conclusão

Essas correções foram escritas enquanto a execução anterior permanecia aberta;
precisam de nova abertura. Testes automáticos cobrem as regressões, mas a
comparação visual da versão corrigida ainda está pendente. Não se afirmou
aprovação estética nem qualidade final das animações.

Sem avaliação de áudio nesta ponte. O FPS inclui render extra de QA e não é
medição de desempenho da versão de jogo. Fuga sem faca, inimigo vendo a entrada
no esconderijo, troca entre dois alvos e combos avançados não foram todos
reexercitados visualmente nesta rodada; as regras disponíveis permanecem
cobertas pelos testes automáticos, e combos avançados continuam fora deste escopo.
