# Contexto transferido para o workspace

Data: 25/10/2026. Origem: solicitação atual do usuário e leitura da conversa ChatGPT “Criar jogo no ThinkPad”, ID `6ade0c3c-dc94-83e8-8ee4-2c9fb3e55060`.

## Escopo autorizado

GAVIÃO: beat 'em up 2D de humor absurdo e atmosfera sombria, pixel art sóbria e caricatural. Scott Pilgrim, LISA e Mother 3 são referências conceituais, sem copiar assets. Sorriso: jovem de cachos escuros, polo escolar branca com detalhes verdes/amarelos, jeans e tênis. Gelado é aliado; Bola é chefe final; Alice é objetivo narrativo. Não implementar os três agora.

Primeira entrega: somente Sorriso, estados idle/walk/run/attack/hurt, setas/WASD, Shift, J, facing, hitbox, boneco estático reativo, cenário escolar, debug e FPS. Phaser 3 em JavaScript, Canvas forçado, 320×180 e nearest-neighbor. Alvo: ThinkPad T400, GM45, P8600, 4 GB. Evitar dependências pesadas.

Direção visual: sem coroas, clichês de gangue, slogans motivacionais, neon ou pôsteres com aparência genérica de IA. Não tratar uma ficha ilustrada como spritesheet.

## Acesso efetivo

O workspace começou vazio, com apenas pastas de saída e de trabalho. Não havia código, imagens, fotos, sprites ou instruções de repositório. A ferramenta `read_thread`, disponibilizada durante a execução, foi chamada com o ID acima e limite de dez turnos. Retornou cinco turnos recentes, sem cursor para conteúdo anterior e sem anexos. Respostas do assistente apareciam como marcadores `chatgpt-content-reference`, não como texto ou imagens recuperáveis. Portanto não há cópia integral da conversa nem transferência das fotos. Não se inventou o conteúdo ausente.

Decisão: usar o briefing atual como fonte de verdade, criar placeholder consistente e registrar a pendência visual. Nenhuma semelhança com as fotos foi validada. Este registro permite continuar o trabalho com novos assets sem depender do cache da conversa.

## Referência fornecida depois da primeira entrega

O usuário rejeitou a semelhança do placeholder e anexou `34977.jpg` nesta conversa. A ficha agora está acessível e foi preservada em `docs/references/sorriso-aprovado.jpg`. Ela substitui a descrição genérica como fonte visual: cabelo cacheado volumoso e irregular, silhueta jovem e alongada, polo branca com gola/punhos verdes, faixas verdes e amarelas nos ombros, terço inferior verde com faixa amarela diagonal, emblema azul pequeno, jeans folgado e tênis claros. Sem coroas ou adereços do pôster na arte jogável.

A ficha é referência de identidade e poses. Não deve ser recortada e apresentada como spritesheet. A correção cria um atlas separado, confere alinhamento e integra os cinco estados. A aprovação final da semelhança permanece com o usuário.

Correção explícita do usuário durante a revisão: **Sorriso é branco, com pele clara**. Esta indicação prevalece sobre o tom quente da ficha ou qualquer interpretação anterior. Aplicar a mesma pele clara a rosto, orelhas, pescoço, braços e mãos em todos os estados; manter cachos escuros, roupa e identidade.

## Ampliação autorizada na versão 0.3

O usuário aceitou o estilo, rejeitou a rigidez das animações e pediu variedade de combo, knockback e, se viável, ragdoll. O alvo deixou de ser estático para permitir treino de deslocamento, lançamento e recuperação. A implementação usa J para jab/direto/gancho, K para chute e corrida + J para avanço. A animação reutiliza partes da arte para manter a identidade; o ragdoll 2D é aplicado ao alvo de treino. Os outros personagens continuam fora do escopo. Referência técnica e limites atuais: `COMBATE-V3.md`.

Na revisão seguinte, o usuário apontou excesso de moleza e falta de sustentação no protagonista. A 0.3.1 mantém a arte e o combate, com coluna rígida, poses de braço definidas, limites nos joelhos, pivôs corretos e contrabalanço de braços/pernas. O corpo solto continua restrito ao alvo lançado. Referência atual: `POSTURA-V031.md`.

## Fonte e autorização atuais — versão 0.4

