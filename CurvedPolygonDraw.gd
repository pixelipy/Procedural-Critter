extends Control

#button references
onready var body_node = $Body
onready var path = $Body/Creature/Path
onready var curve = path.curve

#draw settings
export var point_circle_size = 3
export var handle_size = 4
var shadow_border = 15
var shadow_offset = 13
var shadow_levels = 2

#active modes. Only on can be active at a time
var add_mode = true
var edit_mode = false
var add_member_mode = false
var flipped = false
#control the points that are selected, or about to be selected
var selected = -1
var selected_in_point = false
var selected_out_point = false
var to_select = -1
var body_selected = false
var original_grab_position = Vector2.ZERO
var original_curve_points = []
var light_direction = Vector2.ZERO

#control the selections range
var point_select_range = 4
var handle_select_range = 7
var about_to_select_range = 50
var hide_point_range = 100

#helper booleans
var can_add_point = true
var held = false
var inside_body = false
var hide_points = false
var shadow_intensity = 0.5
var invalid_shape = false

#scenes to be created and saved
var body_polygon = null
var shadow_polygons = []

var shadow_polygon : Polygon2D
var on_light = false
var handling_light = false
var center = Vector2.ZERO
onready var leg_scene = preload("res://IK.tscn")
onready var area = $Body/Area2D
onready var collisionShape = $Body/Area2D/CollisionPolygon2D
onready var add_material = preload("res://materials/add.tres")
onready var light = $Light

func _ready():
	for i in get_tree().get_nodes_in_group("button"):
		i.connect("mouse_entered", self, "on_mouse_entered")
	
#check for inputs
func _input(event):
	if event is InputEventMouseButton:
		
		#adds a member to the creature
		if Input.is_action_pressed("mb_left") and add_member_mode:
			if add_member_mode:
				add_member(get_global_mouse_position())
				add_member_mode = false
				return
		
		if Input.is_action_pressed("mb_left") and on_light:
			handling_light = true
		else:
			handling_light = false
		
		#adds a point into a position
		if event.is_action_pressed("mb_left") and can_add_point and add_mode and !on_light and !handling_light:
			add_point(get_global_mouse_position())
		
		#checks if one point on the curve has been selected
		if event.is_action_pressed("mb_left") and edit_mode:
			var closest_point_index = -1
			var pos = get_global_mouse_position()
			var closest_point = path.curve.get_closest_point(pos)
			var point_count = curve.get_point_count()
			
			#select point
			if is_in_range(pos,closest_point,point_select_range):
				if selected != -1:
					var selected_point = path.curve.get_point_position(selected)
					if is_in_range(closest_point,selected_point,point_select_range):
						return
				for i in point_count:
					var cur_point = curve.get_point_position(i)
					if is_in_range(pos,cur_point,point_select_range):
						closest_point_index = i
						continue
				if closest_point_index != -1:
					selected = closest_point_index
					if hide_points:
						hide_points = false
					path.update()
					update()
			
			#if no point has been selected, check if the handles have been selected
			if selected != -1:
				#check for the handles 
				var handle_in_pos = curve.get_point_in(selected)
				var handle_out_pos = curve.get_point_out(selected)
				var relative_point_position = get_global_mouse_position()-path.curve.get_point_position(selected)
				
				#select in point
				if is_in_range(relative_point_position,handle_in_pos,handle_select_range):
					selected_in_point = true
					selected_out_point = false
				#select out point
				elif is_in_range(relative_point_position,handle_out_pos,handle_select_range):
					selected_out_point = true
					selected_in_point = false
				#select none (deselect)
				else:
					selected_out_point = false
					selected_in_point = false
			
			#if no point,no handle and no polygon was selected
			if closest_point_index == -1 and selected_in_point == false and selected_out_point == false and !inside_body:
				selected = -1
				hide_points = true
				update()
			
			#if no point and no handle was selected, but the polygon was selected
			if closest_point_index == -1 and selected_in_point == false and selected_out_point == false and inside_body and !add_member_mode:
				#drag_body
				hide_points = false
				body_selected = true
				original_grab_position = get_global_mouse_position()
				original_curve_points = []
				for i in curve.get_point_count():
					original_curve_points.append(curve.get_point_position(i))
				
				update()
				pass

