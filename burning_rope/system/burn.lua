local br = require "burning_rope"
local nw = require "nodeworks"

local function gray(alpha)
    return list(alpha, alpha, alpha, alpha)
end

local circle = gfx.prerender(10, 10, function(w, h)
    local rx, ry = w * 0.5, h * 0.5
    gfx.ellipse("fill", rx, ry, rx, ry)
end)

local function fire_particle_component(x, y, w, h)
    local area_pr_rate = 15
    local rate = math.max(16, (w * h) / area_pr_rate)
    return particles{
        buffer=rate * 4,
        image=circle,
        rate=rate,
        lifetime=2,
        radial_acceleration={1, 20},
        size={1, 2},
        color=
            gray(1)
            + gray(0.5)
            + gray(0.5 * 0.5)
            + gray(0),
        dir=-math.pi * 0.5,
        spread=math.pi * 0.25,
        speed=60,
        area={"uniform", w * 0.5, h * 0.5},
        move={x, y}
    }
end

local function entity_filter(entity)
    return {
        pool = entity:has(br.component.burning),
        sfx = entity:has(br.component.burning, nw.component.hitbox),
        particles = entity:has(fire_particle_component)
    }
end

local burn_system = nw.ecs.system.from_function(entity_filter)

function burn_system:on_entity_added(entity, pool)
    if pool == self.sfx then
        local h = entity[nw.component.hitbox]
        entity:add(fire_particle_component, h:unpack())
    end
end

function burn_system:on_entity_removed(entity, pool)
    if pool == self.sfx then
        entity[fire_particle_component]:stop()
    end
end

local function spread_fire(entity, dt)
    local burn = entity[br.component.burning]
    if not burn.cooldown:update(dt) then return end
    burn.cooldown:reset()

    local rect = systems.collision.get_rect(entity)
    if not rect then return end
    local rect_margin = rect:expand(2, 2)
    local collisions = systems.collision.check_rect(entity, rect_margin)

    for _, other in ipairs(collisions) do
        if other ~= entity and other[br.component.flammable] then
            other
                :remove(br.component.flammable)
                :add(br.component.burning)
        end
    end
end

local function extinguish(entity, dt)
    local burn = entity[br.component.burning]
    if not burn.lifetime:update(dt) then return end

    entity
        :remove(br.component.burning)
        :add(br.component.charcoal)

    entity.world("on_burned", entity)
end

local function update_particle(entity, dt)
    entity[fire_particle_component]:update(dt)
end

function burn_system:update(dt)
    List.foreach(self.pool, spread_fire, dt)

    List.foreach(self.pool, extinguish, dt)

    --particle_system:update(dt)
    List.foreach(self.particles, update_particle, dt)
end

local function spread_fire_on_collision(from, to)
    if not from:has(br.component.burning) then return end
    if not to:has(br.component.flammable) then return end

    to
        :remove(br.component.flammable)
        :add(br.component.burning)
end

function burn_system:on_collision(colinfos)
    for _, colinfo in ipairs(colinfos) do
        spread_fire_on_collision(colinfo.item, colinfo.other)
        spread_fire_on_collision(colinfo.other, colinfo.item)
    end
end

function burn_system:keypressed(key)
    if key == "k" then
        self.draw_raw = not self.draw_raw
    end
end

local shader_str =
[[
uniform int cmap_size;
uniform vec3 cmap[8];

vec3 colormap(float intensity) {
    int index = int(floor(intensity * cmap_size));
    index = int(clamp(index, 0, cmap_size - 1));
    return cmap[index];
}

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    vec4 texcolor = Texel(tex, texture_coords);
    float intensity = texcolor.r;
    return vec4(colormap(intensity * color.r), texcolor.r < 0.001 ? 0 : texcolor.a);
}
]]
local shader = gfx.newShader(shader_str)

local colormap = {
    gfx.hex2color("00000000"),
    gfx.hex2color("171426"),
    gfx.hex2color("3d2630"),
    gfx.hex2color("733d38"),
    gfx.hex2color("a32633"),
    gfx.hex2color("f77521"),
    gfx.hex2color("ffad33"),
    gfx.hex2color("ffe861"),
}

shader:send("cmap_size", #colormap)
shader:send("cmap", unpack(colormap))

canvas = gfx.newCanvas(gfx.getWidth(), gfx.getHeight())

function burn_system:draw()
    gfx.push("all")
    gfx.setCanvas(canvas)
    gfx.clear(0, 0, 0, 1)
    gfx.setColor(0.6, 1, 1, 1)
    gfx.setBlendMode("add")
    gfx.setShader()

    for _, entity in ipairs(self.particles) do
        local pa = entity[fire_particle_component]
        local x = entity[nw.component.position]
        local hb = entity[nw.component.hitbox]
        gfx.draw(pa, hb:move(x.x, x.y):center():unpack())
    end

    gfx.pop()

    gfx.push("all")
    gfx.origin()
    gfx.setCanvas()
    gfx.setColor(1, 1, 1, 1)
    if not self.draw_raw then
        gfx.setShader(shader)
    else
        gfx.setShader()
    end
    gfx.draw(canvas, 0, 0)
    gfx.pop()
    gfx.setColor(1, 1, 1)
end

return burn_system
