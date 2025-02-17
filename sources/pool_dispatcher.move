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
    const LOCKUP: vector<u8> = b"lockup";

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
        dispatcher.pools.add(KEEPERS.to_string(), @0xa8fe52622f63be3bc2c7032d25f61a30f01d20f4ec27e71638b34c04a5299115);
        dispatcher.pools.add(ECOSYSTEM_GROWTH_POOL.to_string(), @0x2c8004e874d4c8862b27f79f4bf95aaede1157ff4d87e34911049a28a6ec876b );
        dispatcher.pools.add(STRATEGIC_SUPPORTERS.to_string(), @0xe5f3ac62faba2a915a7bb47be20f7c204fc043f7f5b49db96cbffa66c206dfa1);
        dispatcher.pools.add(TOKEN_TREASURY.to_string(), @0xa44c710a3baee57b67d53104aff0bcd22b9b7780d566357377c4f214312afadc);
        dispatcher.pools.add(TEAM.to_string(), @0xcd43e11fad9a01caad85159c9bf9aa02bbd5910eea2d6f95531d8ad1f1272ef7);
        dispatcher.pools.add(ADVISORS.to_string(), @0xee7c15989e4f071ef022b5ea27420e855c08395bec4998fc54820c9a682e84b7);
        dispatcher.pools.add(LIQUIDITY.to_string(), @0xeae12f80d9b462b60284984a3d6a216f4edcf4cc31c18842941c95fd030aa47f);
        dispatcher.pools.add(LOCKUP.to_string(), @0xefaaecff5491118ffca9090afa473c53b937a5d2beb5b566c347bd386e5a656f);
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
