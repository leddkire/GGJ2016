
extends KinematicBody2D

var dir = 1
var velocity = Vector2()
var projectile_spd = 300


func _fixed_process(delta):
	velocity.x = sign(dir) * projectile_spd
	var motion = Vector2()
	motion = velocity * delta
	move(motion)

func _on_Timer_timeout():
	queue_free()

func _ready():
	add_to_group("projectile")
	set_fixed_process(true)


