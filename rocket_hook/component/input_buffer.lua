local input_buffer = {}
input_buffer.__index = input_buffer

function input_buffer:add(key)
    local entry = {key=key, time=self.__duration}
    table.insert(self, entry)
end

function input_buffer:update(dt)
    for index = #self, 1, -1 do
        local entry = self[index]
        if entry.time <= dt then
            table.remove(self, index)
        else
            entry.time = entry.time - dt
        end
    end
end

function input_buffer:foreach(fn, ...)
    local to_remove = {}

    for index, entry in ipairs(self) do
        if fn(entry.key, ...) then
            table.insert(to_remove, index)
        end
    end

    for i = #to_remove, 1, -1 do
        table.remove(self, to_remove[i])
    end
end


return function(duration)
    return setmetatable(
        {__duration=duration or 0.2},
        input_buffer
    )
end
