// Buffer de comandos com uma única vaga.
// Um aperto fica disponível por `window` ms; um aperto novo substitui o antigo.
// Assim o jogador prepara a próxima ação, mas apertar várias vezes não monta
// uma fila de golpes que dispara sozinha depois.
export const BUFFER_MS = 134; // 8 ticks a 60 Hz

export class CommandBuffer {
  constructor(window = BUFFER_MS) {
    this.window = window;
    this.command = null;
  }

  push(command, now) {
    this.command = { ...command, at: now };
  }

  peek(now) {
    if (this.command && now - this.command.at > this.window) this.command = null;
    return this.command;
  }

  take(now) {
    const command = this.peek(now);
    this.command = null;
    return command;
  }

  clear() {
    this.command = null;
  }
}

// Converte direções absolutas em relativas ao olhar do lutador.
export function commandFrom(input, facing) {
  const dir = Number(!!input.right) - Number(!!input.left);
  const kind = input.grab ? 'grab' : input.kick ? 'kick' : input.attack ? 'attack' : null;
  if (!kind) return null;
  return {
    kind,
    forward: dir !== 0 && dir === facing,
    back: dir !== 0 && dir === -facing,
    up: !!input.up,
    down: !!input.down,
    run: !!input.run,
  };
}
