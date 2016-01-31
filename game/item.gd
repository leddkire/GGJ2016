
extends StaticBody2D

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	pass

func get_texture_name():
	return get_node("Sprite").get_texture().get_name()
