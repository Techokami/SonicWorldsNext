shader_type canvas_item;
// NOTE: palette sizes has to be to the power of 2
uniform float amount : hint_range(1,255,1);
uniform sampler2D originalPalette : filter_nearest;
uniform sampler2D swapPalette : filter_nearest;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

void fragment(){
	vec4 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	
	vec3 color = screen.rgb;
	vec3 pal = texture(originalPalette,vec2(0,0)).rgb;
	vec3 swap_pal = texture(originalPalette,vec2(0,0)).rgb;
	vec3 new_color = pal;
	vec3 remap_color = pal;
	
	for (float i = 0.0; i<=amount; i++){
		pal = texture(originalPalette,vec2(i/amount,0)).rgb;
		swap_pal = texture(swapPalette,vec2(i/amount,0)).rgb;
		
		if (distance(pal, color) < distance(new_color, color)) {
			new_color = pal;
			remap_color = swap_pal;
			
		}
	}
	
	COLOR.rgb = remap_color;
	COLOR.a  = texture(TEXTURE,UV).a;
	
	//COLOR = screen.rgba;
}