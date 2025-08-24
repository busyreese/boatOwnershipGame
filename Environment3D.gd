# ─────────────────────────────────────────────────────────────
# COMPONENT: Environment 3D
# ARTIFACT-ID: b8e5d4f2-environment-beach
# VERSION: 0.1.1
# OWNERSHIP: boatsimgame-prompter
# PURPOSE: Handles 3D environment with sloped beach
# DEPENDS-ON: SlopedBeach.gd, WaterPhysics.gd
# CHANGELOG:
#   - 2025-01-15 0.1.1 Fixed house floating - added ground alignment
#   - 2025-01-14 0.1.0 Initial beach environment
# SAFETY-NOTE: Do not repurpose this artifact for unrelated features.
# ─────────────────────────────────────────────────────────────

# Environment3D.gd - Handles 3D environment with sloped beach
extends Node3D

# 3D Scene nodes
var sun_light: DirectionalLight3D
var environment: Environment
var water_plane: MeshInstance3D
var ocean_material: ShaderMaterial
var beach: Node3D  # Sloped beach instead of pier
var beach_houses: Node3D  # Houses on the beach plateau

# Underwater life
var fish_schools = []
var jellyfish = []
var seaweed = []
var underwater_container: Node3D

# Water physics reference
var water_physics: Node

# Beach and town settings
const BEACH_LENGTH = 50.0  # Horizontal span of beach
const BEACH_WIDTH = 20.0   # Depth from plateau to water
const PLATEAU_WIDTH = 8.0  # Flat area width
const HOUSE_SPACING = 5.5
const HOUSES_PER_SIDE = 6

func setup_environment(camera: Camera3D):
	setup_lighting()
	setup_sky_and_environment(camera)
	setup_beach()

func setup_lighting():
	# Sun light
	sun_light = DirectionalLight3D.new()
	sun_light.position = Vector3(50, 50, -30)
	sun_light.rotation_degrees = Vector3(-35, -135, 0)
	sun_light.light_energy = 1.0
	sun_light.light_color = Color(1.0, 0.95, 0.88)
	sun_light.light_indirect_energy = 0.5
	sun_light.shadow_enabled = true
	sun_light.shadow_blur = 1.0
	add_child(sun_light)

func setup_sky_and_environment(camera: Camera3D):
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.3
	environment.ambient_light_color = Color(0.5, 0.6, 0.7)
	
	# Tonemapping
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 1.0
	
	# Fog
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.5, 0.6, 0.7)
	environment.fog_sun_scatter = 0.05
	environment.fog_density = 0.015
	environment.fog_aerial_perspective = 0.5
	
	# Glow
	environment.glow_enabled = true
	environment.glow_intensity = 0.05
	environment.glow_strength = 0.3
	environment.glow_bloom = 0.1
	environment.glow_hdr_threshold = 1.3
	environment.glow_hdr_scale = 2.0
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	
	# Sky
	var sky = ProceduralSkyMaterial.new()
	sky.sky_top_color = Color(0.3, 0.5, 0.7)
	sky.sky_horizon_color = Color(0.7, 0.75, 0.8)
	sky.sky_curve = 0.15
	sky.ground_bottom_color = Color(0.2, 0.3, 0.4)
	sky.ground_horizon_color = Color(0.4, 0.5, 0.6)
	sky.sun_angle_max = 15.0
	sky.sun_curve = 0.05
	
	var sky_texture = Sky.new()
	sky_texture.sky_material = sky
	environment.sky = sky_texture
	
	camera.environment = environment

func setup_beach():
	# Create sloped beach using our new system
	var BeachScript = preload("res://SlopedBeach.gd")
	beach = BeachScript.new()
	beach.name = "Beach"
	
	# Configure beach parameters - horizontal orientation
	beach.length_m = BEACH_LENGTH  # Horizontal span (X axis)
	beach.width_m = BEACH_WIDTH    # Depth (Z axis)
	beach.plateau_width_m = PLATEAU_WIDTH
	beach.berm_radius_m = 2.0
	beach.slope_angle_deg = 45.0
	beach.water_height = -0.2  # Match ocean plane
	beach.wet_band_m = 1.2
	beach.edge_drop_cm = 3
	beach.lod_quality = "Medium:16"
	beach.enable_curve_noise = true
	beach.curve_noise_amplitude = 0.05
	beach.curve_noise_frequency = 3.0
	
	# Position beach in the middle of the screen, below houses
	beach.position = Vector3(0, 0.5, -5)  # Moved to center of view
	add_child(beach)
	
		# Add collision body for ground detection
	var beach_collision = StaticBody3D.new()
	beach_collision.collision_layer = 1
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(100, 2, 100)
	collision_shape.shape = box_shape
	beach_collision.add_child(collision_shape)
	beach.add_child(beach_collision)

