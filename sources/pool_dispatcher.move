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
        dispatcher.pools.add(KEEPERS.to_string(), @0xd85f83d08b8e98e64bd4e3513936697f2425fa9bc36c17f433e46aef4c479c9a);
        dispatcher.pools.add(ECOSYSTEM_GROWTH_POOL.to_string(), @0x9fc2d70126a9ef36d809f92f9afacdf7cb1395fb0b3e40a9a8bfb98f0c96d3df);
        dispatcher.pools.add(STRATEGIC_SUPPORTERS.to_string(), @0x6973eeb0aad8aabd9e81f8809eff57ff1085f1796357ce853772165cdba2a0fa);
        dispatcher.pools.add(TOKEN_TREASURY.to_string(), @0xf8bc181111430c80e900b7b515ee81d7f44877bd11427b784a3fd92dce390067);
        dispatcher.pools.add(TEAM.to_string(), @0xe7451e1d2e7ac6fd421b113b6871f689f3c2ccb8a4a10dc4573e82f7ad53e882);
        dispatcher.pools.add(ADVISORS.to_string(), @0xd4f29318c8656bfac19c8d2ece14560ea1b76d5db25829681a36207d17ff23be);
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
