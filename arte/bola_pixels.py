from PIL import Image
import sys,json,base64
im=Image.open(sys.argv[1]).convert('RGBA')
print(json.dumps({'width':im.width,'height':im.height,'data':base64.b64encode(im.tobytes()).decode()}))
