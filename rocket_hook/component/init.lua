local nw = require "nodeworks"

local component = {}

function component.draw(draw) return draw or nw.ecs.pool() end

function component.discard(discard) return discard or nw.ecs.pool() end

function component.hand(hand) return hand or nw.ecs.pool() end

function component.shield(value) return value or 0 end

function component.charge(value) return value or 0 end

function component.strength(value) return value or 0 end

function component.defense(value) return value or 0 end

function component.health(value) return value or 0 end

function component.max_health(value) return value or 0 end

local BASE = ...

function component.__index(t, k)
    return require(BASE .. "." .. k)
end

return setmetatable(component, component)
