using Random

SIX_SIDES_DICE = 1:6

function throw_dice(dice_count)
    return rand(SIX_SIDES_DICE, dice_count)
end

function served_generala_probability_estimation(num_throws=1_000_000)
    throws = zeros(num_throws)
    for i in 1:num_throws
        throw = throw_dice(5)
        throws[i] = all(y -> y == throw[1], throw)
    end
    return sum(throws) / num_throws
end

function served_full_probability_estimation(num_throws=1_000_000)
    throws = zeros(num_throws)
    for i in 1:num_throws
        throw = throw_dice(5)
        throws[i] = length(unique(throw)) == 2 && 2 in values(countmap(throw))
    end
    return sum(throws)/num_throws
end

println("The probability of a served generala is: $(served_generala_probability_estimation())")
println("The probability of a served full is: $(served_full_probability_estimation())")
