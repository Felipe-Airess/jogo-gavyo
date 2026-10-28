// Oracle used only at development time. The Godot game never executes JS rules.
import {resolveHit,applyHit,contactQuality} from '../../src/duel/damage.mjs';
import {commandFrom} from '../../src/core/command-buffer.mjs';
import {sweep} from '../../src/duel/collision.mjs';
import {CHARACTER_SPECS,createDuelMoves} from '../../src/duel/moves.mjs';
import {writeFileSync,mkdirSync,readFileSync} from 'node:fs';
const fixtures={damage:[],commands:[],sweeps:[],quality:[]};
fixtures.moves={};
for(const [character,source] of [['sorriso','sorriso-v70'],['miguel','miguel']]){
 const atlas=JSON.parse(readFileSync(new URL(`../../assets/${source}.json`,import.meta.url)));
 fixtures.moves[character]=createDuelMoves(Object.fromEntries(atlas.clips.map(c=>[c.id,c])),CHARACTER_SPECS[character]);
}
mkdirSync(new URL('../assets/full/',import.meta.url),{recursive:true});
writeFileSync(new URL('../assets/full/specs.json',import.meta.url),JSON.stringify(CHARACTER_SPECS));
for(let i=0;i<1200;i++){
 const move={damage:7+i%18,balance:8+i%24,cost:5+i%19,power:1+i%3,hitstun:300+i%221,blockstun:190,push:7};
 const defender={condition:{head:i%101,body:(i*7)%101,legs:(i*11)%101},balance:(i*13)%101,stamina:(i*17)%101};
 const zone=['head','body','legs'][i%3],options={blocked:i%7===0,counter:i%5===0,rocked:i%4===0,ground:i%11===0,quality:['normal','clean','graze'][Math.floor(i/3)%3],scale:[1,.85,.72][Math.floor(i/9)%3]};
 const result=resolveHit(move,defender,zone,options),after=structuredClone(defender);applyHit(after,result);
 fixtures.damage.push({move,defender,zone,options,result,after});
}
for(let mask=0;mask<256;mask++)for(const facing of [-1,1]){
 const keys=['left','right','up','down','run','attack','kick','grab'];
 const input=Object.fromEntries(keys.map((k,i)=>[k,!!(mask&(1<<i))]));fixtures.commands.push({input,facing,result:commandFrom(input,facing)});
}
for(let i=0;i<200;i++){
 const a={x:i%30-15,y:(i*7)%60-30},b={x:(i*13)%60-30,y:(i*11)%60-30},box={x:-5,y:-10,w:10,h:20};
 fixtures.sweeps.push({a,b,half:[3,3],box,result:sweep(a,b,3,3,box)});
}
for(const coverage of [null,0,.249,.25,.599,.6,1])fixtures.quality.push({coverage,result:contactQuality(coverage)});
mkdirSync(new URL('../tests/fixtures/',import.meta.url),{recursive:true});
writeFileSync(new URL('../tests/fixtures/parity.json',import.meta.url),JSON.stringify(fixtures));
console.log('Oracle: 1200 damage, 512 commands, 200 sweeps, 7 contact qualities');
