tool
class_name SmoothPath
extends Path2D

export(float) var spline_length = 100
export(bool) var _smooth setget smooth
export(bool) var _straighten setget straighten

export(Color) var color := Color(1,1,1,1) setget set_color
export var width = 8 setget set_width 

func set_color(value):
	color = value
	update()

func set_width(value):
	width = value
	update()

func straighten(value):
	if not value: return
	for i in curve.get_point_count():
		curve.set_point_in(i, Vector2())
		curve.set_point_out(i, Vector2())

func smooth(value):
	if not value: return

	var point_count = curve.get_point_count()
	for i in point_count:
		var spline = _get_spline(i)
		curve.set_point_in(i, -spline)
		curve.set_point_out(i, spline)

func _get_spline(i):
	var last_point = _get_point(i - 1)
	var next_point = _get_point(i + 1)
	var spline = (next_point-last_point).normalized() * spline_length
	return spline

func _get_point(i):
	var point_count = curve.get_point_count()
	i = wrapi(i, 0, point_count - 1)
	return curve.get_point_position(i)

func _draw():
	var point_count = curve.get_point_count()
	if point_count < 2:
		return
	var points = curve.get_baked_points()
	if points:
		draw_polyline(points, color, width, true)

