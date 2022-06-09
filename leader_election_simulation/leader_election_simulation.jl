using Random
using Distributions
using StatsBase
using DataFrames
using CSV
using Plots

BLOCK_REWARD = 30
VALIDATORS_COUNT = 30
ROUND_COUNT = 1_000_000
TIMEOUT_PROBABILITY  = .5
GOT_WISE_PROBABILITY = .5
ADMITION_STAKE = 32
REINVESTMENT_PROBABILITY = .5

mutable struct Validator
    id::Int64
    stake::Float64
    is_honest::Bool
    proposals::Int64
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

function validator_got_wise()
    return rand(Bernoulli(GOT_WISE_PROBABILITY))
end

function timeout()
    return rand(Bernoulli(TIMEOUT_PROBABILITY))
end

function vote(voter::Validator, proposer::Validator)
    return !timeout() &&
            ((voter.is_honest && proposer.is_honest) ||
            (voter.is_honest&& !proposer.is_honest && validator_got_wise()) || # Verify
            (!voter.is_honest && !proposer.is_honest)) # Byzantine voter votes only byzantine proposals
end

function simulate_proposal_voting(leader::Validator, validators_without_leader)
    votes = map(validator -> vote(validator, leader), validators_without_leader)
    return mean(votes) > 2/3
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
    proposal_accepted = rand(Bernoulli(1))
    proposal_accepted ? reward(leader) : slash(leader)
    for (key, value) in rounds_info
        append!(rounds_info[key], validators_pool.validators[key].stake)
    end
end

function simulate_leader_election_n_rounds(num_rounds, validators_pool)
    rounds_info = Dict(validator.id => [validator.stake] for validator in validators_pool.validators)
    for r in 1:num_rounds
        simulate_leader_election(validators_pool, r, rounds_info)
    end
    return Dict(string(k)=>v  for (k,v) in pairs(rounds_info))
end

begin
    validators_pool = create_validators_pool_with(VALIDATORS_COUNT)
    evolution_of_validators_stake_in_rounds = simulate_leader_election_n_rounds(ROUND_COUNT, validators_pool)
    df = DataFrame(evolution_of_validators_stake_in_rounds)

    plot(
        Matrix(df), 
        labels=permutedims(names(df)),
        legend=false,
    )
end
