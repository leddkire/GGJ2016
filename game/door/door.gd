
extends Sprite

const player_class = preload("res://player.gd")

func _ready():
	# Initialization here
	pass


func _on_Area2D_body_enter( body ):
	if (body extends player_class):
		if get_node("/root/game_data").itemsQty != [1,2,1,3]:
			get_node("Label").set_text("You need more ingredients to complete the ritual!")
		else:
			get_node("/root/camera").cam_target= null
			var same_scn = get_node("/root/global").current_scene_path
			get_node("/root/global").goto_playable_scene("res://the_end/the_end.tscn",null)

func _on_Area2D_body_exit( body ):
	get_node("Label").set_text("")