func light_update():
	var center_point = Vector2.ZERO
	if path.curve.get_point_count() <=0:
		return
	
	for i in path.curve.get_point_count():
		center_point += path.curve.get_point_position(i)
	center_point = center_point/path.curve.get_point_count()
	light_direction = (light.position - center_point).normalized()
	pass





#physics process
func _physics_process(delta):
	if get_global_mouse_position().x>520:
		can_add_point = false
	else:
		can_add_point = true
	
	if Input.is_action_pressed("mb_left") and handling_light:
		light.global_position = get_global_mouse_position()
		light_update()
		body_update()
		shadow_update()
		pass
	elif Input.is_action_pressed("mb_left") and edit_mode:
		#if main point is selected
		if selected != -1:
			var first_point_selected = (selected ==0 or selected == path.curve.get_point_count()-1)
			if ((path.curve.get_point_position(selected)-get_global_mouse_position()).length()<point_select_range or held) and !(selected_in_point or selected_out_point):
				held = true
				if first_point_selected:
					path.curve.set_point_position(0,get_global_mouse_position())
					path.curve.set_point_position(path.curve.get_point_count()-1,get_global_mouse_position())
				else:
					path.curve.set_point_position(selected,get_global_mouse_position())
			#if handle is selected / held
			elif selected_in_point:
				if first_point_selected:
					path.curve.set_point_in(0,get_global_mouse_position()-path.curve.get_point_position(0))
					path.curve.set_point_in(path.curve.get_point_count()-1,get_global_mouse_position()-path.curve.get_point_position(path.curve.get_point_count()-1))
				else:
					path.curve.set_point_in(selected,get_global_mouse_position()-path.curve.get_point_position(selected))
			elif selected_out_point:
				if first_point_selected:
					path.curve.set_point_out(0,get_global_mouse_position()-path.curve.get_point_position(0))
					path.curve.set_point_out(path.curve.get_point_count()-1,get_global_mouse_position()-path.curve.get_point_position(path.curve.get_point_count()-1))
				else:
					path.curve.set_point_out(selected,get_global_mouse_position()-path.curve.get_point_position(selected))
		if body_selected and !invalid_shape:
			var grab_offset = get_global_mouse_position()-original_grab_position
			for i in curve.get_point_count():
				curve.set_point_position(i,original_curve_points[i]+grab_offset)
			pass
		
		
		body_update()
		shadow_update()
		collisionShapeUpdate()
		path.update()
		update()
		
	if Input.is_action_just_released("mb_left") and edit_mode:
		held = false
		selected_in_point = false
		selected_out_point = false
		body_selected = false
		handling_light = false
	pass


#draws the points
func _draw():
	for i in path.curve.get_point_count():
		
		if hide_points and !invalid_shape:
			if path.visible:
				path.visible = false
			return
		if !path.visible:
			path.visible = true
		var point_pos = path.curve.get_point_position(i)
		var handle_in_pos = point_pos+path.curve.get_point_in(i)
		var handle_out_pos = point_pos+path.curve.get_point_out(i)
		
		if selected ==i:
			var rect_in = Rect2(handle_in_pos.x-handle_size/2,handle_in_pos.y-handle_size/2,handle_size,handle_size)
			var rect_out = Rect2(handle_out_pos.x-handle_size/2,handle_out_pos.y-handle_size/2,handle_size,handle_size)
			
			draw_line(point_pos,handle_in_pos,Color.black,1)
			draw_line(point_pos,handle_out_pos,Color.black,1)
			
			draw_rect(rect_in,Color.black,false,2)
			draw_rect(rect_in,Color.blue)
			draw_rect(rect_out,Color.black,false,2)
			draw_rect(rect_out,Color.blue)
			
			draw_circle(point_pos,point_circle_size+1,Color.black)
			draw_circle(point_pos,point_circle_size,Color.yellow)
		else:
			draw_circle(point_pos,point_circle_size+1,Color.black)
			draw_circle(point_pos,point_circle_size,Color.red)

# add point into position
func add_point(pos : Vector2):
	hide_points = false
	var point_pos = Vector2(pos.x,pos.y)
	var cur_point_count = path.curve.get_point_count()
	
	if cur_point_count == 0:
		path.curve.add_point(point_pos,Vector2.ZERO,Vector2.ZERO,0)
	else:
		path.curve.add_point(point_pos,Vector2.ZERO,Vector2.ZERO,cur_point_count)
	
	selected = cur_point_count
	
	path.smooth(true)
	path.update()
	update()


