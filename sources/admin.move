// Copyright (c) Seed Labs

#[allow(unused_field, unused_variable,unused_type_parameter, unused_mut_parameter)]
/// Module for managing a position
module bluefin_spot::admin {
    use sui::tx_context::{TxContext};
    use std::string::{String};
    use sui::clock::{Clock};
    use sui::coin::{Coin};
    use bluefin_spot::config::{GlobalConfig};
    use bluefin_spot::pool::{Pool};


    /// initializes a reward for a given pool
    /// Parameters:
    /// - protocol_config: glocal config object for spot protocol
    /// - pool : pool object
    /// - start_time: start time for the rewards that are to be initilized (must be in future)
    /// - active_for_seconds: seconds for which rewards are to be allocated.
    /// - reward_coin: coin Object with balance for the reward that is to be initialized
    /// - blue_reward_amount: amount of blue rewards (should be 0 in case the reward to be initialized is not Blue Coin)
    /// - clock : sui clock object
    /// 
    public entry fun initialize_pool_reward<CoinTypeA, CoinTypeB, RewardCoinType>(
            protocol_config: &GlobalConfig,
            pool: &mut Pool<CoinTypeA, CoinTypeB>, 
            start_time: u64,
            active_for_seconds: u64,
            reward_coin: Coin<RewardCoinType>, 
            reward_coin_symbol: String,
            reward_coin_decimals: u8,
            blue_reward_amount: u64,
            clock: &Clock,
            ctx: &mut TxContext) {
            
            abort 0
        }

    /// updates the emission for the initialized reward in pool
    /// Parameters:
    /// - protocol_config: glocal config object for spot protocol
    /// - pool : pool object
    /// - active_for_seconds: seconds for which rewards are to be allocated.
    /// - reward_coin: coin Object with balance for the reward that is to be initialized
    /// - blue_reward_amount: amount of blue rewards (should be 0 in case the reward to be initialized is not Blue Coin)
    /// - clock : sui clock object
    /// 
    public entry fun update_pool_reward_emission<CoinTypeA, CoinTypeB, RewardCoinType>(
        protocol_config: &GlobalConfig,
        pool: &mut  Pool<CoinTypeA, CoinTypeB>, 
        active_for_seconds: u64, 
        reward_coin: Coin<RewardCoinType>,
        blue_reward_amount: u64,
        clock: &Clock, 
        ctx: &TxContext) {

        abort 0
    }
    
    /// adds additional seconds to the emission for the initialized reward in pool
    /// Parameters:
    /// - protocol_config: glocal config object for spot protocol
    /// - pool : pool object
    /// - seconds_to_add: seconds to increase for reward emission.
    /// - clock : sui clock object
    /// 
    public fun add_seconds_to_reward_emission<CoinTypeA, CoinTypeB, RewardCoinType>(
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        seconds_to_add: u64, 
        clock: &Clock, 
        ctx: &TxContext) {

        abort 0
    }
}