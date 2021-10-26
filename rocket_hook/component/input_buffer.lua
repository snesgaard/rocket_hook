local input_buffer = {}
input_buffer.__index = input_buffer

function input_buffer:input(input, state)
    table.insert(
        self.__inputs,
        {input=input, state=state, time=self:duration()}
    )
end

function input_buffer:duration() return self.__duration end

function input_buffer:update(dt)
    local to_remove = {}

    for i = #self.__inputs, 1, -1 do
        local input = self.__inputs[i]
        input.duration = input.duration - dt
        if input.duration <= 0 then table.remove(self.__inputs, i) end
    end
end

function input_buffer:peek(inputs_to_check)
    for input, state in pairs(inputs_to_check) do
        if not self:query(input, state) then return false end
    end

    return true
end

function input_buffer:query(input, state)
    for _, i in ipairs(self.__inputs) do
        if i.input == input and i.state == state then return true end
    end

    return false
end

function input_buffer:clear()
    self.__inputs = {}
end


return function(duration)
    return setmetatable(
        {__inputs = {}, __duration=duration or 0.2},
        input_buffer
    )
end
