import{animationPose,jointsFor}from'./animation.mjs';
const BONE_LENGTH={upperNear:11,foreNear:11,upperFar:10,foreFar:11,thighNear:13,thighFar:13,shinNear:12,shinFar:12};
export class CharacterAnimator{
  constructor(scene){
    this.scene=scene;this.texture=scene.textures.createCanvas('sorriso-animated',96,80);this.texture.setFilter(Phaser.Textures.FilterMode.NEAREST);
    this.texture.canvas.dataset.animation='sorriso';this.context=this.texture.context;this.context.imageSmoothingEnabled=false;this.parts=scene.textures.get('sorriso-rig');this.source=this.parts.getSourceImage();this.pose=null;this.transition=null;this.lastState=null;
    this.attachments={};
    const sourceCanvas=document.createElement('canvas');sourceCanvas.width=this.source.width;sourceCanvas.height=this.source.height;const sourceContext=sourceCanvas.getContext('2d');sourceContext.drawImage(this.source,0,0);const pixels=sourceContext.getImageData(0,0,sourceCanvas.width,sourceCanvas.height).data;
    for(const[name,length]of Object.entries(BONE_LENGTH)){
      const f=this.parts.get(name),rows=[];
      for(let y=0;y<f.cutHeight;y++){let sum=0,count=0;for(let x=0;x<f.cutWidth;x++){const alpha=pixels[((f.cutY+y)*sourceCanvas.width+f.cutX+x)*4+3];if(alpha>128){sum+=x+0.5;count++;}}if(count>=2)rows.push({x:sum/count,y:y+0.5});}
      const a=rows[0],b=rows.at(-1),dx=b.x-a.x,dy=b.y-a.y;
      this.attachments[name]={a,angle:Math.atan2(dy,dx),scale:length/Math.hypot(dx,dy)};
    }
  }
  drawPart(name,x,y,angle=0,ox=0.5,oy=0.1,width,height){
    const f=this.parts.get(name),c=this.context,w=width||f.width,h=height||f.height;
    c.save();c.translate(Math.round(48+x),Math.round(74+y));c.rotate(angle);c.drawImage(this.source,f.cutX,f.cutY,f.cutWidth,f.cutHeight,-ox*w,-oy*h,w,h);c.restore();
  }
  bone(name,a,b){
    const f=this.parts.get(name),attachment=this.attachments[name],c=this.context;
    // A mesma escala uniforme em todos os quadros. Pivôs seguem as pontas reais
    // do recorte, inclusive quando a peça original é ligeiramente inclinada.
    c.save();c.translate(Math.round(48+a.x),Math.round(74+a.y));c.rotate(Math.atan2(b.y-a.y,b.x-a.x)-attachment.angle);
    const s=attachment.scale;c.drawImage(this.source,f.cutX,f.cutY,f.cutWidth,f.cutHeight,-attachment.a.x*s,-attachment.a.y*s,f.cutWidth*s,f.cutHeight*s);c.restore();
  }
  render(player,delta,frozen=false){
    if(frozen&&this.pose)return;
    const desired=animationPose(player);
    const state=player.state==='attack'?'attack:'+player.move:player.state;
    if(!this.pose){this.pose={...desired};this.transition=null;this.lastState=state;}
    else if(state!==this.lastState){this.transition={from:{...this.pose},elapsed:0,duration:player.state==='attack'?32:90};this.lastState=state;}
    if(this.transition){
      this.transition.elapsed+=Math.min(delta,50);const t=Math.min(1,this.transition.elapsed/this.transition.duration),blend=t*t*(3-2*t);
      for(const key of Object.keys(desired))this.pose[key]=this.transition.from[key]+(desired[key]-this.transition.from[key])*blend;
      if(t===1)this.transition=null;
    }else this.pose={...desired};
    const p=this.pose,j=jointsFor(p),c=this.context;c.clearRect(0,0,96,80);c.imageSmoothingEnabled=false;
    // Mesmo rosto e mesma roupa em todos os quadros; nenhuma troca de retrato.
    this.bone('thighFar',j.farHip,j.farLeg.joint);this.bone('shinFar',j.farLeg.joint,j.farLeg.end);this.drawPart('shoeFar',j.farLeg.end.x,j.farLeg.end.y,p.farPitch,0.3,0.25);
    this.bone('upperFar',j.farShoulder,j.farArm.joint);this.bone('foreFar',j.farArm.joint,j.farArm.end);
    this.bone('thighNear',j.nearHip,j.nearLeg.joint);this.bone('shinNear',j.nearLeg.joint,j.nearLeg.end);this.drawPart('shoeNear',j.nearLeg.end.x,j.nearLeg.end.y,p.nearPitch,0.3,0.25);
    const angle=Math.atan2(j.hip.y-j.neck.y,j.hip.x-j.neck.x)-Math.PI/2;
    this.drawPart('torso',j.neck.x,j.neck.y,angle,0.5,0.08);
    const neckAngle=p.torsoAngle;this.drawPart('head',j.neck.x+Math.cos(neckAngle)+Math.sin(neckAngle),j.neck.y+Math.sin(neckAngle)-Math.cos(neckAngle),neckAngle+p.head,0.5,0.94);
    this.bone('upperNear',j.nearShoulder,j.nearArm.joint);this.bone('foreNear',j.nearArm.joint,j.nearArm.end);
    this.texture.refresh();
  }
}
