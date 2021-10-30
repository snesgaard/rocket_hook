local nw = require "nodeworks"

local hook_folder = (...):match("(.-)[^%.]+$")
local constants = require(hook_folder .. "constants")

local hook_component = {}

function hook_component.smoke() return true end

function hook_component.direction(dir) return dir:normalize() end

function hook_component.hook_tween()
    return nw.component.tween(0, constants.hook_distance, constants.hook_time)
        :ease(constants.rocket_ease)
end

function hook_component.drag_tween(length)
    return nw.component.tween(0, length, length / constants.player_drag_speed)
        :ease(constants.player_ease)
end

function hook_component.hook_offset(offset)
    return offset
end

function hook_component.initial_position(pos) return vec2(pos:unpack()) end

function hook_component.hook(parent, dir, world)
    local entity = nw.ecs.entity(world)

    local animation_key = constants.hook_animation_from_direction(dir)
    local offset_slice = nw.system.animation.get_base_slice(
        parent, "hook", "body", animation_key
    ) or spatial()

    return entity
        :add(hook_component.direction, dir)
        :add(hook_component.hook_tween)
        :add(hook_component.hook_offset, offset_slice:center())
        :add(nw.component.parent, parent)
        :add(hook_component.initial_position, parent[nw.component.position])
        :add(nw.component.position, entity[hook_component.initial_position] + entity[hook_component.hook_offset])
        :add(nw.component.bump_world, parent[nw.component.bump_world])
        :add(nw.component.hitbox, -5, -5, 10, 10)
end

function hook_component.jet(world, dir, mirror)
    local jet = nw.ecs.entity(world)
        :add(
            nw.component.sprite,
            {
                [nw.component.draw_args] = {0, 0, 0, 1, 1},
            }
        )
        :add(nw.component.animation_state)
        :add(
            nw.component.animation_map,
            get_atlas("art/characters"),
            {
                jet_v="rocket_jet_ball/jet_v_huge",
                jet_h="rocket_jet_ball/jet_h_huge",
                jet_hv="rocket_jet_ball/jet_hv_huge",
            }
        )
        :add(nw.component.mirror, mirror)
        :add(nw.component.hidden)

    nw.system.animation.play(jet, constants.jet_from_direction(dir))

    return jet
end

return hook_component
