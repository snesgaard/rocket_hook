local nw = require "nodeworks"
local rh = require "rocket_hook"

local deck = nw.ecs.system(
    rh.component.draw, rh.component.discard, rh.component.hand
)

deck.MAX_HAND_SIZE = 10

function deck.draw_card(entity)
    local hand = entity % rh.component.hand
    local draw = entity % rh.component.draw

    if deck.is_hand_full(entity) or draw:empty() return end

    local next_card = draw[1]
    draw:remove(next_card)
    hand:add(next_card)

    entity.world("on_card_drawn", entity, next_card)
end

function deck.shuffle_draw(entity)
    local prev_draw = entity % rh.component.draw
    local next_draw = rh.component.draw()

    local indices = List.range(1, prev_draw:size()):shuffle()

    for _, index in ipairs(indices) do
        next_draw:add(prev_draw[index])
    end

    entity:set(rh.component.draw, next_draw)
    entity.world("on_draw_shuffled", entity, prev_draw, next_draw)
end

function deck.play_card(entity, card)
    local hand = entity % rh.component.hand
    local discard = entity % rh.component.discard

    hand:remove(card)
    discard:add(card)

    entity.world("on_card_played", entity, card)
end

function deck.seek(entity, card)
    local draw = entity % rh.component.draw
    local hand = entity % rh.component.hand

    if deck.is_hand_full(hand) then return end
    if not draw:remove(card) then return end
    hand:add(card)

    entity.world("on_card_seek", entity, card)
end

function deck.reanimate(entity, card)
    local hand = entity % rh.component.hand
    local discard = entity % rh.component.discard

    if deck.is_hand_full(hand) then return end
    if not discard:remove(card) then return end
    hand:add(card)

    entity.world("on_card_reanimated", entity, card)
end

function deck.add_to_draw(entity, card, do_shuffle)
    local draw = entity % rh.component.draw

    draw:add(card)
    entity.world("on_card_added_to_draw", entity, card)
    if do_shuffle then return deck.shuffle(entity) end
end

function deck.is_hand_full(hand) return hand:size() >= deck.MAX_HAND_SIZE end

return deck
