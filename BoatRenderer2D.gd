class_name BoatRenderer2D
extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Clean vector boat renderer with flat shading and smooth curves
var style: Dictionary = {}
var t: float = 0.0
var bob_offset: float = 0.0

# Preset styles with improved colors and realism
var STYLE_OLD_SKIFF = {
	"hull_color": Color.html("#8B4513"),  # Realistic brown wood
	"cabin_color": Color.html("#D2691E"),  # Lighter wood
	"accent_color": Color.html("#654321"),  # Dark wood trim
	"hull_length": 110,
	"hull_height": 20,
	"window_count": 0,
	"has_cabin": false,
	"has_mast": false,
	"has_flag": false,
	"bow_sharpness": 0.55,
	"deck_curve": 0.05
}

var STYLE_BASIC_SAILBOAT = {
	"hull_color": Color.html("#FFFFFF"),  # White hull
	"cabin_color": Color.html("#E8E8E8"),  # Light grey cabin
	"accent_color": Color.html("#000080"),  # Navy blue trim
	"hull_length": 150,
	"hull_height": 22,
	"window_count": 2,
	"has_cabin": true,
	"has_mast": true,
	"has_flag": true,
	"bow_sharpness": 0.8,
	"deck_curve": 0.15
}

var STYLE_MOTOR_CRUISER = {
	"hull_color": Color.html("#F0F8FF"),  # Alice blue hull
	"cabin_color": Color.html("#4682B4"),  # Steel blue cabin
	"accent_color": Color.html("#191970"),  # Midnight blue
	"hull_length": 180,
	"hull_height": 26,
	"window_count": 4,
	"has_cabin": true,
	"has_mast": false,
	"has_flag": true,
	"bow_sharpness": 0.9,
	"deck_curve": 0.1
}

var STYLE_LUXURY_YACHT = {
	"hull_color": Color.html("#FAFAFA"),  # Pure white
	"cabin_color": Color.html("#87CEEB"),  # Sky blue windows
	"accent_color": Color.html("#C0C0C0"),  # Silver trim
	"hull_length": 220,
	"hull_height": 30,
	"window_count": 5,
	"has_cabin": true,
	"has_mast": false,
	"has_flag": true,
	"bow_sharpness": 0.95,
	"deck_curve": 0.08
}

func set_boat_style(boat_name: String):
	match boat_name:
		"Old Rowboat":
			style = STYLE_OLD_SKIFF.duplicate()
		"Basic Sailboat":
			style = STYLE_BASIC_SAILBOAT.duplicate()
		"Motor Cruiser":
			style = STYLE_MOTOR_CRUISER.duplicate()
		"Luxury Yacht", "Mega Yacht":
			style = STYLE_LUXURY_YACHT.duplicate()
			if boat_name == "Mega Yacht":
				style.hull_length = 260
				style.hull_height = 35
				style.window_count = 8
		_:
			style = STYLE_OLD_SKIFF.duplicate()

func _draw():
	if style.is_empty():
		return
	
	var origin = Vector2(0, bob_offset)
	
	# Draw shadow first
	_draw_shadow_ellipse(origin)
	
	# Draw wake behind boat
	_draw_wake(origin)
	
	# Draw main hull
	_draw_hull(origin)
	
	# Draw cabin if present
	if style.get("has_cabin", false):
		_draw_cabin(origin)
	
	# Draw mast and sail if present
	if style.get("has_mast", false):
		_draw_mast_and_sail(origin)
	
	# Draw flag if present
	if style.get("has_flag", false):
		_draw_flag(origin)

func _build_hull(origin: Vector2, hl: int, hh: int, bow_sharpness: float, deck_curve: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var segments = 20
	
	# FIXED: Reversed direction - boats now face right
	for i in range(segments + 1):
		var t_val = float(i) / float(segments)
		var x = origin.x - hl/2 + t_val * hl  # Changed from subtraction to addition
		
		# Create smooth hull curve using sine wave for realistic boat shape
		var hull_curve = sin(t_val * PI) * hh
		
		# Apply bow sharpness (sharper at front) - FIXED: Now at the right end
		if t_val > 0.7:  # Changed from 0.3 to 0.7
			var bow_factor = (t_val - 0.7) / 0.3
			hull_curve *= (1.0 - bow_factor * bow_sharpness)
		
		# Apply deck curve
		var deck_y = origin.y - hull_curve
		if deck_curve != 0:
			deck_y += sin(t_val * PI) * deck_curve * hh * 0.3
		
		points.append(Vector2(x, deck_y))
	
	# Close the hull at waterline
	points.append(Vector2(origin.x + hl/2, origin.y))
	points.append(Vector2(origin.x - hl/2, origin.y))
	
	return points

func _draw_hull_with_outline(points: PackedVector2Array, fill_color: Color, outline_width: float = 2.0):
	# Draw filled hull
	draw_colored_polygon(points, fill_color)
	
	# Draw outline (darker than fill, not black)
	var outline_color = fill_color.darkened(0.4)
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], outline_color, outline_width)

