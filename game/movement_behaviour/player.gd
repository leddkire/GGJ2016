
extends KinematicBody2D

var gravity
var move_speed = 100
var velocity = Vector2()
var x_acc = 400

#The current direction the player is facing
#1 is right, -1 is left
var dir_facing 
var sprite_width

#Resources for actions
var repulsor_scn = load("res://repulsor/repulsor.tscn")
var repulsor_anim

var anim_player

#States for invoker abilities
var action_state= IDLE_ACTION
var IDLE_ACTION = 0
var REPULSOR_ACTION = 1
var SHOOT_ACTION =2
var block_facing = false


func process_movement(delta):	
	var motion = Vector2()
	var x_movement
	if(is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		var collider = get_collider()

		move(motion)
	else:
		velocity.y += gravity * delta

	if(Input.is_action_pressed("ui_left")):
		x_movement = - x_acc * delta
		velocity.x += x_movement
	elif(Input.is_action_pressed("ui_right")):
		x_movement = x_acc * delta 
		velocity.x += x_movement
	else:
		velocity.x = 0

	if(not block_facing and velocity.x != 0):
		dir_facing = sign(x_movement)

	velocity.x = round(velocity.x)
	if(abs(velocity.x) > 100):
		velocity.x = sign(velocity.x) * 100
	motion = velocity * delta
	motion = move(motion)

func _input(ev):
	idle_state_function(ev)

func idle_state_function(ev):
	if(ev.is_action_pressed("repulsor")):
		action_state = REPULSOR_ACTION
	if(ev.is_action_pressed("shoot")):
		pass

func _fixed_process(delta):
	process_movement(delta)
	if(not anim_player.is_playing()):
		if(action_state == REPULSOR_ACTION):
			perform_repulsion()
		if(action_state == SHOOT_ACTION):
			perform_shoot()
	set_scale(Vector2(sign(dir_facing),1))

func create_repulsor():
	print("performing repulsor")
	var repulsor_node = repulsor_scn.instance()	
	var repulsor_pos = Vector2(0,0)
	var last_dir_facing = 1
	repulsor_node.set_pos(repulsor_pos)
	add_child(repulsor_node)

func remove_repulsor():
	print("removing repulsor")
	var repulsor_node = get_node("repulsor")	
	repulsor_node.queue_free()
	action_state = IDLE_ACTION
	block_facing = false

func perform_repulsion():
	anim_player.play("repulsor")
	block_facing = true
		

func _ready():
	gravity = get_node("/root/globals").gravity
	sprite_width = get_node("Sprite").get_region_rect().size.x
	anim_player = get_node("AnimationPlayer")
	repulsor_anim = anim_player.get_animation("repulsor")
	action_state = IDLE_ACTION
	dir_facing = 1
	block_facing =false
	add_to_group("player")
	set_fixed_process(true)
	set_process_input(true)


