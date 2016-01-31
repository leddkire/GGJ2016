
extends KinematicBody2D

const player_class = preload("res://player.gd")

const WALK_SPEED = 700
const RUN_SPEED = 1200
const JUMP_SPEED = 300
const JUMP_HEIGHT = 1000
const TIMEOUT_IDLE = 1
const TIMEOUT_CHARGING = 0.5
const TIMEOUT_FREEZED = 2
const TIMEOUT_ATTACKING = 2



# States
const IDLE = 1
const WANDERING = 2
const CHASING = 3
const CHARGING = 4
const ATTACKING = 5
const FREEZED = 6

var state = IDLE
var facing_dir = 1
var timer
var velocity = Vector2()
var gravity
var target
var cast

func _on_contact_receiver_body_enter(body):
	if(body.is_in_group("repulsor")):
		print("REPULSED")
		velocity.y=-50
		var rep_x = body.get_pos().x
		var diff_x = get_pos().x - rep_x
		velocity.x = sign(diff_x) * 200
		state = FREEZED
		timer.set_wait_time(TIMEOUT_FREEZED)
	if(body.is_in_group("projectile")):
		print("SHOT")
		get_node("/root/game_data").add_item_qty("tooth.png")
		body.queue_free()
		queue_free()

func _on_attack_range_body_enter(body):
	if(body.is_in_group("player") and (state == IDLE or state == WANDERING or state == CHASING)):
		state = CHARGING
		if (body.get_pos().x > get_pos().x):
			facing_dir = 1
		else:
			facing_dir = -1
		timer.set_wait_time(TIMEOUT_CHARGING);
		timer.start()
		target = body


func _on_Timer_timeout():
	if state == CHARGING:
		velocity.y = -JUMP_HEIGHT
		velocity.x = facing_dir * JUMP_SPEED
		state = ATTACKING
		timer.set_wait_time(TIMEOUT_ATTACKING)
		timer.start()
	elif state == IDLE:
		randomize();
		var ran = randi() % 1
		if ran == 0:
			facing_dir = -1
		else:
			facing_dir = 0
		state = WANDERING
		randomize();
		ran = randi() % 2
		timer.set_wait_time(ran + 2)
		timer.start()
	elif state == FREEZED:
		state = WANDERING
	elif state == ATTACKING:
		state = WANDERING
	elif state == WANDERING:
		state = IDLE
		timer.set_wait_time(TIMEOUT_IDLE)
		timer.start()

func perform_wolf_movement(delta):
	velocity.y += 100
	if state == WANDERING:
		velocity.x = facing_dir * WALK_SPEED
	elif state == CHASING:
		var pos = get_pos()
		var target_pos = target.get_pos()
		var pos_diff = target_pos - pos
		velocity.x = RUN_SPEED * sign(pos_diff.x)
		facing_dir = sign(pos_diff.x)
	elif state == IDLE or state == CHARGING:
		velocity.x = 0
	var motion = velocity* delta
	motion = move(motion)
	if(is_colliding()):
		var norm = get_collision_normal()
		motion = norm.slide(motion)
		velocity = norm.slide(velocity)

func check_facing():
	var scale = get_scale()
	if(sign(facing_dir) == 1):
		set_scale(Vector2(1,scale.y))
	else:
		set_scale(Vector2(-1,scale.y))

func process_map_collisions():
	if(is_colliding()):
		var body = get_collider()
		if(body.is_in_group("wall")):
			facing_dir = -facing_dir
			

func _fixed_process(delta):
	process_map_collisions()
	perform_wolf_movement(delta)
	check_facing()
	get_node("current_state").set_text("Current State: " + var2str(state))	


func _ready():
	timer = get_node("Timer")
	timer.set_wait_time(TIMEOUT_IDLE)
	timer.start()
	target = null
	gravity = get_node("/root/globals").gravity
	cast = get_node("vision_cast")
	set_fixed_process(true)




func _on_cast_range_body_enter( body ):
	if(body.is_in_group("player") and not (state == ATTACKING or state == CHARGING)):
		state = CHASING
		target = body
