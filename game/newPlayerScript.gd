extends KinematicBody2D

#Resources for actions
var item_class = load("res://item.gd")
var repulsor_scn = load("res://repulsor/repulsor.tscn")
var projectile_scn = load("res://basic_projectile/basic_projectile.tscn")

var StateObject = load("res://classes/StateObject.gd").StateObject

#Movement states
#Suffix MS
var NORMAL_MS = StateObject.new("normal","normal_ms",0,self)

#Jumping states
var NORMAL_JMP = StateObject.new("jump","normal_jmp",0,self)
func normal_jmp(j,delta):
	if (jumping and velocity.y>0):
		jumping=false
	if (on_air_time<JUMP_MAX_AIRBORNE_TIME and j and not prev_jump_pressed and not jumping):
		velocity.y=-JUMP_SPEED
		jumping=true
	on_air_time+=delta
	prev_jump_pressed=j

#Animation states
#Suffix ANIM
var IDLE_ANIM= StateObject.new("idle","idle_anim",0,self)
func idle_anim():
	anim_player.play("Idle")

var RUN_ANIM= StateObject.new("run","run_anim",1,self)
func run_anim():
	anim_player.play("Run")

var JUMP_ANIM= StateObject.new("jump","jump_anim",2,self)
var BASIC_SHOOT_ANIM = StateObject.new("basic_shoot","basic_shoot_anim",3,self)
func basic_shoot_anim():
	anim_player.play("shoot")
	block_anim_change = true

var REPULSOR_ANIM = StateObject.new("repulsor","repulsor_anim",4,self)
func repulsor_anim():
	anim_player.play("repulsor")
	block_anim_change = true

#Variables

#Animation-specific
var anim_player = null
var block_anim_change = false
var current_state_anim = IDLE_ANIM
var next_state_anim = IDLE_ANIM
var channeling = false
#Movement-specific
var velocity = Vector2(0,0)
var dir_facing = 1
var jumping = false
var on_air_time = 100
var prev_jump_pressed = false
var siding_left = false
var current_state_ms = NORMAL_MS
var current_state_jump = NORMAL_JMP
var next_state_ms = NORMAL_MS
var GRAVITY = 900.0
const WALK_FORCE = 1200              # given force when left/right key is pressed, in [px/s]
const WALK_MAX_SPEED = 200          # maximum speed of the player, in [px/s]
const FLOOR_ANGLE_TOLERANCE = 40
const STOP_FORCE = 1800             # friction when no movement key is pressed, in [px/s]
const JUMP_SPEED = 300              # initial velocity when doing a jump, in [px/s]
const JUMP_MAX_AIRBORNE_TIME=0.2    # tolerance of error for time not touching the ground when trying to jump, in [s]. Often the player is for a fraction of second in air, because of the way physics work.
const FLY_JUMP_SPEED = 300          # given force when going up when the player is flying, in [px/s].

#Movement functions

#Animation functions
func begin_shoot():
	channeling = true

func player_shoot():
	channeling = false
	block_anim_change= false
	var projectile_node = projectile_scn.instance()
	var player_pos = get_pos()
	var p_dir = sign(dir_facing) * 20
	var projectile_pos = player_pos + Vector2(p_dir,-5)
	projectile_node.set_pos(projectile_pos)
	projectile_node.dir = dir_facing
	get_node("..").add_child(projectile_node)

func create_repulsor():
	print("performing repulsor")
	channeling = true
	var repulsor_node = repulsor_scn.instance()

	var repulsor_pos = Vector2(10*dir_facing,-5)
	repulsor_node.set_pos(repulsor_pos)
	add_child(repulsor_node)

func remove_repulsor():
	print("removing repulsor")
	channeling = false
	block_anim_change = false
	var repulsor_node = get_node("repulsor")
	repulsor_node.queue_free()

#Process functions

func _input(ev):
	var basic_shoot = ev.is_action_pressed("shoot")
	var repulsor = ev.is_action_pressed("repulsor")
	if(basic_shoot):
		next_state_anim = BASIC_SHOOT_ANIM
	if(repulsor):
		next_state_anim = REPULSOR_ANIM

func process_movement(delta):

	var new_siding_left=siding_left # flag for changing the side of the player (left or right)
	var stop=true
	#Input variables
	var run_left = Input.is_action_pressed("ui_left")
	var run_right = Input.is_action_pressed("ui_right")
	var jump = Input.is_action_pressed("jump")
	#Define force variables
	var gravityFactor = 1
	var xSpeedFactor = 1
	var force = Vector2(0,GRAVITY*gravityFactor)
	#Movement input
	if(run_left):
		if(velocity.x <=0 and velocity.x > -WALK_MAX_SPEED * xSpeedFactor):
			force.x -= WALK_FORCE
			stop = false
	elif(run_right):
		if (velocity.x>=0 and velocity.x < WALK_MAX_SPEED*xSpeedFactor):
			force.x += WALK_FORCE
			stop=false
	# if the player's got no movement impulse, he'll slow down with inertia.
	if (stop):
		var vsign = sign(velocity.x)
		var vlen = abs(velocity.x)
		vlen -= STOP_FORCE * delta
		if (vlen<0):
			vlen=0
		velocity.x=vlen*vsign



	#integrate forces to velocity
	velocity += force * delta
	#integrate velocity into motion and move
	var motion = velocity * delta
	#move and consume motion
	motion = move(motion)

	if(is_colliding()):
		var normal = get_collision_normal()
		motion = normal.slide(motion)
		velocity = normal.slide(velocity)
		move(motion)
		if ( rad2deg(acos(normal.dot( Vector2(0,-1)))) < FLOOR_ANGLE_TOLERANCE ):
			#if angle to the "up" vectors is < angle tolerance
			#char is on floor
			on_air_time=0
	if(current_state_ms == NORMAL_MS):
		var jump_func = current_state_jump.stateFunc
		jump_func.call_func(jump,delta)


	# update the side flag
	if(run_left or run_right):
		new_siding_left=run_left
	# in case the player changed side, the sprite must be mirrored horizontally
	if (new_siding_left!=siding_left):
		if (new_siding_left):
			get_node("Sprite").set_scale( Vector2(-1,1) )
			dir_facing = -1
		else:
			get_node("Sprite").set_scale( Vector2(1,1) )
			dir_facing = 1
		siding_left=new_siding_left
	if(not block_anim_change):
		if(velocity.x == 0):
			next_state_anim = IDLE_ANIM
		else:
			next_state_anim = RUN_ANIM


func process_animations():
	if(current_state_anim.name != next_state_anim.name and not block_anim_change):
		next_state_anim.stateFunc.call_func()
	current_state_anim = next_state_anim

func _fixed_process(delta):
	process_animations()
	if(not channeling):
		process_movement(delta)

#Signal functions

# trigger event when the player collides with a bonus or an enemy
# Node body : body which the player collides with
func _on_Area2D_body_enter( body ):
	if (body extends item_class):
		get_node("/root/game_data").add_item_qty(body.get_texture_name())
		body.free()
	elif(body.is_in_group("attack")):
		get_node("/root/camera").cam_target= null
		var same_scn = get_node("/root/global").current_scene_path
		get_node("/root/global").goto_playable_scene("res://game_over/game_over.scn",null)



func _ready():
	get_node("/root/camera").cam_target=self
	anim_player = get_node("AnimationPlayer")
	add_to_group("player")
	dir_facing = 1
	set_process_input(true)
	set_fixed_process(true)

