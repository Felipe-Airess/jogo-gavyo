shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float intensity : hint_range(0.0,1.0) = 0.55;
void fragment() {
 vec3 c=texture(screen_texture,SCREEN_UV).rgb;
 float l=dot(c,vec3(.299,.587,.114));
 vec3 shadow=vec3(.86,.94,1.08);
 vec3 light=vec3(1.06,1.015,.89);
 c*=mix(shadow,light,smoothstep(.12,.75,l));
 float grain=fract(sin(dot(FRAGCOORD.xy+floor(TIME*12.0),vec2(12.9898,78.233)))*43758.5453)-.5;
 c+=grain*.012*intensity;
 float vignette=1.0-.10*intensity*pow(length((SCREEN_UV-.5)*1.3),2.0);
 COLOR=vec4(mix(texture(screen_texture,SCREEN_UV).rgb,c,intensity)*vignette,1.0);
}
