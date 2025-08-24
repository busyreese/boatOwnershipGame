# ─────────────────────────────────────────────────────────────
# COMPONENT: Ground Alignment System
# ARTIFACT-ID: 8f3d2a5e-9b47-4c82-a1f6-7e8c3d4b5a92
# VERSION: 0.1.0
# OWNERSHIP: boatsimgame-prompter
# PURPOSE: Raycast-based ground snapping and normal alignment for props
# DEPENDS-ON: None
# CHANGELOG:
#   - 2024-01-15 0.1.0 Initial implementation
# SAFETY-NOTE: Do not repurpose this artifact for unrelated features.
# ─────────────────────────────────────────────────────────────

class_name GroundAligner
extends RefCounted

enum PropType {
	HOUSE,
	TREE,
	ROCK,
	GENERIC
}

# Configuration per prop type
var prop_configs = {
	PropType.HOUSE: {
		"height_offset": 0.1,        # Lift slightly to avoid z-fighting
		"max_tilt_degrees": 5.0,     # Houses should be mostly level
		"allow_pitch": false,         # No forward/back tilt
		"allow_roll": false,          # No side tilt
		"min_spacing": 8.0            # Minimum distance between houses
	},
	PropType.TREE: {
		"height_offset": 0.05,
		"max_tilt_degrees": 15.0,     # Trees can lean more
		"allow_pitch": true,
		"allow_roll": true,
		"min_spacing": 3.0
	},
	PropType.ROCK: {
		"height_offset": 0.02,
		"max_tilt_degrees": 20.0,     # Rocks can be at any angle
		"allow_pitch": true,
		"allow_roll": true,
		"min_spacing": 1.5
	},
	PropType.GENERIC: {
		"height_offset": 0.05,
		"max_tilt_degrees": 10.0,
		"allow_pitch": true,
		"allow_roll": true,
		"min_spacing": 2.0
	}
}

# Align a node to ground at its current X,Z position
func align_to_ground(node: Node3D, prop_type: PropType = PropType.GENERIC, 
					 collision_mask: int = 1, max_ray_distance: float = 100.0) -> bool:
	if not node:
		push_warning("GroundAligner: Null node provided")
		return false
	
	var config = prop_configs.get(prop_type, prop_configs[PropType.GENERIC])
	var space_state = node.get_world_3d().direct_space_state
	
	# Cast ray downward from above the node
	var from = node.global_position + Vector3(0, max_ray_distance/2, 0)
	var to = node.global_position - Vector3(0, max_ray_distance/2, 0)
	
	var query = PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		push_warning("GroundAligner: No ground found for %s at position %s" % [node.name, node.global_position])
		return false
	
	# Snap to hit position with offset
	var hit_pos = result.position
	node.global_position = hit_pos + Vector3(0, config.height_offset, 0)
	
	# Align to surface normal if needed
	if config.max_tilt_degrees > 0:
		var normal = result.normal
		align_to_normal(node, normal, config)
	
	return true

# Align node rotation to match surface normal with constraints
func align_to_normal(node: Node3D, normal: Vector3, config: Dictionary):
	if normal.length_squared() < 0.01:
		return # Invalid normal
	
	normal = normal.normalized()
	
	# Calculate desired rotation from normal
	var up = Vector3.UP
	var angle = rad_to_deg(acos(normal.dot(up)))
	
	# Only apply if within tilt limit
	if angle <= config.max_tilt_degrees:
		# Get rotation axis (perpendicular to normal and up)
		var axis = up.cross(normal).normalized()
		
		if axis.length_squared() > 0.01:  # Valid axis
			# Store original yaw
			var original_yaw = node.rotation.y
			
			# Apply rotation based on constraints
			if config.allow_pitch and config.allow_roll:
				# Full alignment to normal
				node.look_at(node.global_position - normal, Vector3.UP)
				node.rotation.x += PI/2  # Correct for look_at orientation
			elif config.allow_pitch and not config.allow_roll:
				# Only pitch (X rotation)
				node.rotation.x = atan2(normal.z, normal.y)
				node.rotation.z = 0
			elif not config.allow_pitch and config.allow_roll:
				# Only roll (Z rotation)
				node.rotation.x = 0
				node.rotation.z = atan2(-normal.x, normal.y)
			
			# Preserve original yaw for houses/buildings
			if not config.allow_pitch and not config.allow_roll:
				node.rotation.y = original_yaw

# Check minimum spacing between objects
func check_spacing(position: Vector3, existing_positions: Array, min_distance: float) -> bool:
	for pos in existing_positions:
		if position.distance_to(pos) < min_distance:
			return false
	return true

# Face an object toward a target point (typically ocean)
func face_toward(node: Node3D, target: Vector3, jitter_degrees: float = 0.0):
	var look_pos = Vector3(target.x, node.global_position.y, target.z)
	node.look_at(look_pos, Vector3.UP)
	
	# Add random yaw jitter for variety
	if jitter_degrees > 0:
		node.rotation.y += deg_to_rad(randf_range(-jitter_degrees, jitter_degrees))
