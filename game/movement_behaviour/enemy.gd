
extends KinematicBody2D

var gravity
var velocity = Vector2()

func _on_contact_receiver_body_enter(body):
	if(body.is_in_group("repulsor")):
		print("REPULSED")
		velocity.y=-50
		var rep_x = body.get_pos().x
		var diff_x = get_pos().x - rep_x
		velocity.x = sign(diff_x) * 200


func _fixed_process(delta):
	velocity.y += delta * gravity
	var motion = velocity * delta
	motion = move(motion)

func _ready():
	gravity = get_node("/root/globals").gravity
	set_fixed_process(true)

