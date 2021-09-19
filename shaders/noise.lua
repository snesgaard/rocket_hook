local glsl_random = require "shaders.random"

local noise = {}

noise.generic_1 = [[
float rand(vec2 n) {
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);

	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}
]]

noise.generic_2 = [[
//	<https://www.shadertoy.com/view/4dS3Wd>
//	By Morgan McGuire @morgan3d, http://graphicscodex.com
//
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
}

float noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
]]

noise.perlin = [[
//	Classic Perlin 2D Noise
//	by Stefan Gustavson
//
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}

float noise(vec2 P){
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 *
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy * 0.5 + 0.5;
}
]]

noise.simplex = [[
// Simplex 2D noise
//
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float noise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g) * 0.5 + 0.5;
}
]]

noise.voroni = [[
//	https://www.shadertoy.com/view/lsjGWD
//	by Pietro De Nicola
//
#define OCTAVES   		1		// 7
#define SWITCH_TIME 	60.0		// seconds
uniform float time;

float t = time/SWITCH_TIME;

float function 			= mod(t,4.0);
bool  multiply_by_F1	= mod(t,8.0)  >= 4.0;
bool  inverse				= mod(t,16.0) >= 8.0;
float distance_type	= 0.5 + 1;

vec2 hash( vec2 p ){
	p = vec2( dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3)));
	return fract(sin(p)*43758.5453);
}

float noise( in vec2 x ){
	vec2 n = floor( x );
	vec2 f = fract( x );

	float F1 = 8.0;
	float F2 = 8.0;

	for( int j=-1; j<=1; j++ )
		for( int i=-1; i<=1; i++ ){
			vec2 g = vec2(i,j);
			vec2 o = hash( n + g );

			o = 0.5 + 0.41*sin( time + 6.2831*o );
			vec2 r = g - f + o;

		float d = 	distance_type < 1.0 ? dot(r,r)  :				// euclidean^2
				  	distance_type < 2.0 ? sqrt(dot(r,r)) :			// euclidean
					distance_type < 3.0 ? abs(r.x) + abs(r.y) :		// manhattan
					distance_type < 4.0 ? max(abs(r.x), abs(r.y)) :	// chebyshev
					0.0;

		if( d<F1 ) {
			F2 = F1;
			F1 = d;
		} else if( d<F2 ) {
			F2 = d;
		}
    }

	float c = function < 1.0 ? F1 :
			  function < 2.0 ? F2 :
			  function < 3.0 ? F2-F1 :
			  function < 4.0 ? (F1+F2)/2.0 :
			  0.0;

	if( multiply_by_F1 )	c *= F1;
	if( inverse )			c = 1.0 - c;

    return c;
}

]]

noise.voroni_good = glsl_random.rand_2d_to_2d .. [[

vec3 voronoi_noise(vec2 value){
    vec2 baseCell = floor(value);

    //first pass to find the closest cell
    float minDistToCell = 10;
    vec2 toClosestCell;
    vec2 closestCell;

    for(int x1=-1; x1<=1; x1++){
        for(int y1=-1; y1<=1; y1++){
            vec2 cell = baseCell + vec2(x1, y1);
            vec2 cellPosition = cell + rand_2d_to_2d(cell);
            vec2 toCell = cellPosition - value;
            float distToCell = length(toCell);
            if(distToCell < minDistToCell){
                minDistToCell = distToCell;
                closestCell = cell;
                toClosestCell = toCell;
            }
        }
    }

    //second pass to find the distance to the closest edge
    float minEdgeDistance = 10;

    for(int x2=-1; x2<=1; x2++){
        for(int y2=-1; y2<=1; y2++){
            vec2 cell = baseCell + vec2(x2, y2);
            vec2 cellPosition = cell + rand_2d_to_2d(cell);
            vec2 toCell = cellPosition - value;

            vec2 diffToClosestCell = abs(closestCell - cell);
            bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y < 0.1;
            if(!isClosestCell){
                vec2 toCenter = (toClosestCell + toCell) * 0.5;
                vec2 cellDifference = normalize(toCell - toClosestCell);
                float edgeDistance = dot(toCenter, cellDifference);
                minEdgeDistance = min(minEdgeDistance, edgeDistance);
            }
        }
    }

    float random = rand_2d_to_1d(closestCell);
    return vec3(minDistToCell, random, minEdgeDistance);
}

float noise(vec2 x) {
	vec3 d = voronoi_noise(x);
	return d.z;
}

]]

local mesh = gfx.newMesh({
    {0, 0, 0, 0},
    {0, 1, 0, 1},
    {1, 1, 1, 1},
    {1, 0, 1, 0},
})

local render_shader = [[

uniform vec2 shift;
uniform vec2 scale;
uniform vec2 size;
uniform bool invert;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float n = noise(texture_coords * size * scale + shift);
    return vec4(vec3(invert ? 1 - n : n), 1.0) * color;
}
]]

local function ensure_vec2(v)
    return type(v) == "number" and {v, v} or v
end

local function get_size()
	local canvas = gfx.getCanvas()
	if canvas then
		return canvas:getWidth(), canvas:getHeight()
	else
		return gfx.getWidth(), gfx.getHeight()
	end
end

local function noise_render(shader, args)
    args = args or {}
    local shift = args.shift or 0
	local wavelength = args.wavelength or 1
    local scale = 1.0 / wavelength
	local w, h = get_size()

    --gfx.clear()
	if args.color then gfx.setColor(args.color) end 
    shader:send("shift", ensure_vec2(shift))
    shader:send("scale", ensure_vec2(scale))
    shader:send("size", {w, h})
    shader:send("invert", args.invert and true or false)
    gfx.draw(mesh, 0, 0, 0, w, h)

    return noise_canvas
end

local shader = require "shaders.shader"

local function create(noise_str)
    local shader_str = noise_str .. render_shader

	print("__SHADER__")
	print(shader_str)

    return shader(noise_render, shader_str)
end

local noise_shaders = {}

for key, noise_str in pairs(noise) do
	noise_shaders[key] = create(noise_str)
end

return noise_shaders
