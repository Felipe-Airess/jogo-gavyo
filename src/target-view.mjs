import{enemyRef,pairRef}from'./pose-state.mjs';
import{SORRISO_ASSET}from'./assets.js';
export class TargetView{
 constructor(scene,clips){this.clips=clips;this.image=scene.add.image(0,0,'sorriso-sheet').setOrigin(SORRISO_ASSET.originX,SORRISO_ASSET.originY);}
 render(model,d,drawX=d.x){
  const p=model.player,pair=pairRef(p),hidden=pair&&(p.grabbed===d.id||p.releaseId===d.id);
  this.image.setVisible(!hidden);if(hidden)return;
  let ref=enemyRef(d),y=d.y;
  if(d.state==='fallen'){
   const age=d.ragdoll.age;ref={clip:'targetHead',frame:age<90?2:age<230?3:4};
   // Quadros de queda acompanham a trajetória física; não deformam o manequim.
   const hipAboveGround=ref.frame===4?4:23;y=Math.min(d.y,d.ragdoll.nodes[2].y+hipAboveGround);
  }else if(d.state==='recovering')ref={clip:'targetClinch',frame:Math.max(0,4-Math.floor(d.recovery/92))};
  this.image.setFrame(this.clips[ref.clip].frames[ref.frame].index).setPosition(Math.round(drawX),Math.round(y)).setFlipX(d.facing>0).setDepth(d.y+.4);
  if(d.dead)this.image.setTint(0xa39689);else this.image.clearTint();
 }
}
