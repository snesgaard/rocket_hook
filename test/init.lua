nw = require "nodeworks"
rh = require "rocket_hook"
on_event = require "nodeworks.test.event_listener"
T = nw.third.knife.test

function isclose(a, b, tol)
    return math.abs(a - b) < (tol or 1e-5)
end

require "test.test_camera"
require "test.test_collision_response"
require "test.test_draw_sprite"
require "test.test_input_remap"
require "test.test_moving_platform"
