local nw = require "nodeworks"
local rh = require "rocket_hook"

local wrap = {}

function wrap.clamp(time, t1, t2)
    return math.clamp(time, t1, t2)
end

function wrap.periodic(time, t1, t2)
    if t2 <= t1 then errorf("t2 must be larger (t1=%f, t2=%f)", t1, t2) end

    -- Sawtooth wave equation
    local t = time - t1
    local p = t2 - t1
    local t_div_p = t / p
    local s = t_div_p - math.floor(t_div_p)
    return t1  + s * p
end

function wrap.bounce(time, t1, t2)
    if t2 <= t1 then errorf("t2 must be larger (t1=%f, t2=%f)", t1, t2) end

    -- Triangle wave equation
    local t = time - t1
    local d = (t2 - t1)
    local p = d
    -- Triangle wave value in range of [0, 1]
    local s = 2 * math.abs((t / p - math.floor(t / p + 0.5)))
    return t1 + s * d
end

local function piecewise(x, condition, func)
    local size = math.min(#condition, #func)

    for s = 1, size do
        if condition[s] then
            local f = func[s]
            return f(x)
        end
    end

    return
end

local function lerp(x, x1, y1, x2, y2, ease_func)
    ease_func = ease_func or nw.ease.linear
    local t = x - x1
    local b = y1
    local c = y2 - y1
    local d = x2 - x1
    return ease_func(t, b, c, d)
end

local component = {}

function component.patrol(path, cycle_time)
    local points = List.map(path, function(p) return vec2(p.x, p.y) end)
    local lines = List.zip(points:sub(1, #points - 1), points:sub(2, #points))
    local lengths = lines:map(function(l)
        local p1, p2 = unpack(l)
        return (p1 - p2):length()
    end)
    local total_length = lengths:reduce(function(a, b) return a + b end, 0)

    local t = 0
    local line_times = list()
    for _, l in ipairs(lengths) do
        local t1 = t
        local t2 = t + cycle_time * l / total_length
        table.insert(line_times, {t1, t2})
        t = t2
    end

    return {
        segments = lines:zip(line_times):map(function(l)
            local line, time = unpack(l)
            local p1, p2 = unpack(line)
            local t1, t2 = unpack(time)
            return {type="line", p1=p1, p2=p2, t1=t1, t2=t2}
        end),
        cycle_time = cycle_time
    }
end

function component.patrol_state(time)
    return {time = time or 0}
end

local system = nw.ecs.system(
    component.patrol, component.patrol_state, nw.component.position
)


local function entity_update(entity, dt)
    local state = entity[component.patrol_state]
    local path = entity[component.patrol]

    local next_time = state.time + dt
    local wrapped_time = wrap.bounce(next_time, 0, path.cycle_time)
    state.time = next_time

    local conditions = path.segments:map(function(s)
        return s.t1 <= wrapped_time and wrapped_time < s.t2
    end)
    local func = path.segments:map(function(s)
        return function(t)
            return lerp(t, s.t1, s.p1, s.t2, s.p2)
        end
    end)

    local p = piecewise(wrapped_time, conditions, func)
    nw.system.collision.move_to(entity, p.x, p.y)
end

function system:update(dt)
    List.foreach(self.pool, entity_update, dt)
end

function system.assemblage(path, cycle_time)
    return {
        [component.patrol_state] = {},
        [component.patrol] = {path, cycle_time}
    }
end

return system
