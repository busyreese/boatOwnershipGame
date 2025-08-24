# ARTIFACT-ID: a7f3c2e1-beach-generator
# SlopedBeach.gd - Parametric beach mesh generator with smooth transitions
@tool
extends Node3D

# Beach dimensions
@export_group("Dimensions")
@export_range(10.0, 100.0, 0.5) var length_m: float = 50.0:
	set(value):
		length_m = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

@export_range(10.0, 50.0, 0.5) var width_m: float = 20.0:
	set(value):
		width_m = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

@export_range(2.0, 15.0, 0.5) var plateau_width_m: float = 8.0:
	set(value):
		plateau_width_m = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

# Transition parameters
@export_group("Profile")
@export_range(0.5, 5.0, 0.1) var berm_radius_m: float = 2.0:
	set(value):
		berm_radius_m = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

@export_range(30.0, 60.0, 5.0) var slope_angle_deg: float = 45.0:
	set(value):
		slope_angle_deg = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

@export var water_height: float = -0.2:
	set(value):
		water_height = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

# Visual parameters
@export_group("Appearance")
@export var sand_material: Material:
	set(value):
		sand_material = value
		_apply_material()

@export_range(0.2, 3.0, 0.1) var wet_band_m: float = 1.0:
	set(value):
		wet_band_m = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

@export_range(0, 10, 1) var edge_drop_cm: int = 3:
	set(value):
		edge_drop_cm = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

# Quality settings
@export_group("Quality")
@export_enum("Low:8", "Medium:16", "High:24") var lod_quality: String = "Medium:16":
	set(value):
		lod_quality = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

@export var cast_shadows: bool = false:
	set(value):
		cast_shadows = value
		_update_shadow_casting()

# Optional organic shoreline
@export_group("Advanced")
@export var enable_curve_noise: bool = false:
	set(value):
		enable_curve_noise = value
		if Engine.is_editor_hint():
			_regenerate_mesh()

@export_range(0.0, 0.5, 0.01) var curve_noise_amplitude: float = 0.1:
	set(value):
		curve_noise_amplitude = value
		if enable_curve_noise and Engine.is_editor_hint():
			_regenerate_mesh()

@export_range(0.5, 5.0, 0.1) var curve_noise_frequency: float = 2.0:
	set(value):
		curve_noise_frequency = value
		if enable_curve_noise and Engine.is_editor_hint():
			_regenerate_mesh()

# Nodes
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D

# Cached data
var profile_points: PackedVector2Array
var profile_uvs: PackedFloat32Array
var mesh_vertices: PackedVector3Array

func _ready():
	setup_nodes()
	_regenerate_mesh()
	
	if not Engine.is_editor_hint():
		if not sand_material:
			sand_material = create_default_sand_material()
			_apply_material()

func setup_nodes():
	if not has_node("BeachMesh"):
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "BeachMesh"
		add_child(mesh_instance)
		mesh_instance.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
	else:
		mesh_instance = $BeachMesh
	
	if not has_node("StaticBody3D"):
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		add_child(static_body)
		static_body.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
		
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		static_body.add_child(collision_shape)
		collision_shape.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
	else:
		static_body = $StaticBody3D
		collision_shape = static_body.get_node("CollisionShape3D")

func _regenerate_mesh():
	if not mesh_instance:
		return
	
	profile_points = generate_profile()
	profile_uvs = calculate_profile_uvs()
	
	var mesh = create_mesh_from_profile()
	mesh_instance.mesh = mesh
	
	update_collision_shape(mesh)
	
	_apply_material()
	_update_shadow_casting()

func generate_profile() -> PackedVector2Array:
	var points = PackedVector2Array()
	var slope_angle_rad = deg_to_rad(slope_angle_deg)
	
	var x = -plateau_width_m / 2.0
	var y = 0.0
	
	points.append(Vector2(x, y))
	x += plateau_width_m
	points.append(Vector2(x, y))
	
	var berm_segments = get_berm_segments()
	if berm_radius_m > 0.01 and berm_segments > 0:
		var berm_center_x = x + berm_radius_m * sin(slope_angle_rad)
		var berm_center_y = y - berm_radius_m * (1.0 - cos(slope_angle_rad))
		
		for i in range(1, berm_segments + 1):
			var t = float(i) / float(berm_segments)
			var angle = lerp(PI/2, PI/2 - slope_angle_rad, t)
			var berm_x = berm_center_x - berm_radius_m * cos(angle)
			var berm_y = berm_center_y + berm_radius_m * sin(angle)
			points.append(Vector2(berm_x, berm_y))
		
		x = berm_center_x + berm_radius_m * sin(slope_angle_rad)
		y = berm_center_y - berm_radius_m * cos(slope_angle_rad)
	
	var target_y = water_height - edge_drop_cm / 100.0
	var slope_distance = abs(y - target_y) / sin(slope_angle_rad)
	var slope_x_distance = slope_distance * cos(slope_angle_rad)
	
	var slope_segments = 8
	for i in range(1, slope_segments + 1):
		var t = float(i) / float(slope_segments)
		var slope_x = x + slope_x_distance * t
		var slope_y = lerp(y, target_y, t)
		points.append(Vector2(slope_x, slope_y))
	
	return points

