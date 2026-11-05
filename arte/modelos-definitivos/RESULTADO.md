# Modelos definitivos — integração de 05/11/2026

Implementação local no Mac, Godot **4.5.1 Compatibility**. Oito modelos importados e galeria disponível. **Aguardando teste/aprovação visual de Felipe. O QA estrito dos originais não está aprovado para sete modelos**; as ocorrências abaixo foram preservadas conforme a ordem de não corrigir modelos definitivos.

## Arquivos e papéis

Os oito ZIPs internos e suas pastas foram preservados, incluindo nomes originais. [INVENTARIO.md](INVENTARIO.md) lista arquivos, todos os ossos, dimensões, polígonos e texturas. [MANIFESTO-ORIGINAIS.json](MANIFESTO-ORIGINAIS.json) registra 32 arquivos: hashes conferidos depois da integração, sem alteração. FBX e texturas copiados para runtime são idênticos às fontes.

| Modelo | Altura aplicada | Rig original | Uso |
|---|---:|---|---|
| Miguel | 1,76 m | Mixamo, 65 ossos | jogador |
| Bola | 1,75 m | Mixamo, 65 ossos | final existente; preparado |
| Felipe | 1,73 m | Tripo/outro, 78 ossos | final existente; preparado para a abertura futura |
| Sorriso | 1,70 m | Tripo/outro, 78 ossos | galeria/preparado; nenhuma cena criada |
| Passa Marcha | 1,71 m | Tripo/outro, 78 ossos | galeria/preparado; nenhuma cena criada |
| Alessandro | 1,93 m | Tripo/outro, 78 ossos | galeria/preparado; nenhuma cena criada |
| Cultista | 2,00 m | Mixamo, 65 ossos | sete postos, mesmo modelo único fornecido |
| Perseguidor | 2,50 m | Mixamo, 65 ossos | papel condicional existente, após alerta se espalhar |

As alturas informadas foram aplicadas com escala **uniforme** da instância; cápsulas acompanham a altura. Pés alinhados pelo limite da malha em repouso, calculado lendo bind/rest/vertices, sem editar malha, textura, pesos ou pose. Nenhum FBX tem animação embutida. Não houve nome ambíguo. O perseguidor tem 10.678 polígonos / 20.495 triângulos; os outros já são triangulados.

Anteriores preservados em [antes-definitivos-20261105](../arquivo-modelos/antes-definitivos-20261105/). **`arte/miguel_animado.glb` permanece byte a byte igual ao commit anterior.** O protótipo histórico usa uma cópia própria em `godot-3d/prototipo/arquivo/`; o capítulo usa o catálogo definitivo.

## Retarget e regra dos ossos

Só bibliotecas existentes Mixamo/Quaternius; não foram recriados clipes. Dois BoneMap com SkeletonProfileHumanoid em `capitulo1/assets/definitivos/`. Mixamo usa o importador nativo OverwriteAxis; os 78 ossos usam **RetargetModifier3D nativo em pose global**, mantendo OriginalSkeleton, twist/helpers e pesos. BoneRoot não vira Root porque seu pivô está no quadril. Usar OverwriteAxis nesses arquivos fazia a hierarquia extra dobrar as pernas incorretamente; a configuração nativa resolveu sem remodelagem.

