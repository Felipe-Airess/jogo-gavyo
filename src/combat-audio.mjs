// Sons curtos gerados localmente; sem arquivos externos ou pacote adicional.
export class CombatAudio{
 constructor(){this.enabled=true;this.context=null;this.lastEvent=null;this.lastStep=-1;}
 unlock(){if(!this.enabled)return;try{this.context??=new(window.AudioContext||window.webkitAudioContext)();this.context.resume().catch(()=>{});}catch{this.enabled=false;}}
 play(kind,strength=1){const c=this.context;if(!this.enabled||!c||c.state!=='running')return;
  const duration=kind==='parry'?.12:kind==='step'?.035:.085,buffer=c.createBuffer(1,Math.ceil(c.sampleRate*duration),c.sampleRate),data=buffer.getChannelData(0);
  for(let i=0;i<data.length;i++){const t=i/c.sampleRate,env=Math.pow(1-i/data.length,3),noise=Math.sin(i*127.1+Math.sin(i*.71)*317.7);data[i]=(noise*.65+Math.sin(t*(kind==='parry'?1800:kind==='step'?130:85)*Math.PI*2)*.35)*env;}
  const source=c.createBufferSource(),gain=c.createGain(),filter=c.createBiquadFilter();source.buffer=buffer;filter.type=kind==='parry'?'highpass':'lowpass';filter.frequency.value=kind==='parry'?850:kind==='guard'?950:kind==='step'?500:1800;gain.gain.value=(kind==='step'?.025:kind==='guard'?.045:.09)*strength;source.connect(filter);filter.connect(gain);gain.connect(c.destination);source.start();source.onended=()=>{source.disconnect();filter.disconnect();gain.disconnect();};
 }
 update(model){const e=model.lastEvent;if(e&&e!==this.lastEvent){this.lastEvent=e;this.play(e.type==='parry'?'parry':e.type==='block'?'guard':'hit',e.heavy?1.2:1);}
  const p=model.player,step=Math.floor((p.runDistance||0)/42);if(p.state==='run'&&step!==this.lastStep){this.lastStep=step;this.play('step');}
 }
}
