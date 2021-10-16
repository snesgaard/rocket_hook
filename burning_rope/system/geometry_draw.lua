local nw = require "nodeworks"
local br = require "burning_rope"
local rh = require "rocket_hook"

local box_drawer_system = nw.ecs.system.from_function(function(entity)
    local is_box = entity:has(nw.component.position, nw.component.hitbox)
    is_box = is_box and not entity:has(rh.component.player_control)
    local is_burning = entity:has(br.component.burning)
    local is_flammable = entity:has(br.component.flammable)
    local is_charcoal = entity:has(br.component.charcoal)
    return {
        pool = is_box and not (is_burning or is_flammable or is_charcoal),
        burning = is_box and is_burning,
        flammable = is_box and is_flammable,
        charcoal = is_box and is_charcoal
    }
end)

function box_drawer_system:draw()
    local function draw_box(mode, entity)
        local hitbox = entity[nw.component.hitbox]
        local x, y = entity[nw.component.position]:unpack()
        local x, y, w, h = hitbox:move(x, y):unpack()
        gfx.rectangle(mode, x, y, w, h)
    end

    gfx.setColor(1, 1, 1)
    for _, entity in ipairs(self.pool) do
        draw_box("fill", entity)
    end

    for _, entity in ipairs(self.burning) do
        gfx.setColor(1, 0.2, 0.1)
        draw_box("fill", entity)
        gfx.setColor(0, 0, 0, 0.5)
        draw_box("line", entity)
    end

    for _, entity in ipairs(self.flammable) do
        gfx.setColor(0.5, 0.2, 0.3)
        draw_box("fill", entity)
        gfx.setColor(0, 0, 0, 0.5)
        draw_box("line", entity)
    end

    for _, entity in ipairs(self.flammable) do
        gfx.setColor(0.5, 0.2, 0.3)
        draw_box("fill", entity)
        gfx.setColor(0, 0, 0, 0.5)
        draw_box("line", entity)
    end

    for _, entity in ipairs(self.charcoal) do
        gfx.setColor(0.5, 0.5, 0.5)
        draw_box("fill", entity)
        gfx.setColor(0, 0, 0, 0.5)
        draw_box("line", entity)
    end
end

return box_drawer_system
