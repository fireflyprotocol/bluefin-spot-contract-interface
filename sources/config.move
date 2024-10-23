// Copyright (c) Seed Labs

#[allow(unused_field, unused_variable,unused_type_parameter, unused_mut_parameter)]
/// Module for managing a position
module bluefin_spot::config {
    use sui::object::{UID};
    use integer_mate::i32::{I32};


    //===========================================================//
    //                         Constants                         //
    //===========================================================//

    /// The protocol's config
    struct GlobalConfig has key, store {
        id: UID,
        min_tick: I32,
        max_tick: I32,
        version: u64,
        reward_managers: vector<address>
    }



    //===========================================================//
    //                      Public Methods                       //
    //===========================================================//

    /// Returns the min/max tick allowed
    public fun get_tick_range(config: &GlobalConfig): (I32, I32){
        abort 0
    }

    /// Assets if the config vesion matches the protocol version
    public fun verify_version(config: &GlobalConfig) {
        abort 0
    }

    /// checks if the given address is the whitelisted rewards manager
    public fun verify_reward_manager(config: &GlobalConfig, manager: address) : bool {
       abort 0
    }

}