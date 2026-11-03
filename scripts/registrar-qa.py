#!/usr/bin/env python3
"""Guarda somente os quadros/estados já publicados pela ponte do protótipo."""
import json, shutil, sys, time
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'work/prototipo-qa'
out=root/'revisao-v2'/sys.argv[1]
out.mkdir(parents=True,exist_ok=True)
end=time.monotonic()+float(sys.argv[2] if len(sys.argv)>2 else 12)
last=None
count=0
while time.monotonic()<end:
    frame=root/'frame.png'
    if frame.exists():
        stamp=frame.stat().st_mtime_ns
        if stamp!=last:
            last=stamp;count+=1
            shutil.copyfile(frame,out/f'{count:02d}.png')
            if (root/'state.json').exists():
                shutil.copyfile(root/'state.json',out/f'{count:02d}.json')
    time.sleep(.12)
print(f'QA_RECORD {count} frames -> {out}')
