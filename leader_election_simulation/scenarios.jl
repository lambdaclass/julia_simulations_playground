module Scenarios
using IterTools
export create_sim_cases, get_scenario_name

const EVEN_INITIAL_STAKE = [true, false]
const REINVESTMENT_PROBABILITY = [0.5, 1.0]
const TIMEOUT_PROBABILITY = [0.0, 0.5]
const GOT_WISE_PROBABILITY = [0.0, 0.50, 1.0]
const WEIGHTED_LEADER = [true, false]

struct SimScenario
    is_initial_stake_even::Bool
    reward_investment_probability::Float16
    timeout_probability::Float16
    got_wise_probability::Float16
    is_weighted_leader::Bool
end

struct SimCase
    byzantine_nodes::Int64
    honest_nodes::Int64
    scenarios::Vector{SimScenario}
end

function get_scenario_name(self::SimScenario) 
    return "$(self.is_initial_stake_even)_$(self.reward_investment_probability)_$(self.timeout_probability)_$(self.got_wise_probability)_$(self.is_weighted_leader)"
end

function create_sim_cases()
    scenarios_result = Vector{SimScenario}()

    scenarios_cases = product(
        EVEN_INITIAL_STAKE,
        REINVESTMENT_PROBABILITY,
        TIMEOUT_PROBABILITY,
        GOT_WISE_PROBABILITY,
        WEIGHTED_LEADER,
    )

    for (
        even_initial_stake,
        reinvestment_probability,
        timeout_probability,
        got_wise_probability,
        weighted_leader,
    ) in scenarios_cases
        append!(
            scenarios_result,
            [
                SimScenario(
                    even_initial_stake,
                    reinvestment_probability,
                    timeout_probability,
                    got_wise_probability,
                    weighted_leader,
                ),
            ],
        )
    end

    return [
        SimCase(20, 10, scenarios_result),
        SimCase(10, 20, scenarios_result),
        SimCase(0, 30, scenarios_result),
    ]
end
end
