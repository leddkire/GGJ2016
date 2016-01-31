
extends KinematicBody2D

# member variables here, example:
# var a=2
# var b="textvav"

#Bear states of behaviour
var state = WANDERING
var WANDERING = 0
var CHASING   = 1
var facing_dir
var gravity
var velocity = Vector2()
var cast
var move_spd = 1200
var target
var patience
var check_p
var anim_player
var block_until_attack_end

func _on_contact_receiver_body_enter(body):
	if(body.is_in_group("repulsor")):
		print("REPULSED")
		velocity.y=-50
		var rep_x = body.get_pos().x
		var diff_x = get_pos().x - rep_x
		velocity.x = sign(diff_x) * 200
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
		var target_pos = target.get_pos()
		var pos_diff = target_pos - pos
		velocity.x = move_spd * sign(pos_diff.x)
		facing_dir = sign(pos_diff.x)
	var motion = velocity* delta
	motion = move(motion)		
	if(is_colliding()):
		var norm = get_collision_normal()
		motion = norm.slide(motion)
		velocity = norm.slide(velocity)

func update_labels():
	var dir_facing = get_node("direction_facing")
	var curr_state = get_node("current_state")
	dir_facing.set_text("Direction: " + var2str(facing_dir))
	curr_state.set_text("Current State: " + var2str(state))
	var base_scale = Vector2(1,1)
	dir_facing.set_scale(base_scale)
	curr_state.set_scale(base_scale)

func process_map_collisions():
	if(is_colliding()):
		var body = get_collider()
		if(body.is_in_group("wall")):
			facing_dir = -facing_dir

	if(cast.is_colliding()):
		var body = cast.get_collider()
		if(body && body.is_in_group("player")):
			state = CHASING
			check_p = true
			target = body

func check_facing():
	var scale = get_scale()
	if(sign(facing_dir) == 1):
		set_scale(Vector2(1,scale.y))
	else:
		set_scale(Vector2(-1,scale.y))

func check_patience():
	var cast_vec= cast.get_cast_to()
	var pos = get_pos()
	var target_pos = target.get_pos()
	var pos_diff = target_pos - pos
	if(abs(pos_diff.x) > abs(cast_vec.x)):
		patience.start()
		check_p=false

func _on_patience_timeout():
	state = WANDERING
	target = null

func notify_end_attack():
	anim_player.play("walk")
	block_until_attack_end = false

func _on_attack_range_body_enter(body):
	if(body.is_in_group("player")):
		if(not block_until_attack_end):
			anim_player.play("attack")
			block_until_attack_end = true

func _fixed_process(delta):
	process_map_collisions()
	perform_bear_movement(delta)
	check_facing()
	if(target && check_p ):
		check_patience()
	update_labels()



func _ready():
	facing_dir= sign(rand_range(-1.0,1.0)) 
	if(facing_dir == 0.0):
		facing_dir = 1
	state = WANDERING
	gravity = get_node("/root/globals").gravity
	cast = get_node("vision_cast")
	patience = get_node("patience")
	anim_player = get_node("AnimationPlayer")
	anim_player.play("walk")
	block_until_attack_end = false
	check_p = false
	set_fixed_process(true)

