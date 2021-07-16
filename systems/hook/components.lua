local hook_folder = (...):match("(.-)[^%.]+$")
local constants = require(hook_folder .. "constants")

local hook_components = {}

function hook_components.smoke() return true end

function hook_components.direction(dir) return dir:normalize() end

function hook_components.hook_tween()
    return components.tween(0, constants.hook_distance, constants.hook_time)
        :ease(constants.rocket_ease)
end

function hook_components.drag_tween(length)
    return components.tween(0, length, length / constants.player_drag_speed)
        :ease(constants.player_ease)
end

function hook_components.hook_offset(offset)
    return offset
end

function hook_components.initial_position(pos) return vec2(pos:unpack()) end

function hook_components.hook(parent, dir)
    local entity = ecs.entity(parent.world)

    local animation_key = constants.hook_animation_from_direction(dir)
    local offset_slice = systems.animation.get_base_slice(
        parent, "hook", "body", animation_key
    ) or spatial()
    if dir.x < 0 or entity[components.mirror] then offset_slice = offset_slice:hmirror() end

    return entity
        :add(hook_components.direction, dir)
        :add(hook_components.hook_tween)
        :add(hook_components.hook_offset, offset_slice:center())
        :add(components.parent, parent)
        :add(hook_components.initial_position, parent[components.position])
        :add(components.position, entity[hook_components.initial_position] + entity[hook_components.hook_offset])
        :add(components.bump_world, parent[components.bump_world])
        :add(components.hitbox, -5, -5, 10, 10)
end

function hook_components.jet(world, dir, mirror)
    local jet = ecs.entity(world)
        :add(components.sprite, {[components.draw_args] = {0, 0, 0, 1, 1}})
        :add(components.animation_state)
        :add(
            components.animation_map,
            get_atlas("art/characters"),
            {
                jet_v="rocket_jet_ball/jet_v_huge",
                jet_h="rocket_jet_ball/jet_h_huge",
                jet_hv="rocket_jet_ball/jet_hv_huge",
            }
        )
        :add(components.mirror, mirror)

    systems.animation.play(jet, constants.jet_from_direction(dir))

    return jet
end

return hook_components
