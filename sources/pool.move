// Copyright (c) Seed Labs

#[allow(unused_field, unused_variable,unused_type_parameter, unused_mut_parameter)]

/// Pool Module
/// This is the core module that houses the add/remove liquidty and swap functionality.
/// The gateway invokes methods from this module to expose public entry method
/// The module makes use of structs defined in Position, Oracel and Tick module to manage
/// protocol state and perform aforementioned actions of liquidity and swap
module bluefin_spot::pool {
    use sui::object::{UID, ID};
    use sui::balance::{Balance};
    use sui::tx_context::{TxContext};
    use std::string::{String};
    use sui::clock::{Clock};
    use bluefin_spot::config::{GlobalConfig};
    use bluefin_spot::position::{Position};
    use bluefin_spot::tick::{TickManager};
    use bluefin_spot::oracle::{ObservationManager};
    use integer_mate::i32::{I32};
    

    //===========================================================//
    //                           Structs                         //
    //===========================================================//

    /// Represents a pool
    struct Pool<phantom CoinTypeA, phantom CoinTypeB> has key, store {
        // Id of the pool
        id: UID,
        // The name of the pool
        name: String,
        // Amount of Coin A locked in pool
        coin_a: Balance<CoinTypeA>,
        // Amount of Coin B locked in pool
        coin_b: Balance<CoinTypeB>,
        // The fee in basis points. 1 bps is represented as 100, 5 as 500
        fee_rate: u64,
        // the percentange of fee that will go to protocol
        protocol_fee_share: u64,        
        // Variable to track the fee accumulated in coin A 
        fee_growth_global_coin_a: u128,
        // Variable to track the fee accumulated in coin B 
        fee_growth_global_coin_b: u128,
        // Variable to track the accrued protocol fee of coin A
        protocol_fee_coin_a: u64,
        // Variable to track the accrued protocol fee of coin B
        protocol_fee_coin_b: u64,
        // The tick manager
        ticks_manager: TickManager,
        // The observations manager
        observations_manager: ObservationManager,
        // Current sqrt(P) in Q96 notation
        current_sqrt_price: u128,
        // The current tick index
        current_tick_index: I32,
        // The amount of liquidity (L) in the pool currently
        liquidity: u128,
        // Vector holding the information for different pool rewards
        reward_infos: vector<PoolRewardInfo>,
        // Is the pool paused
        is_paused: bool,
        // url of the pool logo
        icon_url: String,
        // position index number
        position_index: u128,
        // a incrementer, updated every time pool state is changed
        sequence_number: u128,
    }

    /// Represents reward configs inside a pool
    struct PoolRewardInfo has copy, drop, store {
        // symbol of reward coin
        reward_coin_symbol: String,
        // decimals of the reward coin
        reward_coin_decimals: u8,
        // type string of the reward coin
        reward_coin_type: String,
        // last time the data of this coin was changed.
        last_update_time: u64, 
        //timestamp at which the rewards will finish
        ended_at_seconds: u64,  
        // total coins to be emitted 
        total_reward: u64, 
        // total reward collectale at the moment 
        total_reward_allocated: u64, 
        // amount of reward to be emitted per second
        reward_per_seconds: u128, 
        // global values used to ditribute rewards
        reward_growth_global: u128, 
    }

    /// Represents a swap result. It is used in `calculate_swap_result` and `swap_in_pool` method
    struct SwapResult has copy, drop {
        /// True if position is a2b
        a2b: bool,
        /// True if the amount speicified for swap is input amount
        by_amount_in: bool,
        /// The initial amount specified
        amount_specified: u64,
        /// The amount specified remaining after the swap calculations
        amount_specified_remaining: u64,
        /// The amount of input/output calculated 
        amount_calculated: u64,
        /// The fee growth global of Coin A or B depending on the direciton of swap
        fee_growth_global: u128,
        /// The amount of fee paid as result of the swap
        fee_amount: u64,
        /// The amount of fee earned by the protocol
        protocol_fee: u64,
        /// The price of the pool before the swap
        start_sqrt_price: u128,
        /// The price of the pool after the swap
        end_sqrt_price: u128,
        /// The current tick index of pool after the swap
        current_tick_index: I32,
        /// True if the swap could only be performed partially
        is_exceed: bool,
        /// The liquidity of the pool before the swap
        starting_liquidity: u128,
        /// The liquidity of the pool after the swap
        liquidity: u128,
        /// The number of steps (ticks hopped) during swap calculations
        steps: u64,
        //// The result calculated at each swap step
        step_results: vector<SwapStepResult>,
    }

