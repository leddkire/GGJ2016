
extends Node

var camera = null
var cam_target = null
var root = null
const CAM_OFFSET = -16
const CAM_HSTR = 3#4
const CAM_VSTR = 12#4
const CAM_CUTS = 12
var default_camera_pos = Vector2(0,0)

func _process(delta):
	if(cam_target == null):
		camera.set_pos(default_camera_pos)
	else:
		follow(cam_target)

func follow(target):
	var camera_pos = camera.get_global_pos()
	var target_pos = target.get_global_pos()
	var dist = target_pos - camera_pos
	dist = Vector2(round(dist.x),round(dist.y))
	var move = Vector2(dist.x/(CAM_HSTR +CAM_CUTS), dist.y/CAM_VSTR)
	if (abs(move.x) < 1):
		move.x = sign(move.x)
	if (abs(move.y) < 1):
		move.y = sign(move.y)
	if(dist.x != 0):
		camera_pos.x += move.x
	if(dist.y !=0):
		camera_pos.y += move.y

	#camera_pos.y = round(camera_pos.y)
	#camera_pos.x = round(camera_pos.x)
	camera.set_pos(camera_pos)
	camera.update_labels(target.get_pos())

func _ready():
	var _root=get_tree().get_root()
	root = _root.get_child(_root.get_child_count()-1)
	camera = root.get_node("mainCamera")
	camera.make_current()
	print(camera)
	set_process(true)
