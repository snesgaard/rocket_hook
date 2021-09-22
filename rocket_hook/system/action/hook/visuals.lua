local nw = require "nodeworks"
local hook_folder = (...):match("(.-)[^%.]+$")
local hook_components = require(hook_folder .. "components")

local visuals = {}

function visuals.draw_chain_h(start_pos, end_pos)
    local length = math.abs(start_pos.x - end_pos.x)
    if length == 0 then return end
    local n = (end_pos.x - start_pos.x) / length
    local chain = get_atlas("art/characters"):get_frame("rocket/chain_h")
    local _, _, w, h = chain.quad:getViewport()

    gfx.setColor(1, 1, 1)
    gfx.stencil(function()
        gfx.rectangle("fill", math.min(start_pos.x, end_pos.x), start_pos.y - h, length, h * 2)
    end, "replace", 1)
    gfx.setStencilTest("equal", 1)

    local d = 0
    while d < length do
        local x = start_pos.x + d * n
        chain:draw("body", x, start_pos.y, 0, n, 1)
        d = d + w
    end

    gfx.setStencilTest()
end

function visuals.draw_chain_v(start_pos, end_pos)
    local length = math.abs(start_pos.y - end_pos.y)
    if length == 0 then return end
    local n = (end_pos.y - start_pos.y) / length
    local chain = get_atlas("art/characters"):get_frame("rocket/chain_v")
    local _, _, w, h = chain.quad:getViewport()

    gfx.setColor(1, 1, 1)
    gfx.stencil(function()
        gfx.rectangle("fill", start_pos.x - w, math.max(start_pos.y, end_pos.y), w * 2, -length)
    end, "replace", 1)
    gfx.setStencilTest("equal", 1)

    local d = 0

    while d < length do
        local y = start_pos.y + d * n
        chain:draw("body", start_pos.x, y, 0, 1, -n)
        d = d + h
    end

    gfx.setStencilTest()
end

function visuals.draw_chain_hv(start_pos, end_pos)
    local dv = end_pos - start_pos
    local sx = dv.x > 0 and 1 or -1
    local sy = dv.y > 0 and 1 or -1
    local chain = get_atlas("art/characters"):get_frame("rocket/chain_hv")
    local _, _, w, h = chain.quad:getViewport()

    local x, y = start_pos:unpack()

    gfx.setColor(1, 1, 1)

    gfx.stencil(function()
        gfx.circle("fill", start_pos.x, start_pos.y, dv:length())
    end, "replace", 1)
    gfx.setStencilTest("equal", 1)

    while x * sx + y * sy < end_pos.x * sx + end_pos.y * sy do
        chain:draw("body", x, y, 0, sx, -sy)
        x = x + w * sx
        y = y + h * sy
    end

    gfx.setStencilTest()
end

function visuals.create_smoke_puff(world, x, y)
    return ecs.entity(world)
        :add(components.sprite)
        :add(components.animation_state)
        :add(
            components.animation_map,
            get_atlas("art/characters"),
            {
                smoke_v="smoke/smoke_v",
                smoke_h="smoke/smoke_h",
                smoke_hv="smoke/smoke_hv"
            }
        )
        :add(components.position, x or 0, y or 0)
        :add(hook_components.smoke)
end

return visuals
