// Cenário escolar e fonte provisórios. Personagens são desenhados em módulos próprios.
const GLYPHS={A:'010101111101101',B:'110101110101110',C:'011100100100011',D:'110101101101110',E:'111100110100111',F:'111100110100100',G:'011100101101011',H:'101101111101101',I:'111010010010111',J:'001001001101010',K:'101101110101101',L:'100100100100111',M:'101111111101101',N:'101111111111101',O:'010101101101010',P:'110101110100100',Q:'010101101111011',R:'110101110101101',S:'011100010001110',T:'111010010010010',U:'101101101101111',V:'101101101101010',W:'101101111111101',X:'101101010101101',Y:'101101010010010',Z:'111001010100111','0':'111101101101111','1':'010110010010111','2':'110001010100111','3':'110001010001110','4':'101101111001001','5':'111100110001110','6':'011100111101111','7':'111001010010010','8':'111101111101111','9':'111101111001110',':':'000010000010000','.':'000000000000010','/':'001001010100100','-':'000000111000000','!':'010010010000010','?':'110001010000010','+':'000010111010000','(':'010100100100010',')':'010001001001010','>':'100010001010100'};
export function lettering(ctx,text,x,y,color='#d1d0ad',scale=1) {
  ctx.fillStyle=color;
  const clean=String(text).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toUpperCase();
  for(let i=0;i<clean.length;i++) {const glyph=GLYPHS[clean[i]];if(!glyph)continue;for(let n=0;n<15;n++)if(glyph[n]==='1')ctx.fillRect(x+(i*4+n%3)*scale,y+Math.floor(n/3)*scale,scale,scale);}
}
function canvas(w,h){const c=document.createElement('canvas');c.width=w;c.height=h;return [c,c.getContext('2d')];}
function rect(c,color,x,y,w,h){c.fillStyle=color;c.fillRect(x,y,w,h);}
export function createArt(scene) {
  const [bg,b]=canvas(640,180);
  rect(b,'#252f30',0,0,640,180);rect(b,'#4f584a',0,24,640,64);rect(b,'#35493e',0,88,640,31);
  rect(b,'#8a8e6d',0,86,640,2);rect(b,'#202e2a',0,117,640,6);
  // Faixa de janelas: céu pesado, prédios, travessas e vidro sujo.
  for(let x=16;x<640;x+=160){
    rect(b,'#1d2b2c',x,34,112,47);rect(b,'#7c8b7c',x+3,37,106,40);rect(b,'#929b84',x+4,38,104,13);
    for(let n=0;n<8;n++){const h=9+(n*11)%19;rect(b,'#5e7268',x+4+n*13,77-h,12,h);rect(b,'#879381',x+7+n*13,81-h,2,2);}
    rect(b,'#3c5047',x+3,69,106,8);rect(b,'#293d36',x+36,36,3,43);rect(b,'#293d36',x+73,36,3,43);rect(b,'#293d36',x+3,55,106,2);
    rect(b,'#9b9e7a',x-2,80,116,3);rect(b,'#273932',x,83,113,2);
    for(let n=0;n<7;n++)rect(b,'#778775',x+7+n*15,41+(n*7)%27,1,6);
  }
  for(const x of [139,459]){
    rect(b,'#26342e',x,35,32,84);rect(b,'#637257',x+2,38,28,79);rect(b,'#394f42',x+5,44,22,36);rect(b,'#1b302c',x+7,46,18,32);
    rect(b,'#929779',x+25,87,2,4);rect(b,'#929577',x-2,27,36,7);lettering(b,x===139?'3 - B':'3 - C',x+6,28,'#263a33');
  }
  // Mural e relógio parados: humor em objetos, sem pôster ilustrado.
  rect(b,'#202e28',282,43,30,32);rect(b,'#8b815e',284,45,26,28);rect(b,'#c2ba94',287,47,20,22);
  lettering(b,'AVISO',287,49,'#4c5845');lettering(b,'O SINAL',287,57,'#4c5845');lettering(b,'FALTOU',287,63,'#4c5845');
  rect(b,'#29392f',263,35,11,11);rect(b,'#b1b497',264,36,9,9);rect(b,'#475848',268,38,1,4);rect(b,'#475848',268,41,3,1);
  // Piso de granilite, perspectiva estática e marcas determinísticas.
  rect(b,'#576055',0,123,640,57);
  for(const y of [125,138,155,177])rect(b,'#3c4b43',0,y,640,1);
  for(let x=-100;x<700;x+=42)for(let y=123;y<180;y++)rect(b,'#414e44',Math.round(x+25*(180-y)/57),y,1,1);
  for(let n=0;n<750;n++){const x=(n*73+11)%640,y=125+(n*31)%54;rect(b,n%3?'#646c59':'#455347',x,y,1,1);}
  // Mochila esquecida e balde, fora da faixa de caminhada.
  rect(b,'#202d2b',46,111,11,9);rect(b,'#475447',48,108,7,11);rect(b,'#7d8061',49,111,5,1);
  rect(b,'#2c3d35',389,110,10,10);rect(b,'#7b8570',389,110,10,2);rect(b,'#546550',391,113,6,6);
  // Desgaste controlado, sem filtros em tempo real.
  for(let n=0;n<100;n++)rect(b,'#455343',(n*97)%640,91+(n*11)%24,1+(n%4),1);
  for(const x of [0,318,638])rect(b,'#263a32',x,26,2,95);
  scene.textures.addCanvas('hallway',bg);
}
