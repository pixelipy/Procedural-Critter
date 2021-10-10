extends KinematicBody2D

onready var low_check = $lowCheck
onready var high_check = $highCheck

var y_speed = 40

func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var motion = Vector2(100,0)
	
	if high_check.is_colliding():
		motion.y = -y_speed
	elif !low_check.is_colliding():
		motion.y = y_speed
	
	
	
	
	move_and_collide(motion*delta)
