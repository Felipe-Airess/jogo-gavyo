export class TouchState{
 constructor(){this.sources=new Map();this.pulses=new Set();}
 set(id,values){const before=this.held();this.sources.set(id,{...values});for(const key of['attack','kick','grab'])if(values[key]&&!before[key])this.pulses.add(key);}
 release(id){this.sources.delete(id);}
 held(){const out={};for(const s of this.sources.values())for(const[key,value]of Object.entries(s))if(value)out[key]=true;return out;}
 read(){const out=this.held();for(const k of['attack','kick','grab'])out[k]=this.pulses.has(k);this.pulses.clear();return out;}
 clear(){this.sources.clear();this.pulses.clear();}
}
// Captura é melhor esforço: se o navegador recusar, o toque ainda vale.
const capture=(el,id)=>{try{el.setPointerCapture(id);}catch{}};
export class TouchControls extends TouchState{
 constructor(root,onInteract=()=>{}){super();this.root=root;const pad=root.querySelector('#dpad');const move=e=>{const r=pad.getBoundingClientRect(),dx=(e.clientX-r.left)/r.width-.5,dy=(e.clientY-r.top)/r.height-.5;this.set(e.pointerId,{left:dx<-.16,right:dx>.16,up:dy<-.16,down:dy>.16});this.paint();};
 pad.addEventListener('pointerdown',e=>{e.preventDefault();onInteract();capture(pad,e.pointerId);move(e);});pad.addEventListener('pointermove',e=>{if(this.sources.has(e.pointerId))move(e);});
 for(const button of root.querySelectorAll('[data-action]')){button.addEventListener('pointerdown',e=>{e.preventDefault();onInteract();capture(button,e.pointerId);this.set(e.pointerId,{[button.dataset.action]:true});this.paint();});button.addEventListener('click',e=>e.preventDefault());}
 for(const type of['pointerup','pointercancel','lostpointercapture'])root.addEventListener(type,e=>{this.release(e.pointerId);this.paint();});window.addEventListener('blur',()=>this.clear());window.addEventListener('orientationchange',()=>this.clear());document.addEventListener('visibilitychange',()=>{if(document.hidden)this.clear();});
 }
 paint(){const held=this.held();for(const b of this.root.querySelectorAll('[data-action]'))b.classList.toggle('held',!!held[b.dataset.action]);for(const b of this.root.querySelectorAll('[data-dir]'))b.classList.toggle('held',!!held[b.dataset.dir]);}
 clear(){super.clear();if(this.root)this.paint();}
}
