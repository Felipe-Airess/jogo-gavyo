# Bola — revisão parcial local

03/11/2026. **Modelo criado, exportações e QA técnico conferidos. Entrega visual incompleta: NÃO aprovado como modelo fiel/final. Não integrado ao jogo.**

## Retomada

A instalação que havia parado concluiu após a nova tentativa autorizada. OpenCV foi baixado com curl, conferido por SHA-256 e instalado; NumPy, SciPy, scikit-image e Pillow importam. A falha histórica permanece em DEPENDENCIAS-FALHA.txt. Registro bem-sucedido em DEPENDENCIAS-RETOMADA.txt.

MediaPipe nativo depende de macOS 13 e não abre neste macOS 11. Foi usado o backend HTTP **local já suportado pelo pipeline do Felipe**, com FaceLandmarker WebAssembly/CPU e o mesmo arquivo face_landmarker.task. Chrome local executa o detector. Pillow entrega pixels RGBA sem alteração de cores ao ImageData, evitando a decodificação que travava com a tela desligada. Nenhuma foto é enviada à nuvem. Não houve troca por ajuste do rosto por sliders.

## Feito

- 45/45 fotos preservadas e processadas; 25 com face detectada. TRIAGEM.md registra categorias, notas, yaw/pitch/roll e lacunas. Escolhidas em escolhidas/ e vínculo ao original em origem.json.
- Quatro scripts do Felipe copiados/adaptados para Bola. Corpo MakeHuman masculino, esguio, ALTURA=1,75 m antes do cabelo, peso fornecido aproximadamente 67 kg. Sliders FORMA somente de corpo; rosto por landmarks e contorno.
- Três passadas frontais, uma combinada com perfil e um reparo frontal. Os ensaios anteriores que segmentavam a moldura do quadro e o pescoço foram descartados como alvo final. A checagem do perfil agora usa o registro anterior à correção, sem realinhar o alvo ao erro.
- Cabelo por fatias e máscaras examinadas; pele medida em seis pontos de bochecha de quatro fotos. Farda, gola, jeans, tênis, pele e cabelo separados. Estampas frontal/traseira amostradas de recortes das fotos.
- Pesos interpolados no triângulo da pele para roupa, limitados a quatro e normalizados. Isso retirou as linhas de deformação que apareciam com cópia pelo vértice mais próximo. Removida uma ilha de pele oculta na virilha; UVs criados e n-gons triangulados.
- Fonte arte/bola_boneco.blend, arte/bola_boneco.glb e arte/bola_boneco.fbx. São **rascunhos para revisão**, não versão aprovada.
- Folhas foto/modelo/sobreposição em arte/revisoes/bola/comparacoes/: frente, 34, perfil e corpo. Prévia 426×240 e ampliação sem suavização.
- QA da skill executado sem relaxar limites; relatório e folhas em arte/revisoes/bola/qa/. GLB/FBX reimportados e imagens abertas. Rig nativo e GLB reimportado vistos andando, correndo e levantando de posição baixa.

## Números finais desta revisão

| Medida | Resultado | Meta | Situação |
|---|---:|---:|---|
| Frente, erro bruto dos 478 landmarks | 1.123 mm | <1 mm | **FALHA** |
| Frente, erro simetrizado (diagnóstico) | 0.831 mm | não usar como aprovação | só diagnóstico |
| Perfil, contorno visível, registro fixo | 0.525 mm | <2 mm | passa com limitação abaixo |
| Perfil, máximo | 1.775 mm | informativo | 367 linhas |
| Pele, diferença sRGB por canal | [7.5, 7.0, 5.0] | ≤15 em cada canal | passa nesta luz de revisão |
| Malha, pesos, materiais e normais | pass=true; 0 erros | perfil game | passa técnico |

O número frontal de 0,83 mm anunciado durante o ajuste era **simetrizado**. A medição foi corrigida para incluir a assimetria real da foto e deu 1,12 mm. Não usar o valor menor para declarar a meta cumprida.

São erros de projeção/contorno após registro 2D, não precisão física de um escaneamento. No perfil, o cabelo cobre olho e raiz nasal; a raiz usada no registro é **inferida**, explicitamente anotada em perfil-marcos-manuais.json. A medida não valida a raiz oculta. A escala da cabeça/cabelo usa fotos distantes, mas a silhueta ainda não coincide e a altura total reimportada é 1,7664 m com cabelo e precisa ser reconciliada com os 1,75 m. Foto de corpo tem pontas dos tênis cortadas; comparação de corpo usa escala aproximada e poses diferentes, sem IoU artificial.

## O que vi nas imagens — diferenças que continuam

| Característica e referência aberta | Vista do modelo | Diferença concreta | Veredito |
|---|---|---|---|
| Rosto frontal WA0002 | comparacoes/frente.png | Pálpebras e sobrancelhas angulosas; expressão e volume das bochechas ainda não parecem a foto. Barba rala não representada. Erro bruto acima de 1 mm. | **reparar** |
| Rosto 3/4 WA0043 | comparacoes/34.png | Registro mostra diferença de volume e implantação do cabelo; semelhança ainda insuficiente apesar do ajuste frontal. | **reparar** |
| Nariz/lábios/queixo perfil WA0013 | comparacoes/perfil.png | Contorno visível próximo; raiz coberta não verificável. Região sob o queixo revisada sem deformar o pescoço como no ensaio descartado. | parcial |
| Cabelo distante WA0044/WA0018 e costas WA0025 | modelo-final e comparacoes | Massa lisa demais, topo alto e mechas laterais/da nuca em blocos. Faltam cachos e risca natural; não está fiel. O buraco criado num ensaio foi removido. | **reparar** |
| Farda WA0045/WA0030 | comparacoes/corpo.png e costas do modelo | Cores e estampas vêm das fotos, mas gola está baixa/plana e listras serrilhadas. Tecido mais ajustado, menos caído que na foto. | **reparar** |
| Corpo masculino esguio WA0045 | corpo e prévias do rig | Base masculina e magra; comparação de braço/ombro limitada por A-pose versus braços baixos. Ainda falta validar proporções e altura final sem confundir cabelo com crânio. | parcial |
| Jeans/tênis WA0045 | corpo e prévias do rig | Jeans com barra larga; tênis simplificados, sem cadarços e recortes da foto. | **reparar** |
| Rig — Walk/Running/Crouch_To_Stand existentes | rig-final e rig-exportado | Membros dobram, sem escalas anormais ou estiramentos visíveis nas folhas. Crouch_To_Stand levanta de posição baixa com um joelho perto do chão; **não comprova um ciclo de andar agachado**. | parcial |

A malha atual tem **102.596 triângulos** (58.432 na farda), acima da referência de 25–30 mil faces do projeto. A imagem em 426×240 não significa um modelo geometricamente otimizado: falta reduzir custo após fechar roupa e semelhança.

Não foram testadas todas as poses extremas de ombro/cotovelo/joelho. Não há teste no Godot, pois a integração está fora desta tarefa. O QA visual completo permanece **não aprovado**.

## Ponto exato para continuar

Não refazer extração, instalação ou triagem. Os pixels/landmarks e as exportações estão salvos. Continuar pelo reparo do rosto (erro bruto e revisão 3/4), volume/risca/cachos do cabelo, gola/tecido e tênis. Depois repetir as imagens e o QA afetados, validar escala final e as poses extremas. Não colocar no jogo enquanto a revisão visual não estiver fechada.

Miguel, Felipe e o capítulo 1 não foram alterados; os clipes existentes são apenas lidos. Originais das fotos preservados.
