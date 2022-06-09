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
EVEN_INITIAL_STAKE = true
HONEST_NODE_PROPORTION = 2/3

mutable struct Validator
    id::Int64
    stake::Float64
    is_honest::Bool
    proposals::Int64
end

function reinvest()
    return rand(Bernoulli(REINVESTMENT_PROBABILITY))
end

function reward(validator::Validator)
    if reinvest()
        validator.stake += BLOCK_REWARD
    end
end

function slash(validator::Validator)
    validator.stake -= validator.stake * .05
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

function propose_block(validator::Validator)
    validator.proposals += 1
end

function total_stake(validators)
    return sum(validator -> validator.stake, validators)
end

function stake_proportion(validator::Validator, validators)
    return validator.stake / total_stake(validators)
end

function weight_validator(validator::Validator, validators)
    return stake_proportion(validator, validators)
end

function validators_weight(validators)
    return map(validator -> weight_validator(validator, validators), validators)
end

function select_leader_from(validators)
    return sample(validators, Weights(validators_weight(validators)))
end

function simulate_leader_election(validators_pool, round, rounds_info)
    leader = select_leader_from(validators_pool)
    propose_block(leader)
    proposal_accepted = simulate_proposal_voting(leader, filter(validator -> validator ≠ leader, validators_pool))
    proposal_accepted ? reward(leader) : slash(leader)
    for (key, _) in rounds_info
        append!(rounds_info[key], validators_pool[key].stake)
    end
end

function simulate_leader_election_n_rounds(num_rounds, validators_pool)
    rounds_info = Dict(validator.id => [validator.stake] for validator in validators_pool)
    for r in 1:num_rounds
        simulate_leader_election(validators_pool, r, rounds_info)
    end
    return Dict(string(k)=>v  for (k,v) in pairs(rounds_info))
end

function create_byzantine_validators_with_even_initial_stake(byzantine_validators)
    return [Validator(i, ADMITION_STAKE, false, 0) for i in 1:byzantine_validators]
end

function create_honest_validators_with_even_initial_stake(honest_validators_count)
    return [Validator(i, ADMITION_STAKE, true, 0) for i in 1:honest_validators_count]
end

function create_byzantine_validators_with_random_initial_stake(byzantine_validators)
    return [Validator(i, sample(ADMITION_STAKE:50), false, 0) for i in 1:byzantine_validators]
end

function create_honest_validators_with_random_initial_stake(honest_validators_count)
    return [Validator(i, sample(ADMITION_STAKE:50), true, 0) for i in 1:honest_validators_count]
end

function setup_simulation(validators_count::Int64, even_stake::Bool, honest_validators_proportion::Float64)   
    @assert (0 <= honest_validators_proportion <= 1) "Honest validators proportion must be a value within [0, 1]"
    honest_validators_count = round(validators_count * honest_validators_proportion)
    byzantine_validators_count = validators_count - honest_validators_count
    
    return even_stake ?
        cat(
            create_honest_validators_with_even_initial_stake(honest_validators_count), 
            create_honest_validators_with_even_initial_stake(byzantine_validators_count),
            dims=1
        ) :
        cat(
            create_honest_validators_with_random_initial_stake(honest_validators_count), 
            create_byzantine_validators_with_random_initial_stake(byzantine_validators_count),
            dims=1
        )
end

begin
    validators_pool = setup_simulation(VALIDATORS_COUNT, EVEN_INITIAL_STAKE, HONEST_NODE_PROPORTION)
    evolution_of_validators_stake_in_rounds = simulate_leader_election_n_rounds(ROUND_COUNT, validators_pool)

    df = DataFrame(evolution_of_validators_stake_in_rounds)

    plot(
        Matrix(df), 
        labels=permutedims(names(df)),
        legend=false,
    )
end