func _draw_hull(origin: Vector2):
	var hl = style.get("hull_length", 120)
	var hh = style.get("hull_height", 20)
	var bow_sharpness = style.get("bow_sharpness", 0.7)
	var deck_curve = style.get("deck_curve", 0.1)
	var hull_color = style.get("hull_color", Color.BLUE)
	
	# Build smooth hull polygon
	var hull_points = _build_hull(origin, hl, hh, bow_sharpness, deck_curve)
	
	# Draw hull with outline
	_draw_hull_with_outline(hull_points, hull_color)
	
	# Add waterline reflection
	var waterline_color = Color(0.3, 0.5, 0.7, 0.5)
	draw_line(
		Vector2(origin.x - hl/2, origin.y + 1),
		Vector2(origin.x + hl/2, origin.y + 1),
		waterline_color, 3.0
	)
	
	# Draw accent stripe if specified
	var accent_color = style.get("accent_color", hull_color.darkened(0.3))
	draw_line(
		Vector2(origin.x - hl/2 + 10, origin.y - 3),
		Vector2(origin.x + hl/2 - 10, origin.y - 3),
		accent_color, 2.0
	)

func _draw_cabin(origin: Vector2):
	var hl = style.get("hull_length", 120)
	var hh = style.get("hull_height", 20)
	var cabin_color = style.get("cabin_color", Color.WHITE)
	var accent_color = style.get("accent_color", Color.BLUE)
	
	# FIXED: Cabin positioned correctly for right-facing boats
	var cabin_start_x = origin.x - hl/2 + hl * 0.25  # Moved forward
	var cabin_width = hl * 0.4
	var cabin_height = hh * 0.6
	var cabin_y = origin.y - hh - cabin_height
	
	# Draw cabin main body with rounded corners effect
	var cabin_rect = Rect2(cabin_start_x, cabin_y, cabin_width, cabin_height)
	draw_rect(cabin_rect, cabin_color)
	
	# Draw cabin outline
	var outline_color = cabin_color.darkened(0.3)
	draw_rect(cabin_rect, outline_color, false, 2.0)
	
	# Draw angled cabin roof
	var roof_points = PackedVector2Array([
		Vector2(cabin_start_x - 5, cabin_y),
		Vector2(cabin_start_x + cabin_width + 5, cabin_y),
		Vector2(cabin_start_x + cabin_width, cabin_y - 6),
		Vector2(cabin_start_x, cabin_y - 8)
	])
	draw_colored_polygon(roof_points, cabin_color.darkened(0.15))
	
	# Draw realistic windows
	var window_count = style.get("window_count", 2)
	if window_count > 0:
		var window_spacing = cabin_width / (window_count + 1)
		var window_width = min(14, window_spacing * 0.6)
		var window_height = 10
		
		for i in range(window_count):
			var window_x = cabin_start_x + window_spacing * (i + 1) - window_width/2
			var window_y = cabin_y + cabin_height * 0.35
			
			# Window frame
			var frame_rect = Rect2(window_x - 1, window_y - 1, window_width + 2, window_height + 2)
			draw_rect(frame_rect, accent_color.darkened(0.2))
			
			# Window glass with realistic tint
			var glass_rect = Rect2(window_x, window_y, window_width, window_height)
			draw_rect(glass_rect, Color(0.5, 0.65, 0.8, 0.85))
			
			# Window reflection
			var highlight_rect = Rect2(window_x + 1, window_y + 1, window_width/2, 3)
			draw_rect(highlight_rect, Color(0.9, 0.95, 1.0, 0.7))

