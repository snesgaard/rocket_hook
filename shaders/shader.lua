local shader = {}
shader.__index = shader

shader.__pendantic = true

function shader:__call(...)
    gfx.push('all')
    local shader = self:loveshader()
    if shader then
        gfx.setShader(shader)
        self.__func(self, ...)
    else
        self.__func(...)
    end
    gfx.pop()
end

function shader:loveshader()
    return self.__shader
end

function shader:send(name, ...)
    local s = self:loveshader()
    if shader.__pendantic and not s:hasUniform(name) then return end
    s:send(name, ...)
end

function shader:render_to(canvas, ...)
    local prev_canvas = gfx.getCanvas()
    if type(canvas) == "table" then
        gfx.setCanvas(unpack(canvas))
    else
        gfx.setCanvas(canvas)
    end
    self(...)
    gfx.setCanvas(prev_canvas)
end

function shader:get_size()
	local canvas = gfx.getCanvas()
	if canvas then
		return canvas:getWidth(), canvas:getHeight()
	else
		return gfx.getWidth(), gfx.getHeight()
	end
end

return function(func, shader_str0, shader_str1)
    local loveshader = nil
    if shader_str0 then
        loveshader = gfx.newShader(shader_str0, shader_str1)
    end

    local this = {__shader=loveshader, __func=func}

    return setmetatable(this, shader)
end
