extends Node2D

func _input(event):
	if event is InputEventKey:
		if Input.is_action_pressed("reload"):
			get_tree().reload_current_scene()
