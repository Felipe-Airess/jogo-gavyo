// Buffer de comandos com uma única vaga.
// Um aperto fica disponível por `window` ms; um aperto novo substitui o antigo.
// Assim o jogador prepara a próxima ação, mas apertar várias vezes não monta
// uma fila de golpes que dispara sozinha depois.
export const BUFFER_MS = 134; // 8 ticks a 60 Hz
// Durante um golpe o aperto espera mais: sai na primeira brecha (contato ou
// fim da recuperação) sem o jogador acertar o tempo exato.
export const CHAIN_BUFFER_MS = 400;

export class CommandBuffer {
  constructor(window = BUFFER_MS) {
    this.window = window;
    this.command = null;
  }

  push(command, now) {
    this.command = { ...command, at: now };
  }

  // `window` opcional: janela maior só para quem consulta durante um golpe.
  peek(now, window = this.window) {
    if (this.command && now - this.command.at > window) {
      if (window >= this.window) this.command = null;
      return null;
    }
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
