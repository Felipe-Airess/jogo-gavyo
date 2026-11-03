# Miguel animado — 01/11/2026

Miguel aprovado nas revisões do rosto, polo, jeans e tênis, agora integrado ao
teste Godot 3D. O rosto e a geometria aprovados foram preservados.

O pacote tem **43 clipes: 25 movimentos completos do Mixamo e 18 recortes de
treino**. São recortes dos mesmos movimentos, não 43 capturas diferentes.
Fontes FBX existentes em `arte/mixamo/`; nenhum download adicional do Mixamo
foi necessário para os movimentos integrados nesta rodada.

- `arte/miguel_animado.glb` e `godot-3d/miguel_animado.glb`: mesmo arquivo,
  22 ossos, 2 materiais, textura da polo embutida, 61.688 triângulos.
- `miguel_animacoes.json`: arquivo de origem, intervalo usado, sentido,
  duração real e indicação de loop de cada clipe.
- `<nome do FBX>.jpg`: seis poses de cada movimento completo, renderizadas
  com EEVEE e a textura real. As 150 poses foram inspecionadas visualmente.
- `canais.json`: canais finitos e deslocamento horizontal do quadril avaliado
  em cinco poses de cada ação (máximo menor que 0,0001 m).
- `godot.json`: todos os 43 clipes importados no Godot 4.5.1, com duração e
  cinco poses finitas em todos os 22 ossos.
- `web-treino.png`, `web-galeria.png`, `web-console.json`: teste Chromium
  com WebGL 2; treino e navegação da galeria funcionando.

## Uso

O projeto `godot-3d` inicia no treino. A/D anda; Shift corre; Espaço defende;
J jab; K direto; L gancho; H pesado; I circular; O chute alto; P joelhada.
Tab abre a galeria de todos os clipes; setas trocam e Enter repete.
F reduz a velocidade. F2 abre o teste de desempenho; F2/Esc volta ao treino.
Há botões de toque para deslocamento, defesa, jab, direto, chute e galeria.

A caminhada para trás usa o ciclo de caminhada invertido, registrado no
manifesto. Os loops de treino recebem uma transição no último décimo para
fechar o ciclo. O deslocamento no cenário continua a cargo do jogo.

## Limites conhecidos

Esta entrega cobre a biblioteca local e o treino atual. Não substitui por
movimentos alheios os golpes e reações sem fonte específica. Os atalhos antigos
de uppercut isolado, cotovelada, jab no corpo, chute baixo e combo misto foram
retirados do treino porque não tinham um recorte específico validado. A sequência
com uppercut continua disponível completa na galeria. O alvo usa uma reação de
bloqueio e queda; não apresenta o mesmo bloqueio como três reações anatômicas.

Salto, escalada, abrir porta, reações específicas de cabeça/corpo/perna e
arremessos sincronizados para dois personagens ainda precisam de animação e
integração próprias antes de virar mecânicas do jogo. Os dois FBX de
Brutal Assassination estão disponíveis individualmente, sem alegação de
sincronização de contato entre dois corpos.

Os contatos de golpes do treino são estimativas relativas, sinalizadas em
`contatoRevisado`; não são uma calibração de hitboxes. A galeria preserva as
durações do Mixamo, em vez de impor os tempos dos sprites 2D antigos.

O QA de geometria continua o da versão aprovada em
`../miguel-silhueta-20261101/qa-depois.json`: passou, com sobreposição UV
intencional de 12,03% e 250 pares de faces internas em contato aceitos para o
modelo de jogo. A inspeção por amostragem não garante ausência de toda
interpenetração em todos os quadros. Mãos mantêm o formato do modelo: o rig
compartilhado de 22 ossos não tem articulações individuais dos dedos.

## Reproduzir

```bash
bash scripts/blender-mac.sh -P arte/miguel_publicar_animacoes.py
godot --headless --path godot-3d --editor --import
godot --headless --path godot-3d --script tools/testar_animacoes.gd
GODOT=godot bash godot-3d/tools/build_web.sh
```

Blender 3.6.23 no Mac; transferência de todos os quadros dos FBX, sem a
subamostragem usada nos testes rápidos anteriores. Curvas já assadas são
exportadas diretamente, sem um segundo bake desnecessário.

Skill instalada e aplicada: [blender-animation, roble3/cc-blender-skill](https://skills.sh/roble3/cc-blender-skill/blender-animation),
cerca de 1,5 mil instalações e repositório com mais de 100 estrelas na consulta.
Instalação: `npx skills add roble3/cc-blender-skill --skill blender-animation -g -y --agent codex`.
Backend: Blender local em modo headless; não há servidor Blender MCP configurado.
Exportação web em Compatibility, sem threads, conforme a
[documentação Godot](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html).
