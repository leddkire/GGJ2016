
extends Node

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	get_node("/root/global").goto_playable_scene("res://maps/0-0.tscn", null)
	get_node("/root/global").fade_in()


