
extends Node2D

func _input(ev):
	if(ev.is_action_pressed("repulsor")):
		get_node("/root/game_data")._reset_items()
		var last_scn = get_node("/root/global").last_scene_path
		get_node("/root/global").goto_playable_scene(last_scn,null)

func _ready():
	set_process_input(true)


