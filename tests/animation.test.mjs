import test from'node:test';import assert from'node:assert/strict';
import{animationPose,jointsFor,solveLimb,RIG}from'../src/animation.mjs';
import{MOVES}from'../src/combat.mjs';
test('articulações mantêm comprimento em movimento, golpes e dano',()=>{
  for(const state of['idle','walk','run','hurt',...Object.keys(MOVES)])for(let t=0;t<410;t+=10){
    const move=state in MOVES?state:null,p={state:move?'attack':state,move,elapsed:t,gaitPhase:t/40};
    const j=jointsFor(animationPose(p));
    for(const[a,b,length]of[[j.nearHip,j.nearLeg.joint,13],[j.nearLeg.joint,j.nearLeg.end,12],[j.nearShoulder,j.nearArm.joint,11],[j.nearArm.joint,j.nearArm.end,11]])assert.ok(Math.abs(Math.hypot(b.x-a.x,b.y-a.y)-length)<0.001);
  }
});
test('pé apoiado compensa o avanço do corpo durante a passada',()=>{
  for(const[state,distance]of[['walk',28],['run',52]]){
    let position;
    for(let t=0;t<(state==='run'?0.39:0.49);t+=0.02){const pose=animationPose({state,gaitPhase:t*Math.PI*2,elapsed:0});const worldFoot=t*distance+pose.nearX;if(position!==undefined)assert.ok(Math.abs(worldFoot-position)<0.001);position=worldFoot;assert.equal(pose.nearY,-4);}
  }
});
test('alvo fora do alcance do braço não estica os membros',()=>{
  const a={x:0,y:0},s=solveLimb(a,{x:100,y:0},11,11);assert.ok(s.end.x<22);assert.ok(Number.isFinite(s.joint.y));
});
test('coluna rígida e inclinação contida em todas as ações',()=>{
  for(const state of['idle','walk','run','hurt',...Object.keys(MOVES)])for(let t=0;t<450;t+=8){const pose=animationPose({state:state in MOVES?'attack':state,move:state,elapsed:t,gaitPhase:t/25}),j=jointsFor(pose);assert.ok(Math.abs(Math.hypot(j.neck.x-j.hip.x,j.neck.y-j.hip.y)-RIG.spine)<1e-9);assert.ok(Math.abs(pose.torsoAngle)<=RIG.maxLean);}
});
test('pés realmente alcançam o chão na fase apoiada, sem correção flutuante da IK',()=>{
  for(const state of['idle','walk','run'])for(let t=0;t<Math.PI*2;t+=0.025){const pose=animationPose({state,gaitPhase:t,elapsed:0}),j=jointsFor(pose);for(const[leg,x,y]of[[j.nearLeg,pose.nearX,pose.nearY],[j.farLeg,pose.farX,pose.farY]])if(y===-4)assert.ok(Math.hypot(leg.end.x-x,leg.end.y-y)<0.01);}
});
test('braços contrabalançam as pernas e o cotovelo não inverte a flexão',()=>{
  for(const state of['walk','run']){
    const pose=animationPose({state,gaitPhase:0,elapsed:0});assert.ok(pose.nearX>pose.farX);assert.ok(pose.nearUpper>pose.farUpper);
    for(let phase=0;phase<Math.PI*2;phase+=0.04){const p=animationPose({state,gaitPhase:phase,elapsed:0});assert.ok(p.nearElbow<=-RIG.minElbow&&p.nearElbow>=-RIG.maxElbow);assert.ok(p.farElbow<=-RIG.minElbow&&p.farElbow>=-RIG.maxElbow);}
  }
});
test('solução permanece finita mesmo quando alvo da articulação coincide com a origem',()=>{
  const result=solveLimb({x:0,y:0},{x:0,y:0},13,12);for(const p of[result.joint,result.end])assert.ok(Number.isFinite(p.x)&&Number.isFinite(p.y));
});
