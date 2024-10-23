// Copyright (c) Seed Labs

#[allow(unused_field, unused_variable,unused_type_parameter, unused_mut_parameter)]
/// Gateway Module
module bluefin_spot::gateway {
    use sui::tx_context::{TxContext};
    use sui::coin::{Coin};
    use sui::clock::{Clock};
    use bluefin_spot::config::{GlobalConfig};
    use bluefin_spot::pool::{Pool};
    use bluefin_spot::position::{Position};


    //===========================================================//
    //                   Public Entry Methods                    //
    //===========================================================//

    /// Creates a pool
    public entry fun create_pool<CoinTypeA, CoinTypeB>(
        clock: &Clock, 
        pool_name: vector<u8>, 
        pool_icon_url: vector<u8>, 
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>, 
        tick_spacing: u32, 
        fee_basis_points: u64, 
        current_sqrt_price: u128, 
        ctx: &mut TxContext
        ){
        
        abort 0
    }
    
    //  Provides liquidity to the pool
    public entry fun provide_liquidity<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        coint_a_min: u64,
        coin_b_min: u64,
        liquidity: u128, 
        ctx: &mut TxContext) {

        abort 0

    }

    //  Provides liquidity to the pool
    public entry fun provide_liquidity_with_fixed_amount<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        amount: u64,
        coin_a_max: u64,
        coin_b_max: u64,
        is_fixed_a: bool,
        ctx: &mut TxContext) {

        abort 0

    }


    //  Remove liquidity from the pool
    public entry fun remove_liquidity<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        liquidity: u128, 
        min_coins_a: u64,
        min_coins_b: u64,
        transfer_coins_to: address,
        ctx: &mut TxContext) {


        abort 0

    }

    //  Closes the position and removes any residual liquidity and transfers to the provided address
    public entry fun close_position<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: Position,
        transfer_coins_to: address,
        ctx: &mut TxContext) {

        abort 0

    }


    /// Performs swap on the pool
    public entry fun swap_assets<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        a2b: bool,
        by_amount_in: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_max_limit: u128,
        ctx: &mut TxContext) {

        abort 0
        
    }

    /// Sample flash swap call
    public entry fun flash_swap<CoinTypeA,CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        a2b: bool,
        by_amount_in: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_max_limit: u128,
        ctx: &mut TxContext
        ) {

        abort 0

    }

    /// Allows user to collect the fees accruted on their position
    public entry fun collect_fee<CoinTypeA,CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        position: &mut Position,
        ctx: &mut TxContext
     ){
        abort 0
     }

     /// Allows user to collect the rewards accruted on their position
     public fun collect_reward<CoinTypeA, CoinTypeB, RewardCoinType>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        position: &mut Position,
        ctx: &mut TxContext
        ){

        abort 0
        
    }

    //===========================================================//
    //                        Public Methods                     //
    //===========================================================//

    /// Function to perform swap in a route
    public fun route_swap<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        a2b: bool,
        by_amount_in: bool,
        middle_step: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_max_limit: u128,
        ctx: &mut TxContext
    ): (Coin<CoinTypeA>, Coin<CoinTypeB>){

        abort 0

    }
}