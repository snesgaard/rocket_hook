local nw = require "nodeworks"
local noise = require "shaders.noise"
local sdf = require "shaders.sdf"
local ice = require "shaders.ice"
local blend = require "shaders.blend"

local palette_purple = {
    ice = {
        final = color("453c50"),
        bottom = color("55587b"),
        mid = color("5facd8"),
        top = color("98f0fc")
    }
}

local palette_blue = {
    ice = {
        final = color("453c50"),
        bottom = color("3c87cb"),
        mid = color("52a6d2"),
        top = color("c0cfd6")
    }
}

local palette = palette_blue

local ice_borders = {
    --{min_distance=5, max_distance=20, palette=palette.ice.final, x=0, y=3},
    {min_distance=5, max_distance=20, color=palette.ice.mid},
    {min_distance=0, max_distance=8, color=palette.ice.top},
}

local function create_canvas(w, h)
    w = w or gfx.getWidth()
    h = h or gfx.getHeight()

    return {
        noise = {
            crack = gfx.newCanvas(w, h, {format="r32f"}),
            border = gfx.newCanvas(w, h, {format="r32f"})
        },
        single_distance = gfx.newCanvas(w, h, {format="r32f"}),
        ice_layer = {
            single = gfx.newCanvas(w, h),
            blended = gfx.newCanvas(w, h)
        }
    }
end

local canvas = create_canvas()

local scene = {}

local ice_shapes = {
    spatial(10, 10, 32, 32),
    spatial(50, 10, 200, 32),
    spatial(10, 50, 32, 200),
    spatial(50, 50, 200, 200),
    spatial(300, 150, 200, 32),
    spatial(350, 50, 32, 200),
}

function scene.load()
    noise.voroni_good:render_to(canvas.noise.crack, {wavelength=15})
    noise.simplex:render_to(
        canvas.noise.crack, {wavelength=15, color={1, 1, 1, 0.08}}
    )
    noise.simplex:render_to(canvas.noise.border, {wavelength=10})
    canvas.single_distance:renderTo(function()
        gfx.clear(10000, 10000, 10000, 1)
        gfx.push("all")
        gfx.setBlendMode("darken", "premultiplied")
        for _, is in ipairs(ice_shapes) do
            sdf.rectangle(is:unpack())
        end
        gfx.pop("all")
    end)
    --:render_to(canvas.single_distance, ice_shape:unpack())
end

function scene.keypressed(key, scancode, isrepeat)
    if key == "t" then draw_top = not draw_top end
    if key == "m" then draw_mid = not draw_mid end
    if key == "b" then draw_bottom = not draw_bottom end
end

function scene.draw()
    gfx.scale(2, 2)
    gfx.setColor(palette.ice.bottom)
    for _, is in ipairs(ice_shapes) do
        gfx.rectangle("fill", is:unpack())
    end

    gfx.stencil(
        function()
            sdf.interior(canvas.single_distance)
        end
    )
    gfx.setStencilTest("equal", 1)


    if draw_bottom then
        gfx.push()
        gfx.translate(0, 1)
        gfx.setColor(palette.ice.final:alpha(0.3))
        ice.speckle(canvas.single_distance, canvas.noise.crack, 0.05)
        gfx.pop()
    end

    if draw_mid then
        gfx.setColor(palette.ice.mid:alpha(0.7))
        ice.speckle(canvas.single_distance, canvas.noise.crack, 0.07)
    end

    if draw_top then
        gfx.setColor(palette.ice.top:alpha(0.7))
        ice.speckle(canvas.single_distance, canvas.noise.crack, 0.023)
    end

    for _, ib in ipairs(ice_borders) do
        gfx.push()
        gfx.translate(ib.x or 0, ib.y or 0)
        ice.border(
            canvas.single_distance, canvas.noise.border,
            ib.min_distance, ib.max_distance, ib.color
        )
        gfx.pop()
    end


    --gfx.draw(canvas.noise.crack)

    gfx.setStencilTest()
end


return scene
