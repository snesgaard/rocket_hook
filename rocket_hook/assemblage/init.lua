local rh = require "rocket_hook"
local nw = require "nodeworks"

local assemblages = {}

assemblages.player_motion = dict{
    [nw.component.velocity] = {},
    [nw.component.gravity] = {0, 2000},
    [nw.component.drag] = {0.5}
}

function assemblages.gibbles(x, y, bump_world)
    local ass = dict{
        [components.hitbox] = {-5, -30, 10, 60},
        [components.body] = {},
        [components.bump_world] = {bump_world},
        [components.position] = {x, y},
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
        [rh.component.hook_charges] = {}
    }

    return ass + assemblages.player_motion
end

return assemblages
