shader_type canvas_item;
// Filtro retrô (estilo console 32 bits): pixelização, paleta reduzida com
// pontilhado ordenado, leve aberração e vinheta. Mascara modelos simples e
// esconde o fundo. O HUD fica em camada acima e não passa por aqui.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0,1.0) = 1.0;
uniform float pixel_height = 160.0; // linhas verticais da imagem final
uniform float color_levels = 20.0;  // tons por canal
uniform float dither_amount : hint_range(0.0,2.0) = 1.0;
uniform float contrast = 1.12;
uniform float saturation = 0.78;

float bayer4(vec2 p) {
 int x=int(mod(p.x,4.0)); int y=int(mod(p.y,4.0));
 int i=x+y*4;
 int m[16]=int[16](0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5);
 return float(m[i])/16.0-.5;
}

void fragment() {
 vec2 screen=1.0/SCREEN_PIXEL_SIZE;
 float block=max(1.0,floor(screen.y/pixel_height));
 vec2 cell=floor(FRAGCOORD.xy/block);
 vec2 uv=(cell*block+block*.5)*SCREEN_PIXEL_SIZE;
 vec3 original=texture(screen_texture,SCREEN_UV).rgb;
 vec3 c;
 c.r=texture(screen_texture,uv+vec2(SCREEN_PIXEL_SIZE.x*block*.35,0)).r;
 c.g=texture(screen_texture,uv).g;
 c.b=texture(screen_texture,uv-vec2(SCREEN_PIXEL_SIZE.x*block*.35,0)).b;
 float l=dot(c,vec3(.299,.587,.114));
 c=mix(vec3(l),c,saturation);
 c=(c-.5)*contrast+.5;
 // Sombras puxam para verde-azulado frio; luzes para amarelo de lâmpada.
 c*=mix(vec3(.85,.97,1.05),vec3(1.06,1.0,.86),smoothstep(.1,.7,l));
 c+=bayer4(cell)*dither_amount/color_levels;
 c=floor(clamp(c,0.0,1.0)*color_levels+.5)/color_levels;
 vec2 v=SCREEN_UV-.5;
 c*=1.0-.55*dot(v,v)*1.6;
 COLOR=vec4(mix(original,c,intensity),1.0);
}
