
extends KinematicBody2D


var StateObject = load("res://classes/StateObject.gd").StateObject

const WALK_SPEED = 700
const RUN_SPEED = 1400
const JUMP_SPEED = 400
const JUMP_HEIGHT = 200
const TIMEOUT_IDLE = 1
const TIMEOUT_CHARGING = 0.40
const TIMEOUT_FREEZED = 2 
const TIMEOUT_ATTACKING = 1

var WANDERING_MS = StateObject.new("wandering","wandering_ms",1,self)
func wandering_ms():
	var force = grav_force
	if(sign(dir_facing)==-1):
		if(velocity.x > -WALK_MAX_SPEED * xSpeedFactor):
			force.x -= WALK_FORCE
	elif(sign(dir_facing) == 1):
		if( velocity.x < WALK_MAX_SPEED * xSpeedFactor):
			force.x += WALK_FORCE
	return force

#Movement States
#Suffix MS
var IDLE_MS = StateObject.new("idle","idle_ms",0,self)
func idle_ms():
	velocity.x = 0
	return grav_force



var CHASING_MS = StateObject.new("chasing","chasing_ms",2,self)
func chasing_ms():
	var chasing_factor = xSpeedFactor * 1.5
	var force = Vector2(0,GRAVITY*gravityFactor)
	if(target == null):
		current_state_ms = IDLE_MS
		timer.set_wait_time(TIMEOUT_IDLE)
		timer.start()
		return force
	var dir = target.get_global_pos().x - get_pos().x
	if(sign(dir) == -1):
		if(velocity.x > -WALK_MAX_SPEED * chasing_factor):
			force.x -= WALK_FORCE
			dir_facing = dir
	elif(sign(dir) == 1):
		if(velocity.x < WALK_MAX_SPEED * chasing_factor):
			force.x += WALK_FORCE
			dir_facing = dir
	return force

var CHARGING_MS = StateObject.new("charging","charging_ms",3,self)
func charging_ms():
	velocity.x = 0
	return grav_force

var ATTACKING_MS = StateObject.new("attacking","attacking_ms",4,self)
func attacking_ms():
	var force = grav_force
	var vsign = sign(velocity.x)
	var absv = abs(velocity.x)
	if(absv < 0):
		velocity.x = 0
	else:
		force.x += - vsign * STOP_FORCE
	return force

var STUNNED_MS = StateObject.new("stunned","stunned_ms",5,self)
func stunned_ms():
	var force = grav_force
	var vsign = sign(velocity.x)
	var absv = abs(velocity.x)
	if(absv < 0):
		velocity.x = 0
	else:
		force.x += - vsign * STOP_FORCE

	return force

#Movement-specific
var current_state_ms = IDLE_MS
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
var STOP_FORCE = 350

var gravityFactor = 1
var xSpeedFactor = 1
var grav_force = Vector2(0,GRAVITY*gravityFactor)
var timer
var gravity
var cast
# States
const IDLE = 1
const WANDERING = 2
const CHASING = 3
const CHARGING = 4
const ATTACKING = 5
const FREEZED = 6
var state

func process_movement(delta):
	var new_siding_left = siding_left
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

func process_map_collisions():
	if(is_colliding()):
		var body = get_collider()
		var n = get_collision_normal()
		if(n.x !=0):
			dir_facing = n.x
			
func _fixed_process(delta):
	process_map_collisions()
	process_movement(delta)
	get_node("Label").set_text(current_state_ms.name)
	get_node("Label").set_scale(Vector2(sign(dir_facing),1))

#Signal functions
func _on_contact_receiver_body_enter(body):
	if(body.is_in_group("repulsor")):
		velocity.y=-250
		var rep_x = body.get_global_pos().x
		var diff_x = get_pos().x - rep_x
		velocity.x = sign(diff_x) * 300
		current_state_ms = STUNNED_MS
		timer.set_wait_time(TIMEOUT_FREEZED)
		timer.start()
	if(body.is_in_group("projectile")):
		get_node("/root/game_data").add_item_qty("tooth.png")
		body.queue_free()
		queue_free()


func _on_attack_range_body_enter(body):
	if(body.is_in_group("player") and (current_state_ms == IDLE_MS or current_state_ms == WANDERING_MS or current_state_ms == CHASING_MS) and not current_state_ms == STUNNED_MS):
		current_state_ms = CHARGING_MS
		if (body.get_pos().x > get_pos().x):
			dir_facing = 1
		else:
			dir_facing = -1
		timer.set_wait_time(TIMEOUT_CHARGING);
		timer.start()
		target = body


func _on_Timer_timeout():
	if current_state_ms == CHARGING_MS:
		velocity.y = -JUMP_HEIGHT
		velocity.x = dir_facing * JUMP_SPEED
		current_state_ms = ATTACKING_MS
		timer.set_wait_time(TIMEOUT_ATTACKING)
		timer.start()
	elif current_state_ms == IDLE_MS:
		randomize();
		var ran = randi() % 2
		if ran == 0:
			dir_facing = -1
		else:
			dir_facing = 1
		current_state_ms = WANDERING_MS
		randomize();
		ran = randi() % 2
		timer.set_wait_time(ran + 2)
		timer.start()
	elif current_state_ms == STUNNED_MS:
		current_state_ms = WANDERING_MS
	elif current_state_ms == ATTACKING_MS:
		current_state_ms = WANDERING_MS
	elif current_state_ms == WANDERING_MS:
		current_state_ms = IDLE_MS
		timer.set_wait_time(TIMEOUT_IDLE)
		timer.start()

func _on_cast_range_body_enter( body ):
	if(body.is_in_group("player") and not (current_state_ms == ATTACKING_MS or current_state_ms == CHARGING_MS or current_state_ms == STUNNED_MS)):
		current_state_ms = CHASING_MS
		target = body


func _ready():
	timer = get_node("Timer")
	timer.set_wait_time(TIMEOUT_IDLE)
	timer.start()
	target = null
	gravity = get_node("/root/globals").gravity
	cast = get_node("vision_cast")
	set_fixed_process(true)





