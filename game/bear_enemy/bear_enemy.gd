
extends KinematicBody2D

# member variables here, example:
# var a=2
# var b="textvav"

var StateObject = load("res://classes/StateObject.gd").StateObject

#Movement states
#Suffix MS
var NORMAL_MS = StateObject.new("normal","normal_ms",0,self)
func normal_ms():
	var gravityFactor =1
	var xSpeedFactor = 1
	var force = Vector2(0,GRAVITY*gravityFactor)
	if(sign(dir_facing) == -1):
		if(velocity.x > -WALK_MAX_SPEED * xSpeedFactor):
			force.x -= WALK_FORCE
	elif(sign(dir_facing) == 1):
		if( velocity.x < WALK_MAX_SPEED * xSpeedFactor):
			force.x += WALK_FORCE
	return force

var CHASING_MS = StateObject.new("chasing","chasing_ms",0,self)
func chasing_ms():	
	var gravityFactor =1
	var xSpeedFactor = 1
	var force = Vector2(0,GRAVITY*gravityFactor)
	if(target == null):
		current_state_ms = NORMAL_MS
		return force
	var dir = target.get_global_pos().x - get_pos().x
	if(sign(dir) == -1):
		if(velocity.x > -WALK_MAX_SPEED * xSpeedFactor):
			force.x -= WALK_FORCE
			dir_facing = dir
	elif(sign(dir) == 1):
		if(velocity.x < WALK_MAX_SPEED * xSpeedFactor):
			force.x += WALK_FORCE
			dir_facing = dir
	return force

var REPULSED_MS = StateObject.new("repulsed","repulsed_ms",1,self)
func repulsed_ms():	
	var gravityFactor =1
	var force = Vector2(0,GRAVITY*gravityFactor)
	var vsign = sign(velocity.x)
	var absv = abs(velocity.x)
	print(absv)
	if(absv < 0):
		velocity.x = 0
	else:
		force.x += - vsign * STOP_FORCE

	return force

#Animation states
#Suffix ANIM
var WALKING_ANIM = StateObject.new("walking","walking_anim",0,self)
func walking_anim():
	anim_player.play("walk")

var ATTACK_ANIM = StateObject.new("attack","attack_anim",1,self)
func attack_anim():
	anim_player.play("attack")
	block_anim_change = true

#Variables
#Animation-specific

var anim_player = null
var block_anim_change = false
var current_state_anim = WALKING_ANIM
var next_state_anim = WALKING_ANIM

#Movement-specific
var current_state_ms = NORMAL_MS
var dir_facing = 1
var siding_left = false
var velocity = Vector2(0,0)
var move_spd = 1200
var target
var target_near
var patience
var check_p
var stop = false

var GRAVITY =900.0
var WALK_MAX_SPEED = 50 
var WALK_FORCE = 1000
var STOP_FORCE = 250
#Called when the target has been eliminated

func clean_up():
	target = null



func update_labels():
	var dir_facing = get_node("direction_facing")
	var curr_state = get_node("current_state")
	dir_facing.set_text("Direction: " + var2str(dir_facing))
#	curr_state.set_text("Current State: " + var2str(state))
	#var base_scale = Vector2(1,1)
	#dir_facing.set_scale(base_scale)
	#curr_state.set_scale(base_scale)

func process_map_collisions():
	if(is_colliding()):

		var body = get_collider()
		var n = get_collision_normal()
		if(n.x != 0):
			dir_facing = n.x


func check_facing():
	var scale = get_scale()
	if(sign(dir_facing) == 1):
		set_scale(Vector2(1,scale.y))
	else:
		set_scale(Vector2(-1,scale.y))

#Process functions 



func process_movement(delta):
	
	var new_siding_left = siding_left
	#if(state==CHASING):
	#	var pos = get_pos()
	#	var target_pos = target.get_pos()
	#	var pos_diff = target_pos - pos
	#	facing_dir = sign(pos_diff.x)
	var force = current_state_ms.stateFunc.call_func()
	velocity += force*delta
	var motion = velocity*delta
	motion = move(motion)
	if(is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		move(motion)
	if(sign(dir_facing) == -1):
		new_siding_left = true
	else:
		new_siding_left = false
	if(new_siding_left != siding_left):
		if (new_siding_left):
			set_scale( Vector2(-1,1) )
			dir_facing = -1
		else:
			set_scale( Vector2(1,1) )
			dir_facing = 1
		siding_left=new_siding_left	

func process_animations():
	if(current_state_anim.name != next_state_anim.name and not block_anim_change):
		print(next_state_anim.name)
		next_state_anim.stateFunc.call_func()
	current_state_anim = next_state_anim

func _fixed_process(delta):
	process_animations()	
	process_map_collisions()	
	process_movement(delta)

#Signal functions 
func _on_aggro_range_body_enter(body): 
	if(body.is_in_group("player")): 
		print("ENTERED AGGRO RANGE")
		check_p = true
		target = body
		current_state_ms = CHASING_MS


func _on_aggro_range_body_exit(body):
	if(body.is_in_group("player") && check_p):
		patience.start()
		check_p=false

func _on_stun_timer_timeout():
	get_node("stun_timer").stop()
	block_anim_change = false
	current_state_anim.stateFunc.call_func()
	if(target_near):
		current_state_ms = CHASING_MS	
	else:
		current_state_ms = NORMAL_MS

func _on_patience_timeout():
	print("PATIENCE RAN OUT")
	target = null
	current_state_ms = NORMAL_MS
	get_node("patience").stop()

func notify_end_attack():
	block_anim_change = false
	if(target_near):
		attack_anim()
	else:
		next_state_anim = WALKING_ANIM

func _on_attack_range_body_enter(body):
	if(body.is_in_group("player")):
		next_state_anim = ATTACK_ANIM
		target_near = true

func _on_attack_range_body_exit(body):
	target_near = false


func _on_contact_receiver_body_enter(body):
	if(body.is_in_group("repulsor")):
		print("REPULSED")
		velocity.y = - 200
		var body_pos = body.get_global_pos()
		var pos = get_pos()
		var xDiff = pos.x - body_pos.x
		velocity.x = sign(xDiff) * 200
		get_node("stun_timer").start()
		current_state_ms = REPULSED_MS
		block_anim_change = true
		anim_player.stop()

	if(body.is_in_group("projectile")):
		print("SHOT")
		get_node("/root/game_data").add_item_qty("bear_claw.png")
		body.queue_free()
		queue_free()

func _ready():
	dir_facing= sign(rand_range(-1.0,1.0)) 
	if(dir_facing == 0.0):
		dir_facing = 1
	patience = get_node("patience")
	anim_player = get_node("AnimationPlayer")
	get_node("paw").add_to_group("attack")
	anim_player.play("walk")
	check_p = false
	target_near = false
	set_fixed_process(true)

