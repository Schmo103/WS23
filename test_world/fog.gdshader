shader_type canvas_item;

// Define the color as a uniform variable
uniform vec3 u_color = vec3(0.35, 0.48, 0.95);

// Define the number of octaves as a uniform variable
uniform int u_octaves : hint_range(1, 800) = 4;

// Define the scale for the fbm function as a uniform variable
uniform float u_scale : hint_range(0.1, 1.0) = 0.5;

// Define the UV scale as a uniform variable
uniform float u_uv_scale : hint_range(1.0, 100.0) = 20.0;

// Define the time scale for the motion as a uniform variable
uniform vec2 u_time_scale = vec2(-0.5, 0.5);

// Define the final scale as a uniform variable
uniform float u_final_scale : hint_range(0.1, 1.0) = 0.3;

// Define the mask texture as a uniform variable
uniform sampler2D u_mask;

// Define the modulate color as a uniform variable
uniform vec4 u_modulate;

float rand(vec2 coord){
	return fract(sin(dot(coord, vec2(7805, 7899)) * 1000.0) * 1000.0);
}

float noise(vec2 coord){
	vec2 i = floor(coord);
	vec2 f = fract(coord);

	// 4 corners of a rectangle surrounding our point
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord){
	float value = 0.0;
	float scale = u_scale;

	for(int i = 0; i < u_octaves; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 coord = UV * u_uv_scale;

	vec2 motion = vec2( fbm(coord + u_time_scale * TIME) );

	float final = fbm(coord + motion);

	// Get the mask value at the current UV coordinate
	float mask = texture(u_mask, UV).r;

	// Apply the mask to the final color
	COLOR = vec4(u_color, final * u_final_scale * mask) * u_modulate;
}
