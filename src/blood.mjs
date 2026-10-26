// Efeito gráfico limitado, sem textura, shaders ou simulação pesada.
export class Blood{
 constructor(){this.enabled=true;this.reset();}
 reset(){this.particles=[];this.marks=[];this.seen=0;}
 emit(hit,ground){if(!this.enabled||hit.blocked||!hit.blood)return;const n=hit.finisher?10:hit.zone==='head'?6:3;
  for(let i=0;i<n;i++){const a=(i*2.399+hit.id*.7),speed=18+(i*13)%37;this.particles.push({x:hit.point.x,y:hit.point.y,vx:Math.cos(a)*speed,vy:-12-Math.abs(Math.sin(a))*45,ground,life:700});}
  if(this.particles.length>48)this.particles.splice(0,this.particles.length-48);
 }
 step(ms){const dt=Math.min(ms,50)/1000;for(const p of this.particles){p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=180*dt;p.life-=ms;if(p.y>=p.ground){this.marks.push({x:p.x,y:p.ground,life:6500});p.life=0;}}this.particles=this.particles.filter(p=>p.life>0);for(const m of this.marks)m.life-=ms;this.marks=this.marks.filter(m=>m.life>0).slice(-24);}
 render(g){if(!this.enabled)return;g.fillStyle(0x653a34,.9);for(const m of this.marks)g.fillRect(Math.round(m.x)-1,Math.round(m.y),3,1);g.fillStyle(0x9c5149);for(const p of this.particles)g.fillRect(Math.round(p.x),Math.round(p.y),1,1);}
 renderHands(g,p,art,clock){if(!this.enabled||['rushFall','gettingUp'].includes(p.state))return;
  const f=p.facing,ox=p.x+(p.visualOffsetX||0),lead=art.fist||{x:11,y:-30},other=art.offHand||{x:2,y:-35},swap=p.activeHand==='left'&&['attack','attackRecover'].includes(p.state),right=swap?other:lead,left=swap?lead:other;
  for(const[side,point]of[['right',right],['left',left]]){const level=p.handBlood?.[side]||0;if(!level)continue;const x=Math.round(ox+point.x*f),y=Math.round(p.y+point.y);g.fillStyle(0x7f2425);g.fillRect(x-1,y-1,level>2?3:2,2);if(level>=2){g.fillStyle(0xb0443b);g.fillRect(x,y,1,1);if(p.state==='idle'&&clock%420<220)g.fillRect(x,y+3+Math.floor(clock%420/65),1,2);}}
 }
}
