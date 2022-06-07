using Random

SIX_SIDES_DICE = 1:6

function throw_dice(dice_count)
    return rand(SIX_SIDES_DICE, dice_count)
end
