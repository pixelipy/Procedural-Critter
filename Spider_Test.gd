extends Node2D

onready var front_legs = $Front_legs.get_children()

export var x_speed = 20
export var y_speed = 40

export var step_rate = 0.15
var time_since_last_step = 0
var cur_f_leg = 0
var use_front = false
var initial_pin_offset = Vector2.ZERO
var initial_target_offset = Vector2.ZERO
export var total_order = 2
var cur_order = 0

func _ready():
	for i in get_tree().get_nodes_in_group("Leg"):
		var pin = Position2D.new()
		pin.position = i.position
		
		var ray = RayCast2D.new()
		ray.set_cast_to(Vector2(0,200))
		var flipped = i.flipped
		var flip = 1
		if flipped:
			flip = -1
		var max_leg_extension =((i.length) * (i.segmentCount))-(i.length)
		if flipped:
			max_leg_extension= 10
		
		i.max_leg_distance = max_leg_extension
		ray.position = i.position + Vector2(max_leg_extension,0)
		ray.enabled = true
		i.set_ray(ray)
		$Spider.add_child(pin)
		$Spider.add_child(ray)
		ray.force_raycast_update()
		i.set_pin(pin)
		i.step(i.order)

func _on_IK_step(leg : Node2D):
	leg.step(cur_order)
	pass # Replace with function body.

func _on_IK_finished_step(cur_leg_order : int):
	cur_order = cur_leg_order + 1
	cur_order %= total_order
	print (cur_order)
	pass # Replace with function body.
