extends SceneTree
## Salva o kit modular como MeshLibrary (para abrir no editor do Godot e usar
## num GridMap à mão). O jogo monta o mesmo kit em memória (capitulo1/mapa/kit.gd);
## o teste do mapa confere que este arquivo está em dia.
## Uso: godot --headless --path godot-3d --script res://tools/gerar_kit.gd
const KIT=preload("res://capitulo1/mapa/kit.gd")
const SAIDA:="res://capitulo1/mapa/kit_blockout.meshlib"
func _initialize() -> void:
 var lib: MeshLibrary=KIT.construir()
 var erro:=ResourceSaver.save(lib,SAIDA)
 print("KIT ",SAIDA," itens=",lib.get_item_list().size()," erro=",erro)
 quit(0 if erro==OK else 1)
