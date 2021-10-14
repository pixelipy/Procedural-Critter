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
var smoothness = 0.2

var goal_pos = Vector2.ZERO
var int_pos = Vector2.ZERO
var start_pos = Vector2.ZERO
var step_height = 100.0 #how high the midpoint is
var cur_step_height = Vector2.ZERO
var step_rate = 0.15 # step velocity
var step_time= 0.0 #current time
var max_leg_distance = 90

var flipped_step_height = totalLength*0.15
var flipped_limb_angle_max = -limb_angle_max
var flipped_limb_angle_min = -limb_angle_min

var not_flipped_step_height = step_height
var not_flipped_limb_angle_max = limb_angle_max
var not_flipped_limb_angle_min = limb_angle_min

var pin_body = null
var raycast_collision = Vector2.ZERO

var go_up = false
var go_down = false
var intermediate_position = Vector2.ZERO
var start_position = Vector2.ZERO
var end_position = Vector2.ZERO
var cur_target_position = Vector2.ZERO
var in_step = false
var ray_cast : RayCast2D = null
var joint_thickness : Array = [15,8,3,1]

export var order = 0

onready var target_body = $target

signal step
signal finished_step
	
func _draw()->void:
	var col: = Color.black
	var normal_vectors = []
	var points = []
	var colors = []
	
	for i in range(posList.size()-1):
		var vec = (draw_start[i+1]-draw_start[i]).normalized()
		var normal_vector = Vector2(vec.y,-vec.x).normalized()
		normal_vectors.append(normal_vector)
	
	var vec = (draw_start[posList.size()-1]-draw_start[posList.size()-2]).normalized()
	var normal_vector = Vector2(vec.y,-vec.x).normalized()
	
	normal_vectors.append(normal_vector)
	
	for i in range(posList.size()):
		var point = draw_start[i]-normal_vectors[i]*joint_thickness[i]/2
		points.append(point)
	
	for i in range(posList.size()-1,-1,-1):
		var point = draw_start[i]+normal_vectors[i]*joint_thickness[i]/2
		points.append(point)
	
	var point_pool = PoolVector2Array(points)
	
	if !Geometry.triangulate_polygon(point_pool).empty():
		draw_colored_polygon(point_pool, col)

func _ready()->void:
	step_height = totalLength*0.5
	if flipped:
		step_height = flipped_step_height
		limb_angle_max = flipped_limb_angle_max
		limb_angle_min = flipped_limb_angle_min
	pinPos = Vector2.ZERO
	# add point list including pinPos by default pointing up
	for i in segmentCount +1:
		posList.append(pinPos +(i *Vector2.UP *length))
	for i in posList.size():
		draw_start.append(posList[i])

func set_ray(ray : RayCast2D):
	ray_cast = ray


func set_pin(initial_pin : Position2D):
	pin_body = initial_pin
	
	posList[0] = pin_body.position
	pinPos = pin_body.position
	
	pass

func _process(_delta:float)->void:
	var new_target_pos : Vector2= start_position
	
	if step_time >=0 and step_time <=1.0:
		if step_time < 0.5:
			new_target_pos = lerp(start_position,intermediate_position,step_time*2.0)
		#go to end position
		elif step_time >=0.5:
			new_target_pos = lerp(intermediate_position,end_position,(step_time-0.5)*2.0)
		if step_time >= 1.0:
			if in_step == true:
				emit_signal("finished_step",order)
			in_step = false
	step_time += step_rate
	step_time = clamp(step_time,-1.0,1.0)
	target_body.position = new_target_pos
	
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
	endPos = Vector2(new_position.x,new_position.y)
	$Sprite.position = Vector2(endPos.x,endPos.y)
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
	for i in posList.size():
		draw_start[i] = lerp(draw_start[i],posList[i],smoothness)
#		draw_end[i] = lerp(draw_end[i],posList[i+1],smoothness)
	draw_start[0] = posList[0]
	update()
	if (ray_cast.get_collision_point()-target_body.global_position).length() > 70:
		if !in_step:
			emit_signal("step")
	

func step(cur_order : int):
	if order != cur_order:
		return
	in_step = true
	var target_position_point = ray_cast.get_collision_point()
	
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
		
		if last-i-1 >= 0:
			var previous_angle = 0
			var inv_dir = -1*dir

			var p1_previous:Vector2 = posList[last-i-2]
			var p2_previous:Vector2 = posList[last-i-1]
			var dir_previous:Vector2 = (p2_previous -p1_previous).normalized()

			previous_angle = dir_previous.angle()
			var cur_angle = inv_dir.angle()

			var new_angle_limit_min = previous_angle + deg2rad(limb_angle_min)
			var new_angle_limit_max = previous_angle + deg2rad(limb_angle_max)
			
			var bigger_angle = max(new_angle_limit_max,new_angle_limit_min)
			var smaller_angle = min(new_angle_limit_max,new_angle_limit_min)
			
			var new_angle = clamp(cur_angle,smaller_angle,bigger_angle)
			
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
			
			var bigger_angle = max(new_angle_limit_max,new_angle_limit_min)
			var smaller_angle = min(new_angle_limit_max,new_angle_limit_min)
			
			var new_angle = clamp(cur_angle,smaller_angle,bigger_angle)

			var new_dir = Vector2(cos(new_angle),sin(new_angle)).normalized()
			dir = new_dir
		p2 = p1 +(dir *length)
		posList[i +1] = p2
