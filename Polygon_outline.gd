tool

extends Polygon2D
export (Color) var outline_color = Color(0,0,0) setget set_color
export (float) var width = 1.0 setget set_width


func _draw():
	var poly = get_polygon()
	poly.append(poly[0])
	poly.append(poly[1])
	
	draw_polyline(poly,outline_color,width)

func set_color(value):
	outline_color = value
	update()
	pass

func set_width(value):
	width = value
	update()
	pass
