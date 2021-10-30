local nw = require "nodeworks"
local rh = require "rocket_hook"

local function create_event(input, state)
    return {state=state, age=0, input=input}
end

local function input_history(prev_history)
    return dict(prev_history or {})
end

local system = nw.ecs.system(rh.component.input_buffer)

-- UTILTIY

local function is_pressed(event) return event.state == "pressed" end

local function is_released(event) return event.state == "released" end

local function history_value(prev_value, event)
    prev_value = prev_value or 0
    if is_pressed(event) then
        return prev_value + 1
    elseif is_released(event) then
        return prev_value - 1
    else
        return prev_value
    end
end

local function too_old(event, max_age) return event.age >= max_age end

local function not_too_old(...) return not too_old(...) end

local function add_to_history(history, input, event)
    history[input] = history_value(history[input], event)
end

local function get_epoch(input, buffer)
    local l = buffer[input]

    if not l then
        l = list()
        buffer[input] = l
    end

    return l
end

local function add_to_buffer(buffer, input, state)
    table.insert(get_epoch(input, buffer), create_event(input, state))
end

local function update_buffer(buffer, dt)
    for _, epoch in pairs(buffer) do
        for _, event in ipairs(epoch) do
            event.age = event.age + dt
        end
    end
end

local function pop(entity, max_age)
    max_age = max_age or system.MAX_AGE

    local buffer = entity % rh.component.input_buffer
    local history = entity:ensure(input_history)

    for input, epoch in pairs(buffer) do
        -- First update history
        for _, event in ipairs(epoch) do
            if too_old(event, max_age) then
                add_to_history(history, input, event)
            end
        end

        -- Next remove events that are too old
        buffer[input] = List.filter(epoch, not_too_old, max_age)
    end
end

system.MAX_AGE = 0.2

-- CALLBACKS --

system["input_pressed"] = function(self, input)
    for _, entity in ipairs(self.pool) do
        local buffer = entity % rh.component.input_buffer
        add_to_buffer(buffer, input, "pressed")
        self.world("input_buffer_update", entity, input, "pressed")
    end
end

system["input_released"] = function(self, input)
    for _, entity in ipairs(self.pool) do
        local buffer = entity % rh.component.input_buffer
        add_to_buffer(buffer, input, "released")
        self.world("input_buffer_update", entity, input, "released")
    end
end

system["update"] = function(self, dt)
    for _, entity in ipairs(self.pool) do
        local buffer = entity % rh.component.input_buffer
        update_buffer(buffer, dt)
        pop(entity, system.MAX_AGE)
    end
end

----

-- APIS --

local peek = {}

system.peek = peek

function peek.is_released(entity, input)
    local buffer = entity % rh.component.input_buffer
    local epoch = get_epoch(input, buffer)
    local event = epoch:find(is_released)
    if event then return event.age end
end

function peek.is_down(entity, input)
    local buffer = entity % rh.component.input_buffer
    local history = entity:ensure(input_history)

    local epoch = get_epoch(input, buffer)

    local value = epoch:reduce(history_value, history[input] or 0)

    return value > 0
end

function peek.is_pressed(entity, inputs)
    -- Convert to list if just a string
    if type(inputs) == "string" then inputs = {inputs} end

    -- Get input data structures
    local buffer = entity % rh.component.input_buffer
    -- Copy history, since we need to mutate it
    local history = input_history(entity:ensure(input_history))

    -- First find all pressed events for all inputs
    local input_epochs = List.map(inputs, get_epoch, buffer)
        -- Flatten the list
        :reduce(add, list())
        -- And sort by age (descresing)
        :sort(function(a, b) return a.age > b.age end)

    -- Lambda for checking whehter all inputs are pressed
    local function all_down()
        for _, input in ipairs(inputs) do
            if (history[input] or 0) <= 0 then return false end
        end

        return true
    end

    -- Now we roll through all the events
    for _, event in ipairs(input_epochs) do
        -- Update the histrory
        add_to_history(history, event.input, event)
        -- If the event was a press and all buttons are down we have a yes!
        -- Return the events age, as it is considered when the event happened
        if is_pressed(event) and all_down() then return event.age end
    end
end

-- Redeclare pop versions of the peek functions

local function pop_after_peek(func, entity, ...)
    local max_age = func(entity, ...)
    if not max_age then return end
    pop(entity, max_age)
    return max_age
end

for _, key in pairs{"is_pressed", "is_released"} do
    local func = peek[key]
    system[key] = function(entity, ...)
        return pop_after_peek(func, entity, ...)
    end
end

return system
