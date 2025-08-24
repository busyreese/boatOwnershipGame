// ocean_shader.gdshader - Fixed Gerstner Wave Ocean Shader for Godot 4
shader_type spatial;
render_mode depth_draw_always, cull_disabled;

// Screen and depth textures
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

// Wave parameters
group_uniforms Waves;
uniform vec4 wave_1 = vec4(0.2, 2.0, 0.08, 0.8);
uniform vec4 wave_2 = vec4(-0.15, -0.1, 0.04, 0.6);
uniform vec4 wave_3 = vec4(-3.0, 2.5, 0.06, 0.5);
uniform vec4 wave_4 = vec4(-0.3, -1.0, 0.05, 0.4);
uniform vec4 wave_5 = vec4(1.0, 0.05, 0.08, 1.2);
uniform vec4 wave_6 = vec4(0.8, 0.7, 0.03, 0.5);
uniform vec4 wave_7 = vec4(-1.0, 4.0, 0.05, 0.9);
uniform vec4 wave_8 = vec4(-0.3, -1.0, 0.08, 1.0);

uniform float time_factor = 3.0;
uniform float noise_zoom = 1.5;
uniform float noise_amp = 0.2;

// Water colors - Safe defaults to prevent whiteness
group_uniforms Water_colours;
uniform vec3 base_water_color : source_color = vec3(0.169, 0.373, 0.529);  // #2B5F87
uniform vec3 fresnel_water_color : source_color = vec3(0.655, 0.847, 1.0);  // #A7D8FF
uniform vec4 deep_water_color : source_color = vec4(0.051, 0.145, 0.227, 1.0);  // rgba(13, 37, 58, 1.0)
uniform vec4 shallow_water_color : source_color = vec4(0.376, 0.624, 0.749, 1.0);  // rgba(96, 159, 191, 1.0)

// Depth parameters
group_uniforms Depth;
uniform float beers_law = 0.8;
uniform float depth_offset = -0.75;
uniform float near = 0.5;
uniform float far = 1000.0;

// Edge detection and foam - Reduced intensities
group_uniforms Edge_Detection;
uniform float edge_texture_scale = 2.0;
uniform float edge_texture_offset = 0.5;
uniform float edge_texture_speed = 0.05;
uniform float edge_foam_intensity = 0.3;  // Reduced from 2.0
uniform float edge_fade_start = -2.0;
uniform float edge_fade_end = 4.0;
uniform sampler2D edge_foam_texture : hint_default_white;

// Wave peak effects - Lower intensities
group_uniforms WavePeakEffect;
uniform float peak_height_threshold = 0.4;
uniform vec3 peak_color = vec3(0.9, 0.9, 0.9);  // Slightly darker white
uniform float peak_intensity = 0.3;  // Reduced from 0.7
uniform sampler2D foam_texture : hint_default_white;
uniform float foam_intensity = 0.2;  // Reduced from 0.5
uniform float foam_scale = 1.0;

// Surface details
group_uniforms Surface_details;
uniform float metallic = 0.5;
uniform float roughness = 0.08;
uniform float normal_strength = 0.3;
uniform sampler2D normalmap_a : hint_normal;
uniform sampler2D normalmap_b : hint_normal;

// Fresnel function
float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

// Edge depth calculation
float edge(float depth) {
	depth = 2.0 * depth - 1.0;
	return near * far / (far - depth * (near - far));
}

// Hash function for noise
float hash(vec2 p) {
	return fract(sin(dot(p * 17.17, vec2(14.91, 67.31))) * 4791.9511);
}

// 2D noise
float noise(vec2 x) {
	vec2 p = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	vec2 a = vec2(1.0, 0.0);
	return mix(mix(hash(p + a.yy), hash(p + a.xy), f.x),
			   mix(hash(p + a.yx), hash(p + a.xx), f.x), f.y);
}

// Fractional Brownian Motion
float fbm(vec2 x) {
	float height = 0.0;
	float amplitude = 0.5;
	float frequency = 3.0;
	for (int i = 0; i < 3; i++) {  // Reduced iterations
		height += noise(x * frequency) * amplitude;
		amplitude *= 0.5;
		frequency *= 2.0;
	}
	return height;
}

// Wave result structure
struct WaveResult {
	vec3 displacement;
	vec3 tangent;
	vec3 binormal;
	vec3 normal;
};

// Gerstner wave calculation
WaveResult gerstner_wave(vec4 params, vec2 pos, float time) {
	float steepness = params.z * 0.7;  // Reduced steepness
	float wavelength = params.w;
	float k = 2.0 * PI / wavelength;
	float c = sqrt(9.81 / k);
	vec2 d = normalize(params.xy);
	float f = k * (dot(d, pos.xy) - c * time);
	float a = steepness / k;

	vec3 displacement = vec3(d.x * (a * cos(f)), a * sin(f), d.y * (a * cos(f)));
	vec3 tangent = vec3(1.0 - d.x * d.x * steepness * sin(f), steepness * cos(f), -d.x * d.y * steepness * sin(f));
	vec3 binormal = vec3(-d.x * d.y * steepness * sin(f), steepness * cos(f), 1.0 - d.y * d.y * steepness * sin(f));
	vec3 normal = normalize(cross(tangent, binormal));

	return WaveResult(displacement, tangent, binormal, normal);
}

