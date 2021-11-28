local br = require "burning_rope"
local nw = require "nodeworks"
local rh = require "rocket_hook"

local logic_systems = list(
    --br.system.burn,
    --br.system.rope,
    nw.system.parenting
)

local action_systems = list(
    rh.system.input_remap,
    rh.system.input_buffer,
    rh.system.action.dodge,
    rh.system.action.throw,
    rh.system.action.hook,
)

local decision_systems = list(
    rh.system.decision.gibbles
)

local motion_systems = list(
    nw.system.motion,
    --br.system.fixture,
    nw.system.collision,
    nw.system.collision_contact,
    rh.system.collision_response,
    rh.system.moving_platform
)

local render_systems = list(
    nw.system.animation,
    rh.system.draw_sprite,
    rh.system.camera
)

return {
    logic = logic_systems,
    action = action_systems,
    decision = decision_systems,
    motion = motion_systems,
    render = render_systems
}
