local shader = require "shaders.shader"

local border = {
    shader_str = [[

    uniform Image noise;
    uniform vec2 noise_ratio;
    uniform float max_distance;
    uniform float min_distance;
    uniform float min_prob;

    vec4 effect(vec4 color, Image distance, vec2 texture_coords, vec2 screen_coords)
    {
        float d = Texel(distance, texture_coords).x;
        if (d > 0) discard;
        float n = Texel(noise, texture_coords * noise_ratio).x;
        //float s = smoothstep(-max_distance, -min_distance, d);
        float edge0 = -max_distance;
        float edge1 = -min_distance;
        float s = clamp((d - edge0) / (edge1 - edge0), 0, 1);
        float t = mix(1, 0, max(min_prob, s));
        float i = step(t, n);
        return vec4(i) * color;
    }

    ]],

    func = function(
            shader, distance_canvas, noise_canvas, min_distance, max_distance,
            color, min_prob
    )
        --gfx.clear()
        gfx.setColor(color or {1, 1, 1, 1})

        shader:send("min_distance", min_distance)
        shader:send("max_distance", max_distance)
        shader:send("noise", noise_canvas)
        shader:send(
            "noise_ratio",
            {
                distance_canvas:getWidth() / noise_canvas:getWidth(),
                distance_canvas:getHeight() / noise_canvas:getHeight(),
            }
        )
        shader:send("min_prob", min_prob or 0)
        gfx.draw(distance_canvas)
    end
}

local speckle = {
    shader_str = [[
    uniform float edge;
    uniform Image noise;
    uniform vec2 noise_ratio;

    vec4 effect(vec4 color, Image distance, vec2 texture_coords, vec2 screen_coords)
    {
        float n = Texel(noise, texture_coords * noise_ratio).r;
        float d = Texel(distance, texture_coords).r;
        if (d > 0) discard;
        float s = step(-edge, -n);
        float a = smoothstep(-40, -5, d);
        a = max(a, 0.2);
        return vec4(1, 1, 1, s) * color;
    }
    ]],

    func = function(shader, distance, noise, edge)
        shader:send("edge", edge)
        shader:send("noise", noise)
        shader:send(
            "noise_ratio",
            {
                distance:getWidth() / noise:getWidth(),
                distance:getHeight() / noise:getHeight()
            }
        )

        gfx.draw(distance, 0, 0)
    end
}

local bottom = {
    shader_str = [[
    uniform float edge;
    uniform Image distance;

    vec4 effect(vec4 color, Image noise, vec2 texture_coords, vec2 screen_coords)
    {
        float n = Texel(noise, texture_coords).r;
        float d = Texel(distance, texture_coords).r;
        if (d > 0) discard;
        float s = step(edge, n);
        return vec4(1, 1, 1, s) * color;
    }
    ]],

    func = function(shader, distance, noise, edge)
        shader:send("edge", edge)
        shader:send("distance", distance)
        gfx.draw(noise, 0, 0)
    end
}

return {
    border = shader(border.func, border.shader_str),
    speckle = shader(speckle.func, speckle.shader_str),
    bottom = shader(bottom.func, bottom.shader_str)
}
