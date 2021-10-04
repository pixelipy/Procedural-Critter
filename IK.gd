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
func _draw()->void:
	var col: = Color.white
	for i in posList.size() -1:
		
#		var start:Vector2 = posList[i]
#		var end: Vector2 = posList[i +1]
#		var start:Vector2 = draw_start[i] +(posList[i]-draw_start[i]).normalized()*speed
#		var end: Vector2 = draw_end[i] +(posList[i+1]-draw_end[i]).normalized()*speed
		
		var start:Vector2 = draw_start[i]
		var end: Vector2 = draw_end[i]
		
		
		
#		var start:Vector2 = Vector2(start_x,start_y)
#		var end:Vector2 = Vector2(end_x,end_y)
		
		
		
		
		if flipped:
			start.x = -start.x
			end.x = -end.x
		
		draw_circle(start,5,Color.red)
		draw_line(start, end, col, 2)

# option to move around the pinned point
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var flip = 1
		if flipped:
			flip = -1
		if (pinPos-get_local_mouse_position()).length() > totalLength+total_length_buff:
			var direction_vector = (Vector2(flip*get_local_mouse_position().x,get_local_mouse_position().y)-pinPos).normalized()
			endPos = pinPos+(totalLength+total_length_buff)*direction_vector
		elif (pinPos-get_local_mouse_position()).length() < MIN_DIST:
			var direction_vector = (Vector2(flip*get_local_mouse_position().x,get_local_mouse_position().y)-pinPos).normalized()
			endPos = pinPos+MIN_DIST*direction_vector
		else:
			endPos = Vector2(flip*get_local_mouse_position().x,get_local_mouse_position().y)
		$Sprite.position = Vector2(endPos.x*flip,endPos.y)
	elif event.is_action_pressed("mb_left"):
		pinPos = get_local_mouse_position()
		posList[0] = pinPos

func _ready()->void:
	pinPos = Vector2.ZERO
	# add point list including pinPos by default pointing up
	for i in segmentCount +1:
		posList.append(pinPos +(i *Vector2.UP *length))
	for i in posList.size() -1:
		draw_start.append(posList[i])
		draw_end.append(posList[i+1])

func _process(_delta:float)->void:
	var distance:float = (endPos -pinPos).length()
	var errorDist:float = (endPos -posList[posList.size() -1]).length()
	var itterations: = 0
	# limit the itteration count
	while errorDist > errorMargin && itterations < 3:
		backward_reach()# start at endPos
		forward_reach() # start at pinPos
		errorDist = (endPos -posList[posList.size() -1]).length()
		itterations += 1
	update()
	for i in posList.size() -1:
		draw_start[i] = lerp(draw_start[i],posList[i],smoothness)
		draw_end[i] = lerp(draw_end[i],posList[i+1],smoothness)
	
	
	
	
	

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
	
#func backward_reach()->void:
#	var last: = posList.size() -1
#	posList[last] = endPos
#	var prev_angle = 0
#	for i in last:
#		var p1:Vector2 = posList[last -i]
#		var p2:Vector2 = posList[last -1 -i]
#		var dir:Vector2 = (p2 -p1).normalized()
#
#		if i == last-1:
#			prev_angle = 0
#		else:
#			var p1_previous:Vector2 = posList[last -i]
#			var p2_previous:Vector2 = posList[last -i-1]
#			var dir_previous:Vector2 = (p2_previous-p1_previous).normalized()
#			prev_angle = dir_previous.angle()
#		var new_angle_clamp_min = deg2rad(angle_list_min[last -i])+prev_angle
#		var new_angle_clamp_max = deg2rad(angle_list_max[last -i])+prev_angle
#		var new_angle = clamp(dir.angle(),new_angle_clamp_min, new_angle_clamp_max)
#		dir.x = cos(new_angle)
#		dir.y = sin(new_angle)
#		p2 = p1 +(dir *length)
#		posList[last -1 -i] = p2
#
#func forward_reach()->void:
#	posList[0] = pinPos
#	var prev_angle = 0
#	for i in posList.size() -1:
#		var p1:Vector2 = posList[i]
#		var p2:Vector2 = posList[i +1]
#		var dir:Vector2 = (p2 -p1).normalized()
#		if i == 0:
#			prev_angle = 0
#		else:
#			var p1_previous:Vector2 = posList[i-1]
#			var p2_previous:Vector2 = posList[i]
#			var dir_previous:Vector2 = (p2_previous-p1_previous).normalized()
#			prev_angle = dir_previous.angle()
#		var new_angle_clamp_min = deg2rad(angle_list_min[i])+prev_angle
#		var new_angle_clamp_max = deg2rad(angle_list_max[i])+prev_angle
#		var new_angle = clamp(dir.angle(),new_angle_clamp_min, new_angle_clamp_max)
#		dir.x = cos(new_angle)
#		dir.y = sin(new_angle)
#
#		p2 = p1 +(dir *length)
#		posList[i +1] = p2
#
#
