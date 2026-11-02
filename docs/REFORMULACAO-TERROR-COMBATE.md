# Reformulação — terror e combate

> **Continuidade posterior:** ler [CONTINUAR-NOUTRO-CHAT.md](CONTINUAR-NOUTRO-CHAT.md)
> e [DECISOES-RODADA-3.md](DECISOES-RODADA-3.md) antes de executar este plano.
> Decisões novas prevalecem: câmera sobre ombro; sem celular ao acordar;
> vídeo no pátio de química; perseguição só se o alerta tiver sido espalhado;
> saída pulando portão 1; novos checkpoints e fôlego apenas por spam.
> Trechos divergentes abaixo são históricos, não requisitos atuais.

Decisões confirmadas por Felipe na conversa de 01/11/2026. Documento de direção;
o estado da implementação está descrito no README do protótipo.

> Revisão 2 após o teste do usuário: terceira pessoa na exploração/combate;
> primeira pessoa na perseguição e nas frestas; visual mais limpo, próximo de
> Fears to Fathom. Primeiro acertar um ataque inimigo, uma esquiva e um
> contra-ataque, antes de recolocar sequências. Abertura curta com Miguel
> acordando, celular, vozes e porta aprovada.
>
> Mudança anterior: Felipe substituiu a exploração por quadros laterais por
> terceira pessoa, para explorar narrativa e terror. As menções laterais abaixo
> registram decisões anteriores. Combate com travamento de alvo, troca e opção
> de destravar aprovados. Enquadramento da perseguição ainda precisa ser definido.

## Direção confirmada

- Reformular combate, colisões, cenário e iluminação.
- Referência de luta: UFC 3, pelo impacto e encaixe entre golpes e reações.
  Prioridade: sequências conectadas, depois precisão visual do contato, depois esquivas.
- Ritmo mistura ações rápidas com golpes de peso; jogador cai rápido. Dominar a
  esquiva deve permitir dominar os inimigos.
- Câmera próxima e lateral; personagens e cenários 3D com texturas e pixelização
  de jogo antigo. Hotline Miami é referência visual e de gore explícito.
- Cidade e escola, normalmente à noite ou ao entardecer; Fears to Fathom como
  referência de ambiente.
- Até dois inimigos no confronto, com um atacando por vez. O segundo não pode
  interromper a sequência/finalização. Seu comportamento de espera ainda será definido.
- Esquiva curta de tronco e deslocamento maior para escapar.
- Encurralar numa sequência, jogar no chão e finalizar o caído é a sensação desejada.
- Uma abertura bem executada pode encerrar um inimigo comum. Inimigos importantes
  têm movimentos/batalhas mais elaborados e exigem mais aberturas ou um item específico.
- Cada capítulo acompanha um estudante diferente. Diferenças mecânicas e elenco
  de cada capítulo ainda não definidos.
- Perseguidor forte demais para combater: correr e se esconder.
- Primeiro capítulo acompanha Miguel.
- Exploração por quadros laterais, com mudança de enquadramento entre ambientes.
- Durante a sequência, apertar ataque continua os golpes; outro comando derruba.
- Esconderijos aprovados em princípio (armários, sob mesas, banheiros e salas
  escuras foram os exemplos apresentados), vendo o perseguidor procurar.
- Morrer deve fazer perder mais progresso; intervalo de checkpoints e perdas
  específicas ainda não definidos.

Qualquer abertura válida pode permitir finalizar; a esquiva perfeita não é
requisito obrigatório de toda sequência decisiva. Felipe confirmou também um
modo furtivo: aproximar-se por trás sem ser percebido permite finalizar.

- Retorno após morrer em pontos específicos; locais e distância entre eles pendentes.
- Para esconder-se do perseguidor, quebrar a linha de visão antes. Som e frestas
  permitem perceber se o perigo passou.
- Cultistas com aparência de estranheza quase humana (uncanny valley). Natureza
  sobrenatural e identidade do perseguidor ainda não definidas.

## Proposta principal para testar

Esquivar no momento certo abre uma janela curta; o jogador aperta ataque para
iniciar a sequência de contra-ataque. Manter essa proposta em primeiro plano.
Felipe quer avaliá-la jogando e reconsiderar se não gostar na fase de teste.