O usuário forneceu a folha `34989.png`, rejeitou movimentos robotizados e pediu contato por região. A prévia separada foi construída com desenhos completos dessa folha; ela substitui o rig do protagonista na cena atual. A fonte está preservada em `references/sprites-enviados-34989.png`. Os registros anteriores descrevem o histórico, não a implementação atual.

Após perguntar pela viabilidade, o usuário autorizou com “Entao pode fazer”: inércia e frenagem, erro pesado com avanço e tropeço, combo dependente de contato e abertura, variações direcionais, clinch com joelhadas e resistência separada de cabeça/tronco/braços. A 0.4 integra esses sistemas no jogo principal com dois manequins, sem adicionar Gelado, Bola ou Alice.

O usuário quer peso e movimento humano. Não tomar os testes de lógica como aprovação artística. Frenagem, tropeço, reverso, clinch e joelhada ainda adaptam poses disponíveis; faltam desenhos específicos da pega no pescoço, apoio e recuperação. Estado atual e evidências: `COMBATE-V4.md`, `VERIFICACAO-V4.md` e `browser-test-v4.json`.

## Integração da folha complementar — 0.4.1

O usuário pediu uma folha estática para aprovação, sem prévia animada. Foi gerada uma folha com seis faixas de Sorriso e quatro de manequim, cinco poses cada. Depois autorizou: “vc acha que ta nas proporcoes corretas,se sim pode coloca-las”. As proporções gerais foram consideradas coerentes; o empacotamento igualou a escala à arte anterior e preservou o chão das faixas.

A folha está em `references/sorriso-complementar-aprovado-v1.png`. O atlas atual `sorriso-integrado.png/.json` conserva os 88 desenhos originais e acrescenta 50. As ações novas usam essas poses, em vez das antigas adaptações. Não se promete biomecânica perfeita ou animação final: são chaves com cadência ajustada. Clinch e joelhada são quadros pareados, e o ragdoll mantém a simulação de trajetória com desenho de queda em vez de esticar membros. Referência atual: `POSES-V041.md`.

## Correção de escala e ampliação dos combos — 0.4.2

O usuário apontou que as poses ainda tinham tamanhos diferentes e pediu padronização, animação diferente ao misturar soco/chute e clinch que abra a guarda e permita vários golpes. A comparação anterior apenas por altura não bastava. A nova calibração usa cabeça/tronco e mantém a postura: família original em 1,25, Sorriso complementar preservado, manequim separado em 1,2. Carregar `sorriso-padronizado.png/.json`, células 128×96, raiz (64,88).

J → K usa chute alto com transição e K → J retorno de soco. Uma única continuação pode ser preparada durante o primeiro gesto, sem idle intermediário. Clinch próximo abre guarda intacta com entrada curta e desgaste de braços; não exige mais abertura prévia. Removido o limite de três joelhadas: cada acerto renova a pega; parar permite escape; G solta e tronco esgotado encerra em queda. Desenhos existentes são reutilizados em receitas diferentes; não alegar poses inéditas ou uniformidade perfeita do traço entre as duas fontes. Referência: `COMBOS-V042.md`.

## Corrida, peso, pernas e finalização — 0.5

O usuário pediu trabalho imediato e pesquisa de fóruns/métodos: corrida incomodava, socos permitiam spam, faltava massa, queria sangue, chute em caído com morte, soco corrido levando ambos ao chão, chute de kickboxing, pernas com dano e aleatoriedade controlada.

A 0.5 acrescenta 72 recortes em seis faixas, incluindo corrida dedicada de doze poses; mantém os 138 anteriores. Atlas carregado: `sorriso-v5.png/.json`. Novas fontes/prompts preservados. Corrida usa relógio próprio de distância e apoios. Sequências comuns têm até três ações e recuperação obrigatória, com fôlego. Pernas têm barra própria e esgotamento derruba. Corrido conserva impulso e implica queda/levantada de Sorriso; bloqueio preserva o corpo do alvo. Chute baixo contextual usa cabeça desenhada de caído, marca `dead` e impede levantar até R. Sangue é leve, limitado e desligável com B. Perfis e resposta de treino usam variação reproduzível, não sorteio para falhar contato.

Pesquisa e limites: `MOVIMENTO-V5.md`. 46 testes de regras e onze verificações no navegador. Não confundir isso com aprovação artística: as novas folhas são quadros-chave gerados e ainda precisam de revisão manual de apoio/arcos/intermediários. Sem personagens nomeados novos, narrativa ou áudio; T400 sem medição física.
