
extends Node2D

func _on_contact_receiver_body_enter(body):
	if(body.is_in_group("repulsor")):
		print("REPULSED")

func _ready():
	# Initialization here
	pass


