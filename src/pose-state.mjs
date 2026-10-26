// Escolhas compartilhadas entre desenho, pontos de contato e debug.
export const KNEE_TIMES=[70,65,50,70,70];
export function timedFrame(time,times){let t=Math.max(0,time);for(let i=0;i<times.length;i++){if(t<times[i])return i;t-=times[i];}return times.length-1;}
export function pairRef(p){
 // Atores separados para permitir variações e movimento durante a pega.
 return null;
}
export function enemyRef(d){
 if(d.state==='clinch')return d.clinchMove==='clinchFinish'?{clip:'targetBody',frame:Math.min(4,Math.floor((d.clinchProgress||0)/50))}:{clip:'targetClinch',frame:2};
 if(d.state==='carried')return{clip:d.zone==='head'?'targetHead':'targetBody',frame:1};
 if(d.state==='parried')return{clip:'targetGuard',frame:4};
 if(d.state==='enemyWindup')return{clip:'targetGuard',frame:d.attackArm==='left'?1:0};
 if(d.state==='legDown')return{clip:'targetClinch',frame:4};
 if(d.state==='legStagger')return{clip:'targetClinch',frame:1};
 if(d.state==='bodyDown')return{clip:'targetBody',frame:Math.min(4,2+Math.floor((d.bodyDownAge||0)/120))};
 if(d.guard)return{clip:'targetGuard',frame:Math.min(3,Math.floor((60-d.parts.arms)/12))};
 if(d.state==='guardBreak')return{clip:'targetGuard',frame:4};
 if(d.state==='headStagger')return{clip:'targetHead',frame:d.reaction>145?1:2};
 if(d.state==='bodyStagger')return{clip:'targetBody',frame:d.reaction>190?1:2};
 if(d.parts.arms===0)return{clip:'targetGuard',frame:4};
 return{clip:'targetBody',frame:0};
}
