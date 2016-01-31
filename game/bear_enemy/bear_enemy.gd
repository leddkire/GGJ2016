
extends "res://basic_enemy/enemy.gd"

# member variables here, example:
# var a=2
# var b="textvav"

func _fixed_process(delta):
	basic_enemy_move(delta)	

func _ready():
	set_fixed_process(true)

