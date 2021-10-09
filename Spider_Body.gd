extends KinematicBody2D

func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var motion = Vector2(60*delta,0)
	move_and_collide(motion)
