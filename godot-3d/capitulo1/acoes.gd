extends RefCounted
## Ações usam os clipes existentes. Não gera animação nem escreve pose de osso.
static func build(_actor: CharacterBody3D) -> AnimationLibrary:
 return load("res://capitulo1/animacoes/biblioteca.res")
