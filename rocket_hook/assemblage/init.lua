local rh = require "rocket_hook"
local nw = require "nodeworks"

local assemblages = {}

assemblages.player_motion = dict{
    [nw.component.velocity] = {},
    [nw.component.gravity] = {0, 2000},
    [nw.component.drag] = {0.5}
}

function assemblages.camera(pos)
    local pos = pos or vec2()
    return dict{
        [nw.component.position] = {pos.x, pos.y},
        [rh.component.camera_slack] = {25, 25},
        [rh.component.scale] = {2, 2},
    }
end

function assemblages.gibbles(x, y, bump_world)
    local ass = dict{
        [components.hitbox] = {-5, -30, 10, 60},
        [components.body] = {},
        [components.bump_world] = {bump_world},
        [components.position] = {x, y - 30},
        [rh.component.player_control] = {},
        [nw.component.sprite] = {},
        [nw.component.mirror] = {},
        [nw.component.animation_state] = {},
        [nw.component.animation_map] = {
            get_atlas("art/characters"),
            {
                idle="gibbles_idle/animation",
                hook_h_fire="gibbles_hook/h_fire",
                hook_h_drag="gibbles_hook/h_drag",
                hook_v_fire="gibbles_hook/v_fire",
                hook_v_drag="gibbles_hook/v_drag",
                hook_hv_fire="gibbles_hook/hv_fire",
                hook_hv_drag="gibbles_hook/hv_drag",
                descend="gibbles_arial/descend",
                ascend="gibbles_arial/ascend",
                run="gibbles_run",
                throw="gibbles_throw/throw"
            }
        },
        [nw.component.action] = {"idle"},
        [rh.component.hook_charges] = {},
        [rh.component.can_jump] = {},
        [rh.component.input_buffer] = {}
    }

    return ass + assemblages.player_motion
end


local BASE = ...

function assemblages.__index(t, k) return require(BASE .. "." .. k) end

return setmetatable(assemblages, assemblages)