func setup_ocean(physics: Node):
	water_physics = physics
	
	# Ocean plane
	water_plane = MeshInstance3D.new()
	var water_mesh = PlaneMesh.new()
	water_mesh.size = Vector2(200, 200)
	water_mesh.subdivide_width = 64
	water_mesh.subdivide_depth = 64
	water_plane.mesh = water_mesh
	
	# Ocean shader
	ocean_material = ShaderMaterial.new()
	var shader = load("res://ocean_shader.gdshader")
	if shader:
		ocean_material.shader = shader
		
		# Water colors
		ocean_material.set_shader_parameter("base_water_color", Color(0.169, 0.373, 0.529))
		ocean_material.set_shader_parameter("fresnel_water_color", Color(0.655, 0.847, 1.0))
		ocean_material.set_shader_parameter("deep_water_color", Color(0.051, 0.145, 0.227, 1.0))
		ocean_material.set_shader_parameter("shallow_water_color", Color(0.376, 0.624, 0.749, 1.0))
		
		# Sync with physics
		if water_physics:
			water_physics.sync_with_shader(ocean_material)
		
		# Parameters
		ocean_material.set_shader_parameter("time_factor", 3.0)
		ocean_material.set_shader_parameter("noise_zoom", 1.5)
		ocean_material.set_shader_parameter("fresnel_strength", 0.4)
		ocean_material.set_shader_parameter("wave_strength", 0.3)
		ocean_material.set_shader_parameter("wave_scale", Vector2(5.0, 5.0))
		ocean_material.set_shader_parameter("wave_speed", 0.5)
	
	water_plane.set_surface_override_material(0, ocean_material)
	water_plane.position = Vector3(0, -0.2, 0)
	add_child(water_plane)


 
func setup_underwater_life():
		# Wrapper function for compatibility with Main.gd
		# Main.gd calls this, but we renamed it to setup_underwater_world
	setup_underwater_world()




func setup_underwater_world():
	# Create underwater container
	underwater_container = Node3D.new()
	underwater_container.name = "UnderwaterWorld"
	add_child(underwater_container)
	
	# Create fish schools
	for i in range(3):
		var pos = Vector3(
			randf_range(-20, 20),
			randf_range(-5, -2),
			randf_range(-10, 20)
		)
		create_fish_school(pos)
	
	# Create jellyfish
	for i in range(5):
		var pos = Vector3(
			randf_range(-15, 15),
			randf_range(-8, -3),
			randf_range(-5, 15)
		)
		create_jellyfish(pos)
	
	# Create seaweed patches
	for i in range(12):
		var pos = Vector3(
			randf_range(-25, 25),
			-10,  # Ocean floor
			randf_range(-15, 25)
		)
		create_seaweed(pos)

func create_fish_school(position: Vector3):
	var school = Node3D.new()
	school.position = position
	
	for i in range(8):
		var fish = MeshInstance3D.new()
		var fish_mesh = SphereMesh.new()
		fish_mesh.radius = 0.15
		fish_mesh.height = 0.4
		fish.mesh = fish_mesh
		
		var fish_mat = StandardMaterial3D.new()
		fish_mat.albedo_color = Color(0.3, 0.35, 0.4)
		fish_mat.emission_enabled = true
		fish_mat.emission = Color(0.05, 0.08, 0.1)
		fish_mat.emission_energy = 0.1
		fish_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fish_mat.alpha = 0.6
		fish.set_surface_override_material(0, fish_mat)
		
		fish.position = Vector3(
			randf_range(-1, 1),
			randf_range(-0.5, 0.5),
			randf_range(-1, 1)
		)
		
		school.add_child(fish)
	
	underwater_container.add_child(school)
	fish_schools.append(school)

