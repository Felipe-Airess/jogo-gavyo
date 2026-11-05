from pathlib import Path
import json, math, urllib.parse, urllib.request
root=Path('arte/referencias/bola')
results=[]
for i,p in enumerate(sorted((root/'originais').glob('*.jpg'))):
 url='http://127.0.0.1:8767/analisar?'+urllib.parse.urlencode({'file':str(p.resolve())})
 with urllib.request.urlopen(url,timeout=180) as response: data=json.load(response)
 pts=data['landmarks']; row={'arquivo':p.name,'largura':data['width'],'altura':data['height'],'detectado':bool(pts),'landmarks':pts,'matrix':data['matrix']}
 if pts:
  m=data['matrix']; r=[[m[col*4+line] for col in range(3)] for line in range(3)]
  row['pose_graus']={'yaw':math.degrees(math.atan2(-r[2][0],math.hypot(r[0][0],r[1][0]))),'pitch':math.degrees(math.atan2(r[2][1],r[2][2])),'roll':math.degrees(math.atan2(r[1][0],r[0][0]))}
  eye=math.hypot(pts[263][0]-pts[33][0],pts[263][1]-pts[33][1]); row['olhos_px']=eye
  row['abertura_boca_relativa']=math.hypot(pts[13][0]-pts[14][0],pts[13][1]-pts[14][1])/max(eye,1)
  row['blendshapes']={s['categoryName']:s['score'] for s in data['blendshapes']}
 results.append(row)
 print(i+1,p.name,len(pts),row.get('pose_graus'),flush=True)
 (root/'mediapipe-triagem.json').write_text(json.dumps({'backend':'MediaPipe FaceLandmarker WebAssembly local, CPU; mesmo face_landmarker.task do pipeline','fotos':results},ensure_ascii=False,indent=1)+'\n')
