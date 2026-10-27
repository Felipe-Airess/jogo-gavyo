// Partida: rounds, tempo, melhor de N e anúncios. Não conhece o desenho; a
// cena pergunta `inputsOpen` (se os comandos valem) e `banner` (o que anunciar).
//
// Fases de cada round:
//   intro    — "ROUND N" e depois "LUTA!"; lutadores parados, comandos fechados
//   fight    — luta valendo; relógio corre
//   roundEnd — anúncio do resultado; a queda termina, comandos fechados
// e, no fim, `over` quando alguém chega às vitórias necessárias.
export const MATCH = { introMs: 1700, fightCallMs: 600, roundEndMs: 2600, drawLimit: 9 };
export const TIME_OPTIONS = [60, 99, 0]; // 0 = sem tempo
export const ROUND_OPTIONS = [1, 3, 5];  // melhor de N

// Castigo total: menos castigo vence no tempo. Equilíbrio e fôlego desempatam
// só como fração, para o critério continuar sendo "quem apanhou menos".
export function damageTaken(f) {
  return f.condition.head + f.condition.body + f.condition.legs + (100 - f.balance) * 0.05 + (100 - f.stamina) * 0.02;
}

export class Match {
  constructor({ bestOf = 3, seconds = 60 } = {}) {
    this.bestOf = bestOf;
    this.seconds = seconds;
    this.reset();
  }

  get toWin() { return Math.ceil(this.bestOf / 2); }

  reset() {
    this.round = 1;
    this.wins = [0, 0];
    this.history = [];
    this.over = false;
    this.winner = null;
    this.startRound();
  }

  startRound() {
    this.phase = 'intro';
    this.phaseT = 0;
    this.timeLeft = this.seconds * 1000;
    this.outcome = null;
  }

  get inputsOpen() { return this.phase === 'fight'; }
  get clockSeconds() { return this.seconds ? Math.max(0, Math.ceil(this.timeLeft / 1000)) : null; }

  // Texto grande do momento (ou null).
  get banner() {
    if (this.phase === 'intro') {
      const last = this.bestOf > 1 && this.wins[0] === this.toWin - 1 && this.wins[1] === this.toWin - 1;
      return this.phaseT < MATCH.introMs - MATCH.fightCallMs
        ? { title: last ? 'ROUND FINAL' : 'ROUND ' + this.round, sub: this.bestOf > 1 ? 'MELHOR DE ' + this.bestOf : '' }
        : { title: 'LUTA!', sub: '' };
    }
    if (this.phase === 'roundEnd' && this.outcome) {
      const o = this.outcome;
      const title = o.by === 'ko' ? 'K.O.' : o.by === 'time' ? 'TEMPO!' : 'EMPATE';
      return { title, sub: o.winner ? (o.winner === 1 ? 'PONTO SEU' : 'PONTO DO RIVAL') : 'NINGUEM PONTUA' };
    }
    return null;
  }

  // `duel.result` vem do nocaute; o tempo decide pelo castigo recebido.
  update(dt, duel) {
    if (this.phase === 'done') return null;
    this.phaseT += dt;
    if (this.phase === 'intro') {
      if (this.phaseT >= MATCH.introMs) { this.phase = 'fight'; this.phaseT = 0; return 'fight'; }
      return null;
    }
    if (this.phase === 'fight') {
      if (duel.result) return this.endRound({ by: 'ko', winner: duel.result.winner, reason: duel.result.reason });
      if (this.seconds) {
        this.timeLeft -= dt;
        if (this.timeLeft <= 0) {
          const [a, b] = duel.fighters, da = damageTaken(a), db = damageTaken(b);
          const winner = Math.abs(da - db) < 0.5 ? null : da < db ? a.id : b.id;
          return this.endRound({ by: winner ? 'time' : 'draw', winner, reason: winner ? 'Tempo: venceu quem apanhou menos.' : 'Tempo: castigo igual.' });
        }
      }
      return null;
    }
    if (this.phase === 'roundEnd' && this.phaseT >= MATCH.roundEndMs) {
      if (this.over) { this.phase = 'done'; return 'over'; }
      this.round++;
      this.startRound();
      return 'nextRound';
    }
    return null;
  }

  endRound(outcome) {
    this.outcome = outcome;
    this.history.push(outcome);
    if (outcome.winner) this.wins[outcome.winner - 1]++;
    this.phase = 'roundEnd';
    this.phaseT = 0;
    const leader = this.wins.findIndex(w => w >= this.toWin);
    // Empates em sequência não prendem a partida: depois do limite, quem tem
    // mais vitórias leva; ainda igual, segue até alguém pontuar.
    if (leader >= 0) { this.over = true; this.winner = leader + 1; }
    else if (this.history.length >= MATCH.drawLimit && this.wins[0] !== this.wins[1]) { this.over = true; this.winner = this.wins[0] > this.wins[1] ? 1 : 2; }
    return 'roundEnd';
  }

  // Depois do anúncio final a cena mostra o resultado da partida.
  get finished() { return this.phase === 'done'; }
}
