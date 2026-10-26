// 11 pontos com comprimentos fixos, gravidade e chão. Verlet a 120 Hz.
export const JOINT={head:0,neck:1,hip:2,leftElbow:3,leftHand:4,rightElbow:5,rightHand:6,leftKnee:7,leftFoot:8,rightKnee:9,rightFoot:10};
export const LINKS=[[0,1],[1,2],[0,2],[1,3],[3,4],[1,5],[5,6],[2,7],[7,8],[2,9],[9,10]];
export function standingPose(x,y,lean=0){return [[lean*1.3,-43],[lean,-33],[0,-18],[-9+lean,-27],[-12+lean,-18],[9+lean,-26],[12+lean,-16],[-5,-9],[-8,0],[5,-9],[8,0]].map(([dx,dy])=>({x:x+dx,y:y+dy}));}
export class Ragdoll{
  constructor(x,y,direction=1,speed=150,lift=130,initialPose=null){
    this.floor=y;this.accumulator=0;this.age=0;this.energy=0;const pose=initialPose||standingPose(x,y,direction*2);
    this.nodes=pose.map((p,i)=>{const vx=direction*(speed+(i===0?15:i===4||i===6?35:0)),vy=-lift+(i>=7?25:0);return{...p,px:p.x-vx/120,py:p.y-vy/120};});
    this.links=LINKS.map(([a,b])=>({a,b,length:Math.hypot(pose[b].x-pose[a].x,pose[b].y-pose[a].y)}));
  }
  impulse(direction,speed,lift){for(const n of this.nodes){n.px-=direction*speed/120;n.py+=lift/120;}}
  impulseAt(point,direction,speed,lift){for(const n of this.nodes){const d=Math.hypot(n.x-point.x,n.y-point.y),weight=Math.exp(-d*d/320);n.px-=direction*speed*weight/120;n.py+=lift*weight/120;}}
  step(milliseconds){this.accumulator+=Math.min(50,Math.max(0,milliseconds))/1000;while(this.accumulator>=1/120){this.integrate();this.accumulator-=1/120;this.age+=1000/120;}}
  integrate(){
    for(const n of this.nodes){const vx=(n.x-n.px)*0.996,vy=(n.y-n.py)*0.996;n.px=n.x;n.py=n.y;n.x+=vx;n.y+=vy+470/(120*120);}
    for(let iteration=0;iteration<7;iteration++){
      for(const{a,b,length}of this.links){const p=this.nodes[a],q=this.nodes[b],dx=q.x-p.x,dy=q.y-p.y,dist=Math.max(0.001,Math.hypot(dx,dy)),correction=(dist-length)/dist*0.5;p.x+=dx*correction;p.y+=dy*correction;q.x-=dx*correction;q.y-=dy*correction;}
      for(let i=0;i<this.nodes.length;i++){const n=this.nodes[i],radius=i===0?5:i===1?3:1;n.x=Math.max(17,Math.min(623,n.x));if(n.y>this.floor-radius){const vx=n.x-n.px,vy=n.y-n.py;n.y=this.floor-radius;n.px=n.x-vx*0.78;n.py=n.y+Math.max(0,vy)*0.12;}}
    }
    this.energy=this.nodes.reduce((sum,n)=>sum+Math.hypot(n.x-n.px,n.y-n.py),0)/this.nodes.length;
  }
  get center(){return this.nodes[2];}
}
