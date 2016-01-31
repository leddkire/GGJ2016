
extends StaticBody2D

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	add_to_group("wall")
	add_to_group("absorbs_projectiles")

