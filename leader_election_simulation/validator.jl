module Validator_mod

using Distributions

const SLASH_PENALTY = 1
const BLOCK_REWARD = 2

export slash, propose_block, weight_validator, reward, vote, Validator

mutable struct Validator
    id::Int64
    stake::Float64
    balance::Float64
    is_honest::Bool
    proposals::Int64
end

function slash(self::Validator)
    self.stake -= SLASH_PENALTY
end

function propose_block(self::Validator)
    self.proposals += 1
end

function stake_proportion(self::Validator, validators)
    return self.stake / sum(validator -> validator.stake, validators)
end

function weight_validator(self::Validator, validators)
    return stake_proportion(self, validators)
end

function reinvest(reinvestment_probability)
    return rand(Bernoulli(reinvestment_probability))
end

function reward(self::Validator, reinvestment_probability)
    reinvest(reinvestment_probability) ? self.stake += BLOCK_REWARD :
    self.balance += BLOCK_REWARD
end

function try_raise_timeout(timeout_probability)
    return rand(Bernoulli(timeout_probability))
end

function try_to_got_wise(got_wise_probability)
    return rand(Bernoulli(got_wise_probability))
end

function vote(
    voter::Validator,
    proposer::Validator,
    timeout_probability,
    got_wise_probability,
)
    return !try_raise_timeout(timeout_probability) && (
        (voter.is_honest && proposer.is_honest) || 
        ( voter.is_honest && !proposer.is_honest && try_to_got_wise(got_wise_probability)) || # Verify
        (!voter.is_honest && !proposer.is_honest)
    ) # Byzantine voter votes only byzantine proposals
end

end
