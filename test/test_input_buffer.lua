T("input_buffer", function(T)
    local world = nw.ecs.world{rh.system.input_buffer}

    local entity = nw.ecs.entity(world)
        :add(rh.component.input_buffer)

    T("members", function(T)
        local pool = world:context(rh.system.input_buffer).pool
        T:assert(#pool == 1)
    end)

    T("input_pressed", function(T)
        world("input_pressed", "foo")


        T:assert(rh.system.input_buffer.is_pressed(entity, "foo"))
        T:assert(not rh.system.input_buffer.is_pressed(entity, "bar"))

        local max_age = 0.2

        world("update", max_age + 1)

        T:assert(not rh.system.input_buffer.is_pressed(entity, "foo", max_age))
    end)

    T("input_released", function(T)
        world("input_released", "foo")

        T:assert(rh.system.input_buffer.is_released(entity, "foo"))
        T:assert(not rh.system.input_buffer.is_released(entity, "bar"))

        local max_age = 0.2

        world("update", max_age + 1)

        T:assert(not rh.system.input_buffer.is_released(entity, "foo", max_age))
    end)

    T("input_pressed_multi", function(T)
        local inputs = {"foo", "bar"}

        T:assert(not rh.system.input_buffer.is_pressed(entity, inputs))

        List.foreach(inputs, function(i) world("input_pressed", i) end)

        T:assert(rh.system.input_buffer.is_pressed(entity, inputs))

        local max_age = 0.2
        world("update", max_age + 1)

        T:assert(not rh.system.input_buffer.is_pressed(entity, inputs))

        world("input_released", inputs[1])
        world("input_pressed", inputs[1])

        T:assert(rh.system.input_buffer.is_pressed(entity, inputs))

        -- Spam input with nonense
        for i = 1, rh.system.input_buffer.MAX_BUFFER_SIZE do
            world("input_pressed", "meeeh")
        end

        T:assert(not rh.system.input_buffer.is_pressed(entity, inputs))

        world("input_released", inputs[1])
        world("input_pressed", inputs[1])

        T:assert(rh.system.input_buffer.is_pressed(entity, inputs))

        world("update", max_age + 1)

        T:assert(not rh.system.input_buffer.is_pressed(entity, inputs))
    end)

end)
