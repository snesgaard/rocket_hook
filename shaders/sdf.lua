local shader = require "shaders.shader"

local circle = {
    shader_str = [[
    uniform vec2 center;
    uniform float radius;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        vec2 d = screen_coords - center;
        float c = length(d) - radius;
        return vec4(vec3(c), 1.0);
    }

    ]],

    func = function(shader, x, y, r)
        shader:send("center", {x, y})
        shader:send("radius", r)
        gfx.rectangle("fill", 0, 0, shader:get_size())
    end
}

local rectangle = {
    shader_str = [[

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

    func = function(shader, x, y, w, h)
        --gfx.clear(0, 0, 0, 1)
        shader:send("pos", {x, y})
        shader:send("size", {w, h})
        local cw, ch = shader:get_size()
        gfx.rectangle("fill", 0, 0, cw, ch)
        return canvas
    end
}

local interior = {
    shader_str = [[

    vec4 effect(vec4 color, Image distance, vec2 texture_coords, vec2 screen_coords)
    {
        float d = Texel(distance, texture_coords).r;
        if (d > 0) discard;
        return color;
    }

    ]],

    func = function(shader, distance)
        gfx.draw(distance, 0 ,0)
    end
}

return {
    rectangle = shader(rectangle.func, rectangle.shader_str),
    interior = shader(interior.func, interior.shader_str),
    circle = shader(circle.func, circle.shader_str)
}
