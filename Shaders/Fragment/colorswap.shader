shader_type canvas_item;

uniform bool background_transparent = false;
uniform vec4 color_1_from : hint_color = vec4(1);
uniform vec4 color_1_to : hint_color = vec4(1);
uniform vec4 color_2_from : hint_color = vec4(1);
uniform vec4 color_2_to : hint_color = vec4(1);
uniform vec4 color_3_from : hint_color = vec4(1);
uniform vec4 color_3_to : hint_color = vec4(1);
uniform vec4 color_4_from : hint_color = vec4(1);
uniform vec4 color_4_to : hint_color = vec4(1);
uniform vec4 color_5_from : hint_color = vec4(1);
uniform vec4 color_5_to : hint_color = vec4(1);
uniform vec4 color_6_from : hint_color = vec4(1);
uniform vec4 color_6_to : hint_color = vec4(1);
uniform vec4 color_7_from : hint_color = vec4(1);
uniform vec4 color_7_to : hint_color = vec4(1);
uniform vec4 color_8_from : hint_color = vec4(1);
uniform vec4 color_8_to : hint_color = vec4(1);
uniform float threshold = 0.05;


void fragment(){
	vec4 mix_color = vec4(0f,0f,0f,-1f);
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	if (distance(color_1_from.rgb, color.rgb) < threshold){
		mix_color = color_1_to;
	} else if (distance(color_2_from.rgb, color.rgb) < threshold){
		mix_color = color_2_to;
	} else if (distance(color_3_from.rgb, color.rgb) < threshold){
		mix_color = color_3_to;
	} else if (distance(color_4_from.rgb, color.rgb) < threshold){
		mix_color = color_4_to;
	} else if (distance(color_5_from.rgb, color.rgb) < threshold){
		mix_color = color_5_to;
	} else if (distance(color_6_from.rgb, color.rgb) < threshold){
		mix_color = color_6_to;
	} else if (distance(color_7_from.rgb, color.rgb) < threshold){
		mix_color = color_7_to;
	} else if (distance(color_8_from.rgb, color.rgb) < threshold){
		mix_color = color_8_to;
	}

	color = mix_color;//vec4(mix(color.rgb, vec3(1f,0f,0f), 1.0 - mix_color.a), 1f);
	if (mix_color.a == 0f)
		color = vec4(1f,0f,0f,0f);
	COLOR = color;
}


