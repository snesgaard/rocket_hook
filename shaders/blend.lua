local shader = require "shaders.shader"

local function blend_canvas(mode, canvas)
    gfx.setBlendMode(mode)
    gfx.draw(canvas, 0, 0)

    return color
end

local function layer_canvas(node, layers, clear)
    gfx.clear(clear or {0, 0, 0, 0})

    for _, l in ipairs(layers) do
        local mode, canvas = unpack(l)
        gfx.setBlendMode(mode)
        gfx.draw(canvas, l.x or 0, l.y or 0)
    end

    return color
end

return {
    blend = shader(blend_canvas)
}
