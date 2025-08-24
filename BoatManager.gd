# ARTIFACT-ID: e4f8a2b1-boat-manager-fixed
# VERSION: 0.1.3
# CHANGELOG: Fixed boat spawning failures, improved fallback system
# BoatManager.gd - Handles boat display, animations, and physics
extends Node3D

var boat_containers = {}
var cruise_animations = {}
var water_physics: Node
var boat_bob_strength: float = 0.15
var boat_draft: float = 0.35  # Raise boats above water
var min_clearance: float = 0.2  # Minimum height above water

# Model paths
var boat_models = {
	"Old Rowboat": "res://models/boats/boat-row-small.glb",
	"Basic Sailboat": "res://models/boats/boat-sail-a.glb",
	"Motor Cruiser": "res://models/boats/boat-speed-c.glb",
	"Luxury Yacht": "res://models/boats/ship-small.glb",
	"Mega Yacht": "res://models/boats/ship-ocean-liner.glb",
	# ... rest of boat models ...
}

func set_water_physics(physics: Node):
	water_physics = physics

func update_boat_display():
	# Clear existing boats
	for container in boat_containers.values():
		container.queue_free()
	boat_containers.clear()
	cruise_animations.clear()
	
	# Verify we have boats to display
	if GameManager.owned_boats.is_empty():
		push_warning("BoatManager: No owned boats to display")
		return
	
	var x_offset = -15.0  # Start position along the beach (X axis)
	var boats_created = 0
	
	for boat_name in GameManager.owned_boats:
		var is_current = (boat_name == GameManager.current_boat)
		var boat = create_3d_boat(boat_name, is_current)
		if not boat:
			continue
		
		# Position boats in the water beyond the beach slope
		boat.position = Vector3(x_offset, 0.5, 10.0)  # ABOVE water, beyond beach
		cruise_animations[boat_name]["original_x"] = x_offset
		cruise_animations[boat_name]["original_rotation"] = 0.0  # Facing out to sea
		cruise_animations[boat_name]["base_y"] = 0.5  # Above water base
		boat.rotation_degrees.y = 0.0  # Facing forward (positive Z)
		
		add_child(boat)
		boat_containers[boat_name] = boat
		boats_created += 1
		
		x_offset += 6.0  # More spacing between boats
	
	print("BoatManager: Spawned %d boats (owned: %d)" % [boats_created, GameManager.owned_boats.size()])

func create_3d_boat(boat_name: String, is_current: bool) -> Node3D:
	var boat_container = Node3D.new()
	boat_container.name = "Boat_" + boat_name
	
	var model_path = boat_models.get(boat_name, "")
	var model_loaded = false
	
	# Try to load 3D model if path exists
	if model_path != "":
		if not ResourceLoader.exists(model_path):
			print("BoatManager: Model not found: %s" % model_path)
		else:
			print("BoatManager: Loading model: %s" % model_path)
			var model_resource = load(model_path)
			if model_resource:
				var instance = model_resource.instantiate()
				
				# Scale based on boat type
				var scale_factor = get_boat_scale(boat_name)
				if is_current:
					scale_factor *= 1.2
				
				instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
				
				# Disable shadows on the boat
				disable_boat_shadows(instance)
				
				boat_container.add_child(instance)
				# Ensure visibility
				instance.visible = true
				model_loaded = true
				print("BoatManager: Created boat model: %s at scale %f" % [boat_name, scale_factor])
	
	# Always create fallback if model didn't load
	if not model_loaded:
		print("BoatManager: Creating fallback boat for: %s" % boat_name)
		# Fallback mesh
		create_fallback_boat(boat_container, boat_name, is_current)
	
	# Initialize animation data
	cruise_animations[boat_name] = {
		"original_x": 0.0,
		"original_rotation": 0.0,
		"cruise_distance": 0.0,
		"is_cruising": false,
		"is_returning": false,
		"cruise_progress": 0.0
	}
	
	return boat_container

func disable_boat_shadows(node: Node):
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		disable_boat_shadows(child)

func get_boat_scale(boat_name: String) -> float:
	if boat_name.contains("Rowboat") or boat_name.contains("Fishing"):
		return 0.4
	elif boat_name.contains("Speed") or boat_name.contains("Racing"):
		return 0.6
	elif boat_name.contains("House") or boat_name.contains("Canal"):
		return 0.7
	elif boat_name.contains("Tug") or boat_name.contains("Tow"):
		return 0.65
	elif boat_name.contains("Yacht"):
		return 0.9
	elif boat_name.contains("Ship") or boat_name.contains("Liner"):
		return 1.2
	elif boat_name.contains("Cargo") or boat_name.contains("Container"):
		return 1.1
	return 0.8

