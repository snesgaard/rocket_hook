local double_canvas = {}
double_canvas.__index = double_canvas

function double_canvas:front() return self.__front end

function double_canvas:back() return self.__back end

function double_canvas:swap()
    local f, b = self.__front, self.__back
    self.__front = b
    self.__back = f
    return self.__front, self.__back
end

return function(...)
    local this = {__front = gfx.newCanvas(...), __back=gfx.newCanvas(...)}

    return setmetatable(this, double_canvas)
end
