// Quadros e regras separados da simulação: trocar uma animação não muda o dano.
export const PARRY={window:115,opening:620,rearm:260};
export const FATIGUE={costFactor:.5,exhaustedBelow:6,restPerSecond:36,recoverPerSecond:14,runPerSecond:.8,dragPerSecond:.6};
export const CLINCH_MOVES=new Set(['knee','clinchPunch','clinchElbow','clinchFinish']);
export function extendMoves(moves){
 const make=(name,clip,times,extra={})=>({name,clip,frames:times.map((_,i)=>i),times,active:[3],point:[23,-34],size:[10,8],lunge:0,damage:12,knock:40,stun:480,pause:32,unbalance:16,chain:300,linkAt:300,cost:11,...extra});
 Object.assign(moves,{
  clinchPunch:make('SOCO CURTO','clinchPunch',[45,35,35,45,45,45,55,65],{active:[2],clinch:true,zone:'head',damage:9,cost:7}),
  clinchElbow:make('COTOVELADA','clinchElbow',[45,40,45,45,45,50,50,70],{active:[2],clinch:true,zone:'head',damage:13,cost:11}),
  clinchFinish:make('GOLPE DE QUEDA','clinchFinish',[50,45,55,55,70,60,65,90],{active:[4],size:[12,14],clinch:true,zone:'head',damage:24,cost:22,release:true,knock:92,heavy:true}),
  counterStraight:make('APARO > DIRETO','parryCounter',[35,30,35,45,45,60,65,100],{active:[4],point:[33,-43],lunge:9,damage:22,knock:80,cost:15,zone:'head',carry:{distance:12,time:85},chain:300,linkAt:300}),
  counterBody:make('APARO > CORPO','boxingFluid',[35,25,30,50,75,120],{frames:[0,1,2,3,4,5],active:[3],point:[28,-33],lunge:7,damage:21,knock:56,cost:13,zone:'body',carry:{distance:10,time:80},chain:220,linkAt:200}),
  counterLeft:make('APARO > CRUZADO','counterLeft',[35,30,35,45,45,60,65,100],{active:[4,5],point:[32,-46],lunge:8,damage:22,knock:76,cost:15,zone:'head',carry:{distance:12,time:85},chain:300,linkAt:300}),
  counterBodyLeft:make('APARO > TRONCO','counterLeft',[35,30,35,45,45,60,65,100],{active:[4,5],point:[28,-37],lunge:7,damage:21,knock:56,cost:13,zone:'body',carry:{distance:10,time:80},chain:270,linkAt:250}),
  groundPunch:make('SOCO NO CHAO','clinchFinish',[45,40,55,55,65,65,70,110],{active:[4],point:[17,-6],size:[14,15],ground:true,lunge:5,cost:22,damage:70,pause:50}),
  groundStomp:make('PISADA','groundStomp',[50,50,60,65,65,60,60,105],{active:[3,4],point:[24,-7],size:[14,16],ground:true,lunge:4,cost:26,damage:70,pause:55})
 });
 moves.drive.carry={distance:20,time:110};
 moves.low.carry={distance:12,time:85};
 moves.cross.carry={distance:5,time:45};
 moves.rush.carry={distance:24,time:105};
 moves.rush.name='SOCO DE IMPULSO';
 moves.jab.name='DIRETO NO CORPO';
 moves.cross.name='CRUZADO';
 Object.assign(moves.knee,{clinch:true,zone:'body',clip:'kneeV6',frames:[0,1,2,3,4,5,6,7],times:[45,35,45,50,50,40,45,50],active:[3,4]});
 for(const m of Object.values(moves)){m.duration=m.times.reduce((a,b)=>a+b,0);m.cost=Math.max(3,Math.ceil(m.cost*FATIGUE.costFactor));}
}
export function clinchChoice(input){return input.run&&input.attack?'clinchFinish':input.attack&&input.down?'clinchElbow':input.attack?'clinchPunch':'knee';}
export function canLink(move,player,mixed=false){
 if(move.ground||move.rush||move.clinch||player.stamina<3)return false;
 // Guarda deixa uma recuperação maior; errar só permite ligação mista tardia.
 return player.confirmed||mixed&&!player.hit;
}
