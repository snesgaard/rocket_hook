local travel_time = 0.2
local travel_distance = 50

local function player_travel_tween(pos, dir, mirror)
    local d = vec2(1, -1)
    if dir.x < 0 or (dir.x == 0 and mirror) then d = vec2(-1, -1) end


    return components.tween(pos:copy(), pos + d * travel_distance, travel_time)
end

local function dodge_component(pos, dir, mirror)
    return ecs.entity()
        :add(player_travel_tween, pos, dir, mirror)
end

local function entity_filter(entity)
    return {
        pool = entity:has(components.position, components.action)
                and entity[components.action]:type() == "jump"
    }
end

local dodge_system = ecs.system.from_function(entity_filter)

local function slip_through_filter(item, other)
    if other[components.oneway] then return "cross" end

    return systems.collision.default_move_filter(item, other)
end

function dodge_system.dodge(entity, dir)
    if dir.y <= 0 then
        entity:update(components.action, "jump", dir)
    else
        systems.collision.move(entity, 0, 1, slip_through_filter)
    end
end

function dodge_system:on_entity_added(entity)
    local dir = entity[components.action]:args()
    local mirror = entity[components.mirror]

    entity
        :add(dodge_component, entity[components.position], dir, mirror)
        :remove(components.velocity)

    if dir.x ~= 0 then
        entity:add(components.mirror, dir.x < 0)
    end

    systems.animation.play(entity, "ascend")
end

function dodge_system:on_entity_removed(entity)
    entity
        :remove(dodge_component)
        :ensure(components.velocity)
end

function dodge_system:update(dt)
    List.foreach(self.pool, function(entity)
        local travel_tween = entity[dodge_component][player_travel_tween]
        if not travel_tween:is_done() then
            local prev_position = travel_tween:update(0)
            local next_position = travel_tween:update(dt)
            local relative = next_position - prev_position
            systems.collision.move(entity, relative:unpack())
            return
        end

        local velocity = travel_tween:derivative(travel_tween:get_duration())
        entity
            :add(components.velocity, velocity:unpack())
            :add(components.action, "idle")

    end)
end

function dodge_system:player_action(action, entity, ...)
    return self.pool[entity]
end

return dodge_system
