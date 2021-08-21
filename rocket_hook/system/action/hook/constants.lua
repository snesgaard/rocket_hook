local constants = {
    hook_distance = 150,
    player_time = 0.5,
    hook_time = 0.25,
    rocket_ease = ease.outQuad,
    player_ease = ease.inQuad
}

constants.player_drag_speed = constants.hook_distance / constants.player_time

function constants.hook_animation_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "hook_hv_fire"
    elseif dir.y ~= 0 then
        return "hook_v_fire"
    else
        return "hook_h_fire"
    end
end

function constants.drag_animation_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "hook_hv_drag"
    elseif dir.y ~= 0 then
        return "hook_v_drag"
    else
        return "hook_h_drag"
    end
end

function constants.rocket_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "rocket/rocket_hv"
    elseif dir.y ~= 0 then
        return "rocket/rocket_v"
    else
        return "rocket/rocket_h"
    end
end

function constants.chain_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "rocket/chain_hv"
    elseif dir.y ~= 0 then
        return "rocket/chain_v"
    else
        return "rocket/chain_h"
    end
end

function constants.smoke_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "smoke_hv"
    elseif dir.y ~= 0 then
        return "smoke_v"
    else
        return "smoke_h"
    end
end

function constants.jet_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "jet_hv"
    elseif dir.y ~= 0 then
        return "jet_v"
    else
        return "jet_h"
    end
end

return constants
