
extends KinematicBody2D

# member variables here, example:
# var a=2
# var b="textvav"

#Bear states of behaviour
var state = WANDERING
var WANDERING = 0
var CHASING   = 1
var BOMBEADO =2
var facing_dir
var gravity
var velocity = Vector2()
var cast
var move_spd = 1200
var target
var target_near
var patience
var check_p
var anim_player
var block_until_attack_end

#Movement Constants
var WALK_MAX_SPEED = 200 
var GRAV =900.0
var WALK_FORCE = 1000
#Flag that indicates whether the bear has been repulsed
var stunned =false
var repulsed = false
#Repulsor node
var repulsor = null

#Called when the target has been eliminated
func clean_up():
	target = null

func _on_contact_receiver_body_enter(body):
	if(body.is_in_group("repulsor")):
		print("REPULSED")
		velocity.y = - 500
		var body_pos = body.get_global_pos()
		var pos = get_pos()
		var xDiff = body_pos.x - pos.x
		var scale = get_scale()
		velocity.x = sign(xDiff) * -1000 
		state = BOMBEADO
		get_node("stun_timer").start()
		repulsor = body
		stunned = true

	if(body.is_in_group("projectile")):
		print("SHOT")
		body.queue_free()
		queue_free()

func perform_bear_movement(delta):
	velocity.y += gravity
	if(state==WANDERING):
		velocity.x = move_spd * sign(facing_dir)
	if(state == CHASING):
		var pos = get_pos()
		var target_pos = pos
		if(target != null):
			target_pos = target.get_pos()
		var pos_diff = target_pos - pos
		velocity.x = move_spd * sign(pos_diff.x)
		facing_dir = sign(pos_diff.x)
	if(state==BOMBEADO):
		pass
	if(block_until_attack_end):
		velocity.x+= sign(facing_dir) * WALK_MAX_SPEED*0.75
	var motion = velocity* delta
	motion = move(motion)		
	if(is_colliding()):
		var norm = get_collision_normal()
		motion = norm.slide(motion)
		velocity = norm.slide(velocity)

func alternate_move(delta):
	var preventChangeAnimation = false

	var gravityFactor =1
	var xSpeedFactor = 1
	var force = Vector2(0,GRAV*gravityFactor)
	if(state==CHASING):
		var pos = get_pos()
		var target_pos = target.get_pos()
		var pos_diff = target_pos - pos
		facing_dir = sign(pos_diff.x)
	if(sign(facing_dir) == -1):
		if(velocity.x<=0 and velocity.x > -WALK_MAX_SPEED * xSpeedFactor):
			force.x -= WALK_FORCE
	elif(sign(facing_dir) == 1):
		if(velocity.x>=0 and velocity.x < WALK_MAX_SPEED * xSpeedFactor):
			force.x += WALK_FORCE
	velocity += force*delta
	var motion = velocity*delta
	motion = move(motion)
	if(is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		move(motion)

func update_labels():
	var dir_facing = get_node("direction_facing")
	var curr_state = get_node("current_state")
	dir_facing.set_text("Direction: " + var2str(facing_dir))
	curr_state.set_text("Current State: " + var2str(state))
	#var base_scale = Vector2(1,1)
	#dir_facing.set_scale(base_scale)
	#curr_state.set_scale(base_scale)

func process_map_collisions():
	if(is_colliding()):

		var body = get_collider()
		var n = get_collision_normal()
		if(n.x != 0):
			facing_dir = n.x
		if(state == BOMBEADO && not stunned):
			if(not body.is_in_group("repulsor")):
				if(target):
					state = CHASING
				else:
					state = WANDERING



func _on_aggro_range_body_enter(body):
	if(body.is_in_group("player")):
		state = CHASING
		check_p = true
		target = body

func check_facing():
	var scale = get_scale()
	if(sign(facing_dir) == 1):
		set_scale(Vector2(1,scale.y))
	else:
		set_scale(Vector2(-1,scale.y))

func _on_aggro_range_body_exit(body):
	if(body.is_in_group("player") && check_p):
		patience.start()
		check_p=false

func _on_stun_timer_timeout():
	print("TIME")
	get_node("stun_timer").stop()
	stunned = false

func _on_patience_timeout():
	state = WANDERING
	target = null

func notify_end_attack():
	if(target_near):
		anim_player.play("attack")
	else:
		anim_player.play("walk")
		block_until_attack_end = false

func _on_attack_range_body_enter(body):
	if(body.is_in_group("player")):
		if(not block_until_attack_end):
			anim_player.play("attack")
			block_until_attack_end = true
			velocity.x = 0

func _on_attack_range_body_exit(body):
	target_near = false

func _fixed_process(delta):
	process_map_collisions()
	perform_bear_movement(delta)
	check_facing()
	update_labels()



func _ready():
	facing_dir= sign(rand_range(-1.0,1.0)) 
	if(facing_dir == 0.0):
		facing_dir = 1
	state = WANDERING
	gravity = get_node("/root/globals").gravity
	patience = get_node("patience")
	anim_player = get_node("AnimationPlayer")
	get_node("paw").add_to_group("attack")
	anim_player.play("walk")
	block_until_attack_end = false
	check_p = false
	target_near = false
	set_fixed_process(true)

