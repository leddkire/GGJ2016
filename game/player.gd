extends KinematicBody2D

# class controlling the player

# Classes ---------------------------------------------------------------

#const bonus_class = preload("res://bonus.gd")
#const enemy_class = preload("res://enemies/enemy.gd")
const item_class = preload("res://item.gd")
#const boss_class = preload("res://enemies/boss1_sprite.gd")
#const breath = preload("res://breath.res")
#const star = preload("res://star.res")
#const cone = preload("res://cone.res")
#const hit_stars = preload("res://player_hit.res")

# Constants ---------------------------------------------------------------

const GRAVITY = 900.0               # in [px/s]
const FLOOR_ANGLE_TOLERANCE = 40
const WALK_FORCE = 1200              # given force when left/right key is pressed, in [px/s]
const WALK_MAX_SPEED = 300          # maximum speed of the player, in [px/s]
const STOP_FORCE = 1800             # friction when no movement key is pressed, in [px/s]
const JUMP_SPEED = 300              # initial velocity when doing a jump, in [px/s]
const JUMP_MAX_AIRBORNE_TIME=0.2    # tolerance of error for time not touching the ground when trying to jump, in [s]. Often the player is for a fraction of second in air, because of the way physics work.
const FLY_JUMP_SPEED = 300          # given force when going up when the player is flying, in [px/s].

# enumeration of player's states
const STATE_NORMAL=0  
const STATE_CUTSCENE=10

# enumeration of animations, for array normal_animations
const ANIM_IDLE=0
const ANIM_RUN=1
const ANIM_FALL=2

# Variables ---------------------------------------------------------------

#The current direction the player is facing
#1 is right, -1 is left
var dir_facing 

#Resources for actions
var repulsor_scn = load("res://repulsor/repulsor.tscn")
var projectile_scn = load("res://basic_projectile/basic_projectile.tscn")


var anim_player

var sfx_node=null         # node for sound effects

var state=STATE_NORMAL    # current state of the player
var velocity= Vector2()   # current velocity of the player
var on_air_time=100       # time being on air since last time touching the ground
var jumping=false         # is player doing a jump. Falling, even after a jump, doesn't count.
var currentDoor=null        # the door the player is actually in front of, if any.
var traverse_floor=false    # state of traversing plateforms. Wenn true, the player can go trought special traversable plateforms. Should not be directy modified. It's used for when the player jumps down from a plateform. It doesn't affect when he jumps up.

var prev_jump_pressed=false # previous state of jumping
var anim=""                 # actual sprite animation to play
var siding_left=false       # is player siding left, in which case the sprite must be inverted. This parameter is passed down the bullets and cone the player creates.

# names of animations
var normal_animations=["Idle","run","fall"]
var charged_animations=["chargedIdle","chargedRun","chargedFall"]

#States for invoker abilities
var busy = false
var action_state= IDLE_ACTION
var IDLE_ACTION = 0
var REPULSOR_ACTION = 1
var SHOOT_ACTION =2
var block_facing = false
var channeling = false

# Functions ---------------------------------------------------------------

func _input(ev):
	idle_state_function(ev)

func idle_state_function(ev):
	if(ev.is_action_pressed("repulsor")):
		action_state = REPULSOR_ACTION
	if(ev.is_action_pressed("shoot")):
		action_state = SHOOT_ACTION

# main loop
func _fixed_process(delta):
	if(state!=STATE_CUTSCENE && not channeling):
		_do_move(delta)
	if(not busy):
		if(action_state == REPULSOR_ACTION):
			perform_repulsion()
			busy = true
		if(action_state == SHOOT_ACTION):
			perform_shoot()
			busy = true
	#check_dir_facing()

func check_dir_facing():
	var scale = get_scale()
	if(sign(dir_facing) == 1):
		set_scale(Vector2(1,scale.y))
	else:
		set_scale(Vector2(-1,scale.y))

# function that makes the player move with physics
func _do_move(delta):
	
	var new_siding_left=siding_left # flag for changing the side of the player (left or right)
	
	# Initialize variables for the player's animation.
	# The animation will be changed, if needed, at the end of this function.
#	var pre_anim=""   # in case a new animation is divided in 2 parts, this is the name of the first animation to play. The animation must not loop, because it will be followed by the new_anim animation.
#	var new_anim=anim # name of the next animation to play. must be a valid animation name and the animation must loop.
	
#	var animation=get_node("anim") # animation player node
	var preventChangeAnimation=false # flag to prevent a change of animation, so a transition animation can be completely played, even if something interacts with the player.
