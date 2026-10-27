// Passo fixo da simulação, separado da renderização.
// O navegador entrega quadros de 8, 16 ou 33 ms; a lógica sempre avança em
// ticks iguais. Toques rápidos (apertar e soltar dentro de um quadro, ou entre
// dois ticks) ficam guardados até o próximo tick, então nenhum comando some.
export const PULSES = ['attack', 'kick', 'grab'];

export class FixedStep {
  constructor(hz = 60, maxSteps = 6) {
    this.dt = 1000 / hz;
    this.maxSteps = maxSteps;
    this.reset();
  }

  reset() {
    this.accumulator = 0;
    this.latched = {};
    this.alpha = 0;
    this.ticks = 0;
  }

  // `input` é o estado deste quadro. Botões contínuos valem como estão;
  // pulsos são acumulados até um tick consumi-los.
  advance(frameMs, input, tick) {
    for (const key of PULSES) if (input[key]) this.latched[key] = true;
    // Abaixo de ~10 FPS o jogo desacelera em vez de executar uma rajada
    // de ticks atrasados (evita a "espiral" em hardware lento).
    this.accumulator += Math.min(Math.max(0, frameMs), this.dt * this.maxSteps);
    let steps = 0;
    while (this.accumulator >= this.dt - 1e-6) {
      const sample = { ...input };
      for (const key of PULSES) sample[key] = !!this.latched[key];
      this.latched = {};
      tick(sample, this.dt);
      this.accumulator -= this.dt;
      steps++;
      this.ticks++;
    }
    this.alpha = Math.max(0, Math.min(1, this.accumulator / this.dt));
    return steps;
  }
}

export const lerp = (a, b, t) => a + (b - a) * t;
