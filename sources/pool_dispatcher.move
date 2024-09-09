module testcoin::pool_dispatcher {
    // === Imports ===
    use std::string::{String};
    use sui::bag::{Self, Bag};
    use sui::coin::{Coin};

    // === Constants ===
    const STRATEGIC_SUPPORTERS: vector<u8> = b"strategic_supporters";
    const KEEPERS: vector<u8> = b"keepers";
    const ECOSYSTEM_GROWTH_POOL: vector<u8> = b"ecosystem_growth_pool";
    const ADVISORS: vector<u8> = b"advisors";
    const TEAM: vector<u8> = b"team";
    const TOKEN_TREASURY: vector<u8> = b"token_treasury";
    const LIQUIDITY: vector<u8> = b"liquidity";

    // === Structs ===

    /// Manages token pools.
    public struct PoolDispatcher has key, store {
        /// The unique identifier of the pool dispatcher.
        id: UID,
        /// The pools managed by the dispatcher.
        pools: Bag,
    }

    // === Public package functions ===

    /// Creates a new pool dispatcher.
    public(package) fun default(ctx: &mut TxContext): PoolDispatcher {
        let mut dispatcher = PoolDispatcher {
            id: object::new(ctx),
            pools: bag::new(ctx),
        };
        dispatcher.pools.add(KEEPERS.to_string(), @0xedb69ffab8bb0855dd27d8e3998d3e9ba361f5c37ee6388ff3cccc01c8d8a528);
        dispatcher.pools.add(ECOSYSTEM_GROWTH_POOL.to_string(), @0x9fc2d70126a9ef36d809f92f9afacdf7cb1395fb0b3e40a9a8bfb98f0c96d3df);
        dispatcher.pools.add(STRATEGIC_SUPPORTERS.to_string(), @0x133c277c2f72e60dca3c05b8c833df501791c66796561b73912240750a28fc79);
        dispatcher.pools.add(TOKEN_TREASURY.to_string(), @0xf72dde09ede8569d7e032f9fecd26064ffe3a05cec9257bec1124220511ecb9c);
        dispatcher.pools.add(TEAM.to_string(), @0xe7451e1d2e7ac6fd421b113b6871f689f3c2ccb8a4a10dc4573e82f7ad53e882);
        dispatcher.pools.add(ADVISORS.to_string(), @0xa2b1d1dcd669fc87a06b610ef37c2945f3195cbf4dd301652d6cfab3f38faedf);
        dispatcher.pools.add(LIQUIDITY.to_string(), @0x2a95bdd5d3fa8413654ad2ab84b8ec1c1c4e19afd7f094ee35926c55674b5966);
        return dispatcher
    }

    /// Set the address of an address pool.
    public(package) fun set_address_pool(
        dispatcher: &mut PoolDispatcher,
        name: String,
        address: address,
    ) { 
        let pool: &mut address = &mut dispatcher.pools[name];
        *pool = address;
    }

    /// Transfer the coin to a pool.
    public(package) fun transfer<T>(
        dispatcher: &PoolDispatcher,
        name: String,
        obj: Coin<T>,
    ) {
        let pool: address = dispatcher.pools[name];
        transfer::public_transfer(obj, pool);
    }

    /// Returns true if the pool dispatcher contains a pool with the given name.
    public(package) fun contains(
        dispatcher: &PoolDispatcher,
        name: String,
    ): bool {
       dispatcher.pools.contains(name) 
    }

    #[test_only]
    public(package) fun add_address_pool(
        dispatcher: &mut PoolDispatcher,
        name: String,
        address: address,
    ) {
        dispatcher.pools.add(name, address);
    }

    #[test_only]
    public(package) fun get_address_pool(
        dispatcher: &PoolDispatcher,
        name: String,
    ): address {
        dispatcher.pools[name]
    }
}
