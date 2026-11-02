# Revisão 2 do protótipo

Resposta às críticas e escolhas de Felipe em 01/11/2026. A primeira versão não
foi aceita como base satisfatória de combate, animação, percepção ou apresentação.

## Alterações

- Primeira pessoa na fuga e nas frestas; terceira pessoa no restante.
- Abertura curta e revelação do perseguidor, com controle bloqueado durante a
  cena e opção de pular. Celular/horário e porta introduzem o objetivo.
- Portas físicas/interativas e checkpoints registrando seu estado.
- Remoção do IK de braço e das sequências anteriores. Um gancho completo e
  medido, esquiva curta física e um contra-ataque.
- Patrulha, reação aos passos e ataque autônomo. A preparação, ativo e recuperação
  pertencem ao mesmo clipe; só a fase ativa produz contato/dano.
- Correção da multiplicação de velocidade de animação. Biblioteca separada para
  idle, caminhada, corrida, esquiva e pose sentada, sem modificar o GLB aprovado.
- Resolução maior, iluminação legível, menos ruído nas texturas, janelas/portas,
  mobiliário e uma rua além da saída.

## Evidência de funcionamento

A suíte usa os corpos e ossos do Godot. Jogador parado recebe um golpe de 38;
a esquiva temporal faz o punho passar fora das hurtboxes; um único contra-ataque
conecta e derruba. Não se usa um sinalizador de invulnerabilidade para ignorar
contato visual. O braço correto e o alcance são medidos no clipe.

A conferência nativa começou com a nova abertura e frestas, por imagens do
viewport/interface. A inspeção inicial encontrou uma conversão incorreta da pose
local no gerador da posição sentada e luz excessiva no celular. A conversão foi
corrigida, foram adicionados limites geométricos para pés e altura da corrida,
e a luz/textura foram ajustadas. Toda aprovação visual continua separada dos
resultados automáticos: o jogador decide se a troca é convincente.

Arquivos de evidência em `work/prototipo-qa/revisao-v2/`; logs da suíte em
`work/v2-tests.log`. Uso e limites em `godot-3d/prototipo/README.md`.

## Resultado da execução nativa

Na execução aberta por Felipe, foi possível assistir à abertura, espiar a porta
em primeira pessoa, abrir e sair. A aproximação fez o primeiro cultista perceber,
vir e atacar por iniciativa própria. A esquiva e um contra-ataque encerraram a
troca com Miguel a 100 de vida, sem contato inimigo: ataques 1, erros 1,
contra-ataques conectados 1. O corpo terminou no chão.

Depois, o segundo cultista também iniciou ataque durante a passagem; Miguel
conseguiu evitá-lo e alcançar a descoberta. A revelação passou à primeira pessoa,
a fuga atravessou o obstáculo automaticamente e terminou em `escaped`, com 100
de vida e sem faca. Resultado acumulado: ataques inimigos 2, erros 2, golpes
recebidos 0, contra-ataques conectados 1. Estado salvo em
`work/prototipo-qa/revisao-v2/resultado-final.json`.

A versão final no disco passou em **39 verificações** da nova base. Os últimos
ajustes de pose sentada, estabilidade da corrida, intensidade das velas, ruído
da textura e articulação visual do portão foram feitos após a execução aberta;
esses ajustes precisam de nova abertura. Não foram marcados como aprovação
visual na janela antiga. Cenário e animações ainda dependem da avaliação de Felipe.

## Conferência após a última abertura

Felipe reabriu a versão final. As capturas em `abertura-corrigida/` mostram Miguel
sentado com os pés abaixo do banco, o celular legível sem a luz estourada e os
cortes até a entrega do controle. `corrida-corrigida/` registra movimento nos dois
sentidos sem o salto vertical do ciclo anterior. A execução foi restaurada ao
checkpoint inicial e deixada pausada, com teclas liberadas, para Felipe jogar.

O render de QA agora aguarda um quadro de processamento para atualizar os
comandos de desenho da interface, sem depender do sinal de renderização de uma
janela oclusa. O último conjunto de testes terminou com 39 verificações passando.
Isso confirma esta revisão técnica; a aprovação da sensação e da estética cabe
à avaliação do jogador.
