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
        dispatcher.pools.add(KEEPERS.to_string(), @0x67f0c9fab4b0ec5877fe83503a3b5a91b603d0e6492a7f1089d95a154c0dd7d3);
        dispatcher.pools.add(ECOSYSTEM_GROWTH_POOL.to_string(), @0x927febeb2654b63269ca67683f9a214f021ee09c800005c04a3e33a347a0ffa3);
        dispatcher.pools.add(STRATEGIC_SUPPORTERS.to_string(), @0x493b6b57bb2af12602a1108d6616c839a990940d728e7727b5c4fa172662f4eb);
        dispatcher.pools.add(TOKEN_TREASURY.to_string(), @0x4f4cc0b3d0941707538bdd36fee82b76ee9d6805ac19508d37cff7fe0c5114b2);
        dispatcher.pools.add(TEAM.to_string(), @0x6245be6621f4acb7fedb4ea2a1a25db6bee5ac4b19d37ef11848aa42d35155f8);
        dispatcher.pools.add(ADVISORS.to_string(), @0x69f0e03cd4f1f09e75e23362c15e07513effe7a01b18ac4bffbd5ac897bf53f0);
        dispatcher.pools.add(LIQUIDITY.to_string(), @0x795e2e8bd2b39e70ff355c9d3f92657bf627ca1de98724da6c560dc834d748fe);
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
