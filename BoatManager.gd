# ─────────────────────────────────────────────────────────────
# COMPONENT: Boat Manager
# ARTIFACT-ID: e4f8a2b1-boat-manager-fixed
# VERSION: 0.1.4
# OWNERSHIP: boatsimgame-prompter
# PURPOSE: Handles boat display, animations, and physics
# DEPENDS-ON: GameManager.gd, WaterPhysics.gd
# CHANGELOG:
#   - 2025-01-15 0.1.4 Fixed rowboat orientation and boat water depth
#   - 2025-01-14 0.1.3 Fixed boat spawning failures
# SAFETY-NOTE: Do not repurpose this artifact for unrelated features.
# ─────────────────────────────────────────────────────────────

# BoatManager.gd - Handles boat display, animations, and physics
extends Node3D

var boat_containers = {}
var cruise_animations = {}
var water_physics: Node
var boat_bob_strength: float = 0.12
var boat_draft: float = -0.3  # How deep boats sit in water (negative = lower)
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
		boat.position = Vector3(x_offset, boat_draft, 10.0)  # Lower in water
		cruise_animations[boat_name]["original_x"] = x_offset
		cruise_animations[boat_name]["original_rotation"] = 0.0  # Facing out to sea
		cruise_animations[boat_name]["base_y"] = boat_draft  # Water level base
		boat.rotation_degrees.y = 0.0  # Facing out to sea
		
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
				
				# Fix rotation for specific boat models
				if boat_name == "Old Rowboat":
					# Rowboat model is vertical, rotate to horizontal
					instance.rotation_degrees.z = 90  # Rotate around Z axis to lay flat
					instance.position.y += 0.1  # Slight lift after rotation
				elif boat_name.contains("Sailboat"):
					# Some sailboats may need slight adjustments
					instance.rotation_degrees.y = 180  # Face forward
					instance.position.y -= 0.1
				
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
		"cruise_distance": 50.0,
		"is_cruising": false,
		"is_returning": false,
		"cruise_progress": 0.0,
		"base_y": boat_draft
	}
	
	return boat_container

func disable_boat_shadows(node: Node):
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		disable_boat_shadows(child)

func get_boat_scale(boat_name: String) -> float:
	# Boat-specific scaling
	if boat_name == "Old Rowboat":
		return 0.7
	elif boat_name == "Basic Sailboat":
		return 0.5
	elif boat_name.contains("Speed") or boat_name.contains("Motor"):
		return 0.6
	elif boat_name.contains("Yacht"):
		return 0.8
	elif boat_name.contains("Mega") or boat_name.contains("Ocean"):
		return 1.0
	return 0.6

func create_fallback_boat(container: Node3D, boat_name: String, is_current: bool):
	var hull = MeshInstance3D.new()
	hull.name = "FallbackHull"
	
	# Get boat specs for sizing
	var spec = GameManager.boat_specs.get(boat_name, {})
	var hull_size = Vector3(
		spec.get("length_m", 4.0) * 0.3,
		spec.get("height_m", 0.8) * 0.3,
		spec.get("width_m", 1.5) * 0.3
	)
	
	# Create hull mesh
	var hull_mesh = BoxMesh.new()
	hull_mesh.size = hull_size
	hull.mesh = hull_mesh
	
	# Material based on hull type
	var hull_mat = StandardMaterial3D.new()
	match spec.get("hull_type", "Wood"):
		"Wood":
			hull_mat.albedo_color = Color(0.4, 0.25, 0.15)
		"Fiberglass":
			hull_mat.albedo_color = Color(0.9, 0.9, 0.95)
		"Steel":
			hull_mat.albedo_color = Color(0.3, 0.35, 0.4)
			hull_mat.metallic = 0.6
		_:
			hull_mat.albedo_color = Color(0.5, 0.5, 0.6)
	
	hull_mat.roughness = 0.3
	hull.set_surface_override_material(0, hull_mat)
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Add cabin for larger boats
	if spec.get("has_cabin", false):
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

func apply_water_physics(boat: Node3D, wave_time: float, delta: float, is_cruising: bool = false):
	if not water_physics:
		# Fallback bobbing
		boat.position.y = cruise_animations[boat.name.replace("Boat_", "")]["base_y"] + sin(wave_time * 2.0) * boat_bob_strength * 0.5
		return
	
	# Get water height at boat position
	var water_height = water_physics.get_water_height_at(boat.position, wave_time)
	
	var bob_amplitude = boat_bob_strength * (1.5 if is_cruising else 1.0)
	
	# Apply bobbing with minimum clearance
	var base_y = cruise_animations[boat.name.replace("Boat_", "")]["base_y"]
	var target_y = base_y + water_height + bob_amplitude * sin(wave_time * 2.0 + boat.position.x * 0.1)
	boat.position.y = lerp(boat.position.y, target_y, delta * 3.0)
	
	# Tilt based on waves
	var tilt_strength = 0.05 if is_cruising else 0.02
	boat.rotation.z = sin(wave_time * 1.5) * tilt_strength
	boat.rotation.x = cos(wave_time * 1.8) * tilt_strength * 0.5
