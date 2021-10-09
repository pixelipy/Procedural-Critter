extends Node2D

var pinPos:Vector2
var endPos: = Vector2.ZERO
var errorMargin: = 1.0
export var length: = 60
export var segmentCount: = 5
var totalLength: = length *segmentCount
var posList: = []

var limb_angle_min = 0.1
var limb_angle_max = 90

var MIN_DIST = 70
var total_length_buff = 50
export var flipped = false
#draw IK tentacle line

var draw_start :=[]
var draw_end :=[]
var smoothness = 0.3

var goal_pos = Vector2.ZERO
var int_pos = Vector2.ZERO
var start_pos = Vector2.ZERO
var step_height = 60.0 #how high the midpoint is
var cur_step_height = Vector2.ZERO
var step_rate = 0.1 # step velocity
var step_time= 0.0 #current time
var max_leg_distance = 90


var pin_body = null
var raycast_collision = Vector2.ZERO

var go_up = false
var go_down = false
var intermediate_position = Vector2.ZERO
var start_position = Vector2.ZERO
var end_position = Vector2.ZERO
var cur_target_position = Vector2.ZERO
var in_step = false

onready var target_body = $target

signal step

func _draw()->void:
	var col: = Color.black
	for i in posList.size() -1:
		var start:Vector2
		var end:Vector2
		start = draw_start[i]
		end = draw_end[i]
		
#		draw_circle(start,5,Color.white)
		draw_line(start, end, col, 5)

func _ready()->void:
	pinPos = Vector2.ZERO
	# add point list including pinPos by default pointing up
	for i in segmentCount +1:
		posList.append(pinPos +(i *Vector2.UP *length))
	for i in posList.size() -1:
		draw_start.append(posList[i])
		draw_end.append(posList[i+1])

func set_pin(initial_pin : Position2D):
	pin_body = initial_pin
	
	posList[0] = pin_body.position
	pinPos = pin_body.position
	
	pass

func _process(_delta:float)->void:
	var new_target_pos : Vector2= start_position
	if step_time < 1.0:
		#go to intermediate position
		if step_time <= 0.5:
			new_target_pos = lerp(start_position,intermediate_position,step_time*2.0)
		#go to end position
		elif step_time <1.0:
			new_target_pos = lerp(intermediate_position,end_position,(step_time-0.5)*2.0)
		target_body.position = new_target_pos
		step_time += step_rate
		if step_time >= 1.0:
			in_step = false
	update_positions()
	update_IK()
	pass

func update_positions():
	if pin_body != null:
		posList[0] = pin_body.position
		pinPos = pin_body.global_position - global_position
	if target_body != null:
		endPos = target_body.global_position - global_position+cur_step_height
		pass

func update_target_position(new_position : Vector2):
	var flip = 1
	if flipped:
		flip = -1
	endPos = Vector2(flip*new_position.x,new_position.y)
	$Sprite.position = Vector2(endPos.x*flip,endPos.y)
	pass

func update_IK():
	var distance:float = (endPos -pinPos).length()
	var errorDist:float = (endPos -posList[posList.size() -1]).length()
	var itterations: = 0
	# limit the itteration count
	while itterations < 10:
		backward_reach()
		forward_reach()
		errorDist = (endPos -posList[posList.size() -1]).length()
		itterations += 1
	for i in posList.size() -1:
		if !flipped:
			draw_start[i] = lerp(draw_start[i],posList[i],smoothness)
			draw_end[i] = lerp(draw_end[i],posList[i+1],smoothness)
		if flipped:
			draw_start[i] = lerp(draw_start[i],Vector2(-posList[i].x,posList[i].y),smoothness)
			draw_end[i] = lerp(draw_end[i],Vector2(-posList[i+1].x,posList[i+1].y),smoothness)
	update()
	if (raycast_collision.x-endPos.x) > 220:
		if !in_step:
			emit_signal("step", self)
			in_step = true
		

func step(target_position_point : Vector2):
	if target_body != null:
		start_position = endPos
		end_position = target_position_point - global_position
		intermediate_position = (start_position + end_position)/2.0+Vector2(0,-step_height)
		step_time = 0.0
	pass

func straight_reach()->void:
	var direction:Vector2 = (endPos -pinPos).normalized()
	for i in posList.size():
		posList[i] = pinPos +(i *direction *length)

func backward_reach()->void:
	var last: = posList.size() -1
	posList[last] = endPos
	var prev_angle = 0
	for i in last:
		var p1:Vector2 = posList[last -i]
		var p2:Vector2 = posList[last -1 -i]
		var dir:Vector2 = (p2 -p1).normalized()
		
		if last-i-2 >= 0:
			var previous_angle = 0
			var inv_dir = -1*dir

			var p1_previous:Vector2 = posList[last-i-2]
			var p2_previous:Vector2 = posList[last-i-1]
			var dir_previous:Vector2 = (p2_previous -p1_previous).normalized()

			previous_angle = dir_previous.angle()
			var cur_angle = inv_dir.angle()

			var new_angle_limit_min = previous_angle + deg2rad(limb_angle_min)
			var new_angle_limit_max = previous_angle + deg2rad(limb_angle_max)

			var new_angle = clamp(cur_angle,new_angle_limit_min,new_angle_limit_max)

			var new_dir = Vector2(cos(new_angle),sin(new_angle)).normalized()

			dir = -1*new_dir
		
		p2 = p1 +(dir *length)
		posList[last -1 -i] = p2

func forward_reach()->void:
	posList[0] = pinPos
	var prev_angle = 0
	for i in posList.size() -1:
		var p1:Vector2 = posList[i]
		var p2:Vector2 = posList[i +1]
		var dir:Vector2 = (p2 -p1).normalized()
		
		#####limit angles
		if i > 0:
			var previous_angle = 0
			var p1_previous:Vector2 = posList[i-1]
			var p2_previous:Vector2 = posList[i]
			var dir_previous:Vector2 = (p2_previous -p1_previous).normalized()

			previous_angle = dir_previous.angle()
			var cur_angle = dir.angle()
			var new_angle_limit_min = previous_angle + deg2rad(limb_angle_min)
			var new_angle_limit_max = previous_angle + deg2rad(limb_angle_max)

			var new_angle = clamp(cur_angle,new_angle_limit_min,new_angle_limit_max)
			var new_dir = Vector2(cos(new_angle),sin(new_angle)).normalized()
			dir = new_dir
		
		p2 = p1 +(dir *length)
		posList[i +1] = p2
