local node = require "nodeworks"

local components = {}

local BASE = ...

function components.__index(t, k)
    return require(BASE .. "." .. k)
end

function components.burning(duration, cooldown)
    return {
        lifetime = node.component.timer.create(duration or 3),
        cooldown = node.component.timer.create(0.1)
    }
end

function components.flammable(burn_duration)
    return {
        burn_duration = burn_duration or 3
    }
end

function components.charcoal()
    return true
end

function components.brittle()
    return true
end

function components.fixture(fixture)
    if type(fixture) ~= "table" then
        error("Fixture must be a tabular type")
    end
    return fixture
end

function components.fixture_points(...)
    return ...
end

function components.rope() return true end

return setmetatable(components, components)