#	if(animation!=null and get_node("anim").get_current_animation()=="deflate"): # if the player is deflating, meaning he's falling, prevent to switch to fall animation
#		preventChangeAnimation=true
	
	
	#forces factors, to make the player faster or slower than his original speed. Same for his gravity.
	var gravityFactor=1
	var xSpeedFactor=1

	
	# will be the force applied to move the player
	var force = Vector2(0,GRAVITY*gravityFactor)
	
	# check input/keyboard state
	var walk_left = Input.is_action_pressed("ui_left")
	var walk_right = Input.is_action_pressed("ui_right")
	var walk_up = Input.is_action_pressed("ui_up")
	var walk_down = Input.is_action_pressed("ui_down")
	var jump = Input.is_action_pressed("jump")
	var shoot = Input.is_action_pressed("shoot")
	
	
	# manage traversable plateforms.
	# if the player is moving up, because of a jump mostly, he'll always traverse the floor
	if(velocity.y<0):
		traverse_floor=true
		_switch_layer()
	elif(jump and walk_down): # if he's pressing down and jump buttons, the player is trying to jump down the plateform. 
		jump=false  # prevent the player to go up. He'll simply fall.
		traverse_floor=true # active traverse floor mode. The player will then be like in the middle of the sky and start to fall. But it must stay only the time needed to traverse the current floor. The player must not traverse the next floor below.
		_switch_layer()
		get_node("traverseTimer").start()  # starts a timer to desactivate the traverse floor mode. 
	elif(traverse_floor and get_node("traverseTimer").get_time_left()<=0): # if timer is up and the player was in traverse mode, desactivate it. The player will the immediately collide again with the plateforms.
		traverse_floor=false
		_switch_layer()
	
	var stop=true # flag for saying if the player is not moving by himself (except for inertia).
	
	if(currentDoor!=null and walk_up): # if the player is in front of a door and press up, he'll enter it.
		_start_enter_door()
	
	# manage movement impulse given by the input
	if (walk_left):
		if (velocity.x<=0 and velocity.x > -WALK_MAX_SPEED*xSpeedFactor):
			force.x-=WALK_FORCE
			stop=false
		
	elif (walk_right):
		if (velocity.x>=0 and velocity.x < WALK_MAX_SPEED*xSpeedFactor):
			force.x+=WALK_FORCE
			stop=false
	
#	elif (walk_up): # if not inflated, starts to inflate like a balloon. Otherwise, fly higher.
#			force.y=-FLY_JUMP_SPEED
#			stop=false
#			preventChangeAnimation=false
	
	# if the player got no movement impulse, he'll slow down with inertia.
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
	
	# speed of the floor, in case it's moving
	var floor_velocity=Vector2()
	
	# because the first move would stop if there's a collision, we recalculate the movement to slide along the colliding object.
	if (is_colliding()):
		#ran against something, is it the floor? get normal
		var n = get_collision_normal()
		
		
		if ( rad2deg(acos(n.dot( Vector2(0,-1)))) < FLOOR_ANGLE_TOLERANCE ):
			#if angle to the "up" vectors is < angle tolerance
			#char is on floor
			on_air_time=0
			floor_velocity=get_collider_velocity()
			
		# But we were moving and our motion was interrupted, 
		# so try to complete the motion by "sliding"
		# by the normal
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		
		#then move again
		move(motion)
	
	if (floor_velocity!=Vector2()):
		#if floor moves, move with floor
		move(floor_velocity*delta)
		
	# from here, the player will not be moved anymore 'till the end of the function.
						
			
	if(state==STATE_NORMAL):
		# when in normal state, the player can move, jump, and start to inhale.
		if (jumping and velocity.y>0):
			jumping=false
			
		if (on_air_time<JUMP_MAX_AIRBORNE_TIME and jump and not prev_jump_pressed and not jumping):	
			velocity.y=-JUMP_SPEED	
			jumping=true
			preventChangeAnimation=false
#			sfx_node.play("jump")
			
		on_air_time+=delta
		prev_jump_pressed=jump
		
#		if(velocity.y!=0 and on_air_time>=0.1):
#			new_anim=normal_animations[ANIM_FALL]
#		elif(velocity.x==0):
#			new_anim=normal_animations[ANIM_IDLE]
#		else:
#			new_anim=normal_animations[ANIM_RUN]
	
	# update the side flag
	if(walk_left or walk_right):
		new_siding_left=walk_left
	
	# in case the player changed side, the sprite must be mirrored horizontaly
	if (new_siding_left!=siding_left):
		if (new_siding_left):
			get_node("Sprite").set_scale( Vector2(-1,1) )
			dir_facing = -1
		else:
			get_node("Sprite").set_scale( Vector2(1,1) )
			dir_facing = 1
			
		siding_left=new_siding_left
	
	# update the player's animation, if needed and possible.
