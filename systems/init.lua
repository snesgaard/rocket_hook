systems.hook = require(... .. ".hook")
systems.normal = require(... .. ".normal")
systems.player_input = require(... .. ".player_input")
systems.ground_monitor = require(... .. ".ground_monitor")
systems.dodge = require(... .. ".dodge")
systems.throw = require(... .. ".throw")

local BASE = ...

return function(path) return require(BASE .. "." .. path) end