#check if mouse has entered or exited a body in the group button
func on_mouse_entered():
	can_add_point = false
	pass


#clear curve
func _on_Clear_curve_pressed():
	selected = -1
	can_add_point = true
	edit_mode = false
	add_mode = true
	path.curve.clear_points()
	update()
	path.visible = true
	path.update()
	body_delete()
	$Edges/Buttons/close_curve.disabled = false
	pass # Replace with function body.


#close curve
func _on_close_curve_pressed():
	if path.curve.get_point_count() < 3:
		return
	add_mode = false
	edit_mode = true
#	path.visible = false
	$Edges/Buttons/Add_leg.disabled = false
	$Edges/Buttons/add_flipped.disabled = false
	$Edges/Buttons/close_curve.disabled = true
	var first_point_pos = path.curve.get_point_position(0)
	
	add_point(first_point_pos)
	light_update()
	body_create()
	yield(get_tree(),"idle_frame")
	light_update()
	body_update()
	shadow_update()
	collisionShapeUpdate()
	pass # Replace with function body.


#mouse inside and outside the drawing panel
func _on_Drawing_Panel_mouse_entered():
	can_add_point = true
	update()
	pass # Replace with function body.


func _on_Drawing_Panel_mouse_exited():
	can_add_point = false
	if selected == -1:
		hide_points = true
	update()
	pass # Replace with function body.


#if mouse has entered/exited the polygon
func _on_Area2D_mouse_entered():
	inside_body = true
	pass # Replace with function body.


func _on_Area2D_mouse_exited():
	inside_body = false
	pass # Replace with function body.


func _on_Add_leg_pressed():
	add_member_mode = true
	flipped = false
	pass # Replace with function body.

func _on_add_flipped_pressed():
	add_member_mode = true
	flipped = true
	pass # Replace with function body.


#create, update and delete body
func body_create():
	var polygon = curve.get_baked_points()
	body_polygon = Polygon2D.new()
	var body_polygon_points : PoolVector2Array = []
	for i in polygon.size():
		body_polygon_points.append(polygon[i]+light_direction*shadow_offset)
	
	body_polygon.polygon = body_polygon_points
	body_polygon.color = Color.blueviolet
	
	for j in shadow_levels:
		var shadow_polygon_points : PoolVector2Array = []
		var new_shadow_polygon = Polygon2D.new()
		new_shadow_polygon.color = body_polygon.color.darkened((j+1)*shadow_intensity/float(shadow_levels))
		var is_polygon_clockwise = Geometry.is_polygon_clockwise(polygon)
		var rotation = PI/2
		if !is_polygon_clockwise:
			rotation = -PI/2
		for i in polygon.size():
			var previous_point_idx = wrapi(i-1,0,polygon.size())
			var next_point_idx = wrapi(i+1,0,polygon.size())
			
			var previous_point = polygon[previous_point_idx]
			var next_point = polygon[next_point_idx]
			
			var vector : Vector2= (next_point-previous_point).normalized()
			var normal = vector.rotated(rotation)
			
			if j != shadow_polygons.size()-1:
				var last=shadow_polygons.size()-1
				shadow_polygon_points.append(polygon[i]+normal*shadow_border*(j+1)/float(shadow_levels)+light_direction*shadow_offset*(last-j)/shadow_levels)
			else:
				shadow_polygon_points.append(polygon[i]+normal*shadow_border*(j+1)/float(shadow_levels))
		new_shadow_polygon.polygon = shadow_polygon_points
		
		shadow_polygons.append(new_shadow_polygon)
	
	for i in range(shadow_polygons.size()-1,-1,-1):
		$Body/Creature.add_child(shadow_polygons[i])
		shadow_polygons[i].show_behind_parent = true
	$Body/Creature.add_child(body_polygon)
	
#	body_polygon.add_child(shadow_polygon)
#	collisionShape.polygon = points
#	body_polygon.visible = false
	body_polygon.show_behind_parent = true
	pass


func body_update():
	if body_polygon != null:
		var polygon = path.curve.get_baked_points()
		var body_polygon_points : PoolVector2Array = []
		
		if !Geometry.triangulate_polygon(polygon).empty():
			for i in polygon.size():
				body_polygon_points.append(polygon[i]+light_direction*shadow_offset)
			body_polygon.polygon = body_polygon_points
			path.color = Color.black
			invalid_shape = false
		else:
			invalid_shape = true
			path.color = Color.red

