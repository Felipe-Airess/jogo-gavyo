# Integração de animações — 02/11/2026

Em implementação para teste local, Godot 4.5.1 Compatibility. Base: `f356efd`.
Miguel original preservado; proposta v2 e decoração do mapa não fazem parte.

## Critérios de entrega

1. Miguel, cultistas, Quaternius e Mixamo no SkeletonProfileHumanoid com eixos e silhueta corrigidos. Nunca transportar posições de membros de outro corpo.
2. AnimationTree é o único dono da reprodução. Locomoção acompanha deslocamento real; ações não reiniciam a cada quadro e efeitos seguem eventos do clipe.
3. Loops medidos na emenda (rotação, quadril e pés). Arrancada Running nunca é selecionada como ciclo. Passada medida no rig do Miguel.
4. Empurrão exige mão no tronco, alvo válido e caminho livre. Um efeito por ação; fadiga não desloca o contato em relação ao clipe. Agarrão mantém os dois corpos separados e alinhados.
5. Porta, bolsa, armário e portão têm âncoras verificadas; ação interrompida não concede item nem abre porta depois.
6. Testes de regressão, percurso, toque e capturas no renderizador local antes da entrega. Validação automatizada não equivale à aprovação visual de Felipe.

## Fontes e limites

Fontes: dois GLB Quaternius CC0 e sete FBX Mixamo já versionados. Downloads locais conferidos: mesmos sete FBX; pasta antiga de combate não é pacote novo.

O importador 4.5.1 descartava trilhas ao remover ossos não mapeados dos GLB (erros de índice e somente 10 trilhas restantes). A remoção automática foi desativada; a biblioteca derivada filtra explicitamente apenas as rotações dos 22 ossos de Miguel e posição do quadril. Originais GLB/FBX intactos.

Referências técnicas: [retarget Godot 4.5](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/retargeting_3d_skeletons.html), [AnimationTree 4.5](https://docs.godotengine.org/en/4.5/tutorials/animation/animation_tree.html).
