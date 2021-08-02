local rh = require "rocket_hook"

local system = ecs.system(rh.component.player_control, components.action)


local function get_input_direction()
    local dir_from_input = {
        up = vec2(0, -1),
        down = vec2(0, 1),
        left = vec2(-1, 0),
        right = vec2(1, 0)
    }

    local dir = vec2()

    for input, d in pairs(dir_from_input) do
        if rh.system.input_remap.is_down(input) then
            dir = dir + d
        end
    end

    return dir
end


local input_pressed_handlers = {}


function input_pressed_handlers.idle(entity, input)
    if input == "hook" then
        --entity:update(components.action, "hook", get_input_direction())
        rh.system.action.hook.hook(entity, get_input_direction())
    elseif input == "jump" then
        rh.system.action.dodge.dodge(entity, get_input_direction())
    elseif input == "throw" then
        rh.system.action.throw.throw(entity, get_input_direction())
    end
end


function system:input_pressed(input)
    for _, entity in ipairs(self.pool) do
        local action = entity[components.action]:type()
        local f = input_pressed_handlers[action]
        if f then f(entity, input) end
    end
end


function system:input_released(key)
end


function system:update(dt)
    List.foreach(self.pool, function(entity)
        if entity[components.action]:type() ~= "idle" then return end

        local v = entity:ensure(components.velocity)


        if rh.system.collision_response.is_on_ground(entity) then
            local dir = get_input_direction()
            local speed = 200 * dir.x
            entity:update(components.velocity, speed, v.y)

            if dir.x < 0 then
                entity:update(components.mirror, true)
            elseif dir.x > 0 then
                entity:update(components.mirror, false)
            end

            if speed == 0 then
                systems.animation.play(entity, "idle")
            else
                systems.animation.play(entity, "run")
            end
        else
            if v.y < 0 then
                systems.animation.play(entity, "ascend")
            else
                systems.animation.play(entity, "descend")
            end
        end
    end)
end


return system
