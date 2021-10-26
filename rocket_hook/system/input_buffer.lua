local nw = require "nodeworks"
local rh = require "rocket_hook"

local function create_input_event(input, event)
    return {input=input, event=event, age=0}
end

local function input_history(prev_history)
    local history = {}

    if not prev_history then return history end

    for key, value in pairs(prev_history) do history[key] = value end

    return history
end

local system = nw.ecs.system(rh.component.input_buffer)

system.MAX_BUFFER_SIZE = 30

-- Private utilities
local function add_to_history(input_event, history)
    local prev_value = history[input_event.input] or 0

    if input_event.event == "pressed" then
        history[input_event.input] = prev_value + 1
    elseif input_event.event == "released" then
        history[input_event.input] = prev_value - 1
    end
end

local function add_to_buffer(entity, input, event)
    local buffer = entity % rh.component.input_buffer
    local history = entity:ensure(input_history)
    table.insert(buffer, create_input_event(input, event))

    while #buffer > system.MAX_BUFFER_SIZE do
        local input_event = List.head(buffer)
        table.remove(buffer, 1)
        add_to_history(input_event, history)
    end
end


-- EVENT CALLBACKS

system["update"] = function(self, dt)
    for _, entity in ipairs(self.pool) do
        local buffer = entity % rh.component.input_buffer
        for _, input_event in ipairs(buffer) do
            input_event.age = input_event.age + dt
        end
    end
end

system["input_pressed"] = function(self, input)
    for _, entity in ipairs(self.pool) do
        add_to_buffer(entity, input, "pressed")
    end
end

system["input_released"] = function(self, input)
    for _, entity in ipairs(self.pool) do
        add_to_buffer(entity, input, "released")
    end
end

--

-- APIs

function system.clear_buffer(entity)
    local buffer = entity:ensure(rh.component.input_buffer)

    for _, input_event in ipairs(buffer) do
        add_to_history(input_event, entity:ensure(input_history))
    end

    entity:add(rh.component.input_buffer)
    return system
end

function system.is_released(entity, input, max_age)
    max_age = max_age or 0.2
    -- TODO Add age argument here
    local buffer = entity:ensure(rh.component.input_buffer)

    for _, input_event in ipairs(buffer) do
        local is_same = input_event.input == input
        local is_release = input_event.event == "released"
        local too_old = input_event.age > max_age
        if is_same and is_release and not too_old then return true end
    end

    return false
end

function system.is_pressed(entity, inputs, max_age)
    if type(inputs) == "string" then inputs = {inputs} end

    -- TODO refactor to just handle single input for now.
    -- Multi input can be implemented later.
    max_age = max_age or 0.2

    local history = entity:ensure(input_history)
    local buffer = entity % rh.component.input_buffer

    local down_history = {}

    for _, input in ipairs(inputs) do
        down_history[input] = history[input] or 0
    end

    local function is_valid()
        for _, value in pairs(down_history) do
            if value <= 0 then return false end
        end

        return true
    end

    local function pass(input_event)
        local value = down_history[input_event.input]
        if not value then return end

        if input_event.event == "pressed" then
            down_history[input_event.input] = value + 1

            if input_event.age <= max_age then
                return is_valid()
            end
        elseif input_event.event == "released" then
            down_history[input_event.input] = value - 1
        end
    end

    for _, input_event in ipairs(buffer) do
        if pass(input_event) then return true end
    end

    return false
end

function system.is_down(entity, input)
    local history = entity:ensure(input_history)
    local buffer = entity % rh.component.input_buffer

    local value = history[input] or 0

    for _, input_event in ipairs(buffer) do
        if input_event.input == input then
            if input_event.event == "pressed" then
                value = value + 1
            elseif input_event.event == "released" then
                value = value - 1
            end
        end
    end

    return value > 0
end

return system
