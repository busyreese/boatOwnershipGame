# ─────────────────────────────────────────────────────────────
# COMPONENT: Beach Town Spawner
# ARTIFACT-ID: c4a7f9e2-3d8b-4a56-9c31-2f4e6d8a7b93
# VERSION: 0.1.0
# OWNERSHIP: boatsimgame-prompter
# PURPOSE: Procedurally spawns and aligns beach props (houses, trees, rocks)
# DEPENDS-ON: GroundAligner.gd
# CHANGELOG:
#   - 2024-01-15 0.1.0 Initial implementation
# SAFETY-NOTE: Do not repurpose this artifact for unrelated features.
# ─────────────────────────────────────────────────────────────

@tool
extends Node3D

# Export variables for editor configuration
@export_group("Spawn Counts")
@export_range(0, 20) var house_count: int = 10
@export_range(0, 30) var tree_count: int = 8
@export_range(0, 30) var rock_count: int = 12

@export_group("Scene Assets")
@export var house_scenes: Array[PackedScene] = []
@export var tree_scenes: Array[PackedScene] = []
@export var rock_scenes: Array[PackedScene] = []

@export_group("Placement Settings")
@export var beach_length: float = 50.0
@export var setback_from_water: float = 10.0  # How far back from water
@export var depth_variation: float = 5.0       # Random depth variation
@export var ocean_direction: Vector3 = Vector3(0, 0, 20)  # Where houses face
@export var spacing_jitter: float = 2.0        # Randomness in spacing
@export var placement_seed: int = 12345

@export_group("Ground Detection")
@export_flags_3d_physics var ground_collision_layer: int = 1
@export var max_placement_attempts: int = 50

@export_group("Debug")
@export var regenerate_in_editor: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			spawn_all_props()
@export var clear_props: bool = false:
	set(value):
		if value:
			clear_all_props()

# Runtime state
var ground_aligner: GroundAligner
var placed_positions: Dictionary = {
	"houses": [],
	"trees": [],
	"rocks": []
}
var prop_container: Node3D

func _ready():
	ground_aligner = GroundAligner.new()
	
	if not Engine.is_editor_hint():
		spawn_all_props()

func spawn_all_props():
	print("BeachTownSpawner: Starting prop placement...")
	
	# Clear existing props
	clear_all_props()
	
	# Create container
	prop_container = Node3D.new()
	prop_container.name = "BeachProps"
	add_child(prop_container)
	
	# Set random seed for deterministic placement
	seed(placement_seed)
	
	# Reset position tracking
	placed_positions.clear()
	placed_positions["houses"] = []
	placed_positions["trees"] = []
	placed_positions["rocks"] = []
	
	# Spawn in order: houses first (most important), then trees, then rocks
	spawn_houses()
	spawn_trees()
	spawn_rocks()
	
	print("BeachTownSpawner: Placement complete - Houses: %d, Trees: %d, Rocks: %d" % 
		  [placed_positions.houses.size(), placed_positions.trees.size(), placed_positions.rocks.size()])

func spawn_houses():
	if house_scenes.is_empty():
		push_warning("BeachTownSpawner: No house scenes assigned")
		return
	
	var houses_placed = 0
	var attempts = 0
	
	while houses_placed < house_count and attempts < max_placement_attempts:
		attempts += 1
		
		# Calculate position along beach
		var t = float(houses_placed) / float(max(1, house_count - 1))
		var x = lerp(-beach_length/2, beach_length/2, t)
		x += randf_range(-spacing_jitter, spacing_jitter)
		
		var z = -setback_from_water + randf_range(0, depth_variation)
		var pos = global_position + Vector3(x, 5.0, z)  # Start high for raycast
		
		# Check spacing
		var min_spacing = ground_aligner.prop_configs[GroundAligner.PropType.HOUSE].min_spacing
		if not ground_aligner.check_spacing(pos, placed_positions.houses, min_spacing):
			continue
		
		# Spawn house
		var scene = house_scenes[randi() % house_scenes.size()]
		var house = scene.instantiate()
		prop_container.add_child(house)
		house.global_position = pos
		
		# Align to ground
		if ground_aligner.align_to_ground(house, GroundAligner.PropType.HOUSE, ground_collision_layer):
			# Face toward ocean
			ground_aligner.face_toward(house, global_position + ocean_direction, 12.0)
			placed_positions.houses.append(house.global_position)
			houses_placed += 1
		else:
			house.queue_free()

func spawn_trees():
	if tree_scenes.is_empty():
		push_warning("BeachTownSpawner: No tree scenes assigned")
		return
	
	var trees_placed = 0
	var attempts = 0
	
	while trees_placed < tree_count and attempts < max_placement_attempts * 2:
		attempts += 1
		
		# Random position with bias toward edges
		var x = randf_range(-beach_length/2, beach_length/2)
		var z = randf_range(-setback_from_water - depth_variation, -setback_from_water + depth_variation * 2)
		var pos = global_position + Vector3(x, 5.0, z)
		
		# Check spacing from all props
		var min_spacing = ground_aligner.prop_configs[GroundAligner.PropType.TREE].min_spacing
		var all_positions = placed_positions.houses + placed_positions.trees
		if not ground_aligner.check_spacing(pos, all_positions, min_spacing):
			continue
		
		# Spawn tree
		var scene = tree_scenes[randi() % tree_scenes.size()]
		var tree = scene.instantiate()
		prop_container.add_child(tree)
		tree.global_position = pos
		
		# Align to ground
		if ground_aligner.align_to_ground(tree, GroundAligner.PropType.TREE, ground_collision_layer):
			# Random rotation for variety
			tree.rotation.y = randf() * TAU
			placed_positions.trees.append(tree.global_position)
			trees_placed += 1
		else:
			tree.queue_free()

func spawn_rocks():
	if rock_scenes.is_empty():
		push_warning("BeachTownSpawner: No rock scenes assigned")
		return
	
	var rocks_placed = 0
	var attempts = 0
	
	while rocks_placed < rock_count and attempts < max_placement_attempts * 2:
		attempts += 1
		
		# Random position, can be closer to water
		var x = randf_range(-beach_length/2, beach_length/2)
		var z = randf_range(-setback_from_water + depth_variation, -2.0)  # Can be near waterline
		var pos = global_position + Vector3(x, 5.0, z)
		
		# Check spacing from all props
		var min_spacing = ground_aligner.prop_configs[GroundAligner.PropType.ROCK].min_spacing
		var all_positions = placed_positions.houses + placed_positions.trees + placed_positions.rocks
		if not ground_aligner.check_spacing(pos, all_positions, min_spacing * 0.7):  # Rocks can be closer
			continue
		
		# Spawn rock
		var scene = rock_scenes[randi() % rock_scenes.size()]
		var rock = scene.instantiate()
		prop_container.add_child(rock)
		rock.global_position = pos
		
		# Align to ground
		if ground_aligner.align_to_ground(rock, GroundAligner.PropType.ROCK, ground_collision_layer):
			# Random rotation and scale for variety
			rock.rotation.y = randf() * TAU
			rock.scale *= randf_range(0.6, 1.4)
			placed_positions.rocks.append(rock.global_position)
			rocks_placed += 1
		else:
			rock.queue_free()

func clear_all_props():
	if prop_container:
		prop_container.queue_free()
		prop_container = null
	
	# Also clear any orphaned props
	for child in get_children():
		if child.name == "BeachProps":
			child.queue_free()