    /// Represents the swap result calcualted at each step/tick during
    /// swap amount calculations
    struct SwapStepResult has copy, drop, store {
        tick_index_next: I32,
        initialized: bool,
        sqrt_price_start: u128,
        sqrt_price_next: u128,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        remaining_amount: u64,
    }

    /// The Flash swap receipt. This is a `hot potatoe` and must 
    /// be paid/destroyed before the completion of transaction
    struct FlashSwapReceipt<phantom CoinTypeA, phantom CoinTypeB> {
        pool_id: ID,
        a2b: bool,
        pay_amount: u64,
    }


    //===========================================================//
    //                      Public Functions                     //
    //===========================================================//
    
    /// Allows caller to create a pool on Bluefin spot
    /// Any one can invoke the method to create a pool. Note that the creator can only specify
    /// the fee bases points, the protocol fee % of the fee is fixed to 25% and can not be changed by the creator.
    /// 
    /// Parameters:
    /// - clock              : Sui clock object
    /// - pool_name          : The name of the pool. The convention used on bluefin spot is `CoinA-CoinB` 
    /// - icon_url      : The url to image to be shown on the position NFT of the pool (can be empty as well `""`)
    /// - coin_a_symbol      : The symbol of coin A of the pool. The data is emitted and not stored on pool or the protocol
    /// - coin_a_decimals    : The number of decimals the Coin A has. The data is emitted and not stored on pool or the protocol 
    /// - coin_a_url         : The url of the coin A token metadata or icon or anything else a user creating the 
    ///                        pool might be interested in getting as part of the pool creation event. 
    ///                        The data is emitted and not stored on pool or the protocol
    /// - coin_b_symbol      : The symbol of coin B of the pool. The data is emitted and not stored on pool or the protocol
    /// - coin_b_decimals    : The number of decimals the Coin B has. The data is emitted and not stored on pool or the protocol
    /// - coin_a_url         : The url of the coin A token metadata or icon or anything else a user creating the 
    ///                        pool might be interested in getting as part of the pool creation event. 
    ///                        The data is emitted and not stored on pool or the protocol
    /// - tick_spacing       : An unsigned number representing the tick spacing supported by the pool
    /// - fee_rate           : The maount of fee the pool charges per swap. The fee is represented 
    ///                        in 1e6 format. 1 bips is 1e3, 2.5 bps is 2.5*1e3 and so on.
    /// - current_sqrt_price : The starting sqrt price of the pool
    /// - ctx                : Murable reference to caller's transaction context
    /// 
    /// Events Emitted       : PoolCreated
    public fun new<CoinTypeA, CoinTypeB>(
        clock: &Clock, 
        pool_name: vector<u8>, 
        icon_url: vector<u8>,
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>, 
        tick_spacing: u32,
        fee_rate: u64,
        current_sqrt_price: u128,
        ctx: &mut TxContext) {
        abort 0
    }

