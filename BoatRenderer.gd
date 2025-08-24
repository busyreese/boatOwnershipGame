
class_name BoatRenderer
extends Node2D

@export var style: Dictionary
@export var scale_factor: float = 1.0

var t := 0.0

func _ready():
	set_process(true)
	if style.is_empty():
		style = {
			"hull_color": Color.SKY_BLUE,
			"cabin_color": Color.WHITE,
			"hull_length": 120,
			"hull_height": 18,
			"has_cabin": true,
			"has_mast": false,
			"has_flag": false,
			"window_count": 2
		}

func _process(delta):
	t += delta
	queue_redraw()

func _draw():
	var bob = sin(t * 2.0) * 2.5  # gentle bobbing
	var hl:int = int(style.get("hull_length", 120) * scale_factor)
	var hh:int = int(style.get("hull_height", 18) * scale_factor)

	var origin = Vector2(-hl/2, -hh/2 + bob)

	# Hull - rounded polygon
	var hull_points = PackedVector2Array([
		origin + Vector2(0, hh),
		origin + Vector2(hl * 0.05, hh*0.6),
		origin + Vector2(hl * 0.9, hh*0.6),
		origin + Vector2(hl, hh),
	])
	draw_colored_polygon(hull_points, style.get("hull_color", Color.dark_blue))

	# Waterline
	draw_line(origin + Vector2(0, hh), origin + Vector2(hl, hh), Color(0.4,0.7,1,0.7), 2.0)

	# Cabin
	if style.get("has_cabin", true):
		var cab_w = int(hl * 0.4)
		var cab_h = int(hh * 1.5)
		var cab_x = origin.x + hl * 0.35
		var cab_y = origin.y + hh*0.6 - cab_h
		var cab_rect = Rect2(Vector2(cab_x, cab_y), Vector2(cab_w, cab_h))
		draw_rect(cab_rect, style.get("cabin_color", Color.white))

		# Windows
		var win = style.get("window_count", 3)
		var gap = cab_w / float(max(1, win+1))
		for i in range(win):
			var x = cab_x + gap * (i+1) - 6
			var y = cab_y + cab_h*0.35 + sin(t*4 + i) * 1.5
			draw_rect(Rect2(Vector2(x, y), Vector2(12, 10)), Color(0.7, 0.9, 1.0, 0.95))

	# Mast and flag
	if style.get("has_mast", false):
		var mast_x = origin.x + hl*0.25
		var mast_top = Vector2(mast_x, origin.y - hh*2.2 + bob)
		var mast_bottom = Vector2(mast_x, origin.y + hh*0.55 + bob)
		draw_line(mast_bottom, mast_top, Color(0.8,0.8,0.8), 2.0)
		# Sail - small triangle that 'flutters'
		var sway = sin(t*3.0) * 6.0
		var sail = PackedVector2Array([
			mast_top,
			mast_top + Vector2(60 + sway, 20),
			mast_top + Vector2(10 + sway*0.3, 60),
		])
		draw_colored_polygon(sail, Color(1,1,1,0.9))

	if style.get("has_flag", false):
		var fx = origin.x + hl*0.9
		var fy = origin.y + hh*0.65 + bob
		var flap = sin(t*6.0) * 6.0
		var flag = PackedVector2Array([
			Vector2(fx, fy),
			Vector2(fx+18, fy-6 + flap),
			Vector2(fx+18, fy+6 + flap),
		])
		draw_colored_polygon(flag, Color(1.0, 0.2, 0.2, 0.95))