func calculate_profile_uvs() -> PackedFloat32Array:
	var uvs = PackedFloat32Array()
	if profile_points.is_empty():
		return uvs
	
	var total_distance = 0.0
	var distances = [0.0]
	
	for i in range(1, profile_points.size()):
		var dist = profile_points[i].distance_to(profile_points[i-1])
		total_distance += dist
		distances.append(total_distance)
	
	for dist in distances:
		uvs.append(dist / total_distance if total_distance > 0 else 0.0)
	
	return uvs

func get_berm_segments() -> int:
	var quality_str = lod_quality.split(":")[1]
	return int(quality_str)

func create_mesh_from_profile() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var length_segments = 40 if lod_quality.contains("High") else (20 if lod_quality.contains("Medium") else 10)
	var width_segments = profile_points.size() - 1
	var length_half = length_m / 2.0
	
	mesh_vertices.clear()
	
	for x_idx in range(length_segments + 1):
		var x = -length_half + (length_m * float(x_idx) / float(length_segments))
		var u = float(x_idx) / float(length_segments)
		
		var noise_offset = 0.0
		if enable_curve_noise and curve_noise_amplitude > 0:
			noise_offset = sin(x * curve_noise_frequency * 2.0 * PI / length_m) * curve_noise_amplitude
		
		for i in range(profile_points.size()):
			var profile_pt = profile_points[i]
			var vertex = Vector3(x, profile_pt.y, profile_pt.x + noise_offset)
			var v = profile_uvs[i]
			
			var normal = Vector3.UP
			if i > 0 and i < profile_points.size() - 1:
				var tangent = (profile_points[i+1] - profile_points[i-1]).normalized()
				normal = Vector3(0, tangent.x, -tangent.y).normalized()
			
			var wetness = calculate_wetness(profile_pt.y)
			
			surface_tool.set_uv(Vector2(u, v))
			surface_tool.set_uv2(Vector2(u * 10, v * 10))
			surface_tool.set_normal(normal)
			surface_tool.set_color(Color(wetness, wetness, wetness, 1.0))
			surface_tool.add_vertex(vertex)
			mesh_vertices.append(vertex)
	
	var verts_per_row = profile_points.size()
	for x_idx in range(length_segments):
		var row_start = x_idx * verts_per_row
		var next_row_start = (x_idx + 1) * verts_per_row
		
		for i in range(verts_per_row - 1):
			surface_tool.add_index(row_start + i)
			surface_tool.add_index(next_row_start + i)
			surface_tool.add_index(next_row_start + i + 1)
			
			surface_tool.add_index(row_start + i)
			surface_tool.add_index(next_row_start + i + 1)
			surface_tool.add_index(row_start + i + 1)
	
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	
	return surface_tool.commit()

func calculate_wetness(height: float) -> float:
	var dist_from_water = abs(height - water_height)
	if dist_from_water > wet_band_m:
		return 0.0
	return 1.0 - (dist_from_water / wet_band_m)

func update_collision_shape(mesh: ArrayMesh):
	if not collision_shape or not mesh:
		return
	
	var shape = mesh.create_trimesh_shape()
	collision_shape.shape = shape

func create_default_sand_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.87, 0.70)
	mat.roughness = 0.9
	mat.metallic = 0.0
	mat.vertex_color_use_as_albedo = true
	mat.uv1_scale = Vector3(10, 10, 1)
	mat.uv1_triplanar = true
	mat.uv1_triplanar_sharpness = 1.0
	return mat

func _apply_material():
	if mesh_instance and sand_material:
		mesh_instance.set_surface_override_material(0, sand_material)

func _update_shadow_casting():
	if mesh_instance:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _get_tool_buttons():
	if Engine.is_editor_hint():
		return ["Regenerate Mesh"]
	return []

func get_height_at_position(world_pos: Vector3) -> float:
	var local_pos = to_local(world_pos)
	var closest_height = 0.0
	var min_dist = INF
	
	for vertex in mesh_vertices:
		var dist = Vector2(vertex.x - local_pos.x, vertex.z - local_pos.z).length()
		if dist < min_dist:
			min_dist = dist
			closest_height = vertex.y
	
	return to_global(Vector3(0, closest_height, 0)).y