A continuação foi escolhida: apertar para continuar, com outro comando para
derrubar. Ainda faltam ritmo exigido, tempos, dano e teclas/botões.

## Possibilidade narrativa

Abertura escolhida: Miguel costuma dormir no almoço num lugar escondido da
escola. Dorme demais; ninguém o avisa por não saber que está ali. Acorda à noite
e descobre que o local é usado por um culto nesse horário. Ainda é preciso
definir o esconderijo e se a atividade ocupa a escola ou uma parte dela.

A ideia inicial de invasão evoluiu para essa descoberta noturna. Sair da escola,
sustos inesperados e perseguição compõem a direção; natureza do culto e
perseguidor ainda não estão fechados.

### Detalhes confirmados da abertura

- Miguel é monitor de educação física e dorme dentro da sala de materiais dessa
  disciplina. Esse é o esconderijo em que passa do horário.
- O culto usa o local há tempos; Miguel não sabe disso.
- Estranheza dos cultistas por expressões, olhar, postura e movimentos, inclusive
  articulações estranhas; não deformar as proporções corporais.
- Iluminação varia por ambiente. Na primeira área, preferência por luz
  avermelhada das velas do culto. Fontes e tratamento visual ainda serão testados.
- Perseguidor surge de surpresa um pouco depois: primeiro deixar o jogador se
  acostumar com a exploração e o combate, criando a expectativa de que esse é o
  funcionamento do jogo; depois introduzir um desafio maior que exige fugir.
  Gatilho e apresentação ainda não definidos. Atualização: a perseguição encerra
  o capítulo na saída da escola, após o jogador ter experimentado a base do jogo.
- Primeiro indício percebido por Miguel (som, fresta, ritual etc.) ainda em aberto.

### Fluxo e som aprovados

- Miguel acorda sozinho na sala de materiais, pode explorar e ouve algo do
  corredor antes de abrir a porta (proposta aprovada).
- Objetivo inicial é investigar. Depois da perseguição, o objetivo muda para
  sair imediatamente e contatar os outros protagonistas.
- Primeiro encontro: cultista de costas; tanto passar escondido quanto finalizar
  são opções aprovadas. Não obrigar combate nesse encontro.
- Ambiente silencioso, com grilos e sons do culto. Não adicionar trilha musical
  por padrão à exploração ou às lutas; eventual mudança precisa ser definida.
- Checkpoints discretos, sem exigir locais de salvamento dentro da história.
  Posições, frequência e estado restaurado ainda pendentes.

Essas escolhas resolvem a descoberta inicial por som; o conteúdo exato do som e
o primeiro ritual que Miguel vê continuam em aberto.

### Combate de Miguel e encerramento do capítulo

- Miguel luta de forma instintiva. Não atribuir treinamento formal sem nova decisão.
- Continuação simples por apertos de ataque é a base. Deve haver possibilidade
  de combos avançados que exijam maior precisão e ofereçam recompensa maior;
  comandos, recompensa e escopo no protótipo ainda serão definidos.
- Se o perseguidor alcançar Miguel, um item adequado, como uma faca, pode permitir
  escapar do agarrão. Sem item, não há escape confirmado. Consumo, comando e
  resultado exato da captura sem item ainda precisam ser definidos.
- A perseguição termina na saída da escola e é o final do capítulo. Não colocar
  outro trecho de investigação dentro da escola depois dessa perseguição.
- Ao escapar, Miguel quer contatar os outros protagonistas; mostrar isso no final
  ou no início do capítulo seguinte ainda não foi decidido.

### Itens, movimento e referência da escola

- Faca usada para escapar do agarrão fica presa no perseguidor: o jogador perde
  o item. Sem item adequado, ser agarrado pelo perseguidor resulta em morte.
- Exploração permite correr e agachar livremente; saltar/transpor obstáculos
  apenas em locais apropriados, por ação contextual.
- Combos avançados combinam recompensas (força, rapidez, eficiência e variações),
  com força como benefício principal. Valores e efeitos específicos ainda não definidos.
