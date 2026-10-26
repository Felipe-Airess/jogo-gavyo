# Folha complementar integrada — 0.4.1

25/10/2026. O usuário autorizou integrar a folha após avaliar suas proporções. A conferência considerou identidade, relação entre cabeça e corpo, comprimento dos membros, altura em relação à folha anterior e apoio no chão. As proporções gerais são coerentes para o estilo caricatural; a folha não é um estudo de biomecânica nem uma sequência de captura de movimento.

## Empacotamento

- Fonte aprovada: `references/sorriso-complementar-aprovado-v1.png`, preservada integralmente.
- Atlas carregado: `../assets/sorriso-integrado.png` e `.json`.
- 88 quadros anteriores preservados, 50 complementares acrescentados.
- Células 128×80; oito colunas; raiz (64,72). A margem adicional acomoda o par, sem aumentar a figura.
- Complemento com escala uniforme 56/120, sem redimensionar membros ou aumentar poses agachadas para ficarem tão altas quanto uma pose em pé.
- Fundo, textos e linhas-guia editoriais separados dos desenhos. Nearest-neighbor no preparo e no jogo.

## Uso das poses

| Faixa | Uso |
|---|---|
| Frenagem | Último apoio da corrida, compressão e retorno à postura |
| Soco pesado | Preparação, giro, extensão, avanço e guarda |
| Erro e tropeço | Perda de equilíbrio, passo para recuperar e guarda |
| Golpe para trás | Olhar/pivô antes da extensão no lado novo |
| Clinch | Aproximação, pega, sustentação e liberação |
| Joelhada | Apoio, recolhimento, contato, retração e pé no chão |
| Barriga | Curvatura no acerto; cede até ajoelhar quando esgotada |
| Cabeça | Recuo e sequência de queda |
| Guarda | Desgaste progressivo e braços baixados ao romper |
| Reação ao clinch | Posturas usadas na recuperação da queda |

As poses de aproximação já existentes são aproveitadas conforme o estado; nem todo quadro editorial precisa ser exibido em toda execução. No clinch, o par está no mesmo quadro para conservar o contato das mãos. O manequim independente é ocultado durante esse quadro e reaparece ao soltar. Seu estado, barras e dano continuam independentes.

Cabeça, pescoço e quadril do alvo têm marcadores no JSON. Hurtboxes acompanham esses pontos, inclusive no par. A joelhada aplica impacto apenas na fase de contato. O pesado errado inicia o tropeço antes de entrar na pose final de guarda, evitando guardar e depois voltar à extensão. No giro, a imagem começa no lado anterior enquanto o punho só fica ativo na direção final.

## Verificação

29 testes aprovados, incluindo combo com as hurtboxes desta arte nos dois sentidos, seleção dos quadros, giro e contato da joelhada. Onze verificações no Edge aprovadas: movimento, frenagem, sequência por regiões, erro, giro, bloqueio sem recuo, braços esgotados, clinch, tronco cedendo, pausa/debug e página estreita. Relatório: `browser-test-v41.json`.

O navegador carregou o atlas novo e os módulos de poses/alvo, sem carregar o rig antigo. Resolução 320×180, Canvas forçado, zero erros registrados e zero desenhos com suavização na auditoria. Capturas de frenagem, pesado, erro, giro, clinch, joelhada e alvo cedendo foram inspecionadas. Gravação: `combate-v41.webm`.

Amostra final durante automação/gravação: cerca de 35 FPS e 11 MB de heap JavaScript. Não é benchmark do ThinkPad T400; o hardware alvo permanece sem medição. Oscilações do navegador de teste não certificam desempenho na GM45.

## Limites concretos

São poses-chave desenhadas, com durações ajustadas. Diferenças pequenas entre fontes e transições ainda podem ser refinadas artisticamente. O contra-ataque do manequim ainda não tem uma faixa própria; ele continua sendo uma ação simples de treino. Na queda, o desenho segue a trajetória física do quadril, sem deformação separada de cada membro; os vínculos físicos permanecem visíveis no debug. A integração não altera os controles nem adiciona personagens da narrativa.
