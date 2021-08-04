shader_type canvas_item;

uniform bool use_screen = false;
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
	vec4 color = (use_screen) ? texture(SCREEN_TEXTURE, SCREEN_UV) : texture(TEXTURE, UV);
	
	if (color.a > 0f){
		if (distance(color_1_from.rgb, color.rgb) < threshold){
			color = color_1_to;
		} else if (distance(color_2_from.rgb, color.rgb) < threshold){
			color = color_2_to;
		} else if (distance(color_3_from.rgb, color.rgb) < threshold){
			color = color_3_to;
		} else if (distance(color_4_from.rgb, color.rgb) < threshold){
			color = color_4_to;
		} else if (distance(color_5_from.rgb, color.rgb) < threshold){
			color = color_5_to;
		} else if (distance(color_6_from.rgb, color.rgb) < threshold){
			color = color_6_to;
		} else if (distance(color_7_from.rgb, color.rgb) < threshold){
			color = color_7_to;
		} else if (distance(color_8_from.rgb, color.rgb) < threshold){
			color = color_8_to;
		}
	}

	COLOR = color;
}


