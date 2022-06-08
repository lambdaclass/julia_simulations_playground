using Random
using Distributions
using StatsBase
using DataFrames
using CSV
using Plots

BLOCK_REWARD = 100
VALIDATORS_COUNT = 50
ROUND_COUNT = 1_000_000

mutable struct Validator
    stake::Float64
    id::Int64
end

struct ValidatorsPool
    validators::Array{Validator}
end

function length(validators_pool::ValidatorsPool)
    return length(validators_pool.validators)
end

function create_validators_pool_with(validators_count)
    return ValidatorsPool([Validator(sample(32:50), i) for i in 1:validators_count])
end

function total_stake(validators_pool::ValidatorsPool)
    return sum(validator -> validator.stake, validators_pool.validators)
end

function stake_proportion(validator::Validator, validators_pool::ValidatorsPool)
    return validator.stake / total_stake(validators_pool)
end

function weight_validator(validator::Validator, validators_pool::ValidatorsPool)
    return stake_proportion(validator, validators_pool)
end

function validators_weight(validators_pool::ValidatorsPool)
    return map(validator -> weight_validator(validator, validators_pool), validators_pool.validators)
end

function select_leader_from(validators_pool::ValidatorsPool)
    return sample(validators_pool.validators, Weights(validators_weight(validators_pool)))
end

function reward(validator::Validator)
    validator.stake += BLOCK_REWARD
end

function slash(validator::Validator)
    validator.stake -= validator.stake * .05
end

function simulate_leader_election(validators_pool, round, rounds_info)
    leader = select_leader_from(validators_pool)
    proposal_accepted = rand(Bernoulli(2/3))
    proposal_accepted ? reward(leader) : slash(leader)
    for (key, value) in rounds_info
        append!(rounds_info[key], validators_pool.validators[key].stake)
    end
end

function xxx(num_rounds)
    validators_count = VALIDATORS_COUNT
    validators_pool = create_validators_pool_with(validators_count)  
    rounds_info = Dict(validator.id => [validator.stake] for validator in validators_pool.validators)
    for r in 1:num_rounds
        simulate_leader_election(validators_pool, r, rounds_info)
    end
    return Dict(string(k)=>v  for (k,v) in pairs(rounds_info))
end

begin
    evolution_of_validators_stake_in_rounds = xxx(ROUND_COUNT)

    df = DataFrame(evolution_of_validators_stake_in_rounds)

    plot(
        Matrix(df), 
        labels=permutedims(names(df)),
        legend=false,
    )
end
