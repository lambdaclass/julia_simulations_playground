using Random
using Distributions
using StatsBase
using DataFrames
using CSV
using Plots
using IterTools

BLOCK_REWARD = 2
VALIDATORS_COUNT = 30
ROUND_COUNT = 1_000_000
ADMITION_STAKE = 32
SLASH_PENALTY = 1

HONEST_NODE_PROPORTION = [1/3, 2/3, 1.0]
WEIGHTED_LEADER_ELECTION = [true, false]
EVEN_INITIAL_STAKE = [true, false]
REINVESTMENT_PROBABILITY = [.5, 1.0] # if no reinvestment look at another variables like proposals accepted or balance
TIMEOUT_PROBABILITY  = [.0, .1]
GOT_WISE_PROBABILITY = [.0, .50, 1.0]

SCENARIOS = product(
    HONEST_NODE_PROPORTION,
    WEIGHTED_LEADER_ELECTION,
    EVEN_INITIAL_STAKE, 
    REINVESTMENT_PROBABILITY, 
    TIMEOUT_PROBABILITY, 
    GOT_WISE_PROBABILITY, 
)

mutable struct Validator
    id::Int64
    stake::Float64
    balance::Float64
    is_honest::Bool
    proposals::Int64
end

function reinvest(reinvestment_probability)
    return rand(Bernoulli(reinvestment_probability))
end

function reward(validator::Validator, reinvestment_probability)
    reinvest(reinvestment_probability) ?
    validator.stake += BLOCK_REWARD :
    validator.balance += BLOCK_REWARD
end

function slash(validator::Validator)
    validator.stake -= SLASH_PENALTY
end

function validator_got_wise(got_wise_probability)
    return rand(Bernoulli(got_wise_probability))
end

function timeout(timeout_probability)
    return rand(Bernoulli(timeout_probability))
end

function vote(voter::Validator, proposer::Validator, timeout_probability, got_wise_probability)
    return !timeout(timeout_probability) &&
            ((voter.is_honest && proposer.is_honest) ||
            (voter.is_honest && !proposer.is_honest && !validator_got_wise(got_wise_probability)) || # Verify
            (!voter.is_honest && !proposer.is_honest)) # Byzantine voter votes only byzantine proposals
end

function simulate_proposal_voting(leader::Validator, validators_without_leader, timeout_probability, got_wise_probability)
    votes = map(validator -> vote(validator, leader, timeout_probability, got_wise_probability), validators_without_leader)
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

function select_leader_from(validators, wighted_leader_election)
    return wighted_leader_election ?
        sample(validators, Weights(validators_weight(validators))) :
        sample(validators)
end

function simulate_leader_election(validators_pool, rounds_info, wighted_leader_election, reinvestment_probability, timeout_probability, got_wise_probability)
    leader = select_leader_from(validators_pool, wighted_leader_election)
    propose_block(leader)
    proposal_accepted = simulate_proposal_voting(leader, filter(validator -> validator ≠ leader, validators_pool), timeout_probability, got_wise_probability)
    proposal_accepted ? reward(leader, reinvestment_probability) : slash(leader)
    for (key, _) in rounds_info
        append!(rounds_info[key], validators_pool[key].stake)
    end
end

function simulate_leader_election_n_rounds(num_rounds, validators_pool, reinvestment_probability, timeout_probability, got_wise_probability)
    rounds_info = Dict(validator.id => [validator.stake] for validator in validators_pool)
    for r in 1:num_rounds
        simulate_leader_election(validators_pool, rounds_info, wighted_leader_election, reinvestment_probability, timeout_probability, got_wise_probability)
    end
    return Dict(string(k)=>v  for (k,v) in pairs(rounds_info))
end

function create_byzantine_validators_with_even_initial_stake(byzantine_validators)
    return [Validator(i, ADMITION_STAKE, 0.0, false, 0) for i in 1:byzantine_validators]
end

function create_honest_validators_with_even_initial_stake(honest_validators_count)
    return [Validator(i, ADMITION_STAKE, 0.0, true, 0) for i in 1:honest_validators_count]
end

function create_byzantine_validators_with_random_initial_stake(byzantine_validators)
    return [Validator(i, sample(ADMITION_STAKE:50), 0.0, false, 0) for i in 1:byzantine_validators]
end

function create_honest_validators_with_random_initial_stake(honest_validators_count)
    return [Validator(i, sample(ADMITION_STAKE:50), 0.0, true, 0) for i in 1:honest_validators_count]
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

function simulate_scenario(scenario)
    (honest_node_proportion, wighted_leader_election, even_initial_stake, 
    reinvestment_probability, timeout_probability, got_wise_probability) = scenario
    validators_pool = setup_simulation(VALIDATORS_COUNT, even_initial_stake, honest_node_proportion)
    evolution_of_validators_stake_in_rounds = simulate_leader_election_n_rounds(
        ROUND_COUNT, 
        validators_pool,
        wighted_leader_election, 
        reinvestment_probability, 
        timeout_probability, 
        got_wise_probability
    )

    df = DataFrame(evolution_of_validators_stake_in_rounds)
    CSV.write("./data/$(scenario).csv", df, compress=true)

    savefig(plot(
        Matrix(df), 
        labels=permutedims(names(df)),
        legend=false,
    ), "./images/$(scenario).png")
end

for (i, scenario) in enumerate(SCENARIOS)
    println("Simulating scenario $(i)")
    @show scenario
    @time simulate_scenario(scenario)
    println("$(length(SCENARIOS)-i) more to simulate...")
end
