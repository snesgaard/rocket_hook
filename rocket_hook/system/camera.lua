local rh = require "rocket_hook"
local nw = require "nodeworks"

local components = rh.assemblage.camera():keys()
local system = nw.ecs.system(components:unpack())

function system.track(camera_entity, tracked_entity, bound)
    local slack = camera_entity[rh.component.camera_slack]
    local pos = camera_entity[nw.component.position]
    local scale = camera_entity[rh.component.scale]
    local parent_pos = tracked_entity[nw.component.position]

    local diff = parent_pos - pos

    local adjust = diff
    if adjust.x > 0 then
        adjust.x = math.max(adjust.x - slack.x, 0)
    else
        adjust.x = math.min(adjust.x + slack.x, 0)
    end

    if adjust.y > 0 then
        adjust.y = math.max(adjust.y - slack.y, 0)
    else
        adjust.y = math.min(adjust.y + slack.y, 0)
    end

    local next_pos = pos + adjust

    if bound then
        local half_screen = 0.5 * vec2(
            gfx.getWidth() / scale.x, gfx.getHeight() / scale.y
        )

        next_pos.x = math.clamp(
            next_pos.x,
            bound.x + half_screen.x,
            bound.x + bound.w - half_screen.x
        )

        next_pos.y = math.clamp(
            next_pos.y,
            bound.y + half_screen.y,
            bound.y + bound.h - half_screen.y
        )
    end

    camera_entity:update(nw.component.position, next_pos:unpack())

    return system
end

function system.transform(camera_entity)
    local screen = vec2(gfx.getWidth(), gfx.getHeight())
    local pos = camera_entity[nw.component.position]
    local scale = camera_entity[rh.component.scale]
    gfx.translate(screen.x * 0.5, screen.y * 0.5)
    gfx.scale(scale.x, scale.y)
    gfx.translate(-pos.x, -pos.y)
    return system
end

function system.translation_scale(camera_entity)
    local screen = vec2(gfx.getWidth(), gfx.getHeight())
    local pos = camera_entity[nw.component.position]
    local scale = camera_entity[rh.component.scale]
    local offset = (screen * 0.5 / scale - pos)
    return offset.x, offset.y, scale.x, scale.y
end

return system
