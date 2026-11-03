shader_type canvas_item;
// Filtro retrô sobre a imagem 3D já renderizada em baixa resolução (SubViewport).
// Não lê a tela (hint_screen_texture), então funciona igual no PC, web e
// celular. Pixelização vem da própria resolução baixa + filtro nearest.
uniform float intensity : hint_range(0.0,1.0) = 1.0;
uniform vec2 low_size = vec2(356.0,200.0);
uniform float color_levels = 20.0;
uniform float dither_amount : hint_range(0.0,2.0) = 1.0;
uniform float contrast = 1.12;
uniform float saturation = 0.78;

float bayer4(vec2 p) {
 int x=int(mod(p.x,4.0)); int y=int(mod(p.y,4.0));
 int m[16]=int[16](0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5);
 return float(m[x+y*4])/16.0-.5;
}

void fragment() {
 vec2 cell=floor(UV*low_size);
 vec2 texel=1.0/low_size;
 vec3 original=texture(TEXTURE,UV).rgb;
 vec3 c;
 c.r=texture(TEXTURE,UV+vec2(texel.x*.5,0)).r;
 c.g=original.g;
 c.b=texture(TEXTURE,UV-vec2(texel.x*.5,0)).b;
 float l=dot(c,vec3(.299,.587,.114));
 c=mix(vec3(l),c,saturation);
 c=(c-.5)*contrast+.5;
 c*=mix(vec3(.85,.97,1.05),vec3(1.06,1.0,.86),smoothstep(.1,.7,l));
 c+=bayer4(cell)*dither_amount/color_levels;
 c=floor(clamp(c,0.0,1.0)*color_levels+.5)/color_levels;
 vec2 v=UV-.5;
 c*=1.0-.55*dot(v,v)*1.6;
 COLOR=vec4(mix(original,c,intensity),1.0);
}
