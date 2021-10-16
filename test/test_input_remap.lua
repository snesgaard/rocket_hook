T("input_remap", function(T)
    local world = nw.ecs.world{rh.system.input_remap}

    T("input_pressed", function(T)
        for key, expected_input in pairs(rh.system.input_remap.INPUT_FROM_KEY) do
            world.on_event = on_event()
            world("keypressed", key)
            local _, input = world.on_event:get("input_pressed")
            local err_msg = "Expected input %s from key press %s but got %s"

            T:assert(
                input == expected_input,
                string.format(err_msg, expected_input, key, input)
            )
        end
    end)

    T("input_released", function(T)
        for key, expected_input in pairs(rh.system.input_remap.INPUT_FROM_KEY) do
            world.on_event = on_event()
            world("keyreleased", key)
            local _, input = world.on_event:get("input_released")
            local err_msg = "Expected input %s from key release %s but got %s"

            T:assert(
                input == expected_input,
                string.format(err_msg, expected_input, key, input)
            )
        end
    end)
end)
