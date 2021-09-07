local nw = require "nodeworks"
local noise = require "shaders.noise"

local rectangle_distance = {
    shader = [[

    uniform vec2 pos;
    uniform vec2 size;

    // Taken from https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
    float sdBox( in vec2 p, in vec2 b ) {
        vec2 d = abs(p)-b;
        return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
    }

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        vec2 b = size * 0.5;
        vec2 center = pos + b;
        float d = sdBox(screen_coords - center, b);
        return vec4(vec3(d), 1.0);
    }

    ]],

    func = function(node, x, y, w, h)
        local canvas_args = {format="r32f"}
        local cw, ch = gfx.getWidth(), gfx.getHeight()
        local canvas = node:canvas(cw, ch, canvas_args)
        gfx.clear(0, 0, 0, 1)
        node:shader():send("pos", {x, y})
        node:shader():send("size", {w, h})
        gfx.rectangle("fill", 0, 0, cw, ch)
        return canvas
    end
}

local ice_layer = {
    shader = [[

    uniform Image noise;
    uniform float max_distance;
    uniform float min_distance;
    uniform float min_prob;

    vec4 effect(vec4 color, Image distance, vec2 texture_coords, vec2 screen_coords)
    {
        float d = Texel(distance, texture_coords).x;
        if (d > 0) discard;
        float n = Texel(noise, texture_coords).x;
        //float s = smoothstep(-max_distance, -min_distance, d);
        float edge0 = -max_distance;
        float edge1 = -min_distance;
        float s = clamp((d - edge0) / (edge1 - edge0), 0, 1);
        float t = mix(1, 0, max(min_prob, s));
        float i = step(t, n);
        return vec4(i) * color;
    }

    ]],

    func = function(node, distance, noise, min_distance, max_distance, color, min_prob)
        local cw, ch = gfx.getWidth(), gfx.getHeight()
        local canvas = node:canvas(cw, ch)
        gfx.clear()
        gfx.setColor(color or {1, 1, 1, 1})

        node:shader():send("min_distance", min_distance)
        node:shader():send("max_distance", max_distance)
        if node:shader():hasUniform("noise") then
            node:shader():send("noise", noise)
        end
        if node:shader():hasUniform("min_prob") then
            node:shader():send("min_prob", min_prob or 0)
        end
        gfx.draw(distance)
        return canvas
    end
}


local ramp_noise_shader = [[

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float n = Texel(tex, texture_coords).x;
    float x = step(0.5, n);
    return vec4(vec3(x), 1.0) * color;
}

]]

local function ramp_noise(node, noise_canvas)
    local color = node:canvas(noise_canvas:getWidth(), noise_canvas:getHeight())
    gfx.clear()
    gfx.draw(noise_canvas, 0, 0)
    return color
end

local function blend_canvas(node, args, buffers)
    local w = List.reduce(
        buffers,
        function(v, c) return math.max(v, c:getWidth()) end,
        0
    )
    local h = List.reduce(
        buffers,
        function(v, c) return math.max(v, c:getHeight()) end,
        0
    )

    local color = node:canvas(w, h)

    gfx.clear(args.clear)
    gfx.setBlendMode(args.mode)

    for _, b in ipairs(buffers) do
        gfx.draw(b, 0, 0)
    end

    return color
end

local function layer_canvas(node, args, layers)
    local w = List.reduce(
        layers,
        function(v, c) return math.max(v, c[2]:getWidth()) end,
        0
    )
    local h = List.reduce(
        layers,
        function(v, c) return math.max(v, c[2]:getHeight()) end,
        0
    )

    local color = node:canvas(w, h, args.canvas_args)
    gfx.clear(args.clear or {0, 0, 0, 0})

    for _, l in ipairs(layers) do
        local mode, canvas = unpack(l)
        gfx.setBlendMode(mode or "alpha")
        gfx.draw(canvas, layers.x or 0, layers.y or 0)
    end

    return color
end

local scene = {}

function scene:load()
    nodes = {
        generic_noise = noise("generic_1"),
        simplex_noise = noise("simplex"),
        voroni_noise = noise("voroni"),
        perlin_noise = noise("perlin"),
        ramp_noise = draw_node(ramp_noise, ramp_noise_shader),
        blend = draw_node(blend_canvas),
        layer = draw_node(layer_canvas),
        rectangle_distance = draw_node(
            rectangle_distance.func, rectangle_distance.shader
        ),
        top_ice_layer = draw_node(ice_layer.func, ice_layer.shader),
        mid_ice_layer = draw_node(ice_layer.func, ice_layer.shader),
        bottom_ice_layer = draw_node(ice_layer.func, ice_layer.shader),
    }


    time = 0
end

function scene.update(dt)
    time = time + dt
end

function scene:draw()
    local noise_args = dict{scale=0.1}

    local layers = {
        {"add", nodes.generic_noise(noise_args:set("shift", time))},
        {"add", nodes.voroni_noise(noise_args:set("shift", -time))},
        {"add", nodes.perlin_noise(noise_args:set("shift", {time, -time}))}
    }

    local color = nodes.layer({clear={0, 0, 0, 1}}, layers)

    local noise = nodes.simplex_noise(noise_args)

    local distance = nodes.rectangle_distance(100, 100, 200, 32)
    local ice = {
        nodes.bottom_ice_layer(distance, noise, 10, 60, gfx.hex2color("55587b"), 1),
        nodes.mid_ice_layer(distance, noise, 10, 26, gfx.hex2color("5facd8"), 0.0),
        nodes.top_ice_layer(distance, noise, 0, 16, gfx.hex2color("98f0fc")),
    }
    local color = nodes.blend({clear={0, 0, 0, 0}, mode="alpha"}, ice)

    gfx.draw(color, 0, 0)
end

return scene