// Combine all waves
WaveResult wave(vec2 pos, float time) {
	WaveResult waveResult;
	waveResult.displacement = vec3(0.0);
	waveResult.tangent = vec3(1.0, 0.0, 0.0);
	waveResult.binormal = vec3(0.0, 0.0, 1.0);
	waveResult.normal = vec3(0.0, 1.0, 0.0);

	WaveResult wr;
	
	// Add all 8 waves
	wr = gerstner_wave(wave_1, pos, time);
	waveResult.displacement += wr.displacement;
	waveResult.tangent += wr.tangent;
	waveResult.binormal += wr.binormal;
	waveResult.normal += wr.normal;
	
	wr = gerstner_wave(wave_2, pos, time);
	waveResult.displacement += wr.displacement;
	waveResult.tangent += wr.tangent;
	waveResult.binormal += wr.binormal;
	waveResult.normal += wr.normal;
	
	wr = gerstner_wave(wave_3, pos, time);
	waveResult.displacement += wr.displacement;
	waveResult.tangent += wr.tangent;
	waveResult.binormal += wr.binormal;
	waveResult.normal += wr.normal;
	
	wr = gerstner_wave(wave_4, pos, time);
	waveResult.displacement += wr.displacement;
	waveResult.tangent += wr.tangent;
	waveResult.binormal += wr.binormal;
	waveResult.normal += wr.normal;
	
	wr = gerstner_wave(wave_5, pos, time);
	waveResult.displacement += wr.displacement;
	waveResult.tangent += wr.tangent;
	waveResult.binormal += wr.binormal;
	waveResult.normal += wr.normal;
	
	wr = gerstner_wave(wave_6, pos, time);
	waveResult.displacement += wr.displacement;
	waveResult.tangent += wr.tangent;
	waveResult.binormal += wr.binormal;
	waveResult.normal += wr.normal;
	
	wr = gerstner_wave(wave_7, pos, time);
	waveResult.displacement += wr.displacement;
	waveResult.tangent += wr.tangent;
	waveResult.binormal += wr.binormal;
	waveResult.normal += wr.normal;
	
	wr = gerstner_wave(wave_8, pos, time);
	waveResult.displacement += wr.displacement;
	waveResult.tangent += wr.tangent;
	waveResult.binormal += wr.binormal;
	waveResult.normal += wr.normal;

	// Add subtle noise
	waveResult.displacement.y += fbm(pos.xy * (noise_zoom / 50.0)) * noise_amp;

	return waveResult;
}

// Varyings
varying float height;
varying vec3 world_position;
varying mat3 tbn_matrix;

void vertex() {
	float time = TIME / time_factor;
	WaveResult waveResult = wave(VERTEX.xz, time);
	VERTEX += waveResult.displacement;
	height = waveResult.displacement.y;

	vec3 n = normalize((MODELVIEW_MATRIX * vec4(waveResult.normal, 0.0)).xyz);
	vec3 t = normalize((MODELVIEW_MATRIX * vec4(waveResult.tangent.xyz, 0.0)).xyz);
	vec3 b = normalize((MODELVIEW_MATRIX * vec4((cross(waveResult.normal, waveResult.tangent.xyz)), 0.0)).xyz);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	tbn_matrix = mat3(t, b, n);
}

void fragment() {
	// Get base normal (perturbed if normal maps exist)
	vec3 perturbed_normal = NORMAL;
	
	// Sample depth for underwater effects
	float depth_raw = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	float depth_linearized = PROJECTION_MATRIX[3][2] / (depth_raw + PROJECTION_MATRIX[2][2]);
	
	// Calculate depth blend with Beer's law
	float depth_blend = exp((depth_linearized + VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
	
	// Sample screen texture for refraction
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	
	// Mix water colors based on depth
	vec3 water_depth_color = mix(shallow_water_color.rgb, deep_water_color.rgb, depth_blend_power);
	
	// FIXED: Use mix instead of addition to prevent blow-out
	vec3 refracted_color = mix(screen_color, water_depth_color, 0.7);
	
	// Calculate fresnel for surface reflection
	float fresnel_val = fresnel(2.0, NORMAL, VIEW);
	vec3 surface_color = mix(base_water_color, fresnel_water_color, fresnel_val * 0.5);
	
	// Mix surface and refracted colors
	vec3 base_color = mix(refracted_color, surface_color, 0.6);
	
	// Edge foam detection
	float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_depth - z_pos;
	float edge_fade = smoothstep(edge_fade_start, edge_fade_end, z_dif);
	
	// Apply edge foam using screen blend instead of addition
	if (edge_fade < 0.8) {
		vec3 foam_color = vec3(1.0) * edge_foam_intensity;
		base_color = mix(base_color, foam_color, (1.0 - edge_fade) * 0.3);
	}
	
	// Peak foam based on wave height
	float peak_factor = smoothstep(peak_height_threshold, peak_height_threshold + 0.1, height);
	if (peak_factor > 0.0) {
		// Use screen blend for foam instead of addition
		vec3 foam = peak_color * peak_intensity;
		base_color = mix(base_color, foam, peak_factor * 0.4);
	}
	
	// Final color output - NO ADDITION, only mixing
	ALBEDO = clamp(base_color, vec3(0.0), vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL = perturbed_normal;
	
	// Transparency for underwater visibility
	ALPHA = 0.95;
}
