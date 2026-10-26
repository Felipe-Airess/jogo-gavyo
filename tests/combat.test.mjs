import test from 'node:test';
import assert from 'node:assert/strict';
import {Training,RULES,MOVES,intersects} from '../src/combat.mjs';
import {Ragdoll} from '../src/ragdoll.mjs';
const advance=(m,ms,input={})=>{for(let t=0;t<ms;t+=10)m.step(input,Math.min(10,ms-t));};
test('corrida mais rápida, diagonal normalizada e limites do corredor',()=>{
  const walk=new Training(),run=new Training(),diag=new Training();
  advance(walk,500,{right:true});advance(run,500,{right:true,run:true});advance(diag,100,{right:true,up:true});
  assert.ok(run.player.x>walk.player.x);assert.ok(Math.abs(Math.hypot(diag.player.x-75,diag.player.y-146)-4.9)<0.001);
  advance(run,30000,{left:true,up:true,run:true});assert.equal(run.player.x,RULES.minX);assert.equal(run.player.y,RULES.minY);
});
test('golpe tem preparação, janela ativa e no máximo um acerto por ataque',()=>{
  const m=new Training();m.player.x=218;m.step({attack:true},10);assert.equal(m.attackBox(),null);
  advance(m,100);assert.equal(m.dummy.hits,1);assert.ok(m.attackBox());advance(m,500);assert.equal(m.dummy.hits,1);assert.equal(m.player.state,'idle');
});
test('facing fica travado durante o ataque e o soco esquerdo acerta',()=>{
  const m=new Training();m.player.x=266;m.player.facing=-1;m.step({attack:true},10);advance(m,110,{right:true});
  assert.equal(m.player.facing,-1);assert.equal(m.dummy.hits,1);
});
test('errar por distância, profundidade ou lado não causa dano',()=>{
  for(const [x,y,face] of [[190,146,1],[218,122,1],[218,146,-1]]){
    const m=new Training();Object.assign(m.player,{x,y,facing:face});m.step({attack:true},10);advance(m,500);assert.equal(m.dummy.hits,0);
  }
});
test('colisão física impede atravessar o boneco e permite contornar',()=>{
  const m=new Training();advance(m,4000,{right:true});assert.ok(!intersects(m.body(),m.dummyBody()));assert.ok(m.player.x<m.dummy.x);
  advance(m,500,{down:true});advance(m,1000,{right:true});assert.ok(m.player.x>m.dummy.x);
});
test('hurt interrompe ataque, tem invulnerabilidade e reinício restaura estado',()=>{
  const m=new Training();m.step({attack:true},10);assert.equal(m.hurt(),true);assert.equal(m.player.state,'hurt');assert.equal(m.player.hp,4);assert.equal(m.hurt(),false);
  advance(m,450);assert.equal(m.player.state,'idle');advance(m,450);assert.equal(m.hurt(),true);
  m.reset();assert.equal(m.player.hp,5);assert.equal(m.dummy.hits,0);assert.equal(m.player.state,'idle');assert.equal(m.hitstop,0);
});
test('J encadeia jab, direto e gancho com buffer, sem repetir o mesmo golpe',()=>{
  const m=new Training();m.player.x=218;m.step({attack:true},10);const moves=[m.player.move],queued=new Set();
  for(let t=0;t<900;t+=10){
    const p=m.player,input={};if(m.attackId<3&&p.attackHit&&p.elapsed>=MOVES[p.move].activeEnd&&!queued.has(m.attackId)){input.attack=true;queued.add(m.attackId);}
    const previous=m.attackId;m.step(input,10);if(m.attackId!==previous)moves.push(m.player.move);
  }
  assert.deepEqual(moves,['jab','cross','hook']);assert.equal(m.dummy.hits,3);assert.equal(m.combo.best,3);assert.equal(m.dummy.state,'ragdoll');
});
test('cada soco empurra o alvo na direção do ataque',()=>{
  for(const side of [1,-1]){const m=new Training();m.player.x=242-side*24;m.player.facing=side;m.step({attack:true},10);advance(m,210);assert.ok((m.dummy.x-242)*side>3);assert.equal(m.dummy.hits,1);}
});
test('K é chute independente, causa lançamento maior e queda articulada',()=>{
  const m=new Training();m.player.x=216;m.step({kick:true},10);assert.equal(m.player.move,'kick');advance(m,240);assert.equal(m.dummy.hits,1);assert.equal(m.dummy.state,'ragdoll');assert.equal(m.dummy.ragdoll.nodes.length,11);assert.ok(m.dummy.x>250);
});
test('entrada no hitstop não se perde e ataque não vira de lado no combo',()=>{
  const m=new Training();m.player.x=218;m.step({attack:true},10);advance(m,70);assert.ok(m.hitstop>0);m.step({attack:true,left:true},10);advance(m,160,{left:true});assert.equal(m.player.move,'cross');assert.equal(m.player.facing,1);
});
test('tempo sem atacar reinicia sequência e dano cancela comando pendente',()=>{
  const m=new Training();m.player.x=218;m.step({attack:true},10);advance(m,1100);m.step({attack:true},10);assert.equal(m.player.move,'jab');m.step({kick:true},10);m.hurt();advance(m,450);assert.equal(m.player.state,'idle');assert.equal(m.buffer,null);
});
test('J durante corrida usa avanço e finisher recupera alvo automaticamente',()=>{
  const m=new Training();m.player.x=210;m.step({attack:true,run:true,right:true},10);assert.equal(m.player.move,'dash');advance(m,400);m.player.x=m.dummy.x-24;m.step({kick:true},10);advance(m,3000);assert.equal(m.dummy.state,'idle');assert.equal(m.dummy.ragdoll,null);
});
test('ragdoll preserva vínculos, fica no corredor e não atravessa o chão',()=>{
  const r=new Ragdoll(580,146,1,165,155);for(let i=0;i<240;i++)r.step(10);
  for(const n of r.nodes){assert.ok(Number.isFinite(n.x)&&Number.isFinite(n.y));assert.ok(n.x>=17&&n.x<=623);assert.ok(n.y<=146);}
  for(const l of r.links){const a=r.nodes[l.a],b=r.nodes[l.b];assert.ok(Math.abs(Math.hypot(b.x-a.x,b.y-a.y)-l.length)<2.2);}
});
test('distância e profundidade continuam obrigatórias para chute e golpes',()=>{
  for(const input of [{attack:true},{kick:true}]){const m=new Training();Object.assign(m.player,{x:213,y:122});m.step(input,10);advance(m,500);assert.equal(m.dummy.hits,0);assert.equal(m.combo.best,0);}
});
test('Sorriso consegue sair se o alvo levantar na mesma posição dele',()=>{
  const m=new Training();m.player.x=m.dummy.x;m.player.y=m.dummy.y;advance(m,500,{right:true});assert.ok(m.player.x>m.dummy.x+13);assert.equal(intersects(m.body(),m.dummyBody()),false);
});
