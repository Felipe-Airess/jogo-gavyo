// Arte do alvo continua procedural; os membros acompanham os pontos físicos.
export class DummyView{
  constructor(scene){
    this.scene=scene;this.parts={};
    const make=(key,w,h,draw)=>{if(scene.textures.exists(key))return;const c=document.createElement('canvas');c.width=w;c.height=h;draw(c.getContext('2d'));const t=scene.textures.addCanvas(key,c);t.setFilter(Phaser.Textures.FilterMode.NEAREST);};
    const r=(c,color,x,y,w,h)=>{c.fillStyle=color;c.fillRect(x,y,w,h);};
    make('target-head',16,16,c=>{r(c,'#27342d',0,0,16,16);r(c,'#b3a57d',1,1,14,14);r(c,'#c5b78c',2,2,12,10);r(c,'#66644b',7,1,1,14);r(c,'#3f4638',3,5,3,2);r(c,'#3f4638',10,5,3,2);r(c,'#656049',5,11,6,1);});
    make('target-torso',18,19,c=>{r(c,'#29392e',0,0,18,19);r(c,'#78846a',1,1,16,17);r(c,'#a3a789',2,2,14,8);r(c,'#d0c69b',2,5,14,5);for(let i=0;i<3;i++)r(c,'#565f48',4+i*4,6,2,3);r(c,'#596b54',1,12,16,6);});
    make('target-limb',6,12,c=>{r(c,'#303c31',0,0,6,12);r(c,'#a2956d',1,1,4,10);r(c,'#c1b187',2,1,2,8);r(c,'#6a7257',1,9,4,2);});
    make('target-shoe',10,4,c=>{r(c,'#26382e',0,0,10,4);r(c,'#8b8566',1,0,8,2);});
    for(const name of['upperL','lowerL','upperR','lowerR','thighL','shinL','thighR','shinR'])this.parts[name]=scene.add.image(0,0,'target-limb').setOrigin(0.5,0.12);
    this.parts.torso=scene.add.image(0,0,'target-torso').setOrigin(0.5,0.08);
    this.parts.head=scene.add.image(0,0,'target-head');
    this.parts.footL=scene.add.image(0,0,'target-shoe');this.parts.footR=scene.add.image(0,0,'target-shoe');
  }
  render(model,enemy=null){
    const d=enemy||model.dummy,n=enemy?model.pose(d):model.dummyPose(),parts=this.parts;
    const bone=(name,a,b,width,offset)=>{const dx=b.x-a.x,dy=b.y-a.y;parts[name].setPosition(Math.round(a.x),Math.round(a.y)).setDisplaySize(width,Math.hypot(dx,dy)+3).setRotation(Math.atan2(dy,dx)-Math.PI/2).setDepth(d.y+offset);};
    bone('upperL',{x:n[1].x-5,y:n[1].y+2},n[3],5,-0.7);bone('lowerL',n[3],n[4],5,-0.65);
    bone('thighL',{x:n[2].x-3,y:n[2].y},n[7],6,-0.6);bone('shinL',n[7],n[8],5,-0.5);
    bone('thighR',{x:n[2].x+3,y:n[2].y},n[9],6,-0.4);bone('shinR',n[9],n[10],5,-0.3);
    bone('torso',n[1],n[2],18,0);
    parts.head.setPosition(Math.round(n[0].x),Math.round(n[0].y)).setRotation(Math.atan2(n[1].y-n[0].y,n[1].x-n[0].x)-Math.PI/2).setDepth(d.y+0.1);
    bone('upperR',{x:n[1].x+5,y:n[1].y+2},n[5],5,0.2);bone('lowerR',n[5],n[6],5,0.3);
    parts.footL.setPosition(Math.round(n[8].x),Math.round(n[8].y)-1).setDepth(d.y+0.4);parts.footR.setPosition(Math.round(n[10].x),Math.round(n[10].y)-1).setDepth(d.y+0.5);
  }
}
