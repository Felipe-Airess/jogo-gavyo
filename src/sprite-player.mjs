import{MOVES,frameAt}from'./battle.mjs';
import{gaitFrame}from'./locomotion.mjs';
export function spriteRef(p,moves=MOVES,clips=null){
 const timed=(clip,frames,times,time=p.elapsed)=>({clip,frame:frames[frameAt(time,{frames:frames.map((_,i)=>i),times})]});
 if(clips?.r1_idle){
  if(['idle','winded','guard','attackRecover'].includes(p.state)){const c=clips.r1_idle;return timed('r1_idle',c.frames.map((_,i)=>i),c.durations,p.elapsed%c.totalMs);}
  if(p.state==='walk')return{clip:'r2_walk',frame:gaitFrame(p,clips)};
  if(p.state==='run'){if(p.runStart<280)return timed('r2_runStart',[0,1,2,3,4,5,6,7],[40,35,35,35,35,35,35,30],p.runStart);return{clip:'r2_run',frame:gaitFrame(p,clips)};}
  if(p.state==='brake')return timed('r2_runStop',[0,1,2,3,4,5,6,7],[35,40,50,45,40,40,45,1000]);
 }
 if(p.state==='clinchEntry')return{clip:'clinchPunch',frame:0};
 if(p.state==='clinch')return{clip:p.clinchWalking?'clinchWalk':'clinchPunch',frame:p.clinchWalking?Math.floor(p.clinchDistance/3)%8:0};
 if(p.state==='attack'||p.state==='knee'){const m=moves[p.move],f=frameAt(p.elapsed,m);if(m.sequence){const[clip,frame]=m.sequence[f];return{clip,frame};}return{clip:m.clip,frame:f};}
 if(p.state==='parry')return timed(p.parryArm==='right'?'counterLeft':'parryCounter',[0,1,2],[30,35,1000]);
 if(p.state==='wipe')return timed('wipeHands',[0,1,2,3,4,5,6,7],[100,100,130,130,130,160,140,1000]);
 if(p.state==='run'){if(p.runStart<130)return timed('runTransitions',[0,1,2,3],[25,35,35,1000],p.runStart);return{clip:'runV6',frame:gaitFrame(p)};}
 if(p.state==='walk')return{clip:'walk',frame:gaitFrame(p)};
 if(p.state==='rushFall')return timed('rushFluid',[6,7,8,9,10],[90,100,150,220,10000]);
 if(p.state==='gettingUp')return timed('rushFluid',[10,11],[180,10000]);
 if(p.state==='attackRecover'){const m=moves[p.recoverFrom||p.move];if(m&&!m.sequence)return{clip:m.clip,frame:p.elapsed<80?m.frames.at(-1):m.frames[0]};return{clip:'boxingFluid',frame:p.elapsed<80?11:0};}
 if(p.state==='winded')return timed('idle',[0,1,2,1],[150,150,150,10000]);
 if(p.state==='brake')return timed('runTransitions',[4,5,6,7],[65,85,85,10000]);
 if(p.state==='guard')return{clip:p.parryUntil>0&&p.elapsed<115?'parryCounter':'block',frame:0};
 if(p.state==='stumble')return p.whiffMove==='drive'?timed('missMotion',[0,1,2,3,4],[45,65,80,75,10000]):timed('hurt',[0,2,3],[100,120,10000]);
 if(p.state==='hurt')return timed('hurt',[0,1,2,3],[70,80,100,10000]);
 if(p.state==='recover')return{clip:'clinchPunch',frame:p.elapsed<100?7:0};
 return timed('idle',[0,1,2,3,4,5,4,3,2,1],Array(10).fill(180),p.elapsed%1800);
}
export function spriteMeta(p,clips,moves=MOVES){const ref=spriteRef(p,moves,clips);return clips[ref.clip]?.frames[ref.frame]||clips.idle.frames[0];}
export function spriteFrame(p,clips,moves=MOVES){return spriteMeta(p,clips,moves).index;}
export function spriteFlip(p){return p.state==='attack'&&p.move==='reverse'?p.facing>0:p.facing<0;}
