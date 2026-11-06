# Duração do capítulo 1 — medição de 06/11/2026 (Claude)

Meta de Felipe: **20 a 30 minutos**.

## O que foi medido (robô do teste de percurso, física real)

| Modo | Tempo | Observação |
|---|---:|---|
| Rota (só o obrigatório, sem esperar ninguém) | 237 s ≈ **4 min** | cutscenes incluídas |
| Pátio (agachado no pátio de química) | 243 s ≈ **4 min** | |

O robô anda em linha reta, nunca espera patrulha, não lê nada e não visita nada opcional.

## Estimativa para uma pessoa jogando pela primeira vez

| Parte | Tempo |
|---|---:|
| Deslocamento obrigatório com cuidado (agachado, esperando patrulhas; ~2,5× o robô) | 6–7 min |
| Cutscenes (abertura 36 s, cozinha ~25 s, perseguidor 6 s, descoberta 7 s, final 19 s) | 1,5 min |
| Biblioteca "O leitor" (opcional: pista da ave 1 e nota 3) | 2–4 min |
| Laboratório "Trancado por dentro" (opcional: pista da ave 2) | 2–3 min |
| Notas 1, 2 e 4, item de finalizar, caixa da ave, ventilações | 3–5 min |
| Leitura das notas e pistas | 1–2 min |
| Mortes e retomadas (cozinha, laboratório, fuga) | 2–4 min |
| **Total explorando** | **≈ 18–27 min** |
| **Só o obrigatório, com cuidado** | **≈ 10–13 min** |

## Leitura

- Quem explora fica dentro da meta. Quem vai direto termina em ~10–13 min.
- Para garantir os 20 min para todo mundo, a saída mais simples é tornar
  **obrigatório** um dos encontros opcionais. Por exemplo, a pista da ave da
  biblioteca e a do laboratório passam a abrir o caminho do ritual (o Miguel
  precisa entender o que está gravando). Isso soma ~5–7 min a todos.
- **Decisão de Felipe (06/11): deixar opcional.** Quem explora fica na meta; quem corre termina antes.

## Testes

- `scripts/testar-percurso.sh` (rota): 9/9, sem mortes.
- `--patio`: 10/10 depois de o robô parar de agachar durante a fuga.
- `--furtivo`: o robô anda em pé até a porta da cozinha, ao lado do posto 6, e é
  percebido e morto (a IA nova funcionando). É um modo só de observação; o
  robô precisa aprender a se esgueirar.