    /// Allows caller to provide liquidity to a pool on exchange without specifying the 
    /// exact coin A or coin B amounts. 
    /// @notice The method does not performs slippage check. The caller must have those checks implemented on their end.abort
    /// If the input `balance_a` and `balance_b` to the call are > required amount, the residual amount is returned back
    /// 
    /// Parameters:
    /// - clock              : Sui clock object
    /// - protocol_config    : The `config::GlobalConfig` object used for version verification
    /// - pool               : Mutable reference to the pool to which liquidity is to be provided
    /// - position           : The position to which the liquidity is being provided
    /// - balance_a          : The balance object of coin A. This should be equald to the 
    ///                        amount (including slippage) that user intends to provide to the pool
    /// - balance_b          : The balance object of coin B. This should be equald to the 
    ///                        amount (including slippage) that user intends to provide to the pool
    /// - liquidity          : The amount of liquidity to provide
    /// 
    /// Events Emitted       : LiquidityProvided
    /// 
    /// Returns              : 1. Amount of coin A provided to pool
    ///                        2. Amount of coin B provided to pool
    ///                        3. Residual balance of Coin A
    ///                        4. Residual balance of Coin B
    public fun add_liquidity<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        balance_a: Balance<CoinTypeA>,
        balance_b: Balance<CoinTypeB>,
        liquidity: u128): (u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>) {        
        abort 0
    }


    /// Allows caller to provide liquidity to a pool on exchange with a fixed amount of eithee Coin A or Coin B
    /// The liquidity is computed based on the input amount. 
    /// @notice The method does not performs slippage check. The caller must have those checks implemented on their end
    /// If the input `balance_a` and `balance_b` to the call are > required amount, the residual amount is returned back
    /// 
    /// Parameters:
    /// - clock              : Sui clock object
    /// - protocol_config    : The `config::GlobalConfig` object used for version verification
    /// - pool               : Mutable reference to the pool to which liquidity is to be provided
    /// - position           : The position to which the liquidity is being provided
    /// - balance_a          : The balance object of coin A. This should be equald to the 
    ///                        amount (including slippage) that user intends to provide to the pool
    /// - balance_b          : The balance object of coin B. This should be equald to the 
    ///                        amount (including slippage) that user intends to provide to the pool
    /// - amount             : The amount of Coin A or Coin B to be provided
    /// - is_fixed_a         : True if the amount provided belongs to token A
    /// 
    /// 
    /// Events Emitted       : LiquidityProvided
    /// 
    /// Returns              : 1. Amount of coin A provided to pool
    ///                        2. Amount of coin B provided to pool
    ///                        3. Residual balance of Coin A
    ///                        4. Residual balance of Coin B
    public fun add_liquidity_with_fixed_amount<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        balance_a: Balance<CoinTypeA>,
        balance_b: Balance<CoinTypeB>,
        amount: u64,
        is_fixed_a: bool ): (u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>) {
        abort 0
    }

    
    /// Allows caller to remove liquidity from a pool from given position. The input is the amount of liquidity
    /// user wants the remove. The coin A and coin B amounts are calculated and returned as balances by the method.
    /// The caller must dispatch the returned balances to their desitnation
    /// 
    /// Parameters:
    /// - protocol_config    : The `config::GlobalConfig` object used for version verification
    /// - pool               : Mutable reference to the pool on which the position exist
    /// - position           : The position from which the liquidity is to be removed
    /// - liquidity          : The amount of liquidity to remove
    /// - clock              : Sui clock object
    /// 
    /// Events Emitted       : LiquidityRemoved
    /// 
    /// Returns              : 1. Amount of coin A provided rempved from pool
    ///                        2. Amount of coin B provided removed from pool
    ///                        3. Balnace of Coin A equal to Coin A amount returned above
    ///                        4. Balnace of Coin B equal to Coin B amount returned above
    public fun remove_liquidity<CoinTypeA, CoinTypeB>(
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        liquidity: u128,
        clock: &Clock ) : (u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>) {   
        abort 0
    }

    /// Allows caller to swap assets using the provided pool.
    /// 
    /// Parameters:
    /// - clock                 : Sui clock object
    /// - protocol_config       : The `config::GlobalConfig` object used for version verification
    /// - pool                  : Mutable reference to the pool on which to perform swap
    /// - balance_a             : The balance object of coin A. If the swap direction is b2a, this will be ZERO
    /// - balance_b             : The balance object of coin B. If the swap direction is a2b, this will be ZERO
    /// - a2b                   : True if direction of swap is from token A to B
    /// - by_amount_in          : True if the provided amount is the amount of input token
    /// - amount                : The input/output amount of token
    /// - amount_limit          : The max amount of input token to be used or the min amount of output tokens expected from swap
    /// - sqrt_price_max_limit  : The max price limit to hit during swap ( Max slippage )
    /// 
    /// Events Emitted          : AssetSwap
    /// 
    /// Returns                 : 1. Balance of asset A
    ///                           2. Balance of asset B
    public fun swap<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        balance_a: Balance<CoinTypeA>,
        balance_b: Balance<CoinTypeB>,
        a2b: bool,
        by_amount_in:bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_max_limit: u128,): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
        abort 0
    }

    /// A public getter method to calculate the swap results. This does not modify the state of the protocol and perfomrs the same
    /// swap calculation that `swap_asset` method does. 
    /// 
    /// Parameters:
    /// - pool                  : Non Mutable reference to the pool on which to compute swap results
    /// - a2b                   : True if direction of swap is from token A to B
    /// - by_amount_in          : True if the provided amount is the amount of input token
    /// - amount                : The input/output amount of token
    /// - sqrt_price_max_limit  : The max price limit to hit during swap ( Max slippage )
    /// 
    /// Events Emitted          : SwapResult
    /// 
    /// Returns                 : SwapResult
    public fun calculate_swap_results<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>,
        a2b: bool,
        by_amount_in: bool,
        amount:u64, 
        sqrt_price_max_limit: u128): SwapResult {
        abort 0
    }


    /// Allows caller to perform a flash swap. The underlying maths is same as the `swap_asset` method
    /// But the function does not require a blanace object for coin A or B to be presented to perform a swap.
    /// The method returns a hot potatoe  `FlashSwapReceipt` that along with the swapped balances. The user must
    /// pay the receipt within the same transaction of taking the swap loan.
    /// 
    /// Parameters:
    /// - clock                 : Sui clock object
    /// - protocol_config       : The `config::GlobalConfig` object used for version verification
    /// - pool                  : Mutable reference to the pool on which to perform the flash swap
    /// - a2b                   : True if direction of swap is from token A to B
    /// - by_amount_in          : True if the provided amount is the amount of input token
    /// - amount                : The input/output amount of token
    /// - sqrt_price_max_limit  : The max price limit to hit during swap ( Max slippage )
    /// 
    /// Events Emitted          : AssetSwap
    /// 
    /// Returns                 : 1. Balance of asset A
    ///                           2. Balance of asset B
    ///                           3. FlashSwapReceipt
    public fun flash_swap<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        a2b: bool,
        by_amount_in:bool,
        amount: u64,
        sqrt_price_max_limit: u128,
    ) : (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>) {
        abort 0
    }

    /// Allows caller to pay the debt taken using `flash_swap` method.
    /// It consumes the `FlashSwapReceipt` and takes the balance equal to debt owes to protocol
    /// and deposits it to pool reserves and destroys the receipt. 
    /// 
    /// Parameters:
    /// - protocol_config       : The `config::GlobalConfig` object used for version verification
    /// - pool                  : Mutable reference to the pool from which flash swap was taken
    /// - balance_a             : Balance of Asset A. If flash swap was a2b then it should have the balance equal to `receipt.amount`
    /// - balance_b             : Balance of Asset B. If flash swap was b2 then it should have the balance equal to `receipt.amount`
    /// - receipt               : The flash swap receipt. This will be destroyed by the function
    public fun repay_flash_swap<CoinTypeA, CoinTypeB>(
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        balance_a: Balance<CoinTypeA>, 
        balance_b: Balance<CoinTypeB>, 
        receipt: FlashSwapReceipt<CoinTypeA, CoinTypeB>) {
        abort 0
    } 

    /// Allows caller to open a position on a pool. The position opened is returned by the method
    /// 
    /// Parameters:
    /// - protocol_config       : The `config::GlobalConfig` object used for version verification
    /// - pool                  : Mutable reference to the pool on which the position is being opened
    /// - lower_tick_bits       : The unsigned bits of the lower tick. Ticks are represented as 2^31 with the MSB bit being used for sign
    /// - upper_tick_bits       : The unsigned bits of the lower tick. Ticks are represented as 2^31 with the MSB bit being used for sign
    /// - ctx                   : Murable reference to caller's transaction context
    /// 
    /// Events Emitted          : PositionOpened
    /// 
    /// Returns                 : Created Position
    public fun open_position<CoinTypeA, CoinTypeB>(
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        lower_tick_bits: u32, 
        upper_tick_bits: u32, 
        ctx: &mut TxContext): Position {
        abort 0
    }

    /// Allows caller to close an existing position on a pool. If the position has any residual fees accrued or liquidity
    /// it will be returned by the method and the position object/NFT is destroyed.
    /// @notice the uer must remove all the rewards accured in their position before closing it. This method will
    /// revert if the user has reidual rewards in their position.
    /// 
    /// Parameters:
    /// - clock                 : Sui clock object
    /// - protocol_config       : The `config::GlobalConfig` object used for version verification
    /// - pool                  : Mutable reference to the pool on which the position is being closed
    /// - position              : The object of the position being closed.
    /// 
    /// Events Emitted          : PositionClosed | LiquidityRemoved | UserFeeCollected
    public fun close_position<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        position: Position): (Balance<CoinTypeA>, Balance<CoinTypeB>){
        abort 0
    }    


    /// Allows user to collect the fees accruted on their position. 
    /// The fees for both coin A and B are collected and returned from the method as coin balances
    /// 
    /// Parameters:
    /// - clock                 : Sui clock object
    /// - protocol_config       : The `config::GlobalConfig` object used for version verification
    /// - pool                  : Mutable reference to the pool on which the position exists
    /// - position              : The position for which the fee is to be collected
    /// 
    /// Events Emitted          : UserFeeCollected
    /// 
    /// Returns                 : 1. Amount of Coin A fee collected
    ///                           2. Amount of Coin B fee collected
    ///                           3. Coin A balance equal to Coin A amount
    ///                           4. Coin B balance equal to Coin B amount
    public fun collect_fee<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position ):( u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>){       
        abort 0
    }


    /// Allows user to collect the reward accrued on their position. Only the reward of provided `RewardCoinType` are collected
    /// The user must call this method separately for each reward coin they want to collect
    /// 
    /// Parameters:
    /// - clock                 : Sui clock object
    /// - protocol_config       : The `config::GlobalConfig` object used for version verification
    /// - pool                  : Mutable reference to the pool on which the position exists
    /// - position              : The position for which the rewards are to be collected
    /// 
    /// Events Emitted          : UserRewardCollected
    /// 
    /// Returns                 : The balance of the accrued reward coins
    public fun collect_reward<CoinTypeA, CoinTypeB, RewardCoinType>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position): Balance<RewardCoinType> {
        abort 0
    }

    /// Returns the amount to be paid for the flash swap
    public fun swap_pay_amount<CoinTypeA, CoinTypeB>(receipt: &FlashSwapReceipt<CoinTypeA, CoinTypeB>) : u64 {
        receipt.pay_amount
    }

    /// Returns the address of current pool' manager
    public fun get_pool_manager<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): address {
        abort 0
    }

    /// Returns the accrued protocol fee for coin A
    public fun get_protocol_fee_for_coin_a<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
        pool.protocol_fee_coin_a
    }

    /// Returns the accrued protocol fee for coin B
    public fun get_protocol_fee_for_coin_b<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
        pool.protocol_fee_coin_b
    }

    public fun liquidity<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>
    ): u128 {
        pool.liquidity
    }

    public fun current_sqrt_price<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>
    ): u128 {
        pool.current_sqrt_price
    }

    public fun current_tick_index<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>
    ): I32 {
        pool.current_tick_index
    }

    public fun sequence_number<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>
    ): u128 {
        pool.sequence_number
    }

    public fun verify_pool_manager<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>, manager: address): bool {
        abort 0
    }

    public fun coin_reserves<CoinTypeA, CoinTypeB> (pool: &Pool<CoinTypeA, CoinTypeB>): (u64, u64){
        abort 0
    }
}
