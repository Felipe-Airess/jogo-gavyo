import {MOVES} from './combat.mjs';
const mix=(a,b,t)=>a+(b-a)*t;
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const smooth=t=>{t=clamp(t,0,1);return t*t*(3-2*t);};
export const RIG=Object.freeze({spine:17,thigh:13,shin:12,upperNear:11,foreNear:11,upperFar:10,foreFar:11,maxLean:0.16,minElbow:0.1,maxElbow:2.3});
export function solveLimb(a,target,upper,lower,bend=1){
  const dx=target.x-a.x,dy=target.y-a.y,raw=Math.hypot(dx,dy),ux=raw>0.001?dx/raw:0,uy=raw>0.001?dy/raw:1;
  // Joelhos entre 4 e 140 graus de flexão: não dobram ao contrário nem colapsam.
  const min=Math.sqrt(upper*upper+lower*lower+2*upper*lower*Math.cos(140*Math.PI/180));
  const max=Math.sqrt(upper*upper+lower*lower+2*upper*lower*Math.cos(4*Math.PI/180));
  const d=clamp(raw,min,max),along=(upper*upper-lower*lower+d*d)/(2*d),height=Math.sqrt(Math.max(0,upper*upper-along*along));
  return{joint:{x:a.x+ux*along-uy*height*bend,y:a.y+uy*along+ux*height*bend},end:{x:a.x+ux*d,y:a.y+uy*d}};
}
function curve(elapsed,keys){for(let i=1;i<keys.length;i++)if(elapsed<=keys[i][0]){const[a,av]=keys[i-1],[b,bv]=keys[i];return mix(av,bv,smooth((elapsed-a)/(b-a)));}return keys.at(-1)[1];}
function power(elapsed,m){return curve(elapsed,[[0,0],[Math.max(10,m.activeStart-28),-0.12],[m.activeStart+6,1],[m.activeEnd-5,0.96],[m.duration,0]]);}
export function animationPose(p){
  const phase=p.gaitPhase||0,moving=p.state==='walk'||p.state==='run',running=p.state==='run';
  const pose={hipX:0,hipY:-28,torsoAngle:0,head:0,nearX:6,nearY:-4,farX:-5,farY:-4,nearPitch:0,farPitch:0,nearUpper:-0.6,nearElbow:-1.75,farUpper:-0.25,farElbow:-1.95};
  if(moving){
    const stance=running?0.4:0.5,cycle=running?52:28,stride=cycle*stance/2,lift=running?8:3.5;
    pose.hipY=running?-25.5:-26.5;pose.torsoAngle=running?0.10:0.025;
    const foot=angle=>{const u=((angle/(Math.PI*2))%1+1)%1;if(u<stance)return{x:stride-cycle*u,y:-4,pitch:0};const t=(u-stance)/(1-stance);return{x:-stride+2*stride*smooth(t),y:-4-Math.sin(t*Math.PI)*lift,pitch:-Math.sin(t*Math.PI)*0.18};};
    const near=foot(phase),far=foot(phase+Math.PI);pose.nearX=near.x;pose.farX=far.x;pose.nearY=near.y;pose.farY=far.y;pose.nearPitch=near.pitch;pose.farPitch=far.pitch;
    const swing=Math.cos(phase)*(running?0.62:0.34);
    pose.nearUpper=-0.12+swing;pose.farUpper=-0.12-swing;pose.nearElbow=pose.farElbow=running?-1.35:-0.38;
  }
  if(p.state==='attack'){
    const m=MOVES[p.move],q=power(p.elapsed,m),a=Math.max(0,q);
    // Apoio dos dois pés permanece estável nos socos. A potência vem da rotação.
    if(p.move==='jab'){pose.nearUpper=mix(-0.6,-1.42,a);pose.nearElbow=mix(-1.75,-0.13,a);pose.torsoAngle=q*0.055;}
    if(p.move==='cross'){pose.farUpper=mix(-0.25,-1.5,a);pose.farElbow=mix(-1.95,-0.12,a);pose.torsoAngle=q*0.11;pose.hipX=a*0.5;}
    if(p.move==='hook'){pose.nearUpper=mix(-0.6,-1.85,a);pose.nearElbow=mix(-1.75,-0.95,a);pose.torsoAngle=q*0.04;}
    if(p.move==='kick'){
      pose.nearX=curve(p.elapsed,[[0,6],[m.activeStart-25,9],[m.activeStart+10,27],[m.activeEnd,26],[280,9],[m.duration,6]]);
      pose.nearY=curve(p.elapsed,[[0,-4],[m.activeStart-25,-23],[m.activeStart+10,-29],[m.activeEnd,-28],[280,-22],[m.duration,-4]]);
      pose.torsoAngle=-a*0.1;pose.hipX=a;pose.farUpper=mix(-0.25,0.3,a);pose.farElbow=mix(-1.95,-0.8,a);
    }
    if(p.move==='dash'){pose.torsoAngle=q*0.15;pose.nearUpper=mix(-0.6,-1.32,a);pose.nearElbow=mix(-1.75,-0.3,a);}
    if(q<0){pose.nearUpper-=q*0.35;pose.farUpper-=q*0.2;}
  }
  if(p.state==='hurt'){const q=Math.sin(Math.min(1,p.elapsed/360)*Math.PI);pose.torsoAngle=-q*0.12;pose.head=-q*0.08;pose.nearUpper-=q*0.25;pose.nearElbow+=q*0.2;}
  pose.torsoAngle=clamp(pose.torsoAngle,-RIG.maxLean,RIG.maxLean);
  // A bacia baixa apenas o necessário para que o pé apoiado esteja ao alcance.
  for(const[x,y,offset]of[[pose.nearX,pose.nearY,2],[pose.farX,pose.farY,-2]]){const dx=x-(pose.hipX+offset);if(Math.abs(dx)<24.8)pose.hipY=Math.max(pose.hipY,y-Math.sqrt(24.8*24.8-dx*dx));}
  return pose;
}
export function jointsFor(pose){
  const angle=clamp(pose.torsoAngle,-RIG.maxLean,RIG.maxLean),cos=Math.cos(angle),sin=Math.sin(angle);
  const hip={x:pose.hipX,y:pose.hipY},neck={x:hip.x+sin*RIG.spine,y:hip.y-cos*RIG.spine};
  const nearHip={x:hip.x+2,y:hip.y},farHip={x:hip.x-2,y:hip.y};
  const nearLeg=solveLimb(nearHip,{x:pose.nearX,y:pose.nearY},13,12,-1),farLeg=solveLimb(farHip,{x:pose.farX,y:pose.farY},13,12,-1);
  const nearShoulder={x:neck.x-4*cos-2*sin,y:neck.y-4*sin+2*cos},farShoulder={x:neck.x+5*cos-2*sin,y:neck.y+5*sin+2*cos};
  // Braços usam ângulos anatômicos autorados. Sem IK livre cruzando o ombro.
  const arm=(shoulder,upper,elbow,l1,l2)=>{const a=clamp(upper,-2.05,0.6)+angle,b=a+clamp(elbow,-RIG.maxElbow,-RIG.minElbow);const joint={x:shoulder.x-Math.sin(a)*l1,y:shoulder.y+Math.cos(a)*l1};return{joint,end:{x:joint.x-Math.sin(b)*l2,y:joint.y+Math.cos(b)*l2}};};
  const nearArm=arm(nearShoulder,pose.nearUpper,pose.nearElbow,11,11),farArm=arm(farShoulder,pose.farUpper,pose.farElbow,10,11);
  return{hip,neck,nearHip,farHip,nearLeg,farLeg,nearShoulder,farShoulder,nearArm,farArm};
}