APIs/opções verificadas no [código exato da Godot 4.5.1](https://github.com/godotengine/godot/blob/4.5.1-stable/editor/import/3d/post_import_plugin_skeleton_rest_fixer.cpp): `retarget/rest_fixer/retarget_method=1` (Mixamo), `=2` (78 ossos), `use_global_pose`, `original_skeleton_name`. A orientação geral está na [documentação 4.5 de retarget](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/retargeting_3d_skeletons.html). Não usamos APIs 4.7.

Código de pose/IK antigo foi retirado dos atores, inspeção e contatos. O controlador continua dono das animações do jogo; a galeria tem AnimationTree próprio, crossfade de 0,22 s e nenhum `AnimationPlayer.play/seek`. Contatos usam leitura FK do clipe intacto para escolher posição/orientação do corpo e momento do evento. A travessia do portão desloca o corpo inteiro. Testes medem, não escrevem ossos.

## Conferência visual e QA

Olhei as vistas originais frente/lado/costas, sobreposição wire, capturas reais do Godot em corrida/agachamento/agarrão/morte e filtro retrô. Folhas: [grupo 1](../revisoes/definitivos/folha-1.jpg), [grupo 2](../revisoes/definitivos/folha-2.jpg), [wire](../revisoes/definitivos/folha-wire.jpg), [morte](../revisoes/definitivos/folha-morte.jpg), [retrô](../revisoes/definitivos/folha-retro.jpg). PNGs individuais em [godot](../revisoes/definitivos/godot/); vistas fonte e QA em cada pasta por nome.

| Modelo | O que vi nas poses conferidas | QA original / pendência preservada |
|---|---|---|
| Miguel | corrida com joelho dobrado; agacha sem inversão evidente; punhos à frente no agarrão; morte de costas | 14 faces UV de área zero; 14 vértices duplicados |
| Bola | cabelo e uniforme preservados; pernas separadas ao correr/agachar; morte sem estiramento evidente | 10 faces UV de área zero; 12 vértices duplicados |
| Felipe | uniforme claro e corpo preservados; pernas dobram após retarget nativo; sem braço esticado nas amostras | QA passou, aviso de 7 vértices duplicados |
| Sorriso | cabelo volumoso preservado; corrida/agachamento mantêm silhueta; morte sem inversão evidente | 6 faces UV de área zero; 12 vértices duplicados |
| Passa Marcha | uniforme/calça escura preservados; joelho dobra, mãos avançam no agarrão; morte no chão | 10 faces UV de área zero; 14 vértices duplicados |
| Alessandro | camisa preta e tênis claros preservados; tronco inclina ao agachar; morte de costas | 8 faces UV de área zero; 9 vértices duplicados |
| Cultista | manto acompanha corrida/agachamento como pele rígida, encobre pés/pernas; mangas permanecem largas; ao morrer manto deita com o corpo | 21 faces UV de área zero; 17 vértices duplicados; 2 pares de faces ocultas opostas. Sem simulação de tecido: manto pode intersectar em poses extremas, aprovação visual pendente |
| Perseguidor | membros muito longos vêm da fonte; corrida e mãos avançando preservam essa proporção; dobra joelhos e deita na morte | 18 arestas com orientação inconsistente, 1 par coplanar com z-fighting, 15 arestas non-manifold, 3 pares de faces ocultas opostas |

Todos: nenhum vértice sem peso, nenhum com mais de quatro influências; nenhuma parte flutuante acusada pelo QA. O teste de comprimentos dos membros no esqueleto de skin passa (tolerância 2%) em correr/agachar/agarrar/morrer. Isso não certifica ausência de toda interpenetração em todos os quadros: manto, mangas e pequenos defeitos de fonte continuam para avaliação de Felipe. **Nenhum desses defeitos foi “consertado”.** Relatórios JSON completos em `arte/revisoes/definitivos/<nome>/qa.json`.

Texturas encontradas para os oito modelos, materiais StandardMaterial3D importados. Filtro retrô preserva as cores, com perda de detalhe e realce nas camisas claras. Capturas feitas com OpenGL Compatibility real no Intel Iris. Pacote do preset Web exportado (PCK) e oito modelos/texturas carregados dele. **Não houve execução HTML/WASM em navegador nem teste em celular físico**; entradas de toque foram verificadas com eventos no Godot.

## Como Felipe testa

1. Abrir o capítulo no Godot 4.5.1 em debug, apertar **F10**, ou abrir menu/pausa e tocar em **Galeria de personagens · F10**. A galeria também abre direto por `capitulo1/galeria.tscn`. O jogo fica parado e retorna à mesma instância ao sair.
2. Setas esquerda/direita ou botões Anterior/Próximo trocam personagem. Arrastar mouse/dedo orbita; roda/pinça aproxima/afasta. **Noite/lanterna** e **Filtro retrô** alternam iluminação e filtro.
3. Teclas/botões **1–9**: parado, andar, correr, agachar andando, subir, descer, agarrar, ser agarrado, morte. Lista superior oferece toda a biblioteca existente; não há clipes próprios nos FBX. F10/Esc/Voltar sai.
4. No jogo, conferir Miguel andando/correndo/agachando/escada, portas/armário/bolsa/portão, cultistas nos sete postos, perseguidor após espalhar alerta e Felipe/Bola no final já existente. Não foram criadas abertura ou novas cenas de história, nem alterada a grade.
5. Conferir especialmente manto do cultista e silhueta do perseguidor; anotar qualquer defeito no modelo original para decisão de Felipe, sem remodelagem automática.

## Testes reais

[Saídas completas](../../docs/SAIDAS-MODELOS-DEFINITIVOS.md), sem recorte dos três comandos pedidos:

- `bash scripts/testar-capitulo1.sh`: **413 passed, 0 failed** somando 12 suítes; modelos: **72 passed, 0 failed**.
- `bash scripts/testar-percurso.sh`: **9 passed, 0 failed**, 224,0 s de jogo, sem mortes; vencível sem item/notas.
- Godot headless `capitulo1_nivel_test.gd`: **15 passed, 0 failed**.
- Carregamento do pacote Web: **8 passed, 0 failed**.

Foram corrigidos apenas os encerramentos de dois testes para aguardar liberação de recursos/áudio; o runner continua reprovando qualquer `ERROR:`. A captura avança o AnimationTree em quadros de 1/60 s: não altera pose para conseguir imagem ou teste.

Reprodução: `bash scripts/blender-mac.sh --python arte/inventariar_definitivos.py`; `bash scripts/blender-mac.sh --python arte/conferir_definitivos.py`; Godot com janela `--path godot-3d --rendering-method gl_compatibility --resolution 960x640 -s res://tools/capturar_definitivos.gd`. Blender portátil 3.6.23; nenhum arquivo fonte é reexportado.

## Correção de 05/11/2026 (Claude): braços entrando no corpo

**Problema relatado por Felipe:** nas animações, braços e esqueleto entravam no
corpo. Afetava os quatro modelos com rig Tripo de 78 ossos (Felipe, Passa Marcha,
Sorriso, Alessandro). Miguel, Bola, cultista e perseguidor (rig Mixamo) estavam bons.

**Causa:** os ossos estão certos dentro da malha (medido: 0,2–1 cm do eixo). O
erro estava no retarget do Godot para esse rig (método 2, pose global): o braço
mais caído no repouso afundava no tronco (Passa Marcha 43°, Felipe 20°).

**Correção:** `arte/converter_tripo_para_mixamo.py` (Blender 4.2) gera
`<nome>_mixamo.fbx` em cada pasta: renomeia e reorganiza a hierarquia para o
padrão Mixamo e soma os pesos dos ossos auxiliares (twist, share, olhos, pelve,
raiz) no osso pai. Malha, UV, textura e pose de repouso não mudaram. O Godot
importa esses arquivos pelo mesmo caminho do Miguel (`mapa_mixamo.tres`).
O `catalogo.json` aponta para os novos arquivos e guarda o FBX Tripo original
em `arquivo_tripo_original`. Os originais seguem intactos.

Comparação depois da correção: [folha-rig-corrigido.jpg](../revisoes/definitivos/folha-rig-corrigido.jpg).

Testes (Linux, Godot 4.5.1): capítulo 413/413, percurso 9/9, nível 15/15. Aviso
intermitente "resources still in use at exit" no áudio e no capítulo aparece e
some entre execuções iguais, sem relação com os modelos.
Limite: os ossos de torção somados no pai deixam o antebraço girar como peça
única. Em giro grande do pulso pode haver um leve amassado.

## Correção de 05/11/2026 (Claude): posturas não anatômicas

**Relato de Felipe:** o "parado" tinha as pernas abertas e tortas, e o agarrão
tinha um braço cruzado no peito com o pulso dobrado.

**Causa:** o esqueleto reproduz fielmente a animação. O `Idle` da Quaternius é
um apoio largo (pés a 64% do comprimento da perna); em corpos reais, de quadril
largo e jeans, os pés vão a 77–88% e as pernas parecem tortas. O `Agarrar`
derivado do empurrão saía assimétrico.

**Correção** (dados de animação, não código de jogo nem modelo):
`godot-3d/tools/ajustar_posturas.gd`, rodado sobre `biblioteca.res` depois do
`preparar_biblioteca.gd`:
- nos clipes parados (Idle e variações, Yes, Agarrar, AgarrarEntrada, Empurrar),
  as pernas ficam com 35% do desvio em relação às pernas retas, e o quadril sobe
  o quanto a perna esticou, para o pé continuar no chão;
- o braço esquerdo de `Agarrar`/`AgarrarEntrada` é refletido em espaço global
  para o direito: os dois braços vão para a frente;
- o `Interact` fica de fora, porque a mão dele precisa encostar num alvo medido.

Folha: [folha-posturas.jpg](../revisoes/definitivos/folha-posturas.jpg).
Testes: capítulo 413/413 (aviso intermitente de recurso ao sair), percurso 9/9.
