local nw = require "nodeworks"

local components = {}

function components.hook(x0, y0, x1, y1)
    return {
        radius=vec2(x0 - x1, y0 - y1):length(),
        center=vec2()
    }
end

function components.linear_motion(...)
    return vec2(...)
end

function components.swing_motion(center, radius, angle)
    return {center=center, radius=radius, angle=angle, angular_velocity}
end

function components.player_control(state)
    return state or "normal"
end

function components.brittle() return true end

local BASE = ...


function components.__index(t, k) return require(BASE .. "." .. k) end

function components.moving_platform() return {} end

function components.move_filter(f) return f end

function components.hook_charges(max_charges)
    max_charges = max_charges or 2

    local l = list()

    for i = 1, max_charges do
        table.insert(l, nw.component.timer.create(3, 0))
    end

    return l
end

return setmetatable(components, components)
