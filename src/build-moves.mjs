import{MOVES}from'./battle.mjs';
// Profiles keep the historical simulator fixtures intact while the playable build uses the reviewed art.
export const BUILD_VERSION='0.8.0';
export function createBuildMoves(clips){
 const moves=Object.fromEntries(Object.entries(MOVES).map(([id,m])=>[id,{...m,frames:[...m.frames],times:[...m.times],active:[...m.active],sequence:m.sequence?.map(p=>[...p])}]));
 moves.jabHead={...moves.jab,name:'JAB NA CABECA'};moves.crossBody={...moves.cross,name:'DIRETO NO TRONCO'};moves.highKick={...moves.kick,name:'CIRCULAR ALTO'};
 const map={jab:['jab_body',0,1.6],jabHead:['jab_head',0,1.6],cross:['cross_head',0,1.65],crossBody:['cross_body',0,1.65],low:['hook_body',0,1.7],drive:['overhand_heavy',0,1.65],reverse:['reverse_strike',0,1.65],rush:['running_punch',0,1.6],kick:['round_kick_body',0,1.65],highKick:['round_kick_head',0,1.65],lowKick:['low_kick',0,1.65],comboKick:['combo_punch_kick',5,1.8],stepPunch:['combo_kick_punch',5,1.8]};
 for(const[id,[name,start,factor]]of Object.entries(map)){const clip=clips['r3_'+name];if(!clip)continue;const m=moves[id],frames=clip.frames.slice(start).map((_,i)=>i+start),times=clip.durations.slice(start).map(t=>Math.max(35,Math.round(t*(clip.timingRevision==='0.7.0'?1:factor)))),contacts=clip.contactFrames.filter(i=>i>=start);delete m.sequence;
  Object.assign(m,{clip:clip.id,frames,times,active:contacts,duration:times.reduce((a,b)=>a+b,0),reviewed:true,animationStart:start});
  const contactStart=times.slice(0,frames.indexOf(contacts[0])).reduce((a,b)=>a+b,0),contactEnd=times.slice(0,frames.indexOf(contacts.at(-1))+1).reduce((a,b)=>a+b,0);m.lungeUntil=Math.max(160,contactStart+30);m.chain=Math.min(m.duration-60,contactEnd+150);m.linkAt=Math.min(m.duration-80,contactEnd+120);m.pause=id==='drive'?55:id==='rush'?55:id.includes('Kick')||id==='kick'?42:32;m.carry=m.carry?{...m.carry,time:Math.max(85,m.carry.time)}:undefined;
  if(id==='jab'||id==='low'||id==='crossBody')m.zone='body';else if(id==='cross'||id==='jabHead'||id==='highKick')m.zone='head';else if(id==='lowKick')m.zone='legs';else if(['drive','reverse','rush','comboKick','stepPunch'].includes(id))delete m.zone;else m.zone='body';
  if(id==='comboKick'||id==='stepPunch')m.chain=m.linkAt=m.duration-80;
 }
 return moves;
}
