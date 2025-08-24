# ─────────────────────────────────────────────────────────────
# COMPONENT: Beach Collision Body
# ARTIFACT-ID: a3f7d8e2-beach-collision-9b4c-8f2e3a5d7c91
# VERSION: 0.1.0
# OWNERSHIP: boatsimgame-prompter
# PURPOSE: Provides collision for beach terrain for ground detection
# DEPENDS-ON: None
# CHANGELOG:
#   - 2025-01-15 0.1.0 Initial creation for ground detection
# SAFETY-NOTE: Do not repurpose this artifact for unrelated features.
# ─────────────────────────────────────────────────────────────

extends StaticBody3D

func _ready():
	# Set collision layer to 1 for ground detection
	collision_layer = 1
	collision_mask = 0
	
	# Create a large box collision shape for the beach/ground
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	
	# Make a large flat box that covers the beach area
	box_shape.size = Vector3(100, 1, 100)  # Wide and deep, but thin
	
	collision_shape.shape = box_shape
	collision_shape.position = Vector3(0, -0.5, 0)  # Position just below surface
	
	add_child(collision_shape)
	
	print("Beach collision body created for ground detection")
