# Teste de Felipe — 02/11/2026 (build com animações do Codex + mapa cinza)

## O que Felipe relatou (prioridade nesta ordem)

1. **Locomoção travada:** correr, agachar e andar parecem travados. Algumas
   animações funcionam, outras não. Conferir a máquina de estados em
   `capitulo1/animacoes/controlador.gd`: transições, `speed_scale` casado com
   a velocidade e clipes travados no primeiro quadro.
2. **Hitbox do empurrão:** ele empurra o ar e o cultista cai. O cultista cai
   só para baixo, sem ir para trás. O contato precisa exigir a mão no tronco,
   e a reação precisa de impulso para trás (Hit_Knockback / Sweep_Fall com
   deslocamento real).
3. **Cultistas sem ameaça:** não correm e não tentam matar o jogador. O jogo
   não passa desespero. A caça precisa correr (`cultista_correr`) e agarrar
   de verdade; a perseguição precisa pressionar.
4. **Design do cultista ruim:** o visual precisa ser refeito (roupa/capuz,
   silhueta ameaçadora).
5. **Cutscenes ruins:** a abertura, o avistamento, a descoberta e o final
   precisam de direção de câmera e ritmo.
6. **Filtro retrô:** ficou bom, melhor que o jogo polido, mas fica **difícil
   de enxergar**. Clarear ambiente e névoa, subir a resolução baixa (ex.: 240
   linhas) e dar contraste nos pontos de interesse.
7. **Miguel escuro demais:** dar uma luz de recorte no jogador (rim light) ou
   material menos escuro. O Miguel v2 (branch `feat/modelo-miguel`) também
   está pendente de aprovação.

## O que o Codex não terminou

- O teste da base preservada, "punho não dá saltos artificiais", ainda falha
  (34 cm por quadro; o limite é 30 cm), pelas transições da nova máquina de
  estados.
- `Stunned` termina no chão e `Descending_Stairs` não fecha o ciclo: não usar
  em loop sem cortar ou adaptar.
- Ainda faltam do Mixamo: agachar, espiar, agarrar, ser agarrado, se soltar,
  procurar e facada.
- O atalho `builds/macos-teste/JOGAR.command` não abre o jogo no Mac. Usar
  `bash JOGAR-PROTOTIPO.command` ou `Godot --path godot-3d`.

## Estado dos testes (Claude, nuvem)

| Suíte | Resultado |
|---|---|
| Capítulo | 47/47 |
| Mapa | 18/18 |
| Nível | 10/10 |
| Toque | 10/10 |
| Percurso | 7/7 |
| Base preservada | 38/39 |

Os testes passam, mas o teste de Felipe mostra que a sensação está ruim. Tratar
os itens acima como prioridade sobre os números.