func create_jellyfish(position: Vector3):
	var jelly = MeshInstance3D.new()
	var jelly_mesh = SphereMesh.new()
	jelly_mesh.radius = 0.4
	jelly_mesh.height = 0.6
	jelly_mesh.radial_segments = 16
	jelly.mesh = jelly_mesh
	
	var jelly_mat = StandardMaterial3D.new()
	jelly_mat.albedo_color = Color(0.4, 0.2, 0.5, 0.4)
	jelly_mat.emission_enabled = true
	jelly_mat.emission = Color(0.2, 0.1, 0.25)
	jelly_mat.emission_energy = 0.2
	jelly_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jelly_mat.alpha = 0.5
	jelly_mat.rim_enabled = true
	jelly_mat.rim = 0.5
	jelly_mat.rim_tint = 0.3
	jelly.set_surface_override_material(0, jelly_mat)
	
	jelly.position = position
	underwater_container.add_child(jelly)
	jellyfish.append(jelly)

func create_seaweed(position: Vector3):
	var weed = MeshInstance3D.new()
	var weed_mesh = CylinderMesh.new()
	weed_mesh.height = 2.0
	weed_mesh.top_radius = 0.05
	weed_mesh.bottom_radius = 0.1
	weed.mesh = weed_mesh
	
	var weed_mat = StandardMaterial3D.new()
	weed_mat.albedo_color = Color(0.08, 0.25, 0.1)
	weed_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	weed_mat.alpha = 0.7
	weed.set_surface_override_material(0, weed_mat)
	
	weed.position = position
	underwater_container.add_child(weed)
	seaweed.append(weed)

func setup_coastal_town():
	beach_houses = Node3D.new()
	beach_houses.name = "BeachHouses"
	add_child(beach_houses)
	
	# House models
	var house_models = []
	for i in range(1, 13):
		var path = "res://models/houses/house_type%02d.obj" % i
		if ResourceLoader.exists(path):
			house_models.append(path)
	
	# Trees and rocks models for beach decoration
	var decoration_models = [
		"res://models/trees_rocks/Palm_tree_0817062927_refine.obj",
		"res://models/trees_rocks/Palm_tree_0817063204_refine.obj",
		"res://models/trees_rocks/rock_0817054342_refine.obj",
		"res://models/trees_rocks/rock_0817055145_refine.obj"
	]
	
	# Filter existing models
	var available_decorations = []
	for path in decoration_models:
		if ResourceLoader.exists(path):
			available_decorations.append(path)
	
	if house_models.is_empty():
		print("Note: No house models found, using simple geometry")
		create_simple_beach_houses()
		return
	
	# Place houses on the beach plateau (along X axis, on the plateau)
	var house_x_start = -BEACH_LENGTH/2 + 5
	var house_x_spacing = BEACH_LENGTH / HOUSES_PER_SIDE
	
	for i in range(HOUSES_PER_SIDE):
		if i >= house_models.size():
			break
			
		var house_path = house_models[i % house_models.size()]
		var house_resource = load(house_path)
		if not house_resource:
			continue
		
		var house_instance = create_model_instance(house_resource)
		if not house_instance:
			continue
		
		# Initial position high for raycast
		var x_pos = house_x_start + i * house_x_spacing
		var z_pos = -10.0  # On the beach plateau (back from water)
		
		# Start high for ground detection
		house_instance.position = Vector3(x_pos, 10.0, z_pos)
		house_instance.scale = Vector3(0.8, 0.8, 0.8)
		
		beach_houses.add_child(house_instance)
		
		# Perform ground alignment after adding to scene (only if in tree)
		if is_inside_tree():
			await get_tree().process_frame
			align_to_ground(house_instance)
		# If not in tree yet, alignment will happen without await
		
		# Face toward ocean with slight variation
		var ocean_direction = Vector3(0, 0, 1)  # Toward positive Z (ocean)
		var look_target = house_instance.global_position + ocean_direction * 10
		look_target.y = house_instance.global_position.y  # Keep same height
		house_instance.look_at(look_target, Vector3.UP)
		house_instance.rotation_degrees.y += randf_range(-15, 15)  # Add variation
		
		disable_shadows(house_instance)
	
	# Let houses settle (only if in tree)
	if is_inside_tree():
		await get_tree().process_frame
	
	# Add palm trees and rocks
	if not available_decorations.is_empty():
		for i in range(8):
			var deco_path = available_decorations[randi() % available_decorations.size()]
			var deco_resource = load(deco_path)
			if deco_resource:
				var deco_instance = create_model_instance(deco_resource)
				if deco_instance:
					# Random position on beach (X axis spread, Z axis depth)
					var x = randf_range(-BEACH_LENGTH/2 + 2, BEACH_LENGTH/2 - 2)
					var z = randf_range(-12, -6)  # On plateau and upper slope
					
					# Start high for ground detection
					deco_instance.position = Vector3(x, 10.0, z)
					
					var scale = 0.5 if deco_path.contains("Palm") else 0.3
					deco_instance.scale = Vector3(scale, scale, scale)
					
					beach_houses.add_child(deco_instance)
					
					# Align to ground after adding to scene (only if in tree)
					if is_inside_tree():
						await get_tree().process_frame
						align_to_ground(deco_instance)
					
					deco_instance.rotation_degrees.y = randf_range(0, 360)
					disable_shadows(deco_instance)

