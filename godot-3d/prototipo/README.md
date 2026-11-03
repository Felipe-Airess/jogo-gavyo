# Depois do almoço — protótipo, revisão 2

> **01/11 — início da reformulação:** câmera sobre ombro também na exploração
> livre; bancada separada em `VALIDAR-INICIO.command` para escala, câmera e prévia
> dos clipes existentes. Ver [etapa inicial](../../docs/ETAPA-INICIAL-VALIDACAO.md).
> O restante deste README descreve a revisão 2; mapa, roteiro e animações novos
> ainda não foram integrados ao capítulo.

Direção confirmada por Felipe após jogar a primeira versão: terceira pessoa na
exploração/combate, primeira pessoa na perseguição e nas frestas, imagem mais
limpa e uma troca simples antes de reconstruir sequências.

## Abrir

```bash
bash JOGAR-PROTOTIPO.command
```

Na raiz do projeto. Usa o Godot 4.5.1 portátil em `work/ferramentas/godot/` ou o
executável indicado em `GODOT`. Logs em `work/prototipo-abertura.log` e
`work/prototipo-jogo.log`. Enter inicia; C tenta carregar o checkpoint desta
revisão. O treino/galeria anteriores continuam em `res://main.tscn`.

## Esta revisão

- Abertura de 8 segundos: Miguel na bancada, celular às 21:43 sem sinal, vozes
  e enquadramento da porta. Espaço pula a cena. A exploração vem em seguida.
- Portas com folha, maçaneta e colisão articulada; Espaço abre/fecha e F permite
  olhar pela fresta fechada. Armários continuam como esconderijos.
- Revelação breve do perseguidor; depois a câmera passa aos olhos de Miguel.
  O mouse continua livre. Ao alcançar o portão, o capítulo termina.
- Perfil leve padrão: renderização fixa em 960×540, sem MSAA nem sombras
  dinâmicas, limite de 60 FPS e filtragem com mipmaps. Sem a ampliação pixelada de 426×240 da primeira versão.
- Escola com teto legível, janelas gradeadas, portas, cadeiras, bancada, placas
  físicas, luzes do corredor, velas e rua visível além da saída. A planta continua
  fictícia, inspirada na relação entre materiais/pátio/refeitório descrita por Felipe.

## Combate do teste

**Uma troca:** inimigo prepara o golpe → jogador esquiva → inimigo recupera →
clique esquerdo contra-ataca. Não há sequência de combos nem Q para derrubar nesta
revisão; esses movimentos dependem da aprovação desta base.

O cultista patrulha e reage à visão e aos passos próximos. Correr faz mais
barulho, agachar permite aproximação silenciosa. Há no máximo um atacante ativo.
O aviso amarelo acompanha a preparação; o losango azul marca a recuperação.

O gancho é um clipe completo, com punho direito e janela ativa medidos na
animação. **Não há SkeletonIK3D nem mão puxada até o alvo.** O contato exige
volume/varredura do punho real com a hurtbox e visão desobstruída. A recuperação
não continua produzindo dano. Um contra-ataque conectado derruba o cultista comum.
A aproximação furtiva pelas costas ainda pode encerrar o inimigo.

Clique direito sozinho executa uma esquiva curta; com WASD, faz deslocamento.
Na curta, corpo e cápsula saem da trajetória e retornam. Não há invulnerabilidade
artificial para esconder um soco que continuou tocando o corpo.

## Teclado e mouse

| Comando | Ação |
|---|---|
| WASD / mouse | Mover / olhar |
| Shift / Ctrl | Correr / agachar |
| Espaço | Porta, item, armário, parkour contextual; pular cena |
| F | Espiar/voltar da fresta de uma porta fechada |
| Clique direito | Esquiva curta; com direção, deslocamento |
| Clique esquerdo | Contra-atacar durante abertura / ataque furtivo |
| Botão do meio / rodinha | Travar/destravar / trocar alvo |
| E | Comer empanado |
| Esc / R na pausa ou morte | Pausar / retomar checkpoint |

A faca é exclusiva para escapar uma vez do agarrão do perseguidor e fica presa
nele. Sem faca, a captura mata. Empanado demora 2,4 s e cura 40 pontos; movimento
ou dano cancelam sem consumir. Quantidades são valores iniciais para teste.

## Animações e reprodução

O GLB aprovado e a galeria não são alterados. `motions.tres` é uma biblioteca
exclusiva do protótipo. Caminhada usa um ciclo medido de `Start_Walking`;
respiração, corrida, esquiva curta e pose sentada são poses/ciclos próprios do
protótipo. A corrida usa alvos dos pés para manter a altura do corpo estável e
ciclos fechados. Não são apresentados como novas capturas Mixamo.

O gerador também mede o gancho e grava `motions.json` e `motion_profile.gd`:

```bash
work/ferramentas/godot/Godot.app/Contents/MacOS/Godot --headless --path godot-3d --script res://tools/preparar_movimentos_prototipo.gd
bash scripts/testar-prototipo.sh
```

A suíte verifica a abertura, portas/câmeras, fechamento dos ciclos, estabilidade
da corrida, mão correta, iniciativa do inimigo, dano se o jogador fica parado,
esquiva física, contato do contra-ataque, morte, percepção, cura, checkpoints,
revelação e perseguição em primeira pessoa. O prazo máximo impede teste travado;
saída não zero e erros de script falham a validação.

## Teste visual local

```bash
bash TESTAR-PROTOTIPO.command
```

Fechar a execução normal antes. A ponte `--qa-inspect` salva apenas o jogo em
`work/prototipo-qa/frame.png` e estado em `state.json`. O render de QA inclui uma
cópia da interface. Não captura o desktop nem controla outros aplicativos.
Checkpoints de QA ficam separados do save normal. O arquivo `work/prototipo-qa/sem-captura` suspende as imagens durante o ajuste
de desempenho; estados e comandos continuam disponíveis. O render adicional só é pedido
para a captura; FPS desse modo não é benchmark da experiência final.

O coletor `python3 scripts/registrar-qa.py nome-do-teste 12` guarda, por 12 s,
somente as imagens/estados que a ponte já publicou. Não acessa a tela do sistema.

## Limites

Cenário, cultistas e animações procedurais continuam provisórios. Esta revisão
prioriza a troca de golpes, apresentação e legibilidade; não representa aprovação
estética nem animações finais. Gore e parkour precisam de acabamento. Áudio é
sintético e provisório, sem avaliação auditiva pela ponte de imagens.

Save normal desta revisão: `user://terror_checkpoint_v2.json`; o save v1 é
preservado. Fonte Work Sans sob SIL OFL, em `FONT-LICENSE.txt`.

## Desempenho

Jogar pelo lançador normal para evitar a captura de QA. O perfil leve é padrão;
`-- --qualidade` restaura MSAA/sombras e render na resolução da janela para uma
comparação controlada, quando necessária. O modo leve conserva 960×540, sem
retornar à pixelização de 426×240.

A cada dois segundos, `performance_monitor.gd` registra FPS médio por delta,
percentil 95 e máximo de tempo de quadro, custo de processo/física e draw calls.
Não captura a GPU nem salva imagens. Dados em `work/prototipo-desempenho.json`;
a última amostra de exploração/fuga sem pausa fica em
`work/prototipo-desempenho-ativo.json`. Números de uma janela pausada não devem
ser apresentados como desempenho durante a luta.
