import {MIGUEL_ASSET} from './assets.js';
import {lettering} from './art.js';

// Só as duas sequências entregues. Miguel não usa as animações de outros atores.
export function miguelFrame(clip, elapsed) {
  let time = Math.max(0, elapsed) % clip.totalMs;
  for (const frame of clip.frames) {
    if (time < frame.duration) return frame;
    time -= frame.duration;
  }
  return clip.frames[0];
}

export class MiguelView {
  constructor(scene, data, x = 150, y = 132) {
    this.clips = Object.fromEntries(data.clips.map(clip => [clip.id, clip]));
    this.pose = 'idle';
    this.elapsed = 0;
    this.shadow = scene.add.ellipse(x, y, 25, 4, 0x172723, .6).setDepth(y - 1);
    this.image = scene.add.image(x, y, 'miguel-sheet', 0)
      .setOrigin(MIGUEL_ASSET.originX, MIGUEL_ASSET.originY).setDepth(y + .4);
    const label = scene.textures.createCanvas('miguel-label', 28, 7);
    lettering(label.context, 'MIGUEL', 2, 1, '#d8d5b7');
    label.refresh();
    this.label = scene.add.image(x, y - 77, 'miguel-label').setDepth(y + .5);
    this.render(0);
  }

  setPose(pose) {
    if (!Object.hasOwn(this.clips, pose)) return;
    this.pose = pose;
    this.elapsed = 0;
    this.render(0);
  }

  render(delta) {
    this.elapsed += delta;
    const frame = miguelFrame(this.clips[this.pose], this.elapsed);
    // Olha para Sorriso, à esquerda; os dois últimos quadros já vêm nesse lado.
    this.image.setFrame(frame.index).setFlipX(frame.sourceFacing > 0);
  }

  snapshot() {
    return {pose: this.pose, frame: Number(this.image.frame.name), elapsed: this.elapsed,
      x: this.image.x, y: this.image.y, scale: this.image.scaleX, combat: false};
  }
}