func align_to_ground(node: Node3D):
	# Cast ray down to find ground
	var space_state = get_world_3d().direct_space_state
	var from = node.global_position
	var to = node.global_position - Vector3(0, 100, 0)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # Assuming ground is on layer 1
	query.exclude = [node]
	
	var result = space_state.intersect_ray(query)
	
	if not result.is_empty():
		# Place object on ground with small offset
		var ground_pos = result.position
		node.global_position = ground_pos + Vector3(0, 0.1, 0)  # Small offset to prevent z-fighting
		
		# Optional: Align to surface normal for natural placement
		if result.has("normal"):
			var normal = result.normal
			# Only apply slight tilt for realism, not full alignment
			if normal.y > 0.7:  # Mostly flat surfaces
				var tilt_factor = 0.1  # How much to tilt based on terrain
				node.rotation.x = atan2(normal.z, normal.y) * tilt_factor
				node.rotation.z = atan2(-normal.x, normal.y) * tilt_factor
	else:
		# Fallback if no ground detected - use estimated heights
		if node.global_position.z < -8:  # On plateau
			node.global_position.y = 0.8
		else:  # Near water
			node.global_position.y = 0.5

func create_simple_beach_houses():
	# Fallback: Create simple box houses along X axis
	for i in range(HOUSES_PER_SIDE):
		var house = MeshInstance3D.new()
		var house_mesh = BoxMesh.new()
		house_mesh.size = Vector3(3, 3, 3)
		house.mesh = house_mesh
		
		var house_mat = StandardMaterial3D.new()
		house_mat.albedo_color = Color(0.9, 0.9, 0.8)
		house.set_surface_override_material(0, house_mat)
		
		var x_pos = -BEACH_LENGTH/2 + 5 + i * (BEACH_LENGTH / HOUSES_PER_SIDE)
		house.position = Vector3(x_pos, 2.0, -10.0)  # Along X, on beach plateau
		
		disable_shadows(house)
		beach_houses.add_child(house)
		
		# Add simple roof
		var roof = MeshInstance3D.new()
		var roof_mesh = PrismMesh.new()
		roof_mesh.size = Vector3(3.5, 1.5, 3.5)
		roof.mesh = roof_mesh
		
		var roof_mat = StandardMaterial3D.new()
		roof_mat.albedo_color = Color(0.6, 0.3, 0.2)
		roof.set_surface_override_material(0, roof_mat)
		
		roof.position = Vector3(x_pos, 3.5, -10.0)
		roof.rotation_degrees.x = 90
		
		disable_shadows(roof)
		beach_houses.add_child(roof)

func disable_shadows(node: Node):
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		disable_shadows(child)

func create_model_instance(resource):
	if resource.has_method("instantiate"):
		return resource.instantiate()
	elif resource is Mesh:
		var instance = MeshInstance3D.new()
		instance.mesh = resource
		return instance
	return null

func animate_underwater_life(delta: float, wave_time: float):
	# Animate fish schools
	for school in fish_schools:
		school.rotation.y += delta * 0.2
		school.position.x += sin(wave_time * 0.5) * delta * 2.0
		school.position.z += cos(wave_time * 0.5) * delta * 2.0
		
		if abs(school.position.x) > 25:
			school.position.x *= -0.9
		if abs(school.position.z) > 25:
			school.position.z *= -0.9
	
	# Animate jellyfish
	for jelly in jellyfish:
		jelly.position.y = jelly.position.y + sin(wave_time * 1.5) * delta * 0.5
		jelly.rotation.y += delta * 0.1
	
	# Animate seaweed
	for weed in seaweed:
		weed.rotation.z = sin(wave_time * 2.0 + weed.position.x) * 0.2
		weed.rotation.x = cos(wave_time * 1.8 + weed.position.z) * 0.1
