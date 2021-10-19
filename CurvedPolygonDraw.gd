extends Control

onready var path = $Path
onready var close_path_button = $Button
export var point_circle_size = 3
export var handle_size = 4
var add_mode = true
var edit_mode = false
var can_add_point = true
var selected = -1
var selected_in_point = false
var selected_out_point = false
var held = false
var point_select_range = 4
var handle_select_range = 7

func _ready():
	for i in get_tree().get_nodes_in_group("button"):
		i.connect("mouse_entered", self, "on_mouse_entered")
		i.connect("mouse_exited", self, "on_mouse_exited")

func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("mb_left") and can_add_point and add_mode:
			add_point(get_global_mouse_position())
		if event.is_action_pressed("mb_left") and edit_mode:
			var closest_point_index = -1
			var pos = get_global_mouse_position()
			var closest_point = path.curve.get_closest_point(pos)
			
			#select point
			if (pos-closest_point).length()<point_select_range:
				if (closest_point - path.curve.get_point_position(selected)).length()<point_select_range:
					print ("already selected")
					return
				for i in path.curve.get_point_count():
					var cur_point = path.curve.get_point_position(i)
					if (pos-cur_point).length()<point_select_range:
						closest_point_index = i
						continue
				if closest_point_index != -1:
					selected = closest_point_index
					path.update()
					update()
			
			if selected != -1:
				#check for the handles 
				var handle_in_pos = path.curve.get_point_in(selected)
				var handle_out_pos = path.curve.get_point_out(selected)
				var relative_point_position = get_global_mouse_position()-path.curve.get_point_position(selected)
				
				if ((relative_point_position-handle_in_pos).length() < handle_select_range):
					selected_in_point = true
					selected_out_point = false
				elif ((relative_point_position-handle_out_pos).length() < handle_select_range):
					selected_out_point = true
					selected_in_point = false
				else:
					selected_out_point = false
					selected_in_point = false
			
			if closest_point_index == -1 and selected_in_point == false and selected_out_point == false:
				selected = -1
				path.update()
				update()

func _physics_process(delta):
	if Input.is_action_pressed("mb_left") and edit_mode:
		if selected == -1:
			return
		#if main point is selected
		
		var first_point_selected = (selected ==0 or selected == path.curve.get_point_count()-1)
		if ((path.curve.get_point_position(selected)-get_global_mouse_position()).length()<point_select_range or held) and !(selected_in_point or selected_out_point):
			held = true
			if first_point_selected:
				
				path.curve.set_point_position(0,get_global_mouse_position())
				path.curve.set_point_position(path.curve.get_point_count()-1,get_global_mouse_position())
				pass
			else:
				path.curve.set_point_position(selected,get_global_mouse_position())
			update()
			path.update()
		#if handle is selected / held
		elif selected_in_point:
			if first_point_selected:
				path.curve.set_point_in(0,get_global_mouse_position()-path.curve.get_point_position(0))
				path.curve.set_point_in(path.curve.get_point_count()-1,get_global_mouse_position()-path.curve.get_point_position(path.curve.get_point_count()-1))
			else:
				path.curve.set_point_in(selected,get_global_mouse_position()-path.curve.get_point_position(selected))
			update()
			path.update()
		elif selected_out_point:
			if first_point_selected:
				path.curve.set_point_out(0,get_global_mouse_position()-path.curve.get_point_position(0))
				path.curve.set_point_out(path.curve.get_point_count()-1,get_global_mouse_position()-path.curve.get_point_position(path.curve.get_point_count()-1))
			else:
				path.curve.set_point_out(selected,get_global_mouse_position()-path.curve.get_point_position(selected))
			update()
			path.update()
		pass
	if Input.is_action_just_released("mb_left") and edit_mode:
		held = false
		selected_in_point = false
		selected_out_point = false
		pass
	
	pass


func add_point(pos : Vector2):
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

func _draw():
	for i in path.curve.get_point_count():
		
		var point_pos = path.curve.get_point_position(i)
		if i == selected:
			draw_circle(point_pos,point_circle_size,Color.yellow)
		else:
			draw_circle(point_pos,point_circle_size,Color.red)
		if selected ==i:
			var handle_in_pos = point_pos+path.curve.get_point_in(i)
			var handle_out_pos = point_pos+path.curve.get_point_out(i)
			
			var rect_in = Rect2(handle_in_pos.x-handle_size/2,handle_in_pos.y-handle_size/2,handle_size,handle_size)
			var rect_out = Rect2(handle_out_pos.x-handle_size/2,handle_out_pos.y-handle_size/2,handle_size,handle_size)
			
			draw_line(point_pos,handle_in_pos,Color.white,1)
			draw_line(point_pos,handle_out_pos,Color.white,1)
			
			draw_rect(rect_in,Color.blue)
			draw_rect(rect_out,Color.blue)

func on_mouse_entered():
	can_add_point = false
	pass

func on_mouse_exited():
	can_add_point = true
	pass

func _on_Clear_curve_pressed():
	edit_mode = false
	add_mode = true
	path.curve.clear_points()
	update()
	path.update()
	pass # Replace with function body.


func _on_close_curve_pressed():
	add_mode = false
	edit_mode = true
	var first_point_pos = path.curve.get_point_position(0)
	add_point(first_point_pos)
	pass # Replace with function body.