func create_fallback_boat(container: Node3D, boat_name: String, is_current: bool):
	print("BoatManager: Creating fallback geometry for %s" % boat_name)
	var hull = MeshInstance3D.new()
	var hull_mesh = BoxMesh.new()
	
	var hull_size = Vector3(3, 1, 1.5)
	# Size based on boat type
	if boat_name.contains("Mega") or boat_name.contains("Liner"):
		hull_size = Vector3(6, 2, 2.5)
	elif boat_name.contains("Yacht") or boat_name.contains("Ship"):
		hull_size = Vector3(5, 1.5, 2)
	
	if is_current:
		hull_size *= 1.2
	
	hull_mesh.size = hull_size
	hull.mesh = hull_mesh
	
	var hull_material = StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.6, 0.6, 0.8)  # Light blue boat color
	hull_material.roughness = 0.7
	hull_material.metallic = 0.1
	hull.set_surface_override_material(0, hull_material)
	
	# Disable shadow on fallback boat
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hull.visible = true
	
	# Add a simple cabin for larger boats
	if not boat_name.contains("Rowboat"):
		var cabin = MeshInstance3D.new()
		var cabin_mesh = BoxMesh.new()
		cabin_mesh.size = hull_size * Vector3(0.4, 0.8, 0.6)
		cabin.mesh = cabin_mesh
		cabin.position.y = hull_size.y * 0.9
		
		var cabin_mat = StandardMaterial3D.new()
		cabin_mat.albedo_color = Color(0.9, 0.9, 0.95)
		cabin.set_surface_override_material(0, cabin_mat)
		cabin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		container.add_child(cabin)
	
	container.add_child(hull)

func animate_boats(delta: float, wave_time: float):
	for boat_name in boat_containers:
		var boat = boat_containers[boat_name]
		if not boat:
			continue
		
		var anim_data = cruise_animations.get(boat_name, {})
		
		if boat_name == GameManager.current_boat and GameManager.is_cruising:
			animate_cruising_boat(boat, anim_data, wave_time, delta)
		else:
			animate_docked_boat(boat, boat_name, wave_time, delta, anim_data)

func animate_cruising_boat(boat: Node3D, anim_data: Dictionary, wave_time: float, delta: float):
	var progress = GameManager.get_cruise_progress()
	var cruise_distance = anim_data.get("cruise_distance", 50)
	
	# Handle movement and rotation
	if progress <= 0.48:
		boat.position.x = lerp(float(anim_data["original_x"]), 
							  float(anim_data["original_x"] + cruise_distance), progress * 2.0)
		boat.rotation_degrees.y = 0.0
	elif progress <= 0.52:
		boat.position.x = float(anim_data["original_x"] + cruise_distance)
		var turn_progress = (progress - 0.48) / 0.04
		boat.rotation_degrees.y = lerp(0.0, 180.0, turn_progress)
	else:
		boat.position.x = lerp(float(anim_data["original_x"] + cruise_distance), 
							  float(anim_data["original_x"]), (progress - 0.52) * 2.08)
		boat.rotation_degrees.y = 180.0
	
	# Water interaction
	apply_water_physics(boat, wave_time, delta, true)

func animate_docked_boat(boat: Node3D, boat_name: String, wave_time: float, delta: float, anim_data: Dictionary):
	apply_water_physics(boat, wave_time, delta, false)
	
	# Reset rotation when not cruising
	if not anim_data.get("is_cruising", false):
		boat.rotation_degrees.y = 0.0

func apply_water_physics(boat: Node3D, wave_time: float, delta: float, is_cruising: bool):
	var water_height = -0.2
	if water_physics:
		water_height += water_physics.get_water_height_at(boat.global_position, wave_time)
	
	var bob_multiplier = 0.5 if is_cruising else 0.4
	var bob_offset = sin(wave_time * 2.5 + boat.position.x * 0.1) * boat_bob_strength * bob_multiplier
	bob_offset += sin(wave_time * 3.2 + boat.position.z * 0.15) * boat_bob_strength * 0.3
	
	# Keep boats ABOVE water
	var base_height = water_height + boat_draft + min_clearance
	var final_y = base_height + abs(bob_offset)  # Always add positive bobbing
	
	# Clamp to never go below waterline
	final_y = max(final_y, water_height + min_clearance)
	boat.position.y = lerp(boat.position.y, final_y, delta * 4.0)
	
	# Tilt
	if water_physics:
		var normal = water_physics.get_water_normal_at(boat.global_position, wave_time)
		boat.rotation.z = normal.x * 0.1
		boat.rotation.x = normal.z * 0.08

func start_cruise(route_name: String):
	if not GameManager.current_boat in cruise_animations:
		return
	
	var duration = GameManager.get_cruise_duration(route_name)
	var cruise_distance = float(duration * 4.0)
	
	if duration > 12.0:
		cruise_distance = min(cruise_distance, 80.0)
	
	cruise_animations[GameManager.current_boat]["cruise_distance"] = cruise_distance
	cruise_animations[GameManager.current_boat]["is_cruising"] = true
	cruise_animations[GameManager.current_boat]["is_returning"] = false

func end_cruise():
	if GameManager.current_boat in cruise_animations:
		cruise_animations[GameManager.current_boat]["is_cruising"] = false
		cruise_animations[GameManager.current_boat]["is_returning"] = false
