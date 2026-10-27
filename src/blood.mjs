// Efeito gráfico limitado, sem textura, shaders ou simulação pesada.
export class Blood{
 // Limites por cena: o corredor mantém 48 gotas/24 manchas; o duelo pede mais.
 constructor({particles=48,marks=24,markLife=6500,palette=null}={}){this.enabled=true;this.palette=palette;this.maxParticles=particles;this.maxMarks=marks;this.markLife=markLife;this.reset();}
 reset(){this.particles=[];this.marks=[];this.seen=0;}
 emit(hit,ground,scale=1){if(!this.enabled||hit.blocked||!hit.blood)return;const n=Math.round((hit.finisher?10:hit.zone==='head'?6:3)*scale);
  for(let i=0;i<n;i++){const a=(i*2.399+hit.id*.7),speed=18+(i*13)%37;this.particles.push({x:hit.point.x,y:hit.point.y,vx:Math.cos(a)*speed*(hit.dir?.6:1)+(hit.dir||0)*speed*.8,vy:-12-Math.abs(Math.sin(a))*45,ground:scale>1?ground+((i*5)%7)-3:ground,life:scale>1?1800:700,size:i%3===0&&scale>1?2:1});}
  if(this.particles.length>this.maxParticles)this.particles.splice(0,this.particles.length-this.maxParticles);
 }
 step(ms){const dt=Math.min(ms,50)/1000;for(const p of this.particles){p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=180*dt;p.life-=ms;if(p.y>=p.ground){this.marks.push({x:p.x,y:p.ground,life:this.markLife,w:p.size>1?4:3,h:p.size>1?2:1});p.life=0;}}this.particles=this.particles.filter(p=>p.life>0);for(const m of this.marks)m.life-=ms;this.marks=this.marks.filter(m=>m.life>0).slice(-this.maxMarks);}
 // Gota solta (sangramento do rosto), sem espalhar.
 drip(x,y,ground){if(!this.enabled)return;this.particles.push({x,y,vx:0,vy:8,ground,life:1500,size:1});if(this.particles.length>this.maxParticles)this.particles.shift();}
 render(g){this.renderMarks(g);this.renderParticles(g);}
 renderMarks(g){if(!this.enabled)return;g.fillStyle(this.palette?.mark??0x653a34,.95);for(const m of this.marks)g.fillRect(Math.round(m.x)-1,Math.round(m.y),m.w||3,m.h||1);}
 renderParticles(g){if(!this.enabled)return;g.fillStyle(this.palette?.drop??0x9c5149);for(const p of this.particles)g.fillRect(Math.round(p.x),Math.round(p.y),p.size||1,p.size||1);}
 renderHands(g,p,art,clock){if(!this.enabled||['rushFall','gettingUp'].includes(p.state))return;
  const f=p.facing,ox=p.x+(p.visualOffsetX||0),lead=art.fist||{x:11,y:-30},other=art.offHand||{x:2,y:-35},swap=p.activeHand==='left'&&['attack','attackRecover'].includes(p.state),right=swap?other:lead,left=swap?lead:other;
  for(const[side,point]of[['right',right],['left',left]]){const level=p.handBlood?.[side]||0;if(!level)continue;const x=Math.round(ox+point.x*f),y=Math.round(p.y+point.y);g.fillStyle(0x7f2425);g.fillRect(x-1,y-1,level>2?3:2,2);if(level>=2){g.fillStyle(0xb0443b);g.fillRect(x,y,1,1);if(p.state==='idle'&&clock%420<220)g.fillRect(x,y+3+Math.floor(clock%420/65),1,2);}}
 }
}
