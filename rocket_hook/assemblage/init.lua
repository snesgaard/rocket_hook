local assemblages = {}

assemblages.player_motion = {
    [components.velocity] = {},
    [components.gravity] = {0, 2000},
    [components.drag] = {0.5}
}

return assemblages
