local systems = {}

local BASE = ...
function systems.__index(t, k) return require(BASE .. "." .. k) end

return setmetatable(systems, systems)
