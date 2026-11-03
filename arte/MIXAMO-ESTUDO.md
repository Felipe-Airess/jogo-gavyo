# Estudo das animações do Mixamo (Miguel)

Medido por `arte/miguel_sprites.py` (tabela `MIXAMO`): desvio da pose em
relação ao 1º quadro, alcance de cada mão e pé e altura do corpo, quadro a quadro.

Regras aplicadas:
- **Golpes:** trecho guarda → pico do membro certo (mão esquerda no jab, direita no
  direto/gancho, pé nos chutes, joelho na joelhada) → guarda. Retemporizado para
  a MESMA duração e o MESMO instante de contato que o jogo já usava (alcance,
  hitbox e equilíbrio continuam valendo); contato segurado 2 quadros.
- **Loops** (parado, andar, correr, cansado): ciclo achado onde a pose final ≈ inicial.
- **Ações** (bloqueio, reações, queda, levantar, clinch): só o trecho útil, na
  duração antiga.
- **Combos:** todos os golpes do trecho, ~1,3× a duração antiga.

| Animação | Trecho útil | Uso |
|---|---|---|
| Ready_Idle | ciclo inteiro | guarda/parado |
| Pivot | 0–30% | entrar/baixar guarda |
| Look_Over_Shoulder | ciclo | cansado, grogue |
| Start_Walking | 10–45% início, 45–100% ciclo | andar |
| Running / Running_To_Turn | ciclo / 0–50% | correr, frear |
| Punching_1 | 15–85%, mão esq. | jab |
| Fist_Fight_A | 14–42% esq. / 33–56% dir. / 68–92% dir. | jab no corpo / direto / direto no corpo |
| Hell_Slammer_A | 5–45% / 45–85% | soco pesado / soco no chão |
| Hook_Punch / _1 | 10–85% dir. / esq. | gancho / cotovelada, aparo |
| Knee_Jabs_To_Uppercut | 55–88% / 10–90% (4 golpes) | uppercut / combo |
| Kicking | 25–90%, pé | chute circular, baixo, pisão |
| Armada | 5–100%, pé | chute com passo, chute alto |
| Flying_Kick | 0–60% / inteiro (2 golpes) | chute alto 2 / combo baixo-alto |
| Knee_Jab | 25–55% joelho / inteiro (3 golpes) | joelhada / combo; clinch |
| Blocking | 15–40% | bloqueio |
| Body_Block | 30–55% (tranco) | apanhar cabeça/corpo/perna, segurado |
| Dodging | 5–60% / 30–75% / 25–50% | esquiva / apanhar forte / guarda rompida |
| Esquiva_2 | inteiro / 0–30% | esquiva + contra / escapar do clinch |
| Sweep_Fall | 30–75% / 80–100% / 55–75% | queda / deitado / apanhar no chão |
| Getting_Up | 35–70% | levantar |
| Brutal_Assassination_1 / Brutal_Assassination | arremessar / ser arremessado |
| Dying | (não usado: termina de bruços) | — |
