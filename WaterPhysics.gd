# WaterPhysics.gd - CPU-side wave calculation matching the shader
extends Node

# Wave parameters matching shader - 3 wave sets (long, mid, short)
var wave_sets = {
	"long": {
		"amplitude": 0.10,
		"wavelength": 14.0,
		"speed": 1.2,
		"direction": Vector2(0.7, 0.3).normalized()
	},
	"mid": {
		"amplitude": 0.06,
		"wavelength": 7.0,
		"speed": 1.8,
		"direction": Vector2(-0.4, 0.6).normalized()
	},
	"short": {
		"amplitude": 0.03,
		"wavelength": 3.5,
		"speed": 2.5,
		"direction": Vector2(0.2, -0.8).normalized()
	}
}

var time_factor: float = 3.0  # Match shader's time_factor

# Get water height at a specific world position
func get_water_height_at(world_pos: Vector3, time: float) -> float:
	var height = 0.0
	var pos2d = Vector2(world_pos.x, world_pos.z)
	
	# Calculate Gerstner wave height for each wave set
	for wave_name in wave_sets:
		var wave = wave_sets[wave_name]
		height += calculate_gerstner_height(
			pos2d,
			wave.direction,
			wave.amplitude,
			wave.wavelength,
			wave.speed,
			time / time_factor
		)
	
	# Add small noise component for variation
	var noise_val = sin(pos2d.x * 0.1 + time * 0.5) * sin(pos2d.y * 0.15 + time * 0.7)
	height += noise_val * 0.02
	
	return height

# Calculate single Gerstner wave height
func calculate_gerstner_height(pos: Vector2, direction: Vector2, amplitude: float, wavelength: float, speed: float, time: float) -> float:
	var k = 2.0 * PI / wavelength
	var c = sqrt(9.81 / k)  # Deep water wave speed
	var steepness = 0.5  # Moderate steepness for calm marina
	
	var f = k * (direction.dot(pos) - c * speed * time)
	var a = steepness * amplitude / k
	
	return a * sin(f)

# Get normal at position (for tilt calculations)
func get_water_normal_at(world_pos: Vector3, time: float) -> Vector3:
	var epsilon = 0.1
	var pos = world_pos
	
	# Sample heights around the position
	var h_center = get_water_height_at(pos, time)
	var h_right = get_water_height_at(pos + Vector3(epsilon, 0, 0), time)
	var h_forward = get_water_height_at(pos + Vector3(0, 0, epsilon), time)
	
	# Calculate normal from height differences
	var dx = (h_right - h_center) / epsilon
	var dz = (h_forward - h_center) / epsilon
	
	var normal = Vector3(-dx, 1.0, -dz).normalized()
	return normal

# Sync wave parameters with shader material
func sync_with_shader(ocean_material: ShaderMaterial):
	if not ocean_material:
		return
	
	# Update shader parameters to match our wave sets
	# Long waves
	ocean_material.set_shader_parameter("wave_1", Vector4(
		wave_sets.long.direction.x,
		wave_sets.long.direction.y,
		wave_sets.long.amplitude * 0.8,  # Slightly reduced for shader
		wave_sets.long.wavelength
	))
	ocean_material.set_shader_parameter("wave_2", Vector4(
		-wave_sets.long.direction.y,
		wave_sets.long.direction.x,
		wave_sets.long.amplitude * 0.6,
		wave_sets.long.wavelength * 1.2
	))
	
	# Mid waves
	ocean_material.set_shader_parameter("wave_3", Vector4(
		wave_sets.mid.direction.x,
		wave_sets.mid.direction.y,
		wave_sets.mid.amplitude * 0.8,
		wave_sets.mid.wavelength
	))
	ocean_material.set_shader_parameter("wave_4", Vector4(
		-wave_sets.mid.direction.y,
		wave_sets.mid.direction.x,
		wave_sets.mid.amplitude * 0.6,
		wave_sets.mid.wavelength * 1.1
	))
	
	# Short waves
	ocean_material.set_shader_parameter("wave_5", Vector4(
		wave_sets.short.direction.x,
		wave_sets.short.direction.y,
		wave_sets.short.amplitude * 0.8,
		wave_sets.short.wavelength
	))
	ocean_material.set_shader_parameter("wave_6", Vector4(
		-wave_sets.short.direction.y,
		wave_sets.short.direction.x,
		wave_sets.short.amplitude * 0.6,
		wave_sets.short.wavelength * 0.9
	))
	
	# Fill remaining waves with variations
	ocean_material.set_shader_parameter("wave_7", Vector4(
		0.5, 0.5,
		wave_sets.short.amplitude * 0.4,
		wave_sets.short.wavelength * 1.5
	))
	ocean_material.set_shader_parameter("wave_8", Vector4(
		-0.3, 0.7,
		wave_sets.mid.amplitude * 0.3,
		wave_sets.mid.wavelength * 0.8
	))
	
	ocean_material.set_shader_parameter("time_factor", time_factor)
	
	print("Water physics synced with shader")
