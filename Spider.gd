extends KinematicBody2D
 
onready var front_check = $FrontCheck
onready var low_mid_check = $LowMidCheck
onready var high_mid_check = $HighMidCheck
onready var back_check = $BackCheck
 
onready var front_legs = $FrontLegs.get_children()
onready var back_legs = $BackLegs.get_children()
 
onready var front_leg_position_x = [150,10]
onready var back_leg_position_x = [-10,-150]

export var x_speed = 90
export var y_speed = 40
var accel = 5
export var max_step_rate = 0.4
var time_since_last_step = 0
var cur_f_leg = 0
var cur_b_leg = 0
var use_front = false
export (int) var legs_to_move_at_same_time = 3

var body_thickness = 20
var rest_position
var move_vec = Vector2.ZERO
var direction = 1

func _ready():
	rest_position = self.position.y
	front_check.force_raycast_update()
	back_check.force_raycast_update()
	for i in range(32):
		step()
 
func _physics_process(delta):
	var check_position = 100
	var _input = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	var previous_direction = direction
	
	if _input == -1:
		front_check.position.x = front_leg_position_x[1]
		back_check.position.x = back_leg_position_x[1]
		low_mid_check.position.x = -check_position
		high_mid_check.position.x = -check_position
		direction = _input
	elif _input == 1:
		front_check.position.x = front_leg_position_x[0]
		back_check.position.x = back_leg_position_x[0]
		low_mid_check.position.x = check_position
		high_mid_check.position.x = check_position
		direction = _input
	
	if _input != 0:
		move_vec += Vector2(accel*_input, 0)
		move_vec.x = clamp(move_vec.x,-x_speed,x_speed)
	else:
		move_vec.x = lerp(move_vec.x,0,0.15)
	
	move_vec.y = 0
	if _input != 0:
		if high_mid_check.is_colliding():
			move_vec.y = -y_speed
		elif !low_mid_check.is_colliding():
			move_vec.y = y_speed
	
	move_and_collide(move_vec * delta)

func _process(delta):
	
	if abs(move_vec.x) < 10:
		return
	var step_rate = 1-(abs(move_vec.x)/x_speed)*max_step_rate
	
	time_since_last_step += delta
	if time_since_last_step >= step_rate:
		time_since_last_step = 0
		for i in range(legs_to_move_at_same_time):
			step()
	var front_legs_position = calculate_legs_position(front_legs)
	var back_legs_position = calculate_legs_position(back_legs)
	
	var leg_angle = back_legs_position.angle_to_point(front_legs_position)
	
	leg_angle = rad2deg(leg_angle)
	var is_valid_number = !is_nan(leg_angle)
	if is_valid_number:
		$Sprite.rotation_degrees = clamp($Sprite.rotation_degrees,0,360)
		$Sprite.rotation_degrees = leg_angle
		pass

 
func step():
	var leg = null
	var sensor = null
	if use_front:
		leg = front_legs[cur_f_leg]
		cur_f_leg += 1
		cur_f_leg %= front_legs.size()
		sensor = front_check
	else:
		leg = back_legs[cur_b_leg]
		cur_b_leg += 1
		cur_b_leg %= back_legs.size()
		sensor = back_check
	use_front = !use_front
	var target = sensor.get_collision_point()
	leg.step(target)


func calculate_legs_position(leg_array : Array):
	var leg_array_sum = Vector2.ZERO
	for i in range(leg_array.size()-1):
		leg_array_sum+= leg_array[i].hand_pos
		pass
	
	return leg_array_sum / (leg_array.size()-1)
