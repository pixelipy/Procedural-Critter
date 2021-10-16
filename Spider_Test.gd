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

func _ready():
	for i in get_tree().get_nodes_in_group("Leg"):
		var pin = Position2D.new()
		pin.position = i.position
		
		var ray = RayCast2D.new()
		ray.set_cast_to(Vector2(0,400))
		var flipped = i.flipped
		var flip = 1
		if flipped:
			flip = -0.15
		var max_leg_extension =flip*((i.length-10) * (i.segmentCount))
		
		i.max_leg_distance = max_leg_extension
		i.add_to_group(str("leg",i.order))
		ray.position = i.position + Vector2(max_leg_extension,0)
		ray.enabled = true
		i.set_ray(ray)
		$Spider/Body.add_child(pin)
		$Spider/Body.add_child(ray)
		ray.force_raycast_update()
		i.set_pin(pin)
		i.step(i.order)

func _on_IK_step():
	if can_step:
		for i in get_tree().get_nodes_in_group(str("leg",cur_order)):
			update_leg_info(i)
			i.step(cur_order)
		can_step = false
		
		$min_step_timer.start()
	pass # Replace with function body.

func update_leg_info(leg : Node2D):
	var flipped = leg.flipped
	var flip = 1
	if flipped:
		flip = -1
	
	var motion_fraction = $Spider.motion_fraction
	var max_leg_extension
	if $Spider.motion_fraction < 0:
		leg.flipped = !leg.originally_flipped
		leg.flip(leg.flipped)
		leg.max_leg_distance = -abs(leg.max_leg_distance)
		
		
		
		
	else:
		leg.flipped = leg.originally_flipped
		leg.flip(leg.flipped)
		leg.max_leg_distance = abs(leg.max_leg_distance)
	
#	var max_leg_extension =sign(motion_fraction)*((leg.length-10) * (leg.segmentCount))
	
#	leg.max_leg_distance = max_leg_extension
	leg.ray_cast.position = leg.position + Vector2(leg.max_leg_distance,0)
	
	pass

func _physics_process(delta):
	for i in get_tree().get_nodes_in_group("Leg"):
		if $Spider.motion.x !=0:
			update_leg_info(i)
			pass

func _on_min_step_timer_timeout():
	$Spider.bump()
	cur_order = cur_order + 1
	cur_order %= total_order
	can_step = true
	
	pass # Replace with function body.

func _on_Spider_change_direction(new_dir : int):
	$Spider/Body/Torso.scale.x = new_dir*abs($Spider/Body/Torso.scale.x)
	_on_IK_step()
	pass # Replace with function body.

