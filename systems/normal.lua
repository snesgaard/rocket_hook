
local system = ecs.system.from_function(
    function(entity)
        return {
            pool = entity:has(
                components.position, components.player_control,
                components.velocity
            ),

        }
    end
)

function system:player_action(action, entity, ...)
    if action == "move" then
        local v = entity[components.velocity]
        if systems.ground_monitor.is_on_ground(entity) then
            local velocity = 200
            local dir = ...
            dir.y = dir.y * 0
            self.world:action("move", entity, (dir * velocity):unpack())
            if dir.x < 0 then
                entity:add(components.mirror, true)
                systems.animation.play(entity, "run")
            elseif dir.x > 0 then
                entity:add(components.mirror, false)
                systems.animation.play(entity, "run")
            else
                systems.animation.play(entity, "idle")
            end
        else
            if v.y < 0 then
                systems.animation.play(entity, "ascend")
            else
                systems.animation.play(entity, "descend")
            end
        end

    elseif action == "hook" then
        self.world("throw_hook", entity, ...)
    elseif action == "jump" then
        self.world("do_jump", entity, ...)
    end
end

return system
