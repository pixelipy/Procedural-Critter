extends Node2D

onready var front_check = $Spider/FrontCheck
onready var back_check = $Spider/BackCheck

onready var front_legs = $Front_legs.get_children()

export var x_speed = 20
export var y_speed = 40

export var step_rate = 0.15
var time_since_last_step = 0
var cur_f_leg = 0
var use_front = false
var initial_pin_offset = Vector2.ZERO
var initial_target_offset = Vector2.ZERO

func _ready():
	front_check.force_raycast_update()
	back_check.force_raycast_update()
	for i in get_tree().get_nodes_in_group("Leg"):
		var pin = Position2D.new()
		pin.position = i.position
		$Spider.add_child(pin)
		i.set_pin(pin)
		i.step(front_check.get_collision_point())
	initial_pin_offset = $Pin_Test.position - $Spider.position

func _physics_process(delta):
	$Pin_Test.position = $Spider.position + initial_pin_offset
	
	for i in get_tree().get_nodes_in_group("Leg"):
		i.raycast_collision = front_check.get_collision_point()
	

func _on_IK_step(leg : Node2D):
#	leg.get_node("target").set_global_position(front_check.get_collision_point())
	leg.step(front_check.get_collision_point())
	pass # Replace with function body.
