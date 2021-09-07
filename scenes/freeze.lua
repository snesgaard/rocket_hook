local nw = require "nodeworks"
local noise = require "shaders.noise"

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

local function blend_canvas(node, args, ...)
    local buffers = {...}
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
        voroni_noise = noise("voroni"),
        perlin_noise = noise("perlin"),
        ramp_noise = draw_node(ramp_noise, ramp_noise_shader),
        blend = draw_node(blend_canvas),
        layer = draw_node(layer_canvas)
    }


    time = 0
end

function scene.update(dt)
    time = time + dt
end

function scene:draw()
    local noise_args = dict{width=1000, height=500, shift=time, scale=0.05}

    local layers = {
        {"add", nodes.generic_noise(noise_args:set("shift", time))},
        {"add", nodes.voroni_noise(noise_args:set("shift", -time))},
        {"alpha", nodes.perlin_noise(noise_args:set("shift", {time, -time}))}
    }

    local color = nodes.layer({clear={0, 0, 0, 1}}, layers)

    --local color = ramp_node(noise)
    gfx.draw(color, 0, 0)
end

return scene
