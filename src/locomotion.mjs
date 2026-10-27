// O ciclo pertence à locomoção; avanços de ataques não mudam o pé da corrida.
export const GAIT={runStride:84,walkStride:40,runFrames:8,runTravel:[0,12,25,33,42,54,67,75]};
// Passadas medidas nos marcadores dos pés do lote 2 (scripts/extract-markers.py):
// o pé apoiado recua ~9,3 px por quadro na corrida (ciclo de 12 ≈ 112 px) e
// ~9,6 px na caminhada (ciclo de 8 ≈ 76 px). Com 84 e 40 o pé escorregava.
export const R2_STRIDE={run:112,walk:76};
// Tabela de avanço por quadro tirada dos marcadores: quanto o pé apoiado recua
// de um quadro para o seguinte. Os desenhos não avançam por igual (corrida:
// 4, 14, 10 px...), então distância→quadro segue a tabela, não uma divisão fixa.
// Quadros sem pé apoiado reconhecível usam a média dos medidos.
export function gaitTable(frames){
 const step=[];for(let i=0;i<frames.length;i++){const a=frames[i].feet.filter(p=>p.tipY>=-5),b=frames[(i+1)%frames.length].feet.filter(p=>p.tipY>=-5);let best=null;for(const p of a)for(const q of b){const dx=p.tipX-q.tipX;if(dx>=0&&dx<24&&(best===null||Math.abs(dx-9)<Math.abs(best-9)))best=dx;}step.push(best);}
 const known=step.filter(v=>v!==null),mean=known.length?known.reduce((a,b)=>a+b,0)/known.length:8,travel=step.map(v=>v??mean),start=[];let sum=0;for(const t of travel){start.push(sum);sum+=t;}
 return{start,stride:sum};
}
export function tableFrame(table,distance){const phase=((distance%table.stride)+table.stride)%table.stride;let i=table.start.length-1;while(i>0&&table.start[i]>phase)i--;return i;}
export function gaitFrame(p,clips=null){if(clips?.r2_run){const run=p.state==='run',count=clips[run?'r2_run':'r2_walk'].frames.length,distance=run?p.runDistance||0:p.walkDistance||0,stride=run?R2_STRIDE.run:R2_STRIDE.walk;return Math.floor((distance%stride)/stride*count)%count;}if(p.state==='run'){const phase=(p.runDistance||0)%GAIT.runStride;for(let i=GAIT.runFrames-1;i>=0;i--)if(phase>=GAIT.runTravel[i])return i;return 0;}return Math.floor(((p.walkDistance||0)%40)/40*9);}
export function updateGait(p,dx,dy,dt,clips){
 const moving=Math.hypot(dx,dy);p.gaitDistance=(p.gaitDistance||0)+moving;const key=p.state==='run'?'runDistance':'walkDistance';p[key]=(p[key]||0)+moving;
 // O ciclo de corrida começa no fim da arrancada, na mesma fase do contato.
 if(clips?.r2_run&&p.state==='run'&&(p.runStart||0)<280)p.runDistance=0;
 // Com a passada certa, o apoio vem do próprio desenho; o campo support do atlas
 // salta entre quadros e a correção antiga só produzia tremor.
 if(clips?.r2_run){p.plantedSide=null;p.visualOffsetX=(p.visualOffsetX||0)*Math.exp(-dt/55);return;}
 const running=p.state==='run',frame=gaitFrame(p,clips),modern=running?clips?.r2_run?.frames[frame]:null,support=modern?modern.supportSide:running?frame<2?0:frame>=4&&frame<6?1:null:null;
 const art=modern||(running?clips?.runV6?.frames[frame]:null),foot=art?.support;
 if(foot&&support!==null){
  if(p.plantedSide!==support||p.plantedFacing!==p.facing){p.plantX=p.x+p.facing*foot.x;p.plantedSide=support;p.plantedFacing=p.facing;}
  const desired=Math.max(-3,Math.min(3,p.plantX-p.x-p.facing*foot.x));
  p.visualOffsetX=(p.visualOffsetX||0)+Math.max(-dt*.035,Math.min(dt*.035,desired-(p.visualOffsetX||0)));
 }else{p.plantedSide=null;p.visualOffsetX=(p.visualOffsetX||0)*Math.exp(-dt/55);}
}