- Escola brasileira com referência indicada por Felipe: Joaquim Antônio Albano,
  em Fortaleza (grafada na mensagem como "joaquin antonio albano"). Planta,
  arquitetura e disposição dos ambientes não foram verificadas nem fornecidas;
  não apresentar uma planta inventada como reprodução da escola real.

### Escola, ritual e percepção

- Usar uma versão inspirada na escola, adaptando os espaços ao jogo.
- Segundo Felipe, na escola real a sala de materiais fica no pátio aberto onde
  há o refeitório. Usar essa relação espacial como referência da abertura.
- Os rituais visam libertar um ser antigo (leitura de "um se antigo" na mensagem).
  Identidade, aparência, origem e relação com o perseguidor ainda não definidas.
- Cultistas percebem por visão, conforme direção e obstáculos, e por sons como
  corrida e barulhos próximos. Agachar permite aproximação furtiva pelas costas.
- Uma luta pode atrair outro cultista, mantendo até dois no confronto e sem
  interromper a sequência/finalização. Distâncias de audição, duração do alerta e
  comunicação entre inimigos ainda não definidas.

### Perseguidor e percurso final

- Perseguidor é um cultista maior e mais forte, armado com faca; não é o ser antigo.
- Miguel não interfere no ritual: quase presencia algo, é notado e começa a
  perseguição. O que ele chega a ver ainda não foi definido.
- Percurso com poucas travas. Felipe sugeriu parkour; ações e obstáculos
  específicos ainda precisam ser escolhidos. Não tratar como aprovação de um
  sistema acrobático complexo.
- Na perseguição, o jogador pode escolher correr ou usar esconderijos e retomar
  a fuga. Não exigir uma alternância roteirizada entre corrida e esconderijo.
- Destino final permanece a saída da escola, encerrando o capítulo.

### Parkour, colisões e interação aprovados

- Ações: transpor mesas e bancos, saltar obstáculos baixos, subir em plataformas
  baixas, passar por vãos agachado e agarrar beiradas.
- Na exploração, executar ações por botões. Na perseguição, travessias de
  obstáculos são automáticas ao passar perto; detecção, direção de aproximação e
  prioridade entre rotas ainda precisam ser ajustadas no teste.
- Perseguidor consegue seguir o percurso, demorando mais em alguns obstáculos e
  precisando contornar outros. Uma mesa isolada não deve garantir segurança.
- Combate pode interagir com parede, armários e mesas: sequência adaptada ao
  encurralamento, móveis reagindo ao impacto e derrubada respeitando o espaço.
- Ordem inicial aprovada na proposta: começar por parede e chão e depois ampliar
  para móveis. Animações, colisores, deformações e limites técnicos ainda não
  implementados ou validados.

### Controles, leitura e recuperação

- Plataforma de entrada do primeiro protótipo: teclado. Mapeamento ainda não definido.
- Aberturas comunicadas pela postura/animação e por sinal visual, com referência
  indicada por Felipe aos jogos Arkham. Não presumir contra-ataque automático;
  manter as regras de abertura e continuação já escolhidas.
- Recuperação de vida comendo empanado. Quantidade curada, estoque, obtenção e
  tempo da ação ainda não definidos.
- Faca reservada ao escape do agarrão do cultista perseguidor; não serve como
  arma contra inimigos comuns. Continua ficando presa nele depois do uso.

### Mudança para terceira pessoa e teclado aprovado

- Felipe pediu terceira pessoa para ampliar exploração, narrativa e terror;
  substitui a decisão anterior de exploração por quadros laterais.
- Recomendação ainda sujeita à escolha: câmera atrás de Miguel, controlada pelo
  mouse na exploração; aproximação/enquadramento de combate a definir. Não
  presumir câmera lateral nem travamento de alvo já aprovados nesta nova direção.
- Esquema de teclado apresentado e aceito: A/D mover, Shift correr, S agachar,
  Espaço parkour/interação, J atacar/continuar/furtivo, K esquivar (com direção,
  deslocamento), L derrubar/finalizar no chão, E comer empanado.
- Esse esquema foi aceito antes da mudança de câmera; agora precisa acomodar
  movimento WASD e remapear agachar. Nenhuma nova tecla foi escolhida ainda.
- Comer empanado exige tempo. Interrupção, duração, capacidade de carregar e
  quantidade curada continuam pendentes.

