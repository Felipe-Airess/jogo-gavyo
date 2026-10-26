// O ciclo pertence à locomoção; avanços de ataques não mudam o pé da corrida.
export const GAIT={runStride:84,walkStride:40,runFrames:8,runTravel:[0,12,25,33,42,54,67,75]};
export function gaitFrame(p){if(p.state==='run'){const phase=(p.runDistance||0)%GAIT.runStride;for(let i=GAIT.runFrames-1;i>=0;i--)if(phase>=GAIT.runTravel[i])return i;return 0;}return Math.floor(((p.walkDistance||0)%40)/40*9);}
export function updateGait(p,dx,dy,dt,clips){
 const moving=Math.hypot(dx,dy);p.gaitDistance=(p.gaitDistance||0)+moving;const key=p.state==='run'?'runDistance':'walkDistance';p[key]=(p[key]||0)+moving;
 const running=p.state==='run',frame=gaitFrame(p),support=running?frame<2?0:frame>=4&&frame<6?1:null:null;
 const art=running?clips?.runV6?.frames[frame]:null,foot=art?.support;
 if(foot&&support!==null){
  if(p.plantedSide!==support||p.plantedFacing!==p.facing){p.plantX=p.x+p.facing*foot.x;p.plantedSide=support;p.plantedFacing=p.facing;}
  const desired=Math.max(-3,Math.min(3,p.plantX-p.x-p.facing*foot.x));
  p.visualOffsetX=(p.visualOffsetX||0)+Math.max(-dt*.035,Math.min(dt*.035,desired-(p.visualOffsetX||0)));
 }else{p.plantedSide=null;p.visualOffsetX=(p.visualOffsetX||0)*Math.exp(-dt/55);}
}
