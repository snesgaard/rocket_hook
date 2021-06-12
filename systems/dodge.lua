local travel_time = 0.2
local travel_distance = 50

local function player_travel_tween(pos, dir)
    local d = dir.x > 0 and vec2(1, -1) or vec2(-1, -1)
    return components.tween(pos:copy(), pos + d * travel_distance, travel_time)
        --:ease(ease.outQuad)
end

local function dodge_component(pos, dir)
    return ecs.entity()
        :add(player_travel_tween, pos, dir)
end

local dodge_system = ecs.system(
    components.player_control, dodge_component, components.position
)

function dodge_system:do_jump(entity, dir)
    entity
        :add(dodge_component, entity[components.position], dir)
        :remove(components.velocity)
        :remove(components.gravity)
end

function dodge_system:update(dt)
    List.foreach(self.pool, function(entity)
        systems.animation.play(entity, "ascend")
        local travel_tween = entity[dodge_component][player_travel_tween]
        if not travel_tween:is_done() then
            local next_position = travel_tween:update(dt)
            self.world:action("move_to", entity, next_position:unpack())
            return
        end

        local velocity = travel_tween:derivative(travel_tween:get_duration())
        entity
            :remove(dodge_component)
            :add(components.velocity, velocity:unpack())
            :add(components.gravity, 0, 1000)
    end)
end

function dodge_system:player_action(action, entity, ...)
    return self.pool[entity]
end

return dodge_system
