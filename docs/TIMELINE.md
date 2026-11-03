# Timeline — Gavião, capítulo 1 jogável

Definida com Felipe em 02/11/2026. Qualquer IA (Claude ou Codex) segue esta ordem,
**uma etapa por vez**. Ao fim de cada etapa: Felipe testa, e só então a próxima
começa. Ao pegar o trabalho, leia também `docs/TESTE-FELIPE-20261102.md` e
`docs/PASSAGEM-PARA-CLAUDE.md`. Marque o checklist ao concluir.

## Visão do capítulo (decisões de Felipe)

- **Meta:** capítulo 1 jogável do começo ao fim, de **20 a 30 minutos**, no **PC
  e no celular**. Sem prazo; Felipe tem bastante tempo por semana.
- **Medo:** perseguição, atmosfera, sustos e perturbação, os quatro.
- **Defesa:**
  - o **empurrão sai**;
  - sem item, o cultista **agarra** e começa um **minigame de escape em
    sequência** (botões/direções); falhar leva à morte;
  - há **um item escondido de uso único** que **finaliza** um cultista comum.
- **Perseguidor:** **nunca** pode ser finalizado; só fugir e se esconder.
  Aparece **só se o alerta se espalhar** (como hoje).
- **Quantidade:** 6 a 8 cultistas comuns e 1 perseguidor.
- **Morte:** cena **cruel e pesada** e depois o checkpoint.
- **Salvar:** checkpoints fixos e automáticos.
- **Objetivos:**
  - pegar a bolsa, gravar o ritual e fugir;
  - **notas do culto**;
  - **chave/acesso**, sem trancas arbitrárias, com propósito na história;
  - **item de finalizar**;
  - **pistas da ave**.
  O conteúdo (textos das notas, significado da ave) **Felipe escreve**. A IA só
  coloca no jogo e usa texto provisório marcado `[PROVISÓRIO]` até lá.
- **Visual dos inimigos:**
  - **cultistas comuns:** altos, "animais fingindo ser humanos", olhos fundos e
    escuros com pupila pequena; uns encapuzados, outros de cabelo comprido;
  - **perseguidores:** não escondem o rosto; pálidos, muito altos, cabelo
    longo, sorriso grande.
- **Cutscenes:** cinematográficas, com cortes de câmera e clima de filme. Falas
  de Miguel vêm de Felipe.
- **Trilha:** Felipe está criando e manda os arquivos.
- **Amigos (Bola, Felipe):** só no final.
- **Proibido:** combate de luta (socos/combos), armas de fogo, gameplay do
  capítulo 2.
- **Trabalho:** Claude e Codex se revezam. Quem pega lê este arquivo e a
  passagem, e atualiza ao sair.

## Etapas

### Etapa 0 — Preparar
- [ ] Voltar ao Miguel original (`cp arte/miguel_animado.glb godot-3d/miguel_animado.glb`).
- [ ] Luz de contorno no Miguel, para ele aparecer no escuro.
- **Teste de Felipe:** o Miguel aparece bem?

### Etapa 1 — Medo

**Etapa jogável entregue para o teste de Felipe (02/11/2026).** Pressão e sete
patrulheiros na grade implementados. Morte e trilha definitivas continuam nas
pendências abaixo; os substitutos provisórios foram autorizados nas Partes 1/4.
- [x] Remover o empurrão.
- [x] Cultista vê → pausa 0,4 s → grita → corre a 3,0 m/s → cerca → agarra.
  Sem visão: último ponto visto, busca por 60 s, retorno lento ao posto.
- [x] Minigame de escape em sequência; falhar é morte. Implementado em 02/11/2026:
  WASD/setas e quatro botões de toque; morte temporária com tela preta de 1,5 s
  e retorno automático ao checkpoint. Cena de morte abaixo continua pendente.
- [ ] Cena de morte cruel e pesada, depois checkpoint.
- [x] Perseguição com pressão: passos novos por proximidade, respiração acelerada,
  tremor óptico leve e som de tensão [PROVISÓRIO]. Trilha final virá de Felipe.
- [x] Armários contra quem caça: só abre e retira Miguel quem viu a entrada.
  Memória individual por cultista; sem testemunha, ronda sem abrir.
- [x] Sete patrulheiros comuns nos postos 1–7 e perseguidor condicional no posto 8.
  Todos com caminho de até 10 m até armário; duas rotas continuam livres.
- **Teste de Felipe:** fugir dá desespero?

### Etapa 2 — Movimento
- [ ] Andar, correr e agachar sem travar: transições suaves, passo casado com
  a velocidade.
- [ ] Integrar o que falta do Mixamo (Felipe baixa): agachar, espiar, agarrar,
  ser agarrado, se soltar, procurar.
- **Teste de Felipe:** mover é gostoso?

### Etapa 3 — Enxergar
- [ ] Clarear a cena mantendo o filtro retrô.
- [ ] Resolução do filtro um pouco maior.
- [ ] Luzes guiando o caminho.
- **Teste de Felipe:** dá para jogar sem forçar a vista?

### Etapa 4 — Mapa e objetivos
- Revisão preparada em [REVISAO-MAPA.md](REVISAO-MAPA.md): plantas renderizadas,
  rota proposta e F9 de passeio em debug. Aguardando resposta de Felipe no próprio arquivo.
- [ ] Felipe aprova ou corrige a grade (`godot-3d/capitulo1/mapa/terreo.txt`).
- [ ] Colocar notas, chave/acesso, item de finalizar e pistas da ave (texto
  de Felipe; até lá `[PROVISÓRIO]`).
- [ ] Ajustar a duração para 20 a 30 minutos.
- [ ] Decorar com as fotos (`docs/referencias/escola-fotos/`).
- **Teste de Felipe:** o caminho e os objetivos fazem sentido?

### Etapa 5 — Inimigos novos (visual)
- [ ] Cultistas comuns conforme a descrição acima.
- [ ] Perseguidor conforme a descrição acima.
- **Teste de Felipe:** dão medo?

### Etapa 6 — Cutscenes cinematográficas
- [ ] Abertura, primeiro cultista, perseguidor descobrindo o Miguel, final.
- [ ] Falas de Miguel enviadas por Felipe.
- **Teste de Felipe:** parecem filme?

### Etapa 7 — Trilha e som

SFX da Parte 3 integrados em 02/11/2026; tabela em `SONS-FELIPE-PARTE3.md`.
Trilha, respiração humana e canto definitivo não vieram nesse pacote.
- [ ] Integrar a trilha de Felipe.
- [ ] Mixagem de ambiente, sustos e tensão.

### Etapa 8 — Miguel
- [ ] Melhorar o modelo original sem mudar o corpo (o v2 foi reprovado por
  deformar o peito).

### Etapa 9 — Publicar
- [ ] Build web por PR para a `main` (pasta `capitulo1/`), testada no PC e no
  celular.
