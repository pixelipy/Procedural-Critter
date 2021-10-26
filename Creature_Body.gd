extends KinematicBody2D

#onready var low_check = $lowCheck
#onready var high_check = $highCheck

var y_speed = 60.0
var x_speed = 120.0
var y_accel = 20.0
var x_accel = 5.0
var max_offset = 20.0
var offset = 0.0
var cur_offset = 0.0
var motion : Vector2= Vector2.ZERO
var direction = 1
var motion_fraction := 0.0

signal change_direction
onready var initial_position

func _ready():
#	initial_position = $Body.position
	pass # Replace with function body.

func _physics_process(delta):
	var input = int(Input.is_action_pressed("right"))-int(Input.is_action_pressed("left"))
	
	if input !=0:
		motion+= Vector2(input*x_accel,0)
	else:
		motion.x = lerp(motion.x,0,0.15)
	
	motion.x = clamp(motion.x,-x_speed,x_speed)
	
	if motion.x>0 and direction != 1:
		direction = 1
		emit_signal("change_direction",1)
	elif motion.x < 0 and direction != -1:
		direction = -1
		emit_signal("change_direction",-1)
	
	
	motion_fraction = motion.x/x_speed
	
#	if high_check.is_colliding():
#		motion.y -=y_accel
#	elif !low_check.is_colliding():
#		motion.y +=y_accel
#	else:
#		motion.y = lerp(motion.y,0,0.15)
#	$Body.position.y = lerp($Body.position.y,initial_position.y + cur_offset,0.15)
	
	cur_offset = lerp(cur_offset,offset,0.15)
	
	motion.y = clamp(motion.y,-y_speed,y_speed)
	
	
	move_and_collide(motion*delta)

func bump():
	if abs(motion.x) < 20:
		return
	cur_offset = 0
	offset = float(abs(motion.x/x_speed))*max_offset
	pass