#	if(!preventChangeAnimation and new_anim!=anim):
#		anim=new_anim
#		if(pre_anim!=""):
#			animation.play(pre_anim)
#			animation.queue(anim)
#		else:
#			animation.play(anim)


# Initializer
func _ready():
#	sfx_node=get_node("sfx")
	get_node("/root/camera").cam_target=self
	anim_player = get_node("AnimationPlayer")
	action_state = IDLE_ACTION
	dir_facing = 1
	block_facing =false
	add_to_group("player")
	set_fixed_process(true)
	set_process_input(true)

# generic function to decrease a timer. If the timer goes below 0, it's set to 0.
# float value : timer to decrease, in [s]
# float delta : amount to decrease, in [s]
# return decreased timer, or 0 if timer < 0
func decTimeout(value,delta):
	if(value>0):
		value=value-delta
		if(value<0):
			value=0
	return value


# trigger event when the player collides with a bonus or an enemy
# Node body : body which the player collides with
func _on_Area2D_body_enter( body ):
	if (body extends item_class):
		get_node("/root/game_data").add_item_qty(body.get_texture_name())
		body.free()
#	if(body extends enemy_class and body.alive):
#		hit()
#		body.explode()
#	if(body extends bonus_class):
#		get_bonus(body.bonus_type)
#		body.queue_free()
#	if("is_enemy" in body):
#		hit()
#
# event when the player is hit, is knocked back and lose life.
# edit: here should also start a phase of immortality
#func hit():
#	var instance=hit_stars.instance()
#	instance.set_direction(siding_left)
#	add_child(instance)
#	if(siding_left):
#		velocity+=Vector2(500,0)
#	else:
#		velocity-=Vector2(500,0)
#	get_node("/root/gamedata").remove_player_life(1)
#	sfx_node.play("hit")
#
# gives the player the effect of a bonus.
# int bonus_type : type of bonus (see bonus resource)
#func get_bonus(bonus_type):
#	var gameData=get_node("/root/gamedata")
#	if(bonus_type==0):
#		gameData.increase_player_life(3)
#		sfx_node.play("health")
#	elif(bonus_type==1):
#		gameData.restore_player_life()
#		sfx_node.play("health")
#	elif(bonus_type==2):
#		gameData.add_player_continue()
#		sfx_node.play("life")

# allocate the which the player can interact with.
# Door door : door node. If null, it means the player cannot interact with a door (which is the case most of the time).
func setDoor(door):
	currentDoor=door

# starts the animation to enter in a door.
func _start_enter_door():
	state=STATE_CUTSCENE
	get_node("/root/global").fade_out()
	get_node("anim").play("enter_door")
	get_node("/root/soundMgr").play_sfx("door")

# set the player's camera the current one
func focusCamera():
	get_node("Camera2D").make_current()

# move to a different scene specified by the current door. The scene must be in the root or a subfolder of res://maps/ and have the extension .scn
# This private function is called by the enter_door animation
func _enter_door():
	if(currentDoor!=null):
		get_node("/root/global").goto_playable_scene("res://maps/"+currentDoor.destination+".scn",currentDoor.dest_point)

# trigger event to activate an enemy
# Node2d body : body entered in the activation zone
#func _on_enemyActivator_body_enter( body ):
#	if(body extends enemy_class and body.alive):
#		body.activate()

# update the player for the traversable plateform layer (bit 14).
func _switch_layer():
	if(traverse_floor):
		set_layer_mask(1)
	else:
		set_layer_mask(16385)

# triggered when the timeout for traversing plateforms expired. Then it disables the traverse mode of the player
func _on_Traverse_timeout():
	traverse_floor=false
	_switch_layer()

func perform_idle():
	action_state = IDLE_ACTION
	busy = false
	print("Back to idle")
	anim_player.play("Idle")
	
func perform_shoot():
	print("channeling shoot")
	anim_player.play("shoot")
	channeling = true

func player_shoot():
	print("shot")
	channeling = false
	var projectile_node = projectile_scn.instance()
	var player_pos = get_pos()
	var p_dir = sign(dir_facing) * 30
	var projectile_pos = player_pos + Vector2(p_dir,10)
	projectile_node.set_pos(projectile_pos)
	projectile_node.dir = dir_facing
	get_node("..").add_child(projectile_node)
	perform_idle()

func perform_repulsion():
	anim_player.play("repulsor")
	block_facing = true

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
	var repulsor_node = get_node("repulsor")	
	repulsor_node.queue_free()
	block_facing = false
	perform_idle()
