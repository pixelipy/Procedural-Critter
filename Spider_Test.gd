extends Node2D

export var x_speed = 20
export var y_speed = 40

export var step_rate = 0.15
var time_since_last_step = 0
var cur_f_leg = 0
var use_front = false
var body_offset = 0
var initial_pin_offset = Vector2.ZERO
var initial_target_offset = Vector2.ZERO
export var total_order = 2
var cur_order = 0
var can_step = true
export var cur_dir = 1
export var step_timer_wait_time = 0.35
var previous_dir = cur_dir
var sensor_distance = 25
func _ready():
	$min_step_timer.wait_time = step_timer_wait_time
	for i in get_tree().get_nodes_in_group("Leg"):
		var pin = Position2D.new()
		pin.position = i.position
		
		var ray = RayCast2D.new()
		ray.set_cast_to(Vector2(0,400))
		var flipped = i.flipped
		var flip = 0.7
		if flipped:
			flip = -0.15
		var length = 0
		for j in i.length:
			length += j
		var max_leg_extension =flip*(length)
		
		i.max_leg_distance = max_leg_extension
		
		i.add_to_group(str("leg",i.order))
		ray.position = i.position + Vector2(max_leg_extension,0)
		ray.enabled = true
		i.set_ray(ray)
		$Spider/Body.add_child(pin)
		$Spider/Body.add_child(ray)
		ray.force_raycast_update()
		i.set_pin(pin)
#		i.step(i.order)
	_on_Spider_change_direction(1)
	cur_dir = 1

func _on_IK_step():
	if can_step:
		for i in get_tree().get_nodes_in_group(str("leg",cur_order)):
			flip_leg(i,cur_dir)
			i.step(cur_order)
		can_step = false
		
		$min_step_timer.start()
	pass # Replace with function body.

func flip_leg(leg : Node2D, new_dir : int):
	var max_leg_extension
	if new_dir > 0:
		leg.flipped = leg.originally_flipped
		leg.flip(leg.flipped)
	elif new_dir < 0:
		leg.flipped = !leg.originally_flipped
		leg.flip(leg.flipped)
	
	var flipped = leg.flipped
	var flip = 1
	if flipped:
		flip = -1
	
	leg.ray_cast.position = leg.position + Vector2(cur_dir*leg.max_leg_distance,0)
	
	pass

func _physics_process(delta):
	for i in get_tree().get_nodes_in_group("Leg"):
		flip_leg(i, cur_dir)

func _on_min_step_timer_timeout():
	$Spider.bump()
	cur_order = cur_order + 1
	cur_order %= total_order
	can_step = true
	
	pass # Replace with function body.

func _on_Spider_change_direction(new_dir : int):
	$Spider/lowCheck.position.x = $Spider/Body/Torso.position.x + new_dir*sensor_distance
	$Spider/highCheck.position.x = $Spider/Body/Torso.position.x + new_dir*sensor_distance
	
	for i in get_tree().get_nodes_in_group("Leg"):
		previous_dir = cur_dir
		$Flip_tween.stop_all()
		$Flip_tween.interpolate_property(self,"cur_dir", cur_dir,new_dir,0.5,Tween.TRANS_LINEAR,Tween.EASE_OUT)
		$Flip_tween.interpolate_property($Spider/Body/Torso,"scale",Vector2(cur_dir,1),Vector2(new_dir,1),0.5,Tween.TRANS_LINEAR,Tween.EASE_OUT)
		$Flip_tween.start()
		$min_step_timer.wait_time = 0.15
		
	_on_IK_step()
	pass # Replace with function body.


func _on_Flip_tween_tween_started(object, key):
	
	pass # Replace with function body.


func _on_Flip_tween_tween_completed(object, key):
	$min_step_timer.wait_time = step_timer_wait_time
	pass # Replace with function body.