func shadow_update():
	if shadow_polygons != []:
		var polygon = path.curve.get_baked_points()
		var is_polygon_clockwise = Geometry.is_polygon_clockwise(polygon)
		var rotation = PI/2
		if !is_polygon_clockwise:
			rotation = -PI/2
		for j in shadow_polygons.size():
			var shadow_polygon_points : PoolVector2Array = []
			for i in polygon.size():
				
				var previous_point_idx = wrapi(i-1,0,polygon.size())
				var next_point_idx = wrapi(i+1,0,polygon.size())
				
				var previous_point = polygon[previous_point_idx]
				var next_point = polygon[next_point_idx]
				
				var vector : Vector2= (next_point-previous_point).normalized()
				var normal = vector.rotated(rotation)
				if j != shadow_polygons.size()-1:
					var last=shadow_polygons.size()-1
					shadow_polygon_points.append(polygon[i]+normal*shadow_border*(j+1)/float(shadow_levels)+light_direction*shadow_offset*(last-j)/shadow_levels)
				else:
					shadow_polygon_points.append(polygon[i]+normal*shadow_border*(j+1)/float(shadow_levels))
			
			if !Geometry.triangulate_polygon(shadow_polygon_points).empty() and !Geometry.triangulate_polygon(polygon).empty():
				shadow_polygons[j].polygon = shadow_polygon_points
	pass

func collisionShapeUpdate():
	if shadow_polygons != []:
		var polygon = shadow_polygons[shadow_polygons.size()-1].polygon
		if !Geometry.triangulate_polygon(polygon).empty():
			var shape = Geometry.convex_hull_2d(polygon)
			collisionShape.polygon = shape
		pass
	pass





func body_delete():
	if body_polygon != null:
		body_polygon.queue_free()
		body_polygon = null
	if shadow_polygon != null:
		shadow_polygon.queue_free()
		shadow_polygon = null
	pass


func add_member(pos : Vector2):
	
	## initialize leg
	var member = leg_scene.instance()
	
	var total_length = 0
	for j in member.length:
			total_length += j
			
	var flip = 0.7
	if flipped:
		flip = -0.7
	
	member.flipped = flipped
	
	
	var max_leg_extension =flip*total_length
	member.max_leg_distance = max_leg_extension
	
	#set pin the leg will be attached to
	var pin = Position2D.new()
	pin.position = pos
	
	
	#set the raycast used by the member
	var ray = RayCast2D.new()
	ray.set_cast_to(Vector2(0,400))
	ray.position = pin.position + Vector2(0.7*max_leg_extension,0)
	ray.enabled = true
	ray.force_raycast_update()
	
	$Body/Creature.add_child(ray)
	$Body/Creature.add_child(pin)
	body_node.add_child(member)
	
	member.set_ray(ray)
	member.set_pin(pin)
	yield(get_tree(),"idle_frame")
	member.step(member.order)
	pass


func is_in_range(point1 : Vector2, point2 : Vector2, check_range : float):
	return (point1-point2).length()<check_range


func _on_red_slider_value_changed(value):
	if body_polygon == null:
		return
	var cur_color = body_polygon.color
	body_polygon.color = Color(value,cur_color.g,cur_color.b)
	for i in shadow_polygons.size():
		shadow_polygons[i].color = body_polygon.color.darkened((i+1)*shadow_intensity/float(shadow_levels))
	pass # Replace with function body.

func _on_green_slider_value_changed(value):
	if body_polygon == null:
		return
	var cur_color = body_polygon.color
	body_polygon.color = Color(cur_color.r,value,cur_color.b)
	for i in shadow_polygons.size():
		shadow_polygons[i].color = body_polygon.color.darkened((i+1)*shadow_intensity/float(shadow_levels))
	pass # Replace with function body.

func _on_blue_slider_value_changed(value):
	if body_polygon == null:
		return
	var cur_color = body_polygon.color
	body_polygon.color = Color(cur_color.r,cur_color.g,value)
	for i in shadow_polygons.size():
		shadow_polygons[i].color = body_polygon.color.darkened((i+1)*shadow_intensity/float(shadow_levels))
	pass # Replace with function body.

func _on_Light_mouse_entered():
	on_light = true
	pass # Replace with function body.

func _on_Light_mouse_exited():
	on_light = false
	pass # Replace with function body.
