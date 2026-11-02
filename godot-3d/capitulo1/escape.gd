extends RefCounted
## Estado do minigame. Não conhece atores, animações, HUD nem checkpoints.
const DIRECTIONS=[KEY_UP,KEY_RIGHT,KEY_DOWN,KEY_LEFT]
var random:=RandomNumberGenerator.new()
var attempts:=0
var sequence: Array[int]=[]
var cursor:=0
var limit:=3.0
var remaining:=0.0
var active:=false
func start() -> void:
 attempts+=1; cursor=0; sequence.clear()
 limit=maxf(1.5,3.0-.3*(attempts-1)); remaining=limit
 for i in mini(7,attempts+2): sequence.append(DIRECTIONS[random.randi_range(0,3)])
 active=true
static func direction(code: int) -> int:
 match code:
  KEY_W,KEY_UP: return KEY_UP
  KEY_D,KEY_RIGHT: return KEY_RIGHT
  KEY_S,KEY_DOWN: return KEY_DOWN
  KEY_A,KEY_LEFT: return KEY_LEFT
 return 0
## -1 falha, 0 em andamento/entrada alheia, 1 acerto completo.
func press(code: int) -> int:
 var arrow=direction(code)
 if not active or arrow==0: return 0
 if remaining<=0 or arrow!=sequence[cursor]: active=false; return -1
 cursor+=1
 if cursor==sequence.size(): active=false; return 1
 return 0
func tick(dt: float) -> bool:
 if not active: return false
 remaining=maxf(0,remaining-dt)
 if remaining>0: return false
 active=false; return true
func clear() -> void:
 active=false; cursor=0; sequence.clear(); remaining=0
