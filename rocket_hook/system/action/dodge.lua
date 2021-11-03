local nw = require "nodeworks"

local travel_time = 0.2
local travel_distance = 50

local function player_travel_tween(pos, dir, mirror)
    --local d = vec2(1, -1)
    --if dir.x < 0 or (dir.x == 0 and mirror) then d = vec2(-1, -1) end
    local d = vec2(dir.x, -1)


    return nw.component.tween(pos:copy(), pos + d * travel_distance, travel_time)
end

local function dodge_component(pos, dir, mirror)
    return nw.ecs.entity()
        :add(player_travel_tween, pos, dir, mirror)
end

local function entity_filter(entity)
    return {
        pool = entity:has(nw.component.position, nw.component.action)
                and entity[nw.component.action]:type() == "jump"
    }
end

local dodge_system = nw.ecs.system.from_function(entity_filter)

dodge_system.TRAVEL_TIME = travel_time
dodge_system.TRAVEL_DISTANCE = travel_distance

local function slip_through_filter(item, other)
    if other[nw.component.oneway] then return "cross" end

    return nw.system.collision.default_move_filter(item, other)
end

function dodge_system.dodge(entity, dir)
    if dir.y <= 0 then
        entity:update(nw.component.action, "jump", dir)
    else
        nw.system.collision.move(entity, 0, 1, slip_through_filter)
    end
end

function dodge_system:on_entity_added(entity)
    local dir = entity[nw.component.action]:args()
    local mirror = entity[nw.component.mirror]

    entity
        :add(dodge_component, entity[nw.component.position], dir, mirror)
        :remove(nw.component.velocity)

    if dir.x ~= 0 then
        entity:add(nw.component.mirror, dir.x < 0)
    end

    nw.system.animation.play(entity, "ascend")
end

function dodge_system:on_entity_removed(entity)
    entity
        :remove(dodge_component)
        :ensure(nw.component.velocity)
end

function dodge_system:update(dt)
    List.foreach(self.pool, function(entity)
        local travel_tween = entity[dodge_component][player_travel_tween]
        if not travel_tween:is_done() then
            local prev_position = travel_tween:update(0)
            local next_position = travel_tween:update(dt)
            local relative = next_position - prev_position
            nw.system.collision.move(entity, relative:unpack())
            return
        end

        local velocity = travel_tween:derivative(travel_tween:get_duration())
        entity
            :add(nw.component.velocity, velocity:unpack())
            :add(nw.component.action, "idle")

    end)
end

function dodge_system:player_action(action, entity, ...)
    return self.pool[entity]
end

return dodge_system
