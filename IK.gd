extends Node2D

var pinPos:Vector2
var endPos: = Vector2.ZERO
var posList: = []
var draw_start :=[]
var draw_end :=[]
var intermediate_position = Vector2.ZERO
var start_position = Vector2.ZERO
var end_position = Vector2.ZERO
var cur_target_position = Vector2.ZERO
var step_time= 0.0
var max_leg_distance : float = 90
var pin_body = null
var in_step = false
var ray_cast : RayCast2D = null

onready var target_body = $target

export var length : Array = [70,70,70,70]
export var segmentCount: = 3
export var flipped = false
export var step_smoothness = 0.2
export var step_height = 50.0
export var step_rate = 0.15
export var clockwise_constraint : float= 90.0
export var anticlockwise_constraint : float= 0.1
export var joint_thickness : Array = [8,5,3,1]
export var order = 0
export var line_width := 1.5
export var leg_color := Color(0,0,0) setget set_color

var totalLength : int
var clockwiseConstraintAngle = clockwise_constraint
var antiClockwiseConstraintAngle = anticlockwise_constraint
var originally_flipped

signal step
signal finished_step
	
func _draw()->void:
	var col: = Color.brown
	var normal_vectors = []
	var points = []
	var colors = []
	
	for i in range(posList.size()-1):
		var vec
		if i > 0 and i < posList.size()-1:
			vec = (draw_start[i+1]-draw_start[i-1]).normalized()
		else:
			vec = (draw_start[i+1]-draw_start[i]).normalized()
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
	
	var last_point = (points[0] + points[points.size()-1])/2
	var last_point_vec = (points[0] - points[points.size()-1]).normalized()
	var last_point_normal = Vector2(last_point_vec.y,-last_point_vec.x)
	last_point -= last_point_normal*3.0
	points.append(last_point)
	
	
	var point_pool = PoolVector2Array(points)
	
	
	if !Geometry.triangulate_polygon(point_pool).empty():
		draw_colored_polygon(point_pool, leg_color,point_pool,null,null,true)
	
	point_pool.append(point_pool[0])
	point_pool.append(point_pool[1])
	
#	draw_polyline(point_pool,Color.black,line_width)

func _ready()->void:
	for i in length.size():
		totalLength +=length[i]
	
	originally_flipped = flipped
	flip(flipped)
	pinPos = Vector2.ZERO
	# add point list including pinPos by default pointing up
	for i in segmentCount +1:
		if i == 0:
			posList.append(pinPos)
		else:
			posList.append(pinPos +(i *Vector2.UP *length[i-1]))
	for i in posList.size():
		draw_start.append(posList[i])

func flip(flipped : bool):
	if flipped:
		clockwiseConstraintAngle = anticlockwise_constraint
		antiClockwiseConstraintAngle = clockwise_constraint
	else:
		clockwiseConstraintAngle = clockwise_constraint
		antiClockwiseConstraintAngle = anticlockwise_constraint
	pass

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
		endPos = target_body.global_position - global_position
#		endPos = get_local_mouse_position()
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
		draw_start[i] = lerp(draw_start[i],posList[i],step_smoothness)
#		draw_end[i] = lerp(draw_end[i],posList[i+1],smoothness)
	draw_start[0] = posList[0]
	update()
	if (ray_cast.get_collision_point()-target_body.global_position).length() > 30:
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
		if i == 0:
			posList[i] = pinPos
		else:
			posList[i] = pinPos +(i *direction *length[i-1])

func backward_reach()->void:
	var last: = posList.size() -1
	posList[last] = endPos
	for i in range(last,0,-1):
		if i != last:
			var p1:Vector2 = posList[i]
			var p2:Vector2 = posList[i-1]
			var dir:Vector2 = (p2 -p1).normalized()
			
			var previous_p1 = posList[i+1]
			var previous_p2 = posList[i]
			var previous_dir = (previous_p2 -previous_p1).normalized()
			
			var constrained_dir = constrain_angle(dir,previous_dir,clockwiseConstraintAngle,antiClockwiseConstraintAngle)
			dir = constrained_dir
			p2 = p1 +(dir *length[i-1])
			posList[i-1] = p2
		else:
			var p1:Vector2 = posList[i]
			var p2:Vector2 = posList[i-1]
			var dir:Vector2 = (p2 -p1).normalized()

			var previous_p1 = posList[i-1]
			var previous_p2 = posList[i-2]
			var previous_dir = (previous_p2 -previous_p1).normalized()

			var constrained_dir = constrain_angle(dir,previous_dir,clockwiseConstraintAngle,antiClockwiseConstraintAngle)
			dir = constrained_dir
			p2 = p1 +(dir *length[i-1])
			posList[i-1] = p2
			pass

func forward_reach()->void:
	
	posList[0] = pinPos
	for i in posList.size()-1:
		var p1:Vector2 = posList[i]
		var p2:Vector2 = posList[i+1]
		var dir:Vector2 = (p2 -p1).normalized()

		if i >= 1:
			var previous_p1 = posList[i-1]
			var previous_p2 = posList[i]
			var previous_dir = (previous_p2-previous_p1).normalized()
			var constrained_dir = constrain_angle(dir,previous_dir,clockwiseConstraintAngle,antiClockwiseConstraintAngle)
			dir = constrained_dir

		p2 = p1 +(dir *length[i])
		posList[i+1] = p2

func constrain_angle(dir : Vector2, baseline : Vector2, clockwiseAngle : int, antiClockwiseAngle : int):
	var angle = baseline.angle_to(dir)
	
	if rad2deg(angle) > clockwiseAngle:
		return baseline.rotated(deg2rad(clockwiseAngle))
	if rad2deg(angle) < -antiClockwiseAngle:
		return baseline.rotated(deg2rad(-antiClockwiseAngle))
	
	return dir
	pass

func set_color(value):
	leg_color = value
	update()