func _draw_mast_and_sail(origin: Vector2):
	var hl = style.get("hull_length", 120)
	var hh = style.get("hull_height", 20)
	var accent_color = style.get("accent_color", Color.GRAY)
	
	# FIXED: Mast position for right-facing boats
	var mast_x = origin.x - hl/4 + hl * 0.1  # Adjusted for proper sailing position
	var mast_base_y = origin.y - hh
	var mast_height = hh * 3.5
	var mast_top_y = mast_base_y - mast_height
	
	# Draw mast with taper
	for i in range(3):
		var width = 4 - i
		var offset = i * 0.5
		draw_line(
			Vector2(mast_x - offset, mast_base_y), 
			Vector2(mast_x - offset, mast_top_y), 
			accent_color.lightened(i * 0.1), 
			width
		)
	
	# Draw boom (horizontal spar)
	var boom_length = hl * 0.35
	draw_line(
		Vector2(mast_x, mast_base_y - hh * 0.5),
		Vector2(mast_x + boom_length, mast_base_y - hh * 0.4),  # Slight angle
		accent_color, 2.5
	)
	
	# Draw main sail with realistic billowing
	var sail_flutter = sin(t * 3.5) * 5.0
	var sail_points = PackedVector2Array()
	
	# Create curved sail shape
	var sail_segments = 12
	sail_points.append(Vector2(mast_x, mast_top_y + 5))
	
	for i in range(sail_segments):
		var t_val = float(i) / float(sail_segments - 1)
		var sail_height = t_val * mast_height * 0.75
		var sail_width = (1.0 - t_val * 0.3) * boom_length * 0.85
		
		# Add billowing effect
		var billow = sin(t_val * PI) * (8.0 + sail_flutter)
		
		sail_points.append(Vector2(
			mast_x + sail_width + billow,
			mast_top_y + 5 + sail_height
		))
	
	sail_points.append(Vector2(mast_x, mast_base_y - hh * 0.5))
	
	# Draw sail with gradient effect
	draw_colored_polygon(sail_points, Color(0.98, 0.98, 1.0, 0.95))
	
	# Draw sail seams
	for i in range(3):
		var seam_y = mast_top_y + (i + 1) * mast_height * 0.2
		draw_line(
			Vector2(mast_x, seam_y),
			Vector2(mast_x + boom_length * 0.7, seam_y + 10),
			Color(0.85, 0.85, 0.9, 0.5),
			1.0
		)

func _draw_flag(origin: Vector2):
	var hl = style.get("hull_length", 120)
	var hh = style.get("hull_height", 20)
	var accent_color = style.get("accent_color", Color.RED)
	
	# FIXED: Flag at stern (back) of right-facing boat
	var flag_pole_x = origin.x - hl/2 + 10  # At the back (left side)
	var flag_pole_base = origin.y - hh
	var flag_pole_top = flag_pole_base - 25
	
	# Draw flag pole
	draw_line(Vector2(flag_pole_x, flag_pole_base), Vector2(flag_pole_x, flag_pole_top), Color(0.4, 0.3, 0.2), 2.0)
	
	# Draw waving flag
	var flag_wave = sin(t * 5.0) * 4.0
	var flag_points = PackedVector2Array([
		Vector2(flag_pole_x, flag_pole_top),
		Vector2(flag_pole_x + 20 + flag_wave, flag_pole_top + 2),
		Vector2(flag_pole_x + 18 + flag_wave * 0.7, flag_pole_top + 10),
		Vector2(flag_pole_x, flag_pole_top + 8)
	])
	
	draw_colored_polygon(flag_points, accent_color)
	
	# Flag outline
	for i in range(flag_points.size() - 1):
		draw_line(flag_points[i], flag_points[i+1], accent_color.darkened(0.3), 1.0)

func _draw_wake(origin: Vector2):
	var hl = style.get("hull_length", 120)
	
	# FIXED: Wake trails from stern (left side for right-facing boats)
	var wake_color = Color(1.0, 1.0, 1.0, 0.2)
	var stern_x = origin.x - hl/2  # Back of boat
	
	for i in range(4):
		var wake_offset = sin(t * 2.5 + i * 0.5) * 3.0
		var wake_y = origin.y + 3 + i * 2 + wake_offset
		var wake_length = 40 + i * 15
		
		# Wake trails behind boat (to the left)
		draw_line(
			Vector2(stern_x, wake_y),
			Vector2(stern_x - wake_length, wake_y + randf_range(-2, 2)),
			wake_color,
			2.0 - i * 0.3
		)

func _draw_shadow_ellipse(origin: Vector2):
	var hl = style.get("hull_length", 120)
	var shadow_color = Color(0.0, 0.1, 0.2, 0.15)
	
	# Draw elliptical shadow under boat
	var shadow_points = PackedVector2Array()
	var segments = 20
	
	for i in range(segments + 1):
		var angle = float(i) / float(segments) * PI * 2.0
		var x = origin.x + cos(angle) * hl * 0.45
		var y = origin.y + 10 + sin(angle) * 8
		shadow_points.append(Vector2(x, y))
	
	draw_colored_polygon(shadow_points, shadow_color)
