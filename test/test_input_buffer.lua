local input_buffer = rh.system.input_buffer

T("input_buffer", function(T)
    local world = nw.ecs.world{input_buffer}

    local entity = nw.ecs.entity(world)
        :add(rh.component.input_buffer)

    T("members", function(T)
        local pool = world:context(input_buffer).pool
        T:assert(#pool == 1)
    end)

    T("input_released", function(T)
        world("input_released", "foo")

        T:assert(input_buffer.peek.is_released(entity, "foo"))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(not input_buffer.peek.is_released(entity, "foo"))
    end)

    T("input_pressed", function(T)
        world("input_pressed", "foo")

        T:assert(input_buffer.peek.is_pressed(entity, "foo"))
        T:assert(not input_buffer.peek.is_pressed(entity, "bar"))
        T:assert(not input_buffer.peek.is_released(entity, "foo"))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(not input_buffer.peek.is_pressed(entity, "foo"))
        T:assert(not input_buffer.peek.is_pressed(entity, "bar"))
        T:assert(not input_buffer.peek.is_released(entity, "foo"))
    end)

    T("is_down", function(T)
        T:assert(not input_buffer.peek.is_down(entity, "foo"))

        world("input_pressed", "foo")

        T:assert(input_buffer.peek.is_down(entity, "foo"))
        T:assert(not input_buffer.peek.is_down(entity, "bar"))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(input_buffer.peek.is_down(entity, "foo"))

        world("input_released", "foo")

        T:assert(not input_buffer.peek.is_down(entity, "foo"))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(not input_buffer.peek.is_down(entity, "foo"))

        world("input_pressed", "foo")

        T:assert(input_buffer.peek.is_down(entity, "foo"))

        world("input_released", "foo")

        T:assert(not input_buffer.peek.is_down(entity, "foo"))
    end)

    T("is_pressed_multi", function(T)
        local inputs = {"foo", "bar"}

        T:assert(not input_buffer.peek.is_pressed(entity, inputs))

        for _, input in ipairs(inputs) do
            world("input_pressed", input)
        end

        T:assert(input_buffer.peek.is_pressed(entity, inputs))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(not input_buffer.peek.is_pressed(entity, inputs))
    end)

    T("is_pressed_delay", function(T)
        world("input_pressed", "foo")
        world("update", input_buffer.MAX_AGE + 1)
        world("input_pressed", "bar")

        T:assert(input_buffer.peek.is_pressed(entity, "bar"))
        T:assert(not input_buffer.peek.is_pressed(entity, "foo"))
        T:assert(input_buffer.peek.is_down(entity, "foo"))

        T:assert(input_buffer.peek.is_pressed(entity, {"foo", "bar"}))

        world("update", input_buffer.MAX_AGE / 2)

        T:assert(input_buffer.peek.is_pressed(entity, {"foo", "bar"}))

        world("input_released", "foo")

        T:assert(input_buffer.peek.is_pressed(entity, {"foo", "bar"}))
    end)

    T("is_pressed_pop", function(T)
        world("input_pressed", "foo")
        T:assert(input_buffer.is_pressed(entity, "foo"))
        T:assert(not input_buffer.is_pressed(entity, "foo"))

        world("input_pressed", "foo")
        world("update", input_buffer.MAX_AGE / 2)
        world("input_pressed", "foo")
        T:assert(input_buffer.is_pressed(entity, "foo"))
        T:assert(input_buffer.is_pressed(entity, "foo"))
        T:assert(not input_buffer.is_pressed(entity, "foo"))

        T:assert(input_buffer.peek.is_down(entity, "foo"))
    end)

    T("is_pressed_multi_pop", function(T)
        world("input_pressed", "foo")
        world("input_pressed", "bar")
        world("update", input_buffer.MAX_AGE / 2)
        world("input_pressed", "foo")

        T:assert(input_buffer.is_pressed(entity, {"foo", "bar"}))
        T:assert(input_buffer.is_pressed(entity, {"foo", "bar"}))
        T:assert(not   input_buffer.is_pressed(entity, {"foo", "bar"}))
    end)

    T("is_released_pop", function(T)
        world("input_released", "foo")
        T:assert(input_buffer.is_released(entity, "foo"))
        T:assert(not input_buffer.is_released(entity, "foo"))
    end)
end)
