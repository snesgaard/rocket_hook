local rh = require "rocket_hook"
local nw = require "nodeworks"

local system = ecs.system(rh.component.moving_platform, nw.component.position)

function system.move_filter(item, other)
    if item[rh.component.moving_platform] then
        local col = item[rh.component.moving_platform]
        if col[other] then return "cross" end
    end
end

function system:on_entity_added(entity)
    entity[rh.component.move_filter] = system.move_filter
end

function system:on_entity_removed(entity)

end

function system:on_moved(entity, dx, dy)
    if not self.pool[entity] then return end

    for other, _ in pairs(entity[rh.component.moving_platform]) do
        if other[nw.component.velocity] then
            nw.system.collision.move(other, dx, dy)
        end
    end
end

local function get_above_entity(item, item_rect, other, other_rect)
    if item_rect.y + item_rect.h <= other_rect.y then return item, other end
    if other_rect.y + other_rect.h <= item_rect.y then return other, item end
end


function system:on_contact_begin(item, other, colinfo)
    -- First if neither of the colliders are a part of this system, exit
    if not self.pool[item] and not self.pool[other] then return end
    -- First test if collision is solid, if not exit
    if colinfo.type == "cross" then return end
    -- Second test if it happened on the y-axis
    if math.abs(colinfo.normal.y) < 0.9 then return end
    -- Now check which entity is above the other
    local above, below = get_above_entity(
        item, colinfo.itemRect, other, colinfo.otherRect
    )
    -- Only the below entity can tether, if not part of the pool, exit
    if not self.pool[below] then return end

    below[rh.component.moving_platform][above] = true
end

function system:on_contact_end(item, other)
    -- Break thether, if any
    if self.pool[item] then item[rh.component.moving_platform][other] = nil end
    if self.pool[other] then other[rh.component.moving_platform][item] = nil end
end

return system
