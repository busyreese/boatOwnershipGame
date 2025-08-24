// ARTIFACT-ID: c9f6a3d7-sand-shader
// sand_beach_shader.gdshader - Sandy beach material with wet sand effect
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Sand colors
uniform vec3 sand_color : source_color = vec3(0.96, 0.87, 0.70);
uniform vec3 wet_sand_color : source_color = vec3(0.65, 0.55, 0.40);

// Texture parameters
uniform sampler2D sand_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float texture_scale = 10.0;
uniform float normal_strength = 0.5;

// Material properties
uniform float roughness_dry = 0.9;
uniform float roughness_wet = 0.4;
uniform float metallic_sand = 0.0;

// Water interaction
uniform float water_height = -0.2;
uniform float wet_band_size = 1.0;

// Triplanar mapping for slopes
vec4 triplanar_texture(sampler2D tex, vec3 world_pos, vec3 world_normal, float scale) {
	vec3 blend = abs(world_normal);
	blend = normalize(max(blend, 0.00001));
	float b = blend.x + blend.y + blend.z;
	blend /= vec3(b, b, b);
	
	vec4 xaxis = texture(tex, world_pos.yz * scale);
	vec4 yaxis = texture(tex, world_pos.xz * scale);
	vec4 zaxis = texture(tex, world_pos.xy * scale);
	
	return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

vec3 triplanar_normal(sampler2D tex, vec3 world_pos, vec3 world_normal, float scale) {
	vec3 blend = abs(world_normal);
	blend = normalize(max(blend, 0.00001));
	float b = blend.x + blend.y + blend.z;
	blend /= vec3(b, b, b);
	
	vec3 xaxis = texture(tex, world_pos.yz * scale).xyz * 2.0 - 1.0;
	vec3 yaxis = texture(tex, world_pos.xz * scale).xyz * 2.0 - 1.0;
	vec3 zaxis = texture(tex, world_pos.xy * scale).xyz * 2.0 - 1.0;
	
	xaxis = vec3(xaxis.z, xaxis.y, xaxis.x);
	yaxis = vec3(yaxis.x, xaxis.z, yaxis.y);
	zaxis = vec3(xaxis.x, yaxis.y, zaxis.z);
	
	return normalize(xaxis * blend.x + yaxis * blend.y + zaxis * blend.z);
}

varying vec3 world_pos;
varying float wetness_factor;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float height_above_water = world_pos.y - water_height;
	wetness_factor = 1.0 - smoothstep(0.0, wet_band_size, height_above_water);
	wetness_factor = max(wetness_factor, COLOR.r);
}

void fragment() {
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	vec4 sand_tex = triplanar_texture(sand_texture, world_pos, world_normal, texture_scale);
	vec3 normal_tex = triplanar_normal(sand_normal, world_pos, world_normal, texture_scale);
	
	vec3 base_color = mix(sand_color, wet_sand_color, wetness_factor);
	
	ALBEDO = base_color * sand_tex.rgb;
	ROUGHNESS = mix(roughness_dry, roughness_wet, wetness_factor);
	METALLIC = metallic_sand;
	
	float current_normal_strength = mix(normal_strength, normal_strength * 0.3, wetness_factor);
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), normal_tex * 0.5 + 0.5, current_normal_strength);
	
	SPECULAR = mix(0.5, 0.8, wetness_factor);
	
	float rim = 1.0 - dot(normalize(VIEW), NORMAL);
	rim = pow(rim, 2.0);
	EMISSION = vec3(0.02, 0.03, 0.04) * rim * wetness_factor;
}
