
extends KinematicBody2D

var movSpd = 400
var vel = Vector2()

func _draw():
	draw_circle(Vector2(0,0),10.0,Color(55,240,0))

func _process(delta):
	update()

func _fixed_process(delta):
	var vel = Vector2()
	if(Input.is_action_pressed("ui_left")):
		vel.x -= movSpd
	if(Input.is_action_pressed("ui_right")):
		vel.x += movSpd
	if(Input.is_action_pressed("ui_up")):
		vel.y -= movSpd
	if(Input.is_action_pressed("ui_down")):
		vel.y += movSpd

	move(vel * delta)

func _ready():
	get_node("/root/camera/").cam_target = self
	set_fixed_process(true)
	set_process(true)