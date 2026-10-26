import{createBuildMoves,BUILD_VERSION}from'./build-moves.mjs';
import{TouchControls}from'./touch-controls.mjs';
import{Battle,MOVES,CLINCH}from'./battle.mjs';
import{spriteFrame,spriteFlip,spriteMeta}from'./sprite-player.mjs';
import{createArt,lettering}from'./art.js';
import{TargetView}from'./target-view.mjs';
import{SORRISO_ASSET,MIGUEL_ASSET}from'./assets.js';
import{MiguelView}from'./miguel-view.mjs';
import{Blood}from'./blood.mjs';
import{CombatAudio}from'./combat-audio.mjs';
import{FixedStep,lerp}from'./core/fixed-step.mjs';
import{DuelScene}from'./duel/duel-scene.mjs';
const $=id=>document.getElementById(id),ui={play:$('play'),debug:$('debug'),reset:$('reset'),status:$('status'),game:$('game'),training:$('training'),mode:$('game-mode')};
// Botões compartilhados atuam na cena visível (corredor ou duelo).
let game,current='Corridor';const active=()=>game.scene.getScene(current);
class Corridor extends Phaser.Scene{
 constructor(){super('Corridor');this.mode='title';this.debugVisible=false;this.hudClock=0;this.cameraPosition=0;}
 preload(){this.load.spritesheet('sorriso-sheet',SORRISO_ASSET.image,{frameWidth:SORRISO_ASSET.frameWidth,frameHeight:SORRISO_ASSET.frameHeight});this.load.json('sorriso-data',SORRISO_ASSET.data);this.load.spritesheet('miguel-sheet',MIGUEL_ASSET.image,{frameWidth:MIGUEL_ASSET.frameWidth,frameHeight:MIGUEL_ASSET.frameHeight});this.load.json('miguel-data',MIGUEL_ASSET.data);this.load.json('sorriso-markers','assets/sorriso-markers.json');}
 create(){
  if(!this.textures.exists('sorriso-sheet')||!this.textures.exists('miguel-sheet')||!this.cache.json.get('miguel-data')){$('loading').textContent='Não foi possível carregar a folha. Reabra pelo INICIAR.cmd.';return;}
  this.clips=Object.fromEntries(this.cache.json.get('sorriso-data').clips.map(c=>[c.id,c]));createArt(this);this.model=new Battle(2,731,createBuildMoves(this.clips));this.stepper=new FixedStep(60);this.prev=null;this.model.artClips=this.clips;this.blood=new Blood();this.combatAudio=new CombatAudio();this.add.image(0,0,'hallway').setOrigin(0);
  this.shadow=this.add.ellipse(76,146,25,4,0x172723,0.6);this.sorriso=this.add.image(76,146,'sorriso-sheet',0).setOrigin(SORRISO_ASSET.originX,SORRISO_ASSET.originY);
  this.miguel=new MiguelView(this,this.cache.json.get('miguel-data'));$('miguel-pose').onchange=()=>{this.miguel.setPose($('miguel-pose').value);ui.game.focus({preventScroll:true});};
  this.enemyViews=this.model.enemies.map(()=>({view:new TargetView(this,this.clips),shadow:this.add.ellipse(0,146,25,5,0x172723,0.6)}));
  this.bars=this.add.graphics().setDepth(650);this.effects=this.add.graphics().setDepth(700);this.debugLayer=this.add.graphics().setDepth(720);
  this.cameras.main.setBounds(0,0,640,180);this.cameras.main.roundPixels=true;
  this.hudTexture=this.textures.createCanvas('hud',320,28);this.add.image(0,0,'hud').setOrigin(0).setDepth(800).setScrollFactor(0);
  this.noteTexture=this.textures.createCanvas('note',320,11);this.add.image(0,169,'note').setOrigin(0).setDepth(800).setScrollFactor(0);
  this.overlayTexture=this.textures.createCanvas('overlay',320,180);this.add.image(0,0,'overlay').setOrigin(0).setDepth(900).setScrollFactor(0);
  for(const t of Object.values(this.textures.list))t.setFilter(Phaser.Textures.FilterMode.NEAREST);this.game.canvas.getContext('2d').imageSmoothingEnabled=false;
  this.touch=new TouchControls($('touch-controls'),()=>this.combatAudio.unlock());this.registry.set('touch',this.touch);this.registry.set('audio',this.combatAudio);this.registry.set('ui',ui);$('toggle-touch').setAttribute('aria-pressed',String(document.body.classList.contains('touch-mode')));
  this.keys=this.input.keyboard.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT,SHIFT,J,K,G,L,H,R,B,ENTER,ESC,F2');this.pressed=new Set();
  this.input.keyboard.on('keydown',e=>{if(!e.repeat)this.pressed.add(e.code);if(!this.combatAudio.context)this.combatAudio.unlock();});this.input.keyboard.addCapture(['UP','DOWN','LEFT','RIGHT','SPACE','F2']);
  this.game.events.on('blur',()=>{if(this.scene.isActive()&&this.mode==='playing')this.changeMode('paused');this.input.keyboard.resetKeys();this.pressed.clear();});this.events.on('wake',()=>{if(this.mode==='playing')this.changeMode('paused');});
  document.addEventListener('visibilitychange',()=>{const s=active();if(document.hidden&&s?.mode==='playing')s.changeMode('paused');});
  $('blood').onclick=()=>{this.blood.enabled=!this.blood.enabled;$('blood').setAttribute('aria-pressed',String(this.blood.enabled));$('blood').textContent=this.blood.enabled?'Sangue: sim':'Sangue: não';ui.game.focus({preventScroll:true});};
  $('audio').onclick=()=>{this.combatAudio.enabled=!this.combatAudio.enabled;if(this.combatAudio.enabled)this.combatAudio.unlock();$('audio').setAttribute('aria-pressed',String(this.combatAudio.enabled));$('audio').textContent=this.combatAudio.enabled?'Som: sim':'Som: não';ui.game.focus({preventScroll:true});};
  $('touch-pause').onclick=()=>active().toggle();$('toggle-touch').onclick=()=>{document.body.classList.toggle('touch-mode');$('toggle-touch').setAttribute('aria-pressed',String(document.body.classList.contains('touch-mode')));this.touch.clear();requestAnimationFrame(fit);};
  ui.play.onclick=()=>{active().toggle();ui.game.focus({preventScroll:true});};ui.reset.onclick=()=>{active().restart();ui.game.focus({preventScroll:true});};ui.debug.onclick=()=>{const s=active();s.debugVisible=!s.debugVisible;ui.debug.setAttribute('aria-pressed',String(s.debugVisible));ui.game.focus({preventScroll:true});};
  ui.mode.onchange=()=>{const duel=ui.mode.value==='duel',from=active();from.changeMode(from.mode==='playing'?'paused':from.mode);current=duel?'Duel':'Corridor';const sm=this.game.scene;if(duel){sm.sleep('Corridor');sm.run('Duel');}else{sm.sleep('Duel');sm.run('Corridor');}ui.training.disabled=duel;$('miguel-pose').disabled=duel;ui.debug.setAttribute('aria-pressed','false');for(const s of game.scene.getScenes(false))s.debugVisible=false;ui.game.focus({preventScroll:true});};ui.training.onchange=()=>{this.model.setMode(ui.training.value);ui.game.focus({preventScroll:true});};
  this.renderWorld(0);this.paintHud();this.paintOverlay();$('loading').remove();
  window.gaviao={game:this.game,duel:()=>game.scene.getScene('Duel')?.model?.snapshot(),scene:()=>active()?.scene.key,snapshot:()=>({version:BUILD_VERSION,touch:this.touch.held(),sprite:{frame:this.sorriso.frame.name,flip:this.sorriso.flipX},mode:this.mode,debug:this.debugVisible,miguel:this.miguel.snapshot(),player:{...this.model.player},enemies:this.model.enemies.map(d=>({...d,ragdoll:d.ragdoll?{nodes:d.ragdoll.nodes.map(n=>({...n})),age:d.ragdoll.age}:null})),target:this.model.nearest?.id,combo:{...this.model.combo},lastHit:this.model.lastHit,attack:this.model.attackBox(),message:this.model.message,fps:this.game.loop.actualFps,renderer:this.game.renderer.type,canvas:[this.game.canvas.width,this.game.canvas.height]})};
 }
 changeMode(mode){this.mode=mode;this.stepper?.reset();this.input.keyboard.resetKeys();this.pressed?.clear();this.touch?.clear();ui.play.textContent=mode==='playing'?'Pausar':mode==='title'?'Jogar':mode==='dead'?'Tentar de novo':'Continuar';this.paintOverlay();}
 toggle(){this.combatAudio?.unlock();if(this.mode==='dead')this.restart();else this.changeMode(this.mode==='playing'?'paused':'playing');}
 restart(){this.miguel.setPose($('miguel-pose').value);this.model.reset();this.model.setMode(ui.training.value);this.blood.reset();this.lastBloodHit=null;this.cameraPosition=0;this.changeMode('playing');this.renderWorld(0);this.paintHud();}
 update(time,delta){
  if(!this.model)return;const touch=this.touch.read(),pressed=this.pressed;this.pressed=new Set();const tap=key=>pressed.has(key);
  if(tap('F2')){this.debugVisible=!this.debugVisible;ui.debug.setAttribute('aria-pressed',String(this.debugVisible));}
  if(tap('KeyR'))this.restart();
  if(tap('KeyB'))$('blood').click();
  if((tap('Enter')&&!['BUTTON','SELECT'].includes(document.activeElement?.tagName))||tap('Escape'))this.toggle();
  if(this.mode==='playing'){
   if(tap('KeyH'))this.model.hurt();
   // Passo fixo: mesmo resultado a 30, 60 ou 144 FPS; pulsos esperam o próximo tick.
   this.stepper.advance(delta,{left:touch.left||this.keys.A.isDown||this.keys.LEFT.isDown,right:touch.right||this.keys.D.isDown||this.keys.RIGHT.isDown,up:touch.up||this.keys.W.isDown||this.keys.UP.isDown,down:touch.down||this.keys.S.isDown||this.keys.DOWN.isDown,run:touch.run||this.keys.SHIFT.isDown,guard:touch.guard||this.keys.L.isDown,attack:touch.attack||tap('KeyJ'),kick:touch.kick||tap('KeyK'),grab:touch.grab||tap('KeyG')},(input,dt)=>{const p=this.model.player;this.prev={x:p.x,y:p.y,enemies:this.model.enemies.map(d=>d.x)};this.model.step(input,dt);});
   const hit=this.model.lastHit;if(hit&&hit!==this.lastBloodHit){this.lastBloodHit=hit;this.blood.emit(hit,this.model.enemies.find(d=>d.id===hit.target)?.y||146);}this.blood.step(delta);this.combatAudio.update(this.model);
   if(this.model.player.hp<=0)this.changeMode('dead');
  }
  const stateMessage=this.model.player.state==='attackRecover'?'Recuperando o apoio.':this.model.player.state==='winded'?'Sem fôlego. Espere recuperar.':this.model.player.state==='gettingUp'?'Levantando.':this.model.message;
  const message=this.mode==='paused'?'Pausado. Toque em Continuar.':this.mode==='title'?'Toque em Jogar para entrar.':stateMessage;if(ui.status.textContent!==message)ui.status.textContent=message;
  this.renderWorld(delta);this.hudClock+=delta;if(this.hudClock>=90){this.paintHud();this.hudClock=0;}
 }
 renderWorld(delta){
  this.miguel.render(this.mode==='playing'?delta:0);
  const p=this.model.player,a=this.mode==='playing'&&this.model.hitstop<=0&&this.prev?this.stepper.alpha:1,px=this.prev?lerp(this.prev.x,p.x,a):p.x,py=this.prev?lerp(this.prev.y,p.y,a):p.y;this.sorriso.setPosition(Math.round(px+(p.visualOffsetX||0)),Math.round(py-(p.fallHeight||0))).setFrame(spriteFrame(p,this.clips,this.model.moves)).setFlipX(spriteFlip(p)).setDepth(p.y+0.6).setAlpha(p.invulnerable>0&&Math.floor(p.invulnerable/70)%2===0?.5:1);this.shadow.setPosition(Math.round(px),Math.round(py)).setDepth(p.y-1);
  this.bars.clear();this.effects.clear();this.debugLayer.clear();
  for(let i=0;i<this.model.enemies.length;i++){
   const d=this.model.enemies[i],view=this.enemyViews[i];const dx=this.prev&&d.state!=='fallen'?lerp(this.prev.enemies[i],d.x,a):d.x;view.view.render(this.model,d,dx);view.shadow.setPosition(Math.round(dx),d.y).setDepth(d.y-1);
   const pose=this.model.pose(d),top=Math.min(...pose.slice(0,3).map(n=>n.y))-20,colors=[0xcab47a,0xa3b180,0x87aeb0,0xb39d80],names=['head','body','arms','legs'],max=[70,80,60,60];
   for(let j=0;j<4;j++){this.bars.fillStyle(0x1a2924);this.bars.fillRect(Math.round(d.x)-15,Math.round(top)+j*3,30,2);this.bars.fillStyle(colors[j]);this.bars.fillRect(Math.round(d.x)-15,Math.round(top)+j*3,Math.round(30*d.parts[names[j]]/max[j]),2);}
   if(this.debugVisible){const boxes=this.model.hurtboxes(d);for(const[name,b]of Object.entries(boxes)){this.debugLayer.lineStyle(1,name==='head'?0xd5ba79:0x88bdc0);this.debugLayer.strokeRect(Math.round(b.x),Math.round(b.y),b.w,b.h);}if(d.guard){this.debugLayer.lineStyle(1,0xb9cc8c);this.debugLayer.strokeRect(d.x+d.facing*11-5,d.y-53,10,33);}if(d.ragdoll&&d.state==='fallen'){this.debugLayer.lineStyle(1,0xaaa47c);for(const l of d.ragdoll.links){const a=pose[l.a],b=pose[l.b];this.debugLayer.lineBetween(a.x,a.y,b.x,b.y);}}}
  }
  const hit=this.model.lastHit;if(hit&&this.model.clock-hit.at<90){const{point}=hit;this.effects.lineStyle(1,hit.blocked?0xaecb8c:0xe0c795);this.effects.lineBetween(point.x-3,point.y-3,point.x+3,point.y+3);this.effects.lineBetween(point.x+3,point.y-3,point.x-3,point.y+3);}
  this.blood.render(this.effects);
  this.blood.renderHands(this.effects,p,spriteMeta(p,this.clips,this.model.moves),this.model.clock);
  if(p.counterUntil>this.model.clock){this.effects.lineStyle(1,0xc3c9a2,.9);this.effects.strokeCircle(p.x,p.y-53,4);}
  if(this.debugVisible){const a=this.model.attackBox();if(a){this.debugLayer.lineStyle(1,0xe39777);this.debugLayer.strokeRect(a.x,a.y,a.w,a.h);}const b=this.model.body();this.debugLayer.lineStyle(1,0x9cad8a);this.debugLayer.strokeRect(b.x,b.y,b.w,b.h);}
  const nearest=this.model.nearest,follow=nearest?.state==='fallen'&&Math.abs(nearest.x-p.x)<180?(p.x+nearest.x)/2-160:p.x-120,target=Phaser.Math.Clamp(follow,0,320);if(this.mode==='playing')this.cameraPosition+=(target-this.cameraPosition)*(1-Math.exp(-delta/85));this.cameras.main.scrollX=Math.round(this.cameraPosition);
 }
 paintHud(){
  const c=this.hudTexture.context,p=this.model.player,d=this.model.nearest;c.clearRect(0,0,320,28);c.fillStyle='#142321';c.fillRect(0,0,320,27);c.fillStyle='#8c956f';c.fillRect(0,26,320,1);
  lettering(c,'SORRISO',7,5,'#d8d5b7');for(let i=0;i<5;i++){c.fillStyle=i<p.hp?'#b3b878':'#394b3d';c.fillRect(7+i*8,15,6,3);}
  if(d){lettering(c,'ALVO '+d.id,72,5,'#c7c4a1');for(const[label,key,x,max,color]of[['C','head',112,70,'#cab47a'],['T','body',146,80,'#a3b180'],['B','arms',180,60,'#87aeb0'],['P','legs',214,60,'#b39d80']]){lettering(c,label,x,5,color);c.fillStyle='#354438';c.fillRect(x+6,5,24,4);c.fillStyle=color;c.fillRect(x+6,5,Math.round(24*d.parts[key]/max),4);}}
  c.fillStyle='#354438';c.fillRect(7,21,38,2);c.fillStyle=p.stamina<24?'#a97560':'#91a17b';c.fillRect(7,21,Math.round(38*p.stamina/100),2);
  lettering(c,'SEQ '+this.model.combo.hits,72,16,'#acb899');const action=p.state==='attack'||p.state==='knee'?this.model.moves[p.move].name:p.state==='clinchEntry'?'ABRINDO GUARDA':p.state==='clinch'?'CLINCH '+p.strikes:p.state==='parry'||p.counterUntil>this.model.clock?'APARO > J':p.state==='wipe'?'LIMPANDO A MAO':p.state==='brake'?'FREANDO':p.state==='stumble'?'DESEQUILIBRIO':'MELHOR '+this.model.combo.best;lettering(c,action.slice(0,24),108,16,'#d1bd85');lettering(c,'FPS '+Math.round(this.game.loop.actualFps||0),269,5,'#c1c7a7');lettering(c,'CANVAS',269,16,'#82947e');this.hudTexture.refresh();
  if(p.grabbed){c.fillStyle='#3e4a38';c.fillRect(243,16,18,3);c.fillStyle='#c7af71';c.fillRect(243,16,Math.round(18*Math.min(1,p.grip/CLINCH.maxGrip)),3);this.hudTexture.refresh();}
  const n=this.noteTexture.context;n.clearRect(0,0,320,11);n.fillStyle='#182922';n.fillRect(0,0,320,11);lettering(n,document.body.classList.contains('touch-mode')?'MOVA E ATAQUE COM DOIS DEDOS':'J: SOCO  K: CHUTE  G: CLINCH  L: DEFESA',7,3,'#a3ae90');this.noteTexture.refresh();
 }
 paintOverlay(){const c=this.overlayTexture.context;c.clearRect(0,0,320,180);if(this.mode!=='playing'){c.fillStyle='rgba(12,23,21,.86)';c.fillRect(0,28,320,141);lettering(c,this.mode==='title'?'DEPOIS DO SINAL':this.mode==='dead'?'FIM DO EXPEDIENTE':'PAUSADO',28,65,'#ded8b3',2);lettering(c,this.mode==='title'?'CORPO > CABECA > DESEQUILIBRIO':this.mode==='dead'?'R PARA RECOMECAR':'CONTINUAR PARA VOLTAR',28,92,'#c1c5a1');if(this.mode==='title'){lettering(c,'J: SOCO  K: CHUTE  G: CLINCH',28,110,'#9fae90');lettering(c,'> TOQUE EM JOGAR',28,134,'#c7b376');}}this.overlayTexture.refresh();}
}
function fit(){const host=$('viewport'),touch=document.body.classList.contains('touch-mode'),header=document.querySelector('header').getBoundingClientRect().height,toolbar=document.querySelector('.toolbar').getBoundingClientRect().height,side=innerWidth/innerHeight>1.2,available=touch?Math.max(120,innerHeight-header-toolbar-(side?35:195)):Math.max(180,innerHeight-235),raw=Math.min(6,host.clientWidth/320,available/180),zoom=touch?Math.max(.75,raw):Math.max(1,Math.floor(raw));const width=Math.floor(320*zoom),height=Math.floor(180*zoom);ui.game.style.width=width+'px';ui.game.style.height=height+'px';host.style.height=height+2+'px';const c=ui.game.querySelector('canvas');if(c){c.style.width=width+'px';c.style.height=height+'px';}}
document.body.classList.toggle('touch-mode',matchMedia('(pointer:coarse)').matches||navigator.maxTouchPoints>0||innerWidth<700);
window.addEventListener('error',()=>{if($('loading'))$('loading').textContent='Erro ao abrir. Use INICIAR.cmd e consulte o README.';});
game=new Phaser.Game({type:Phaser.CANVAS,width:320,height:180,parent:'game',backgroundColor:'#152822',pixelArt:true,roundPixels:true,antialias:false,antialiasGL:false,banner:false,audio:{noAudio:true},fps:{target:60,smoothStep:false},scale:{mode:Phaser.Scale.NONE,width:320,height:180},scene:[Corridor,DuelScene],callbacks:{postBoot:()=>requestAnimationFrame(fit)}});window.addEventListener('resize',fit);fit();
