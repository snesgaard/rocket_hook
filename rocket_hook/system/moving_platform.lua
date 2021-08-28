local rh = require "rocket_hook"
local nw = require "nodeworks"

local system = ecs.system(rh.component.moving_platform, nw.component.position)

function system:on_moved(entity, dx, dy)
    if not self.pool[entity] then return end

    for other, _ in pairs(entity[rh.component.moving_platform]) do
        nw.system.collision.move(other, dx, dy)
    end
end

function system:on_contact_begin(item, other, colinfo)
    if not self.pool[item] or self.pool[other] then return end
    local cos0 = -colinfo.normal.y
    if cos0 < 0.9 then return end

    item[rh.component.moving_platform][other] = true
end

function system:on_contact_end(item, other)
    if not self.pool[item] then return end

    item[rh.component.moving_platform][other] = nil
end

return system
