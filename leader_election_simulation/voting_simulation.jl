include("./scenarios.jl")
include("./validator.jl")

using .Validator_mod
using .Scenarios
using Random
using StatsBase
using DataFrames
using CSV
using Plots
using IterTools

const VALIDATORS_COUNT = 30
const ROUND_COUNT = 1_000_000
const ADMITION_STAKE = 32

function simulate_proposal_voting(
    leader::Validator,
    validators_without_leader,
    timeout_probability,
    got_wise_probability,
)
    votes = map(
        validator -> vote(validator, leader, timeout_probability, got_wise_probability),
        validators_without_leader,
    )
    return mean(votes) >= 19 / 29
end

function validators_weight(validators)
    return map(validator -> weight_validator(validator, validators), validators)
end

function select_leader_from(validators, wighted_leader_election)
    return wighted_leader_election ?
           sample(validators, Weights(validators_weight(validators))) : sample(validators)
end

function simulate_leader_election(
    validators_pool,
    rounds_info,
    reinvestment_probability,
    timeout_probability,
    got_wise_probability,
    weighted_leader_election,
)
    leader = select_leader_from(validators_pool, weighted_leader_election)
    propose_block(leader)
    proposal_accepted = simulate_proposal_voting(
        leader,
        filter(validator -> validator ≠ leader, validators_pool),
        timeout_probability,
        got_wise_probability,
    )
    proposal_accepted ? reward(leader, reinvestment_probability) : slash(leader)
    for id in rounds_info["id"]
        append!(rounds_info["stake"][string(id)], validators_pool[id].stake)
        append!(rounds_info["balance"][string(id)], validators_pool[id].balance)
        append!(rounds_info["proposals"][string(id)], validators_pool[id].proposals)
    end
    return rounds_info
end

function simulate_leader_election_n_rounds(
    num_rounds,
    validators_pool,
    wighted_leader_election,
    reinvestment_probability,
    timeout_probability,
    got_wise_probability,
)
    rounds_info = Dict(
        "id" => [],
        "is_honest" => [],
        "stake" => Dict(),
        "balance" => Dict(),
        "proposals" => Dict(),
    )

    for validator in validators_pool
        append!(rounds_info["id"], validator.id)
        append!(rounds_info["is_honest"], (validator.id, validator.is_honest))
        rounds_info["stake"][string(validator.id)] = [validator.stake]
        rounds_info["balance"][string(validator.id)] = [validator.balance]
        rounds_info["proposals"][string(validator.id)] = [validator.proposals]
    end

    for r = 1:num_rounds
        simulate_leader_election(
            validators_pool,
            rounds_info,
            wighted_leader_election,
            reinvestment_probability,
            timeout_probability,
            got_wise_probability,
        )
    end

    return rounds_info
end

function create_validators(honest_validators, byzantine_validators, even_stake)
    if even_stake
        return cat([Validator(honest_validators + i, ADMITION_STAKE, 0.0, false, 0) for i = 1:byzantine_validators], [Validator(i, ADMITION_STAKE, 0.0, true, 0) for i = 1:honest_validators], dims = 1)
    end
    
    return cat([
        Validator(i, sample(ADMITION_STAKE:50), 0.0, true, 0) for
        i = 1:honest_validators
    ], [
        Validator(honest_validators + i, sample(ADMITION_STAKE:50), 0.0, false, 0) for
        i = 1:byzantine_validators
    ], dims = 1)
end

function write_reports(report_results, scenario, honest_nodes, byzantine_nodes) 
    CSV.write(
        "./data/stake/$(honest_nodes)_$(byzantine_nodes)_$(get_scenario_name(scenario)).csv",
        DataFrame(report_results["stake"]),
        compress = true,
    )
    CSV.write(
        "./data/balance/$(honest_nodes)_$(byzantine_nodes)_$(get_scenario_name(scenario)).csv",
        DataFrame(report_results["balance"]),
        compress = true,
    )
    CSV.write(
        "./data/proposals/$(honest_nodes)_$(byzantine_nodes)_$(get_scenario_name(scenario)).csv",
        DataFrame(report_results["proposals"]),
        compress = true,
    )
end

function start_simulation(honest_nodes, byzantine_nodes, simulation_scenarios)
    for scenario in simulation_scenarios
        validators_pool = create_validators(
            honest_nodes,
            byzantine_nodes,
            scenario.is_initial_stake_even,
        )
        
        evolution_of_validators_stake_in_rounds = simulate_leader_election_n_rounds(
            ROUND_COUNT,
            validators_pool,
            scenario.reward_investment_probability,
            scenario.timeout_probability,
            scenario.got_wise_probability,
            scenario.is_weighted_leader,
        )

        write_reports(evolution_of_validators_stake_in_rounds, scenario, honest_nodes, byzantine_nodes)
    end
end

function main()
    for simulation_case in create_sim_cases()
        println(
            "Starting scenarios with: $(simulation_case.honest_nodes) honest nodes and $(simulation_case.byzantine_nodes) byzantine nodes",
        )
        @time start_simulation(
            simulation_case.honest_nodes,
            simulation_case.byzantine_nodes,
            simulation_case.scenarios,
        )
    end
end

main()
