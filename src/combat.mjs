import {Ragdoll,standingPose} from './ragdoll.mjs';
export const RULES=Object.freeze({width:640,minX:16,maxX:624,minY:122,maxY:164,walk:49,run:88,hurtMs:360,invulnerableMs:850,bufferMs:230,comboGraceMs:650});
export const MOVES=Object.freeze({
  jab:{name:'JAB',duration:205,activeStart:58,activeEnd:102,chainAt:140,reach:31,lunge:4,knock:55,stun:310,pause:16,lift:0,damage:1},
  cross:{name:'DIRETO',duration:255,activeStart:76,activeEnd:132,chainAt:176,reach:34,lunge:7,knock:72,stun:360,pause:22,lift:0,damage:2},
  hook:{name:'GANCHO',duration:355,activeStart:106,activeEnd:170,chainAt:305,reach:35,lunge:8,knock:115,stun:650,pause:30,lift:125,damage:3},
  kick:{name:'CHUTE',duration:405,activeStart:116,activeEnd:192,chainAt:350,reach:43,lunge:5,knock:165,stun:750,pause:36,lift:155,damage:4},
  dash:{name:'AVANCO',duration:295,activeStart:74,activeEnd:134,chainAt:206,reach:35,lunge:14,knock:90,stun:380,pause:22,lift:0,damage:2}
});
export function intersects(a,b){return a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;}
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
export class Training{
  constructor(){this.reset();}
  reset(){
    this.player={x:75,y:146,facing:1,state:'idle',hp:5,elapsed:0,locomotion:0,gaitPhase:0,invulnerable:0,attackHit:false,move:null,lightIndex:0,travel:0};
    this.dummy={x:242,y:146,hits:0,reaction:0,state:'idle',vx:0,stun:0,damage:0,ragdoll:null,recovery:0,recoveryFrom:null};
    this.hitstop=0;this.clock=0;this.attackId=0;this.lastHit=null;this.buffer=null;this.lastLightAt=-9999;this.combo={hits:0,best:0,ttl:0};
  }
  body(x=this.player.x,y=this.player.y){return{x:x-6,y:y-7,w:12,h:9};}
  dummyBody(){return{x:this.dummy.x-7,y:this.dummy.y-7,w:14,h:9};}
  attackBox(){const p=this.player,m=MOVES[p.move];if(p.state!=='attack'||!m||p.elapsed<m.activeStart||p.elapsed>=m.activeEnd)return null;return{x:p.facing>0?p.x+6:p.x-m.reach,y:p.y-9,w:m.reach-6,h:16};}
  dummyPose(){
    const d=this.dummy;if(d.state==='ragdoll')return d.ragdoll.nodes;
    const pose=standingPose(d.x,d.y,d.state==='hit'?Math.sign(d.vx)*Math.min(5,d.reaction/45):0);
    if(d.state==='recovering'&&d.recoveryFrom){const t=clamp(d.recovery/440,0,1),ease=t*t*(3-2*t);return pose.map((p,i)=>({x:d.recoveryFrom[i].x+(p.x-d.recoveryFrom[i].x)*ease,y:d.recoveryFrom[i].y+(p.y-d.recoveryFrom[i].y)*ease}));}return pose;
  }
  hurt(){const p=this.player;if(p.invulnerable>0||p.hp===0)return false;p.hp--;p.state='hurt';p.elapsed=0;p.invulnerable=RULES.invulnerableMs;this.buffer=null;return true;}
  movePlayer(dx,dy=0){
    const p=this.player,d=this.dummy,solid=d.state==='idle'||d.state==='hit',overlap=solid&&intersects(this.body(),this.dummyBody());
    const nx=clamp(p.x+dx,RULES.minX,RULES.maxX);if(!solid||!intersects(this.body(nx,p.y),this.dummyBody())||(overlap&&Math.abs(nx-d.x)>Math.abs(p.x-d.x)))p.x=nx;
    const ny=clamp(p.y+dy,RULES.minY,RULES.maxY);if(!solid||!intersects(this.body(p.x,ny),this.dummyBody())||(overlap&&Math.abs(ny-d.y)>Math.abs(p.y-d.y)))p.y=ny;
  }
  beginAttack(kind,input={}){
    const p=this.player;if(kind==='kick'){p.move='kick';p.lightIndex=0;this.lastLightAt=-9999;}
    else if(input.run&&(input.left||input.right)&&p.state!=='attack'){p.move='dash';p.lightIndex=0;this.lastLightAt=this.clock;}
    else{const chain=this.clock-this.lastLightAt<RULES.comboGraceMs;p.lightIndex=chain?(p.lightIndex+1)%3:0;p.move=['jab','cross','hook'][p.lightIndex];this.lastLightAt=this.clock;}
    p.state='attack';p.elapsed=0;p.attackHit=false;p.travel=0;this.attackId++;this.buffer=null;
  }
  hit(){
    const p=this.player,d=this.dummy,m=MOVES[p.move];p.attackHit=true;d.hits++;d.damage+=m.damage;d.reaction=230;d.stun=m.stun;
    this.combo.hits=this.combo.ttl>0?this.combo.hits+1:1;this.combo.best=Math.max(this.combo.best,this.combo.hits);this.combo.ttl=1050;
    if(d.state==='ragdoll')d.ragdoll.impulse(p.facing,m.knock*0.65,m.lift||70);
    else if(m.lift>0){d.ragdoll=new Ragdoll(d.x,d.y,p.facing,m.knock,m.lift);d.state='ragdoll';}
    else{d.vx=p.facing*m.knock;d.state='hit';}
    this.hitstop=m.pause;this.lastHit={id:this.attackId,move:p.move,combo:this.combo.hits,facing:p.facing,x:d.x,y:d.y};
  }
  updateDummy(dt){
    const d=this.dummy;d.reaction=Math.max(0,d.reaction-dt);d.stun=Math.max(0,d.stun-dt);
    if(d.state==='ragdoll'){d.ragdoll.step(dt);d.x=d.ragdoll.center.x;if(d.ragdoll.age>1750){d.recoveryFrom=d.ragdoll.nodes.map(n=>({x:n.x,y:n.y}));d.state='recovering';d.recovery=0;d.vx=0;}}
    else if(d.state==='recovering'){d.recovery+=dt;if(d.recovery>=440){d.state='idle';d.ragdoll=null;d.recoveryFrom=null;}}
    else{d.x=clamp(d.x+d.vx*dt/1000,RULES.minX+12,RULES.maxX-12);d.vx*=Math.exp(-8*dt/1000);if(d.stun===0)d.state='idle';}
  }
  canHitDummy(){
    const d=this.dummy,p=this.player,box=this.attackBox();if(!box||d.state==='recovering'||!intersects(box,this.dummyBody()))return false;
    if(d.state==='ragdoll'){const torso=d.ragdoll.nodes[1];return d.ragdoll.age<1100&&torso.y>p.y-67&&torso.y<p.y-14;}return true;
  }
  step(input,delta){
    const dt=clamp(delta,0,50),p=this.player;this.clock+=dt;
    if(input.attack||input.kick)this.buffer={kind:input.kick?'kick':'light',expires:this.clock+RULES.bufferMs};if(this.buffer&&this.buffer.expires<this.clock)this.buffer=null;
    if(this.hitstop>0){this.hitstop=Math.max(0,this.hitstop-dt);return;}
    this.updateDummy(dt);this.combo.ttl=Math.max(0,this.combo.ttl-dt);if(this.combo.ttl===0)this.combo.hits=0;
    p.invulnerable=Math.max(0,p.invulnerable-dt);p.elapsed+=dt;if(p.hp===0){this.buffer=null;return;}
    if(p.state==='hurt'){if(p.elapsed<RULES.hurtMs)return;p.state='idle';p.elapsed=0;}
    if(p.state==='attack'){
      const m=MOVES[p.move],travel=m.lunge*clamp(p.elapsed/m.activeEnd,0,1);this.movePlayer((travel-p.travel)*p.facing);p.travel=travel;
      if(!p.attackHit&&this.canHitDummy())this.hit();
      if(this.buffer&&p.elapsed>=m.chainAt&&p.attackHit){this.beginAttack(this.buffer.kind,input);return;}
      if(p.elapsed<m.duration)return;p.state='idle';p.elapsed=0;
    }
    const dx=Number(!!input.right)-Number(!!input.left),dy=Number(!!input.down)-Number(!!input.up);if(dx)p.facing=dx>0?1:-1;
    if(this.buffer){this.beginAttack(this.buffer.kind,input);return;}
    if(dx||dy){const length=Math.hypot(dx,dy),speed=input.run?RULES.run:RULES.walk,beforeX=p.x,beforeY=p.y;this.movePlayer(dx/length*speed*dt/1000,dy/length*speed*dt/1000);const distance=Math.hypot(p.x-beforeX,p.y-beforeY);p.locomotion+=distance;p.gaitPhase+=distance/(input.run?52:28)*Math.PI*2;p.state=input.run?'run':'walk';}else p.state='idle';
  }
}