### Terceira pessoa: câmera, mouse e cura confirmados

- Câmera de combate trava no alvo, permite trocar de inimigo e destravar.
- Felipe aceitou a proposta com mouse: WASD mover, Ctrl agachar, clique esquerdo
  atacar/continuar sequência, clique direito esquivar, Q derrubar/finalizar.
  Mantêm-se Shift correr, Espaço parkour/interação e E comer empanado. A combinação
  direcional para esquiva curta versus deslocamento continua a ajustar no teste.
- Teclas de travar/destravar e trocar alvo ainda não escolhidas.
- Dano durante o consumo do empanado cancela a cura e preserva o item (opção de
  cancelamento escolhida em resposta à alternativa de perder o empanado).
- Duração, capacidade de carregar, obtenção e quantidade curada ainda pendentes.
- Esta seção substitui as pendências anteriores sobre câmera de combate,
  remapeamento para WASD e interrupção da cura.

### Esquiva, perseguição e estoque confirmados

- Clique direito sem direção: esquiva curta de tronco. Com WASD: esquiva com
  deslocamento. Regra aprovada para o teste.
- Na perseguição, câmera livre; olhar para trás virando pelo mouse, sem botão
  dedicado e sem travar a câmera no perseguidor (proposta escolhida).
- Carregar tantos empanados quanto encontrar, sem limite fixo de estoque.
  Disponibilidade no cenário e quantidade curada ainda precisam ser definidas.
- Botão do meio para travar/destravar e rodinha para trocar de alvo aprovados.
- Cada empanado recupera parte da vida. Quantidade exata e tempo de consumo
  serão ajustados no teste; não há valor numérico aprovado ainda.

## Estado ao encerrar a definição inicial

Direção principal e controles definidos. Felipe autorizou implementar todo o
recorte proposto, reutilizar Miguel 3D e cultistas genéricos e começar com combos
simples. Implementação inicial em `godot-3d/prototipo/`; uso, validação e limites
em [README do protótipo](../godot-3d/prototipo/README.md).
Prioridade de avaliação: encaixe das sequências, precisão do contato, esquivas,
câmera em terceira pessoa e legibilidade no ambiente escuro. Ajustar valores
com base na experiência jogável de Felipe.

## Questões abertas

- Comportamento de ataques sem abertura, percepção furtiva e alcance das finalizações.
- Diferenças entre estudantes; Miguel abre o primeiro capítulo.
- Transições dos quadros laterais e regras para descobrir esconderijos.
- Localização dos pontos de retorno, recuperação e perdas concretas ao morrer.
- Paleta, fontes de luz e limites de escuridão para leitura dos ataques.
- Tipos de ferimentos e finalizações; gore explícito confirmado, técnicas e
  desmembramento ainda não definidos.
- Relação entre capítulos por estudante e a ideia anterior de trocar personagens.

## Primeiro teste sugerido, ainda não aprovado como escopo

Um trecho de escola, um estudante e um inimigo comum: ataque legível, duas esquivas,
abertura de contra-ataque, sequência sincronizada, queda e finalização. Avaliar
contato visual, resposta dos controles e sensação antes de ampliar o conteúdo.

## Revisão 2 — resposta ao teste do usuário

Felipe rejeitou o combate anterior por correção/teleporte da mão errada, falta
 de coesão das animações e cultistas pouco ativos. Também pediu iluminação mais
legível, resolução mais limpa, portas e apresentação narrativa/câmera.

Escolhas confirmadas: primeira pessoa na perseguição e nas frestas; terceira
pessoa na exploração e no combate. Reduzir a pixelização e aproximar o visual de
Fears to Fathom. Validar primeiro uma troca com ataque inimigo, esquiva e
contra-ataque; sequências mais elaboradas ficam para depois. Abertura com Miguel
acordando, vendo o celular, ouvindo o culto e saindo pela porta, com controle
sendo entregue aos poucos.

Implementação: biblioteca de movimento exclusiva do protótipo, sem modificar o
GLB aprovado; golpe completo medido, sem IK de braço; percepção/patrulha e
ataque autônomo; portas físicas com frestas; abertura e revelação dirigidas.
Estado de validação e limitações estão no README do protótipo.
