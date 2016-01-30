
extends Camera2D

func update_labels(target_pos):
	get_node("playerPos").set_text(var2str(target_pos))
	get_node("cameraPos").set_text(var2str(get_pos()))

func _ready():
	# Initialization here
	pass


