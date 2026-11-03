"""[PROVISÓRIO] Pulso/drone local sem samples externos; Felipe fornecerá a trilha final."""
from pathlib import Path
import math
import struct
import wave

out = Path(__file__).resolve().parents[1] / 'capitulo1/assets/tensao_provisoria.wav'
rate = 22050
seconds = 8
frames = bytearray()
for i in range(rate * seconds):
    t = i / rate
    pulse = (0.5 + 0.5 * math.sin(2 * math.pi * t)) ** 6
    # Frequências inteiras: fechamento periódico em 8 s, sem salto no loop.
    signal = (0.07 + 0.12 * pulse) * math.sin(2 * math.pi * 55 * t)
    signal += 0.045 * math.sin(2 * math.pi * 83 * t) * (0.5 + 0.5 * math.cos(2 * math.pi * t / 8))
    frames += struct.pack('<h', round(signal * 32767))
with wave.open(str(out), 'wb') as stream:
    stream.setnchannels(1)
    stream.setsampwidth(2)
    stream.setframerate(rate)
    stream.writeframes(frames)
print(out)
