import{extendMoves,clinchChoice,canLink,PARRY,FATIGUE}from'./context-moves.mjs';
import{Ragdoll}from'./ragdoll.mjs';
import{enemyRef,KNEE_TIMES}from'./pose-state.mjs';
import{updateGait}from'./locomotion.mjs';
export const LIMITS={minX:16,maxX:624,minY:122,maxY:164};
export const PARTS={head:70,body:80,arms:60,legs:60};
export const CLINCH={entry:240,grip:3200,maxGrip:4000,refresh:700,guardDamage:18};
const PUNCHES=new Set(['jab','jabHead','cross','crossBody','drive','low','reverse','stepPunch','rush']);
const KICKS=new Set(['kick','highKick','comboKick','lowKick','groundKick']);
export const MOVES={
 jab:{name:'SOCO NO CORPO',clip:'jab',frames:[0,1,4,5],times:[90,60,75,115],active:[1],point:[24.5,-36.8],size:[8,6],lunge:4,damage:16,knock:48,stun:490,pause:20,unbalance:14,chain:220},
 cross:{name:'DIRETO NA ABERTURA',clip:'cross',frames:[0,2,3,4,5],times:[100,55,45,80,110],active:[2,3],point:[25,-36.8],size:[9,6],lunge:7,damage:18,knock:60,stun:540,pause:26,unbalance:18,chain:265},
 drive:{name:'GOLPE PESADO',clip:'heavyMotion',frames:[0,1,2,3,4],times:[145,70,55,100,160],active:[2,3],point:[35,-40],size:[9,7],lunge:12,damage:24,knock:112,stun:620,pause:32,unbalance:35,chain:450,heavy:true,finish:true},
 low:{name:'SOCO BAIXO',clip:'hook',frames:[0,1,2,3,4],times:[90,55,70,85,140],active:[2],point:[14,-25],size:[9,7],lunge:8,damage:20,knock:44,stun:560,pause:24,unbalance:20,chain:330},
 reverse:{name:'GOLPE PARA TRAS',clip:'reverseMotion',frames:[0,1,2,3,4],times:[55,55,55,65,140],active:[3],point:[32,-36],size:[9,6],lunge:3,damage:15,knock:65,stun:400,pause:22,unbalance:15,chain:285},
 kick:{name:'CHUTE FRONTAL',clip:'kick',frames:[0,1,2,3,5],times:[100,70,85,90,140],active:[2],point:[31,-23],size:[11,8],lunge:5,damage:24,knock:120,stun:650,pause:32,unbalance:30,chain:420,heavy:true,finish:true},
 comboKick:{name:'SOCO > CHUTE ALTO',clip:'highKick',sequence:[['jab',4],['highKick',0],['highKick',1],['highKick',2],['highKick',4],['kick',0]],frames:[0,1,2,3,4,5],times:[35,35,50,65,55,90],active:[2,3,4],point:[37,-45],size:[10,8],lunge:9,damage:20,knock:72,stun:650,pause:28,unbalance:23,chain:265,linkAt:240},
 stepPunch:{name:'CHUTE > DIRETO',clip:'combo',sequence:[['kick',5],['combo',0],['combo',3],['combo',5],['combo',7]],frames:[0,1,2,3,4],times:[35,55,55,65,100],active:[2,3],point:[30,-45],size:[10,7],lunge:10,damage:16,knock:48,stun:540,pause:24,unbalance:18,chain:240,linkAt:220},
 knee:{name:'JOELHADA',clip:'kneeMotion',frames:[0,1,2,3,4],times:KNEE_TIMES,active:[2],point:[18,-25],size:[10,9],lunge:0,damage:10,knock:0,stun:500,pause:30,unbalance:12,chain:325}
};
for(const m of Object.values(MOVES))m.duration=m.times.reduce((a,b)=>a+b,0);
for(const name of['jab','cross','low','kick'])MOVES[name].point=MOVES[name].point.map(v=>v*1.25);
Object.assign(MOVES.jab,{linkAt:160});Object.assign(MOVES.cross,{linkAt:205});Object.assign(MOVES.drive,{linkAt:330});Object.assign(MOVES.low,{linkAt:235});Object.assign(MOVES.reverse,{linkAt:245});Object.assign(MOVES.kick,{linkAt:270});
// Mais desenhos nas fases, mantendo o instante de contato explícito.
Object.assign(MOVES.jab,{clip:'boxingFluid',frames:[0,1,2,3,4,5],times:[35,25,30,55,85,110],active:[3],cost:10});
Object.assign(MOVES.cross,{clip:'boxingFluid',frames:[6,7,8,9,10,11],times:[40,25,35,50,80,160],active:[9,10],cost:14});
Object.assign(MOVES.kick,{clip:'roundFluid',frames:[0,1,2,3,4,5,6,7,8,9,10,11],times:[40,35,35,35,35,55,50,40,35,35,40,50],active:[5,6,7],point:[35,-42],cost:22,linkAt:330});
MOVES.lowKick={name:'CHUTE NA PERNA',clip:'lowFluid',frames:[0,1,2,3,4,5,6,7,8,9,10,11],times:[35,35,35,35,40,55,55,35,35,35,35,60],active:[5,6],point:[32,-13],size:[10,8],lunge:6,damage:18,knock:24,stun:450,pause:32,unbalance:18,chain:400,linkAt:345,cost:18,zone:'legs'};
MOVES.groundKick={name:'CHUTE NO CHAO',clip:'groundFluid',frames:[0,1,2,3,4,5,6,7,8,9,10,11],times:[50,45,45,50,40,60,60,45,40,40,45,80],active:[5,6],point:[27,-5],size:[12,9],lunge:4,damage:70,knock:0,stun:0,pause:55,unbalance:0,chain:660,linkAt:660,cost:28,ground:true};
MOVES.rush={name:'SOCO COM O CORPO',clip:'rushFluid',frames:[0,1,2,3,4,5],times:[55,50,50,55,65,95],active:[3,4],point:[32,-41],size:[11,9],lunge:10,damage:28,knock:125,stun:700,pause:45,unbalance:50,chain:600,linkAt:600,cost:34,rush:true,heavy:true,finish:true};
MOVES.lowKick.active=[4];MOVES.groundKick.active=[6];
for(const[name,m]of Object.entries(MOVES)){m.duration=m.times.reduce((a,b)=>a+b,0);m.cost??=name==='knee'?7:name==='drive'?24:16;}
extendMoves(MOVES);
for(const id of['counterStraight','counterBody','counterLeft','counterBodyLeft'])PUNCHES.add(id);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const approach=(v,t,a)=>v+clamp(t-v,-a,a);
export const overlap=(a,b)=>a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;
export function frameAt(time,m){let t=Math.max(0,time);for(let i=0;i<m.times.length;i++){if(t<m.times[i])return m.frames[i];t-=m.times[i];}return m.frames.at(-1);}
export function enemy(id,x,y=146){return{id,x,y,facing:-1,state:'idle',parts:{...PARTS},vx:0,stun:0,timer:0,reaction:0,zone:null,lowered:false,unbalance:0,hits:0,guard:false,ragdoll:null,recoveryFrom:null,recovery:0,knockedOut:false,aiTimer:700+id*180};}
export class Battle{
 constructor(count=2,seed=731,moveSet=MOVES){this.moves=moveSet;
  // O que o lutador do jogador tem desenhado (Miguel não corre, não agarra, não limpa a mão)
  // e o golpe desenhado que substitui um que falta. Padrão: tudo, sem troca.
  this.can={run:true,grab:true,wipe:true};this.fallback={};this.count=count;this.seed=seed;this.mode='reaction';this.reset();}
 random(){this.rngState=(Math.imul(this.rngState,1664525)+1013904223)>>>0;return this.rngState/4294967296;}
 reset(){
  this.rngState=this.seed>>>0;
  this.player={x:76,y:146,facing:1,vx:0,vy:0,state:'idle',elapsed:0,distance:0,gaitDistance:0,visualOffsetX:0,move:null,travel:0,hit:false,confirmed:false,hp:5,stamina:100,chainCount:0,invulnerable:0,guard:false,grip:0,knees:0,strikes:0,grabbed:null,wasRunning:false,handBlood:{left:0,right:0},idleTime:0,parryUntil:0,counterUntil:0,clinchDistance:0};
  this.enemies=Array.from({length:this.count},(_,i)=>({...enemy(i+1,230+i*240),mass:.94+this.random()*.12,balanceLimit:44+this.random()*10,downTime:1400+this.random()*400,dead:false,attackArm:i%2?'left':'right'}));
  this.clock=0;this.hitstop=0;this.attackId=0;this.buffer=null;this.lastHit=null;this.advantage=null;this.carry=null;this.guardHeld=false;this.parryReady=0;this.lastEvent=null;this.eventId=0;
  this.combo={hits:0,best:0,ttl:0};this.message='Acerte, acompanhe e escolha a próxima abertura.';
 }
 event(type,extra={}){this.lastEvent={id:++this.eventId,type,at:this.clock,...extra};}
 get nearest(){const p=this.player;return[...this.enemies].filter(d=>!d.dead).sort((a,b)=>Math.hypot(a.x-p.x,a.y-p.y)-Math.hypot(b.x-p.x,b.y-p.y))[0];}
 setMode(mode){this.mode=mode;for(const d of this.enemies)d.guard=false;}
 pose(d){
  if(d.state==='fallen')return d.ragdoll.nodes;
  const x=d.x,y=d.y,f=d.facing,down=d.state==='bodyDown'||d.parts.body===0,fold=d.lowered||down||d.state==='clinch';
  let n=[[0,-61],[0,-51],[0,-28],[-10,-40],[-14,-28],[10,-40],[14,-28],[-5,-14],[-8,0],[5,-14],[8,0]].map(([a,b])=>({x:x+a,y:y+b}));
  if(fold){n[0].y+=down?21:14;n[0].x+=f*7;n[1].y+=down?16:10;n[1].x+=f*4;n[2].y+=down?5:1;}
  if(d.zone==='head'&&d.reaction>0){n[0].x-=f*5*d.reaction/260;n[0].y+=2;}
  if(d.guard){n[3]={x:x+f*9,y:y-36};n[4]={x:x+f*13,y:y-51};n[5]={x:x+f*5,y:y-35};n[6]={x:x+f*14,y:y-40};}
  if(d.parts.arms===0){n[4]={x:x-10,y:y-15};n[6]={x:x+10,y:y-15};}
  if(down){n[4]={x:x-3,y:y-23};n[6]={x:x+3,y:y-25};}
  if(d.state==='clinch'){n[0]={x:x+f*5,y:y-37};n[1]={x:x+f*4,y:y-33};}
  if(d.state==='recovering'&&d.recoveryFrom){const t=clamp(d.recovery/460,0,1),q=t*t*(3-2*t);return n.map((p,i)=>({x:d.recoveryFrom[i].x+(p.x-d.recoveryFrom[i].x)*q,y:d.recoveryFrom[i].y+(p.y-d.recoveryFrom[i].y)*q}));}
  const ref=enemyRef(d),art=this.artClips?.[ref.clip]?.frames[ref.frame]?.pose;
  if(art)for(let i=0;i<3;i++)n[i]={x:x-art[i].x*f,y:y+art[i].y};
  return n;
 }
 hurtboxes(d){const n=this.pose(d),h=d.state==='fallen'?this.groundHead(d):n[0];return{head:{x:h.x-6,y:h.y-6,w:12,h:12},body:{x:Math.min(n[1].x,n[2].x)-9,y:Math.min(n[1].y,n[2].y),w:18+Math.abs(n[1].x-n[2].x),h:Math.max(12,Math.abs(n[1].y-n[2].y)+4)},legs:{x:d.x-10,y:d.y-21,w:20,h:21}};}
 groundHead(d){const art=this.artClips?.targetHead?.frames[4]?.pose?.[0];if(art&&d.ragdoll&&d.ragdoll.age>=230)return{x:d.x-art.x*d.facing,y:Math.min(d.y,d.ragdoll.nodes[2].y+4)+art.y};return d.ragdoll?.nodes[0]||{x:d.x,y:d.y-6};}
 get groundTarget(){const p=this.player;return this.enemies.filter(d=>d.state==='fallen'&&!d.dead&&d.ragdoll.age>450&&Math.abs(d.y-p.y)<=8).map(d=>({d,head:this.groundHead(d)})).filter(({head})=>Math.abs(head.x-p.x)<46&&head.y>p.y-16).sort((a,b)=>Math.abs(a.head.x-p.x)-Math.abs(b.head.x-p.x))[0]?.d;}
 body(x=this.player.x,y=this.player.y){return{x:x-6,y:y-7,w:12,h:9};}
 move(dx,dy=0){
  const p=this.player,block=this.enemies.filter(d=>!['fallen','recovering','clinch','carried','bodyDown'].includes(d.state));let nx=clamp(p.x+dx,LIMITS.minX,LIMITS.maxX),ny=clamp(p.y+dy,LIMITS.minY,LIMITS.maxY);
  for(const d of block){const b={x:d.x-7,y:d.y-7,w:14,h:9},inside=overlap(this.body(),b);if(overlap(this.body(nx,p.y),b)&&!(inside&&Math.abs(nx-d.x)>Math.abs(p.x-d.x)))nx=p.x;if(overlap(this.body(nx,ny),b)&&!(inside&&Math.abs(ny-d.y)>Math.abs(p.y-d.y)))ny=p.y;}
  p.distance+=Math.hypot(nx-p.x,ny-p.y);p.x=nx;p.y=ny;
 }
 movePair(d,dx,dy=0){
  const p=this.player,x=p.x,y=p.y;
  dx=clamp(dx,Math.max(LIMITS.minX-p.x,LIMITS.minX-d.x),Math.min(LIMITS.maxX-p.x,LIMITS.maxX-d.x));
  dy=clamp(dy,Math.max(LIMITS.minY-p.y,LIMITS.minY-d.y),Math.min(LIMITS.maxY-p.y,LIMITS.maxY-d.y));
  for(const e of this.enemies){if(e===d||['fallen','recovering'].includes(e.state))continue;const b={x:e.x-7,y:e.y-7,w:14,h:9};if(overlap(this.body(d.x+dx,d.y+dy),b))return 0;}
  this.move(dx,dy);d.x+=p.x-x;d.y+=p.y-y;return Math.hypot(p.x-x,p.y-y);
 }
 attackBox(){
  const p=this.player,m=this.moves[p.move];if(!['attack','knee'].includes(p.state)||!m||!m.active.includes(frameAt(p.elapsed,m)))return null;
  const f=frameAt(p.elapsed,m),[clip,index]=m.sequence?.[f]||[m.clip,f],art=(this.playerClips||this.artClips)?.[clip]?.frames[index];
  const kick=KICKS.has(p.move)||p.move==='groundStomp',tip=m.ground||p.move==='knee'?null:kick?art?.foot:art?.fist;
  const[w,h]=m.size,[x,y]=tip?[tip.x,tip.y]:m.point;return{x:p.x+p.facing*x-w/2,y:p.y+y-h/2,w,h};
 }
 // Golpe escolhido; sem desenho para ele, o substituto de this.fallback (se houver).
 choose(input){const n=this.chooseRaw(input),f=this.fallback[n];return this.moves[n]||!f||!this.moves[f]?n:f;}
 chooseRaw(input){
  const p=this.player,dir=Number(!!input.right)-Number(!!input.left),recent=p.state==='attack'||this.clock-(p.actionAt??-1000)<620;
  const ground=((input.down&&input.kick)||(input.attack)||(input.run&&input.kick))&&this.moves.groundPunch?this.groundTarget:null;
  if(ground){p.facing=this.groundHead(ground).x>=p.x?1:-1;p.groundId=ground.id;return input.kick?(input.run?'groundStomp':'groundKick'):'groundPunch';}
  if(p.counterUntil>this.clock&&input.attack){const d=this.enemies.find(e=>e.id===p.counterTarget);if(d&&!d.knockedOut&&Math.abs(d.x-p.x)<52&&Math.abs(d.y-p.y)<9){p.facing=d.x>p.x?1:-1;p.counterUntil=0;return input.down?(p.parryArm==='right'?'counterBodyLeft':'counterBody'):p.parryArm==='right'?'counterLeft':'counterStraight';}}
  if(input.up&&input.attack&&this.moves.jabHead)return'jabHead';
  if(input.up&&input.kick&&this.moves.highKick)return'highKick';
  if(input.down&&input.run&&input.attack&&this.moves.crossBody)return'crossBody';
  if(input.kick&&input.down)return'lowKick';
  if(input.kick)return recent&&PUNCHES.has(p.move)?'comboKick':'kick';
  if(input.run&&Math.hypot(p.vx,p.vy)>60)return'rush';
  if(input.down)return'low';if(dir===-p.facing)return'reverse';if(dir===p.facing||input.run)return'drive';
  if(recent&&KICKS.has(p.move))return'stepPunch';
  const a=this.advantage;if(a&&this.clock-a.at<750&&a.target.parts.head>0)return a.zone==='body'?'cross':a.zone==='head'?'drive':'jab';return'jab';
 }
 begin(name){
  const p=this.player,m=this.moves[name];if(!m||p.stamina<m.cost){this.buffer=null;this.message=m?'Sem fôlego: recupere a base.':'Golpe ainda sem desenho.';return false;}
  const chaining=p.state==='attack';p.chainCount=m.clinch?0:chaining?p.chainCount+1:1;p.stamina-=m.cost;p.exhaustedAttack=p.stamina<=FATIGUE.exhaustedBelow;p.runMomentum=Math.hypot(p.vx,p.vy);
  if(name==='reverse')p.facing*=-1;
  if(m.clinch){const d=this.enemies.find(e=>e.id===p.grabbed);if(d){d.clinchMove=name;d.clinchProgress=0;}}
  p.linkFrom=p.move;p.actionAt=this.clock;p.releaseId=null;p.queuedClinch=null;p.queuedKnee=false;p.state=m.clinch?'knee':'attack';p.move=name;p.elapsed=0;p.travel=0;p.hit=false;p.confirmed=false;p.grabUntil=0;p.fallTrigger=0;p.idleTime=0;p.vx*=m.rush?1:.3;p.vy=0;p.guard=false;p.previousTip=null;p.sweptBox=null;p.activeHand=name==='cross'||name==='crossBody'||name==='counterLeft'||name==='counterBodyLeft'?'left':'right';this.buffer=null;this.attackId++;return true;
 }
 hurt(direction=-this.player.facing){
  const p=this.player;if(p.invulnerable>0||p.hp<=0)return false;
  this.endCarry(true);this.release(false);p.hp--;p.invulnerable=850;p.counterUntil=0;p.parryUntil=0;
  if(['rushFall','gettingUp'].includes(p.state))return true;
  p.state='hurt';p.elapsed=0;p.vx=direction*40;this.buffer=null;this.advantage=null;this.event('hurt');return true;
 }
 launch(d,zone,point,knock=80,lift=85){const pose=this.pose(d);d.ragdoll=new Ragdoll(d.x,d.y,this.player.facing,knock,lift,pose);d.ragdoll.impulseAt(point,this.player.facing,35,15);d.state='fallen';d.downKind=zone;d.timer=d.downTime;d.guard=false;d.lowered=false;d.vx=0;}
 startPlayerFall(){const p=this.player;this.endCarry();p.state='rushFall';p.elapsed=0;p.fallHeight=8;p.fallVy=42;p.fallVx=p.facing*Math.max(45,p.runMomentum*.72);p.visualOffsetX=0;this.buffer=null;this.advantage=null;this.message=p.confirmed?'O impulso levou os dois. Recupere o apoio.':'Sorriso perdeu o equilíbrio. Recupere o apoio.';}
 stain(m){if(this.player.move!=='knee'&&this.player.move!=='clinchElbow'&&!KICKS.has(this.player.move)&&!m.ground){const p=this.player,k=p.activeHand||'right';p.handBlood[k]=Math.min(4,p.handBlood[k]+1);}}
 damage(d,m,zone,point,blocked=false){
  const p=this.player;p.hit=true;p.confirmed=!blocked;d.hits++;d.zone=blocked?'arms':zone;d.reaction=260;
  const amount=blocked?12:m.damage;d.parts[blocked?'arms':zone]=Math.max(0,d.parts[blocked?'arms':zone]-amount);
  this.hitstop=blocked?12:m.pause;this.lastHit={id:this.attackId,move:p.move,target:d.id,zone:d.zone,blocked,point:{...point},damage:amount,at:this.clock,blood:!blocked&&amount>=9};this.event(blocked?'block':'hit',{heavy:!!m.heavy});
  if(blocked){this.advantage=null;this.combo.hits=0;d.vx=0;if(d.parts.arms===0){d.guard=false;d.state='guardBreak';d.stun=700;this.message='Guarda rompida. Os braços cederam.';}else this.message='Defendido: desgaste nos braços, corpo sem recuo.';return;}
  this.stain(m);d.guard=false;d.stun=m.stun;d.lowered=zone!=='legs';d.state=zone==='head'?'headStagger':zone==='legs'?'legStagger':'bodyStagger';d.unbalance+=m.unbalance;
  this.combo.hits=this.combo.ttl>0?this.combo.hits+1:1;this.combo.best=Math.max(this.combo.best,this.combo.hits);this.combo.ttl=1050;this.advantage={target:d,zone,at:this.clock};
  if(m.clinch){d.state='clinch';return;}
  if(m.carry&&d.parts.legs>0){d.vx=0;d.state='carried';this.carry={target:d.id,move:p.move,zone,point:{...point},elapsed:0,travel:0,distance:m.carry.distance/(d.mass||1),duration:m.carry.time,direction:p.facing};this.message='Contato firme: o corpo acompanha o golpe.';return;}
  this.finishImpact(d,m,zone,point);
 }
 finishImpact(d,m,zone,point){
  const p=this.player;d.state=zone==='head'?'headStagger':zone==='legs'?'legStagger':'bodyStagger';d.vx=p.facing*m.knock/(d.mass||1);
  if(zone==='legs'){this.message='Perna atingida: o apoio está cedendo.';if(d.parts.legs===0){this.launch(d,'legs',point,32,15);this.message='A perna cedeu.';}return;}
  if(m.rush){if(d.parts.head===0)d.knockedOut=true;this.launch(d,zone,point,Math.max(105,p.runMomentum*1.3),45);p.fallTrigger=p.elapsed+10;return;}
  if(d.parts.head===0){d.knockedOut=true;this.launch(d,'head',point,75,55);this.message='Cabeça esgotada: desmaio.';return;}
  if(d.parts.body===0){d.state='bodyDown';d.lowered=true;d.stun=0;d.vx*=.4;this.message='O tronco cedeu.';}
  else this.message=zone==='body'?'Corpo aberto. Acompanhe e procure a cabeça.':'Cabeça atingida. Procure outra abertura.';
  if(m.finish&&d.unbalance>=d.balanceLimit)this.launch(d,zone,point,m.knock*.75,80);
 }
 updateCarry(dt){
  const c=this.carry;if(!c)return false;const d=this.enemies.find(e=>e.id===c.target);
  if(!d||d.dead||this.player.state!=='attack'){this.endCarry(true);return false;}
  c.elapsed+=dt;const t=clamp(c.elapsed/c.duration,0,1),travel=c.distance*(1-(1-t)*(1-t)),dx=(travel-c.travel)*c.direction;c.travel=travel;
  const moved=this.movePair(d,dx);d.facing=-c.direction;
  if(t>=1||Math.abs(dx)>.02&&moved<.001)this.endCarry();return true;
 }
 endCarry(interrupted=false){const c=this.carry;if(!c)return;this.carry=null;const d=this.enemies.find(e=>e.id===c.target);if(!d||d.dead)return;if(interrupted){if(d.parts.head===0){d.knockedOut=true;this.launch(d,'head',this.pose(d)[0],18,10);}else{d.state='bodyStagger';d.stun=220;d.vx=0;}}else this.finishImpact(d,this.moves[c.move],c.zone,{x:d.x,y:d.y+(c.point.y-this.player.y)});}
 finishGround(d,m){const p=this.player,h=this.groundHead(d);d.dead=true;d.knockedOut=true;d.parts.head=0;d.timer=Infinity;d.ragdoll.impulseAt(h,p.facing,12,0);p.hit=p.confirmed=true;this.hitstop=m.pause;this.lastHit={id:this.attackId,move:p.move,target:d.id,zone:'head',point:{...h},damage:m.damage,blocked:false,blood:true,finisher:true,at:this.clock};if(p.move==='groundPunch')p.handBlood.right=Math.min(4,p.handBlood.right+2);this.event('hit',{heavy:true});this.message='Finalizado. R reinicia o treino.';}
 contact(){
  let box=this.attackBox();const p=this.player;if(p.hit)return;
  if(!box){const m=this.moves[p.move];if(m)p.previousTip={x:p.x+p.facing*6,y:p.y+m.point[1]};return;}
  const m=this.moves[p.move],tip={x:box.x+box.w/2,y:box.y+box.h/2},old=p.previousTip||tip;
  box={x:Math.min(old.x,tip.x)-box.w/2,y:Math.min(old.y,tip.y)-box.h/2,w:Math.abs(tip.x-old.x)+box.w,h:Math.abs(tip.y-old.y)+box.h};p.sweptBox=box;p.previousTip=tip;
  if(m.ground){const d=this.enemies.find(e=>e.id===p.groundId)||this.groundTarget;if(!d||d.dead||d.state!=='fallen'||d.ragdoll.age<450||Math.abs(d.y-p.y)>8)return;const h=this.groundHead(d);if(overlap(box,{x:h.x-6,y:h.y-6,w:12,h:12}))this.finishGround(d,m);return;}
  for(const d of [...this.enemies].sort((a,b)=>Math.abs(a.x-p.x)-Math.abs(b.x-p.x))){
   if(d.knockedOut||['fallen','recovering','carried','clinch'].includes(d.state)||Math.abs(d.y-p.y)>8)continue;
   const hits=Object.entries(this.hurtboxes(d)).filter(([zone,b])=>(!m.zone||m.zone===zone)&&overlap(box,b)).map(([zone,b])=>{const x=Math.max(box.x,b.x),y=Math.max(box.y,b.y),w=Math.min(box.x+box.w,b.x+b.w)-x,h=Math.min(box.y+box.h,b.y+b.h)-y;return{zone,area:w*h,point:{x:x+w/2,y:y+h/2}};}).sort((a,b)=>b.area-a.area);
   const front=(p.x-d.x)*d.facing>0,guardBox={x:d.x+d.facing*11-5,y:d.y-53,w:10,h:33};
   if(d.guard&&front&&m.zone!=='legs'&&(overlap(box,guardBox)||hits.length)){this.damage(d,m,'arms',{x:guardBox.x+guardBox.w/2,y:box.y+box.h/2},true);return;}
   if(hits.length){this.damage(d,m,hits[0].zone,hits[0].point);return;}
  }
 }
 grab(){if(!this.can.grab)return;
  const p=this.player;if(['clinchEntry','clinch','knee'].includes(p.state)){this.release();return;}
  if(p.state==='attack'){p.grabUntil=Math.max(this.moves[p.move].chain,p.elapsed)+260;this.message='Agarrão preparado após o golpe.';return;}
  if(!['idle','walk','run','brake','guard'].includes(p.state))return;
  const d=this.nearest;if(!d||d.knockedOut||['fallen','recovering','carried'].includes(d.state)||Math.abs(d.x-p.x)>30||Math.abs(d.y-p.y)>8){this.message='Aproxime-se para agarrar.';return;}
  if(d.guard)d.parts.arms=Math.max(0,d.parts.arms-CLINCH.guardDamage);
  p.facing=d.x>=p.x?1:-1;p.grabAnchor=(p.x+d.x-p.facing*28)/2;p.grabbed=d.id;p.grip=CLINCH.grip;p.knees=0;p.strikes=0;p.queuedClinch=null;p.state='clinchEntry';p.elapsed=0;p.vx=p.vy=0;p.guard=false;p.idleTime=0;d.state='clinch';d.guard=false;d.vx=0;d.lowered=true;d.stun=0;this.buffer=null;this.message='J soco · baixo+J cotovelo · K joelho · Shift+J derruba.';
 }
 release(recover=true){const p=this.player,d=this.enemies.find(e=>e.id===p.grabbed);p.releaseId=null;if(d?.state==='clinch'){d.state=d.parts.body===0?'bodyDown':'bodyStagger';d.stun=450;}p.grabbed=null;p.grip=0;p.queuedClinch=null;p.queuedKnee=false;if(recover&&['clinchEntry','clinch','knee'].includes(p.state)){p.state='recover';p.elapsed=0;}}
 tickClinch(input,dt){
  const p=this.player,d=this.enemies.find(e=>e.id===p.grabbed),s=dt/1000;if(!d){this.release();return;}
  p.grip-=dt;if(p.grip<=0){this.message='O clinch escapou.';this.release();return;}
  if(p.state==='clinchEntry'){if(Number.isFinite(p.grabAnchor))p.x+=clamp(p.grabAnchor-p.x,-28*s,28*s);if(p.elapsed>=CLINCH.entry){p.state='clinch';p.elapsed=0;const next=p.queuedClinch;p.queuedClinch=null;if(next)this.begin(next);}return;}
  if(p.state==='clinch'){
   if(input.attack||input.kick){if(!this.begin(clinchChoice(input)))this.release();return;}
   const dx=Number(!!input.right)-Number(!!input.left),dy=Number(!!input.down)-Number(!!input.up),len=Math.hypot(dx,dy)||1,speed=21/(d.mass||1);
   p.clinchWalking=!!(dx||dy);if(p.clinchWalking){const moved=this.movePair(d,dx/len*speed*s,dy/len*speed*s*.65);p.clinchDistance+=moved;p.grip-=dt*.25;p.stamina=Math.max(0,p.stamina-s*FATIGUE.dragPerSecond);if(!p.stamina)this.release();}return;
  }
  p.clinchWalking=false;const m=this.moves[p.move];d.clinchProgress=p.elapsed;
  if(!p.hit&&m.active.includes(frameAt(p.elapsed,m))){
   const zone=m.zone||'body',box=this.attackBox(),target=this.hurtboxes(d)[zone];
   if(!box||!overlap(box,target))return;
   const point={x:clamp(box.x+box.w/2,target.x,target.x+target.w),y:clamp(box.y+box.h/2,target.y,target.y+target.h)};this.damage(d,m,zone,point);p.strikes++;if(p.move==='knee')p.knees++;p.grip=Math.min(CLINCH.maxGrip,p.grip+CLINCH.refresh);d.vx=0;
   if(m.release||d.parts.head===0||d.parts.body===0){if(d.parts.head===0)d.knockedOut=true;this.launch(d,zone,point,m.release?92:55,45);this.release(false);p.state='attack';p.recoverFrom=p.move;this.message=m.release?'Pegada solta no impacto: o alvo perdeu a base.':'O alvo cedeu.';return;}
   d.state='clinch';this.message=m.name+'. Escolha o próximo golpe.';
  }
  if(p.elapsed>=m.duration){const next=p.queuedClinch;p.queuedClinch=null;d.clinchMove=null;if(next){if(!this.begin(next))this.release();}else{p.state='clinch';p.elapsed=0;}}
 }
 enemyAttack(d){
  const p=this.player;if(d.parts.arms<=0||Math.abs(d.x-p.x)>=36||Math.abs(d.y-p.y)>=9)return;
  if(p.guard&&(d.x-p.x)*p.facing>0){
   if(this.clock<=p.parryUntil){p.state='parry';p.elapsed=0;p.parryArm=d.attackArm==='right'?'left':'right';p.counterTarget=d.id;p.counterUntil=this.clock+PARRY.opening;p.parryUntil=0;d.state='parried';d.stun=620;d.guard=false;this.hitstop=42;this.event('parry');this.message='Aparo! J responde; baixo+J procura o corpo.';}
   else{this.message='Defesa firme. Solte e aperte L no instante do contato para aparar.';this.hitstop=12;this.event('block');}
  }else this.hurt(d.facing);
 }
 updateEnemy(d,dt){
  const p=this.player,s=dt/1000;d.reaction=Math.max(0,d.reaction-dt);d.stun=Math.max(0,d.stun-dt);d.unbalance=Math.max(0,d.unbalance-s*5);
  if(d.dead){d.ragdoll.step(dt);d.x=d.ragdoll.center.x;return;}
  if(d.parts.body===0)d.bodyDownAge=(d.bodyDownAge||0)+dt;
  if(d.state==='carried')return;
  if(d.state==='clinch'){const q=1-Math.exp(-dt/55);d.x+=(clamp(p.x+p.facing*28,16,624)-d.x)*q;d.y+=(p.y-d.y)*q;d.facing=-p.facing;return;}
  if(d.state==='fallen'){d.ragdoll.step(dt);d.x=d.ragdoll.center.x;d.timer-=dt;if(d.timer<=0&&!d.knockedOut&&d.parts.legs>0){d.recoveryFrom=d.ragdoll.nodes.map(n=>({...n}));d.state='recovering';d.recovery=0;}return;}
  if(d.state==='recovering'){d.recovery+=dt;if(d.recovery>=460){d.state=d.parts.body===0?'bodyDown':d.parts.legs===0?'legDown':'idle';d.lowered=d.parts.body===0;d.ragdoll=null;d.recoveryFrom=null;d.stun=0;}return;}
  d.x=clamp(d.x+d.vx*s,16,624);d.vx*=Math.exp(-8*s);
  if(d.state==='enemyWindup'){d.timer-=dt;if(d.timer<=0){this.enemyAttack(d);if(d.state!=='parried')d.state='idle';d.attackArm=d.attackArm==='left'?'right':'left';d.aiTimer=900+this.random()*550;}return;}
  if(d.parts.body===0){d.state='bodyDown';d.guard=false;return;}
  if(d.parts.legs===0){d.state='legDown';d.guard=false;return;}
  if(d.stun>0){d.guard=false;return;}
  d.state='idle';d.lowered=false;d.facing=p.x<d.x?-1:1;d.guard=this.mode==='guard'&&d.parts.arms>0;
  if(this.mode==='sparring'&&d.parts.arms>0&&p.hp>0){d.aiTimer-=dt;d.guard=d.aiTimer>450;if(d.aiTimer<=0&&Math.abs(d.x-p.x)<48&&Math.abs(d.y-p.y)<9){d.guard=false;d.state='enemyWindup';d.timer=320+this.random()*130+(1-d.parts.legs/60)*180;}}
 }
 step(input,ms){let remaining=clamp(ms,0,100),first=true;while(remaining>1e-6){const dt=Math.min(1000/120,remaining);this.tick(first?input:{...input,attack:false,kick:false,grab:false},dt);remaining-=dt;first=false;}}
 tick(input,dt){
  const p=this.player,s=dt/1000;this.clock+=dt;const pulse=input.attack||input.kick,guardPress=input.guard&&!this.guardHeld;this.guardHeld=!!input.guard;
  if(guardPress&&this.clock>=this.parryReady&&['idle','walk','run','brake','guard','wipe'].includes(p.state)){p.parryUntil=this.clock+PARRY.window;this.parryReady=this.clock+PARRY.rearm;p.guard=true;p.state='guard';p.elapsed=0;}
  if(pulse&&p.state==='attack'&&!this.buffer){const m=this.moves[p.move],mixed=(input.kick&&PUNCHES.has(p.move))||(input.attack&&KICKS.has(p.move));if(canLink(m,p,mixed)&&(mixed||p.elapsed>=m.times[0]))this.buffer={move:this.choose(input),until:Math.max(m.linkAt,p.elapsed)+180,mixed};}
  if(pulse&&(p.state==='clinchEntry'||p.state==='knee'&&p.hit)&&!p.queuedClinch)p.queuedClinch=clinchChoice(input);
  if(pulse&&p.state==='parry'&&!p.counterQueued)p.counterQueued={attack:!!input.attack,kick:!!input.kick,down:!!input.down};
  if(this.buffer&&this.buffer.until<p.elapsed)this.buffer=null;
  if(input.grab&&p.state==='attack'){this.grab();input={...input,grab:false};}
  if(this.hitstop>0){this.hitstop=Math.max(0,this.hitstop-dt);return;}
  for(const d of this.enemies)this.updateEnemy(d,dt);
  p.elapsed+=dt;p.invulnerable=Math.max(0,p.invulnerable-dt);this.combo.ttl=Math.max(0,this.combo.ttl-dt);if(!this.combo.ttl)this.combo.hits=0;
  if(['idle','walk','guard','winded','wipe'].includes(p.state))p.stamina=Math.min(100,p.stamina+s*FATIGUE.restPerSecond);else if(p.state==='attackRecover')p.stamina=Math.min(100,p.stamina+s*FATIGUE.recoverPerSecond);else if(p.state==='run')p.stamina=Math.max(0,p.stamina-s*FATIGUE.runPerSecond);
  if(p.hp<=0){p.state='hurt';this.endCarry(true);return;}
  if(input.grab)this.grab();
  if(['clinchEntry','clinch','knee'].includes(p.state)){this.tickClinch(input,dt);return;}
  if(p.state==='parry'){if(p.elapsed<90)return;const next=p.counterQueued;p.counterQueued=null;p.state=input.guard?'guard':'idle';p.elapsed=0;if(next){this.begin(this.choose(next));return;}}
  if(p.state==='rushFall'){p.x=clamp(p.x+p.fallVx*s,LIMITS.minX,LIMITS.maxX);p.fallVx*=Math.exp(-2.6*s);p.fallVy-=470*s;p.fallHeight=Math.max(0,p.fallHeight+p.fallVy*s);if(!p.fallHeight)p.fallVy=0;if(p.elapsed>=760){p.state='gettingUp';p.elapsed=0;p.fallHeight=0;}return;}
  if(['gettingUp','attackRecover','winded'].includes(p.state)){p.vx=approach(p.vx,0,240*s);if(p.elapsed>(p.state==='gettingUp'?420:p.state==='winded'?550:p.recoverDuration||180)){p.state='idle';p.elapsed=0;p.chainCount=0;}return;}
  if(['hurt','stumble','recover'].includes(p.state)){p.vx=approach(p.vx,0,(p.state==='stumble'?100:200)*s);this.move(p.vx*s);if(p.elapsed>({hurt:360,stumble:330,recover:220}[p.state])){p.state='idle';p.elapsed=0;}return;}
  if(p.state==='attack'){
   const m=this.moves[p.move];if(this.carry){p.elapsed-=dt;this.updateCarry(dt);return;}
   const t=clamp(p.elapsed/(m.lungeUntil||(m.times[0]+m.times[1])),0,1),travel=m.lunge*t*t*(3-2*t);this.move((travel-p.travel)*p.facing);p.travel=travel;
   if(m.rush){this.move(p.vx*s);p.vx=approach(p.vx,0,60*s);}this.contact();if(this.carry)return;
   if(m.rush&&p.confirmed&&p.fallTrigger&&p.elapsed>=p.fallTrigger){this.startPlayerFall();return;}
   if(p.grabUntil>=p.elapsed&&p.elapsed>=m.chain){p.grabUntil=0;p.state='idle';this.grab();return;}
   if(this.buffer&&canLink(m,p,this.buffer.mixed)&&p.elapsed>=(this.buffer.mixed?m.linkAt:m.chain)){const next=this.buffer.move;if(this.begin(next))return;}
   if(p.elapsed<m.duration)return;
   if(!p.hit&&p.exhaustedAttack){p.state='stumble';p.elapsed=0;p.whiffMove=p.move;p.vx=p.facing*(m.heavy?38:18);this.buffer=null;this.advantage=null;this.message='Sem fôlego e golpe no vazio: recupere o equilíbrio.';return;}
   p.state='attackRecover';p.recoverFrom=p.move;p.elapsed=0;p.recoverDuration=p.hit&&!p.confirmed?240:m.heavy?250:120;this.buffer=null;return;
  }
  const moving=input.left||input.right||input.up||input.down;
  if(p.state==='wipe'){
   if(pulse||moving||input.guard||input.grab){p.state='idle';p.elapsed=0;p.idleTime=0;}
   else{if(p.elapsed>460){const amount=Math.floor((p.elapsed-460)/95);for(const k of['left','right'])p.handBlood[k]=Math.max(0,p.wipeStart[k]-amount);}if(p.elapsed>=1050){p.handBlood={left:0,right:0};p.state='idle';p.elapsed=0;p.idleTime=0;}return;}
  }
  if(pulse){if(!this.begin(this.choose(input))){p.state='winded';p.elapsed=0;}return;}
  p.guard=!!input.guard;if(p.guard){p.vx=approach(p.vx,0,400*s);p.vy=approach(p.vy,0,400*s);this.move(p.vx*s,p.vy*s);p.state='guard';p.idleTime=0;return;}
  const dx=Number(!!input.right)-Number(!!input.left),dy=Number(!!input.down)-Number(!!input.up),length=Math.hypot(dx,dy)||1,max=input.run&&p.stamina>0?88:49;
  const before=Math.abs(p.vx);if(!dx&&!dy&&p.wasRunning&&before>20&&p.state!=='brake'){p.state='brake';p.elapsed=0;}
  const oldState=p.state;p.vx=approach(p.vx,dx/length*max,(dx?300:210)*s);p.vy=approach(p.vy,dy/length*max,(dy?300:260)*s);const oldX=p.x,oldY=p.y;this.move(p.vx*s,p.vy*s);
  if(Math.abs(p.vx)>10)p.facing=Math.sign(p.vx);else if(dx)p.facing=Math.sign(dx);
  if(dx||dy){p.state=input.run&&this.can.run&&p.stamina>0?'run':'walk';p.wasRunning=p.state==='run';p.idleTime=0;if(p.state==='run'&&oldState!=='run')p.runStart=0;p.runStart=(p.runStart||0)+dt;}
  else if(Math.hypot(p.vx,p.vy)<2){p.state='idle';p.wasRunning=false;if(oldState!=='idle')p.elapsed=0;p.idleTime+=dt;if(this.can.wipe&&p.idleTime>2300&&(p.handBlood.left||p.handBlood.right)){p.state='wipe';p.elapsed=0;p.wipeStart={...p.handBlood};}}
  else if(p.state!=='brake')p.state='walk';
  updateGait(p,p.x-oldX,p.y-oldY,dt,this.playerClips||this.artClips);
 }
}
