import fs from 'node:fs/promises';
import path from 'node:path';
import {Presentation,PresentationFile} from '@oai/artifact-tool';
import {FontLibrary} from '/Users/enzo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/node_modules/skia-canvas/lib/index.js';
const root='/Users/enzo/Desktop/cpu-8-bit';
const build=root+'/presentazione/.build';
FontLibrary.use('Caveat',[root+'/presentazione/fonts/Caveat.ttf']);
const data=JSON.parse(await fs.readFile(build+'/content.json','utf8'));
const p=Presentation.create({slideSize:{width:1600,height:900}});
const ink='#393832',soft='#5c584f',paper='#f7f3e8';
function shape(s,g,x,y,w,h,fill='none',stroke='none',weight=0,name='') {return s.shapes.add({geometry:g,name,position:{left:x,top:y,width:w,height:h},fill,line:{style:'solid',fill:stroke,width:weight}})}
function text(s,str,x,y,w,h,size=34,bold=false,color=ink,align='left') {const t=shape(s,'textbox',x,y,w,h);t.text=str;t.text.style={typeface:'Caveat',fontSize:size,bold,color,alignment:align,verticalAlignment:'top',insets:0,autoFit:'none',wrap:'none'};return t}
function line(s,x,y,w,h,color=ink,weight=1){return shape(s,'line',x,y,w,h,'none',color,weight)}
function num(s,n,x,y){shape(s,'ellipse',x,y,73,73,'none','#777268',1.8);text(s,String(n),x,y+3,73,65,53,false,ink,'center')}
function base(d,i){const s=p.slides.add();s.background.fill=paper;
for(let x=0;x<1600;x+=28)line(s,x,0,0,900,'#dce3df',.65);
for(let y=0;y<900;y+=28)line(s,0,y,1600,0,'#dce3df',.65);
line(s,132,0,0,900,'#cd9992',1.5);
for(const y of [152,450,748])shape(s,'ellipse',43,y,23,23,'#ddd9cf','#c4bfb2',.8);
text(s,'appunti / CPU 8-bit',192,60,650,40,26,false,soft);
text(s,d.label+' · progetto didattico',940,60,572,40,26,false,soft,'right');
text(s,'Serie didattica YouTube / CPU 8-bit',192,829,1000,40,22,false,soft);
text(s,`pag. ${i+1} / 9`,1370,829,145,40,22,false,soft,'right');
s.speakerNotes.text='Fonti: README.md; docs/isa.md; tools/assembler/README.md; tools/simulator-web/README.md del repository CPU 8-bit. Stile Graphite Notebook, beautiful-html-slides. Runtime HTML originale Zara Zhang, MIT. Font Caveat, SIL OFL 1.1.';
return s;}
for(const [i,d] of data.entries()){
const s=base(d,i);text(s,d.eyebrow,192,145,1280,42,28,false,soft);
if(d.layout==='cover'){
text(s,d.title,192,217,850,335,98,true);line(s,202,580,610,0,soft,2);
text(s,d.subtitle,192,607,850,140,33,false,soft);text(s,d.byline,192,756,850,50,29,false,soft);
// Editable conceptual diagram matching the HTML reference.
shape(s,'rect',1050,228,425,365,'none',soft,2);
text(s,'dentro la CPU',1080,245,365,45,32,false,soft,'center');
const nodes=[['registri',1080,315,170,82],['ALU',1280,315,155,82],['unità di\ncontrollo',1080,480,170,90],['memoria',1280,480,155,90]];
for(const [t,x,y,w,h] of nodes){shape(s,'rect',x,y,w,h,'none',soft,1.8);text(s,t,x+4,y+12,w-8,h-15,32,false,soft,'center');}
line(s,1067,438,390,0,soft,2);for(const x of [1165,1355]){line(s,x,397,0,41,soft,2);line(s,x,438,0,42,soft,2);}
text(s,'bus dati · 8 bit',1173,405,180,34,25,false,soft);text(s,'capire, costruendo.',1070,630,390,55,35,false,soft,'center');
}else if(d.layout==='closing'){
text(s,d.title,192,237,1250,300,92,true);text(s,d.subtitle,192,580,1230,145,34,false,soft);text(s,d.contact,192,743,1230,55,32);line(s,192,796,760,0,ink,1.3);
}else{
const two=d.title.includes('\n');text(s,d.title,192,201,1322,two?190:115,82,true);
const start=two?418:369;
if(d.layout==='agenda'){
for(const [j,item] of d.items.entries()){const x=192+(j%2)*690,y=start+Math.floor(j/2)*184;num(s,j+1,x,y);text(s,item.title,x+100,y+4,540,60,43,true);text(s,item.body,x+100,y+76,545,100,32,false,soft);}
}else if(d.layout==='process'){
for(const [j,item] of d.items.entries()){const x=192+j*336;num(s,j+1,x,start+15);text(s,item.title,x,start+124,290,65,38,true);text(s,item.body,x,start+203,295,135,31,false,soft);if(j<3)text(s,'⟶',x+252,start+15,75,65,52,false,soft);}
}else if(d.layout==='metrics'){
for(const [j,item] of d.items.entries()){const x=192+j*449;shape(s,'rect',x,start,419,310,'none','#777268',1.8);text(s,item.title,x+23,start+22,375,58,35,true);text(s,item.value,x+23,start+83,375,125,103,true);text(s,item.body,x+23,start+222,375,78,31,false,soft);}
}else if(d.layout==='three'){
for(const [j,item] of d.items.entries()){const x=192+j*449;line(s,x,start,406,0,soft,1.8);num(s,j+1,x+12,start+26);text(s,item.title,x+12,start+125,395,62,44,true);text(s,item.body,x+12,start+207,405,190,32,false,soft);}
}else if(d.layout==='code'){
shape(s,'rect',192,start,530,390,'none',soft,1.8);text(s,d.code,230,start+28,450,355,39);const a=d.items[0];text(s,a.title,797,start+28,690,95,63,true);text(s,a.body,797,start+145,720,192,33,false,soft);text(s,a.caption,797,start+339,720,85,28,false,soft);
}
if(d.caption.length)text(s,d.caption.join('\n'),192,d.layout==='metrics'?717:760,1322,83,26,false,soft);
}
}
await fs.mkdir(build+'/previews',{recursive:true});
await (await PresentationFile.exportPptx(p)).save(build+'/candidate.pptx');
for(const [i,s] of p.slides.items.entries()){
const blob=await p.export({slide:s,format:'png',scale:.75});await fs.writeFile(build+`/previews/slide-${i+1}.png`,new Uint8Array(await blob.arrayBuffer()));
}
const montage=await p.export({format:'webp',montage:true,scale:.25});await fs.writeFile(build+'/montage.webp',new Uint8Array(await montage.arrayBuffer()));
console.log('Exported draft and nine slide previews.');
const skill='/Users/enzo/.codex/plugins/cache/openai-primary-runtime/presentations/26.1011.11113/skills/presentations';
const {finalizePresentation}=await import(skill+'/container_tools/artifact_tool_utils.mjs');
const result=await finalizePresentation({workspaceDir:root,candidatePath:build+'/candidate.pptx',finalPath:root+'/presentazione/powerpoint/CPU-8-bit.pptx',pythonExecutable:'/Users/enzo/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3',integrityValidatorPath:skill+'/container_tools/inspect_presentation_package_integrity.py',layoutValidatorPath:skill+'/container_tools/inspect_presentation_layout_geometry.py',layoutArgs:['--expected-slide-size-emu','15240000,8572500','--validate-bullet-geometry','--validate-heading-fit'],explicitTotalSlideCount:9,requiredNativeTableOwnerSlides:[],requiredNativeChartOwnerSlides:[],fontPolicy:{basis:'design',families:['Caveat']},verifyArtifactToolImport:true,receiptPath:build+'/validation.json'});
console.log(JSON.stringify(result));
