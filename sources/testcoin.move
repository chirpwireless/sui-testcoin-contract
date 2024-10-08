module testcoin::testcoin {
    // === Imports ===
    use testcoin::pool_dispatcher::{Self, PoolDispatcher};
    use testcoin::schedule::{Self};
    use testcoin::treasury::{Self, Treasury};
    use std::string::{String};
    use sui::clock::{Clock};
    use sui::coin::{Self, Coin};
    use sui::object_bag::{Self, ObjectBag};
    use sui::object_table::{Self, ObjectTable};
    use sui::pay::{Self};
    use sui::url;

    // === Errors ===
    #[allow(unused_const)]
    /// Error code indicating that a migration attempt is not considered an
    /// upgrade.
    const ENotUpgrade: u64 = 1;
    /// Error code used when a function call is made from an incompatible
    /// package version.
    const EWrongVersion: u64 = 2;

    /// Error code used when an invalid pool is used in the schedule.
    const EInvalidPool: u64 = 3;

    // === Constants ===
    /// Maximum supply of TESTCOIN tokens.
    const COIN_MAX_SUPPLY: u64 = 3_000_000_000_000_000_000;
    /// Number of decimal places for TESTCOIN coins, where 10 implies
    /// 10,000,000,000 smallest units (cents) per TESTCOIN token.
    const COIN_DECIMALS: u8 = 10;
    /// Human-readable description of the TESTCOIN token.
    const COIN_DESCRIPTION: vector<u8> = b"TESTCOIN token description";
    /// Official name of the TESTCOIN token.
    const COIN_NAME: vector<u8> = b"Testcoin";
    /// Symbol for the TESTCOIN token, aligned with ISO 4217 formatting.
    const COIN_SYMBOL: vector<u8> = b"TCON";
    /// Coin icon
    const COIN_ICON: vector<u8> = b"https://storage.googleapis.com/tcoin/tcoin.webp";
    /// Current version of the vault.
    const VAULT_VERSION: u64 = 1;
    /// Pool dispatcher component name
    const POOL_DISPATCHER: vector<u8> = b"pool_dispatcher";
    /// Treasury component name
    const TREASURY: vector<u8> = b"treasury";
    /// Depository component name
    const DEPOSITORY: vector<u8> = b"depository";

    // === Structs ===
    /// The one-time witness for the module
    public struct TESTCOIN has drop {}

    /// Administrative capability for modifying the minting schedule.
    ///
    /// This struct acts as an authorization object, enabling its holder to
    /// perform authorized actions such as modifying the minting schedule. It
    /// ensures that schedule modifications are restricted to authorized
    /// personnel only.
    public struct ScheduleAdminCap has key, store {
        /// Unique identifier for the administrative capability.
        id: UID,
    }

    /// The central registry for all contract components.
    public struct Vault has key, store {
        /// The unique identifier of the vault.
        id: UID,
        /// The registry of all contract components.
        registry: ObjectBag,
        /// Version of the vault.
        version: u64,
    }

    // === Functions ===
    /// Initialize the TESTCOIN token on the blockchain and set up the minting
    /// schedule.
    ///
    /// This function creates a new TESTCOIN token, defines its properties such
    /// as number of decimals places, symbol, name, and description, and
    /// establishes a vault for it. It also assigns an admin capability to
    /// the sender of the transaction that allows them to manage the minting
    /// schedule.
    fun init(otw: TESTCOIN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            otw,
            COIN_DECIMALS,
            COIN_SYMBOL,
            COIN_NAME,
            COIN_DESCRIPTION,
            option::some(url::new_unsafe_from_bytes(COIN_ICON)),
            ctx,
        );
        transfer::public_freeze_object(metadata);

        let mut vault = Vault {
            id: object::new(ctx),
            registry: object_bag::new(ctx),
            version: VAULT_VERSION,
        };

        vault.registry.add(POOL_DISPATCHER.to_string(), pool_dispatcher::default(ctx));
        vault.registry.add(TREASURY.to_string(), treasury::create(treasury_cap, COIN_MAX_SUPPLY, schedule::default(), ctx));
        vault.registry.add(DEPOSITORY.to_string(), object_table::new<address, Coin<TESTCOIN>>(ctx));

        vault.premint(ctx);

        transfer::transfer(ScheduleAdminCap{id:object::new(ctx)}, ctx.sender());
        transfer::share_object(vault);
    }

    /// Mints new TESTCOIN tokens according to the predefined schedule.
    ///
    /// This function allows any user to mint TESTCOIN tokens in accordance with the
    /// established minting schedule. No special capabilities are required to invoke
    /// this function. It can be called anytime after the designated time in the schedule,
    /// except for the "zero mint," which can occur at any time after contract deployment.
    ///
    /// ## Parameters:
    /// - `vault`: Mutable reference to the Vault managing the minting process.
    /// - `clock`: Reference to the Clock, providing the current time context.
    ///
    /// ## Errors
    /// - `EWrongVersion`: If the vault version does not match the VAULT_VERSION.
    /// - `EMintLimitReached`: If the minting has reached its limit or if the schedule is not set.
    /// - `EInappropriateTimeToMint`: If the mint attempt occurs outside the allowable schedule window.
    public fun mint(vault: &mut Vault, clock: &Clock, ctx: &mut TxContext) {
        assert!(vault.version == VAULT_VERSION, EWrongVersion);
        let (mut pools, mut coins) = {
            let treasury: &mut Treasury<TESTCOIN> = vault.treasury();
            treasury.mint(clock, ctx)
        };
        {
            let dispatcher: &mut PoolDispatcher = vault.pool_dispatcher();
            while(!pools.is_empty()) {
                let pool = pools.pop_back();
                let coin = coins.pop_back();
                dispatcher.transfer(pool, coin);
            };
            pools.destroy_empty();
            coins.destroy_empty();
        }

    }

    /// Replaces a schedule entry in the `Vault` of TESTCOIN tokens.
    ///
    /// This function updates the currently active schedule entry or subsequent
    /// entries. If the contract has been deployed and no minting has occurred,
    /// it permits replacement of any entry.
    ///
    /// ## Parameters:
    /// - `_`: Reference to the ScheduleAdminCap, ensuring execution by authorized users only.
    /// - `vault`: Mutable reference to the Vault managing the minting schedule.
    /// - `index`: Index of the schedule entry to update.
    /// - `pools`: Vector of addresses for the distribution pools.
    /// - `amounts`: Vector of amounts corresponding to each address in the pools.
    /// - `number_of_epochs`: Number of TESTCOIN epochs the entry will remain active.
    /// - `epoch_duration_ms`: Duration of each epoch in milliseconds.
    /// - `timeshift_ms`: Initial time shift for the entry start in milliseconds.
    ///
    /// ## Errors
    /// - `EWrongVersion`: If the vault version does not match the VAULT_VERSION.
    /// - `EIndexOutOfRange`: If specified index is out of range or entry is irreplaceable.
    /// - `EInvalidScheduleEntry`: If the parameters of the new entry are invalid.
    /// - `EInvalidPool`: If the pools specified in the entry are not valid.
    public fun set_entry(
        _: &ScheduleAdminCap,
        vault: &mut Vault,
        index: u64,
        pools: vector<String>,
        amounts: vector<u64>,
        number_of_epochs: u64,
        epoch_duration_ms: u64,
        timeshift_ms: u64,
    ) {
        assert!(vault.version == VAULT_VERSION, EWrongVersion);
        {
            let dispatcher: &PoolDispatcher = vault.pool_dispatcher();
            let mut i = 0;
            while(i < pools.length()) {
                assert!(dispatcher.contains(pools[i]), EInvalidPool);
                i = i + 1;
            };
        };
        let entry = treasury::create_entry<TESTCOIN>(pools, amounts, number_of_epochs, epoch_duration_ms, timeshift_ms);
        let treasury: &mut Treasury<TESTCOIN> = vault.treasury();
        treasury.set_entry(index, entry)
    }

    /// Inserts a new schedule entry before the specified index in the `Vault` of TESTCOIN tokens.
    ///
    /// Authorized users with the ScheduleAdminCap can insert a new entry at
    /// any position following the current active entry. If no minting has
    /// occurred since the contract's deployment, entries can be inserted at
    /// any position.
    ///
    /// ## Parameters:
    /// - `_`: Reference to the ScheduleAdminCap, ensuring execution by authorized users only.
    /// - `vault`: Mutable reference to the Vault managing the minting schedule.
    /// - `index`: The position at which the new entry will be inserted.
    /// - `pools`: Vector of addresses for the distribution pools.
    /// - `amounts`: Vector of amounts corresponding to each address in the pools.
    /// - `number_of_epochs`: Number of TESTCOIN epochs the entry will be active.
    /// - `epoch_duration_ms`: Duration of each epoch in milliseconds.
    /// - `timeshift_ms`: Initial time shift for the entry start in milliseconds.
    ///
    /// ## Errors
    /// - `EWrongVersion`: If the vault version does not match the VAULT_VERSION.
    /// - `EIndexOutOfRange`: If the specified index is out of range for insertion.
    /// - `EInvalidScheduleEntry`: If the parameters of the new entry are invalid.
    /// - `EInvalidPool`: If the pools specified in the entry are not valid.
    public fun insert_entry(
        _: &ScheduleAdminCap,
        vault: &mut Vault,
        index: u64,
        pools: vector<String>,
        amounts: vector<u64>,
        number_of_epochs: u64,
        epoch_duration_ms: u64,
        timeshift_ms: u64,
    ) {
        assert!(vault.version == VAULT_VERSION, EWrongVersion);
        {
            let dispatcher: &PoolDispatcher = vault.pool_dispatcher();
            let mut i = 0;
            while(i < pools.length()) {
                assert!(dispatcher.contains(pools[i]), EInvalidPool);
                i = i + 1;
            };
        };
        let entry = treasury::create_entry<TESTCOIN>(pools, amounts, number_of_epochs, epoch_duration_ms, timeshift_ms);
        let treasury: &mut Treasury<TESTCOIN> = vault.treasury(); 
        treasury.insert_entry(index, entry)
    }

    /// Removes a schedule entry at the specified index in the `Vault` of TESTCOIN tokens.
    ///
    /// This function allows authorized users, holding the ScheduleAdminCap, to
    /// remove an existing entry from the minting schedule. The function can
    /// only modify entries that follow the currently active entry unless no
    /// minting has occurred since the contract's deployment, in which case any
    /// entry can be removed.
    ///
    /// ## Parameters:
    /// - `_`: Reference to the ScheduleAdminCap, ensuring execution by authorized users only.
    /// - `vault`: Mutable reference to the Vault managing the minting schedule.
    /// - `index`: The position from which the entry will be removed.
    ///
    /// ## Errors
    /// - `EWrongVersion`: If the vault version does not match the VAULT_VERSION.
    /// - `EIndexOutOfRange`: If the specified index is out of range for removal.
    public fun remove_entry(_: &ScheduleAdminCap, vault: &mut Vault, index: u64) {
        assert!(vault.version == VAULT_VERSION, EWrongVersion);
        let treasury: &mut Treasury<TESTCOIN> = vault.treasury(); 
        treasury.remove_entry(index);
    }

    /// Sets the address of the pool in schedule.
    ///
    /// This function allows authorized users, holding the ScheduleAdminCap, to
    /// set the address of the pool in the schedule.
    ///
    /// ## Parameters:
    /// - `_`: Reference to the ScheduleAdminCap, ensuring execution by authorized users only.
    /// - `vault`: Mutable reference to the Vault managing the minting schedule.
    /// - `name`: The name of the pool.
    /// - `pool`: The address of the pool.
    ///
    /// ## Errors
    /// - `EWrongVersion`: If the vault version does not match the VAULT_VERSION.
    /// - `EInvalidPool`: If the pool is not valid.
    public fun set_address_pool(_: &ScheduleAdminCap, vault: &mut Vault, name: String, pool: address) {
        assert!(vault.version == VAULT_VERSION, EWrongVersion);
        let dispatcher: &mut PoolDispatcher = vault.pool_dispatcher();
        assert!(dispatcher.contains(name), EInvalidPool);
        dispatcher.set_address_pool(name, pool);
    }

    /// Claims the coin from the depository and sends it to the caller.
    ///
    /// This function lets the callers claim coins deposited into the
    /// depository by other users. The caller can claim only the amount
    /// deposited for their address and not others.
    ///
    /// ## Parameters:
    /// - `vault`: Mutable reference to the Vault managing the depository.
    /// - `amount`: The amount of coins to claim.
    /// 
    /// ## Errors
    /// - `EWrongVersion`: If the vault version does not match the VAULT_VERSION.
    entry fun claim(vault: &mut Vault, amount: u64, ctx: &mut TxContext) {
        assert!(vault.version == VAULT_VERSION, EWrongVersion);
        let depository: &mut ObjectTable<address, Coin<TESTCOIN>> = vault.depository();
        let coin = depository[ctx.sender()].split(amount, ctx);
        if (depository[ctx.sender()].value() == 0) {
            depository.remove(ctx.sender()).destroy_zero();
        };
        transfer::public_transfer(coin, ctx.sender());
    }

    #[allow(lint(self_transfer))]
    /// Deposits coins into the depository for recipients to claim later.
    /// 
    /// This function allows users to deposit coins into a recipient's depository
    /// account, merging with existing coins under the recipient's address. If
    /// no record exists for the specified recipient, a new one is created.
    /// 
    /// ## Parameters:
    /// - `vault`: Mutable reference to the Vault managing the depository.
    /// - `coins`: Vector of coins to deposit.
    /// - `recipients`: Vector of recipients to deposit coins for.
    /// - `amounts`: Vector of amounts to deposit for each recipient.
    ///
    /// ## Errors
    /// - `EWrongVersion`: If the vault version does not match the VAULT_VERSION.
    public fun deposit_batch(
        vault: &mut Vault,
        mut coins: vector<Coin<TESTCOIN>>,
        mut recipients: vector<address>,
        mut amounts: vector<u64>,
        ctx: &mut TxContext,
    ) {
        assert!(vault.version == VAULT_VERSION, EWrongVersion);

        let mut all_coins = coins.pop_back();
        pay::join_vec(&mut all_coins, coins);

        while(!recipients.is_empty()) {
            let recipient: address = recipients.pop_back();
            let amount: u64 = amounts.pop_back();
            let coin: Coin<TESTCOIN> = all_coins.split(amount, ctx);
            let depository: &mut ObjectTable<address, Coin<TESTCOIN>> = vault.depository();
            if (!depository.contains(recipient)) {
                depository.add(recipient, coin)
            } else {
                depository[recipient].join(coin)
            }
        };
        recipients.destroy_empty();
        transfer::public_transfer(all_coins, ctx.sender());
    }

    /// Unblocks minting of TESTCOIN tokens.
    ///
    /// This function allows authorized users, holding the ScheduleAdminCap, to
    /// unblock minting of TESTCOIN tokens.
    ///
    /// ## Parameters:
    /// - `_`: Reference to the ScheduleAdminCap, ensuring execution by authorized users only.
    /// - `vault`: Mutable reference to the Vault managing the minting schedule.
    ///
    /// ## Errors
    /// - `EWrongVersion`: If the vault version does not match the VAULT_VERSION.
    entry fun unblock_minting(
        _: &ScheduleAdminCap,
        vault: &mut Vault,
    ) {
        assert!(vault.version == VAULT_VERSION, EWrongVersion);

        let treasury: &mut Treasury<TESTCOIN> = vault.treasury();
        treasury.unblock_minting();
    }

    // === Private Functions ===

    /// Returns the treasury from the vault.
    fun treasury(vault: &mut Vault): &mut Treasury<TESTCOIN> {
        &mut vault.registry[TREASURY.to_string()]
    }

    /// Returns the pool dispatcher from the vault.
    fun pool_dispatcher(vault: &mut Vault): &mut PoolDispatcher {
        &mut vault.registry[POOL_DISPATCHER.to_string()]
    }

    /// Returns the depository from the vault.
    fun depository(vault: &mut Vault): &mut ObjectTable<address, Coin<TESTCOIN>> {
        &mut vault.registry[DEPOSITORY.to_string()]
    }

    /// Premints the initial supply of TESTCOIN tokens.
    fun premint(vault: &mut Vault, ctx : &mut TxContext) {
        let coin = {
            let treasury: &mut Treasury<TESTCOIN> = vault.treasury();
            treasury.premint(150_000_000_000_000_000,ctx)
        };
        {
            let dispatcher: &mut PoolDispatcher = vault.pool_dispatcher();
            dispatcher.transfer(b"liquidity".to_string(), coin);
        }
    }


    // === Test only functions ===

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(TESTCOIN{}, ctx)
    }

    #[test_only]
    public fun add_address_pool(vault: &mut Vault, name: String, pool: address) {
        let dispatcher: &mut PoolDispatcher = vault.pool_dispatcher();
        dispatcher.add_address_pool(name, pool);
    }

    #[test_only]
    public fun get_address_pool(vault: &mut Vault, name: String): address {
        let dispatcher: &PoolDispatcher = vault.pool_dispatcher();
        dispatcher.get_address_pool(name)
    }

    #[test_only] public fun coin_decimals(): u8 { COIN_DECIMALS }
    #[test_only] public fun coin_description(): vector<u8> { COIN_DESCRIPTION }
    #[test_only] public fun coin_name(): vector<u8> { COIN_NAME }
    #[test_only] public fun coin_symbol(): vector<u8> { COIN_SYMBOL }
}

#[test_only]
module testcoin::testcoin_tests {
    use testcoin::testcoin::{Self, TESTCOIN, EInvalidPool, ScheduleAdminCap, Vault};
    use std::string;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self};
    use sui::test_scenario;
    use sui::test_utils;

    const PUBLISHER: address = @0xA;
    const TEST_POOL: vector<u8> = b"test_pool";
    const NON_EXISTENT_POOL: vector<u8> = b"non_existent_pool";

    #[test]
    fun test_currency_creation() {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
        };
        scenario.next_tx(PUBLISHER);
        {
            let metadata = test_scenario::take_immutable<coin::CoinMetadata<TESTCOIN>>(&scenario);
            test_utils::assert_eq(coin::get_decimals(&metadata), testcoin::coin_decimals());
            test_utils::assert_eq(string::index_of(&string::from_ascii(metadata.get_symbol()), &string::utf8(testcoin::coin_symbol())), 0);
            test_utils::assert_eq(string::index_of(&metadata.get_name(), &string::utf8(testcoin::coin_name())), 0);
            test_utils::assert_eq(string::index_of(&metadata.get_description(), &string::utf8(testcoin::coin_description())), 0);
            test_scenario::return_immutable(metadata);
        };
        scenario.end();
    }

    #[test]
    fun test_set_entry_allows_to_modify_default_schedule()
    {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
            clock::share_for_testing(clock::create_for_testing(scenario.ctx()));
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            vault.add_address_pool(TEST_POOL.to_string(), PUBLISHER);
            test_scenario::return_shared(vault);
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let cap: ScheduleAdminCap = test_scenario::take_from_sender(&scenario);
            testcoin::unblock_minting(&cap, &mut vault);

            // Setting zero mint params
            testcoin::set_entry(&cap, &mut vault, 0, vector[TEST_POOL.to_string()], vector[1000], 1, 1000, 0);
            testcoin::mint(&mut vault, &clock, scenario.ctx());

            test_scenario::return_shared(vault);
            test_scenario::return_shared(clock);
            test_scenario::return_to_sender(&scenario, cap);
        };
        scenario.next_tx(PUBLISHER);
        {
            assert_eq_testcoin_coin(PUBLISHER, 1000, &scenario);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidPool)]
    fun test_set_entry_disallows_to_specify_non_existent_pools()
    {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
            clock::share_for_testing(clock::create_for_testing(scenario.ctx()));
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            let cap: ScheduleAdminCap = test_scenario::take_from_sender(&scenario);

            // Fails because the pool does not exist
            testcoin::set_entry(&cap, &mut vault, 0, vector[NON_EXISTENT_POOL.to_string()], vector[1000], 1, 1000, 0);

            test_scenario::return_shared(vault);
            test_scenario::return_to_sender(&scenario, cap);
        };
        scenario.end();
    }

    #[test]
    fun test_insert_entry_allows_add_new_entries_into_default_schedule()
    {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
            clock::share_for_testing(clock::create_for_testing(scenario.ctx()));
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            vault.add_address_pool(TEST_POOL.to_string(), PUBLISHER);
            test_scenario::return_shared(vault);
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let cap: ScheduleAdminCap = test_scenario::take_from_sender(&scenario);
            testcoin::unblock_minting(&cap, &mut vault);

            // inserting new zero mint stage
            testcoin::insert_entry(&cap, &mut vault, 0, vector[TEST_POOL.to_string()], vector[1000], 1, 1000, 0);
            testcoin::mint(&mut vault, &clock, scenario.ctx());

            test_scenario::return_shared(vault);
            test_scenario::return_shared(clock);
            test_scenario::return_to_sender(&scenario, cap);
        };
        scenario.next_tx(PUBLISHER);
        {
            assert_eq_testcoin_coin(PUBLISHER, 1000, &scenario);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidPool)]
    fun test_insert_entry_disallows_to_specify_non_existent_pools()
    {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
            clock::share_for_testing(clock::create_for_testing(scenario.ctx()));
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            let cap: ScheduleAdminCap = test_scenario::take_from_sender(&scenario);
            // Fails because the pool does not exist
            testcoin::insert_entry(&cap, &mut vault, 0, vector[NON_EXISTENT_POOL.to_string()], vector[1000], 1, 1000, 0);
            test_scenario::return_shared(vault);
            test_scenario::return_to_sender(&scenario, cap);
        };
        scenario.end();
    }

    #[test]
    fun test_remove_entry_allows_to_remove_entries_from_default_schedule()
    {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
            clock::share_for_testing(clock::create_for_testing(scenario.ctx()));
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            vault.add_address_pool(TEST_POOL.to_string(), PUBLISHER);
            test_scenario::return_shared(vault);
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let cap: ScheduleAdminCap = test_scenario::take_from_sender(&scenario);
            testcoin::unblock_minting(&cap, &mut vault);

            testcoin::insert_entry(&cap, &mut vault, 0, vector[TEST_POOL.to_string()], vector[1000], 1, 1000, 0);
            testcoin::insert_entry(&cap, &mut vault, 1, vector[TEST_POOL.to_string()], vector[3117], 1, 1000, 0);
            // removing first mint stage
            testcoin::remove_entry(&cap, &mut vault, 0);

            // Should mint 3117 coins
            testcoin::mint(&mut vault, &clock, scenario.ctx());

            test_scenario::return_shared(vault);
            test_scenario::return_shared(clock);
            test_scenario::return_to_sender(&scenario, cap);
        };
        scenario.next_tx(PUBLISHER);
        {
            assert_eq_testcoin_coin(PUBLISHER, 3117, &scenario);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidPool)]
    fun test_set_address_pool_disallows_to_set_non_existent_pool()
    {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            let cap: ScheduleAdminCap = test_scenario::take_from_sender(&scenario);
            // Fails because the pool does not exist
            testcoin::set_address_pool(&cap, &mut vault, NON_EXISTENT_POOL.to_string(), PUBLISHER);
            test_scenario::return_shared(vault);
            test_scenario::return_to_sender(&scenario, cap);
        };
        scenario.end();
    }

    #[test]
    fun test_set_address_pool_allows_to_set_address_of_pool()
    {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            vault.add_address_pool(TEST_POOL.to_string(), @0xDEADBEEF);
            test_scenario::return_shared(vault);
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            let cap: ScheduleAdminCap = test_scenario::take_from_sender(&scenario);
            testcoin::set_address_pool(&cap, &mut vault, TEST_POOL.to_string(), PUBLISHER);
            test_scenario::return_shared(vault);
            test_scenario::return_to_sender(&scenario, cap);
        };
        scenario.end();
    }

    #[test]
    fun test_pay_reward_allows_to_pay_claimable_rewards()
    {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
            clock::share_for_testing(clock::create_for_testing(scenario.ctx()));
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut vault: Vault = scenario.take_shared();
            let wallets = vector[@0x111, @0x222, @0x333];
            let coins = vector[
                coin::mint_for_testing<TESTCOIN>(5000, scenario.ctx()),
                coin::mint_for_testing<TESTCOIN>(5000, scenario.ctx()),
                coin::mint_for_testing<TESTCOIN>(5000, scenario.ctx()),
            ];
            testcoin::deposit_batch(&mut vault, coins, wallets, vector[1000, 2000, 3000], scenario.ctx());
            test_scenario::return_shared(vault);
        };
        scenario.next_tx(@0x111);
        {
            let mut vault: Vault = scenario.take_shared();
            testcoin::claim(&mut vault, 1000, scenario.ctx());
            test_scenario::return_shared(vault);
        };
        scenario.next_tx(@0x222);
        {
            let mut vault: Vault = scenario.take_shared();
            testcoin::claim(&mut vault, 2000, scenario.ctx());
            test_scenario::return_shared(vault);
        };
        scenario.next_tx(@0x333);
        {
            let mut vault: Vault = scenario.take_shared();
            testcoin::claim(&mut vault, 3000, scenario.ctx());
            test_scenario::return_shared(vault);
        };
        scenario.next_tx(PUBLISHER);
        {
            assert_eq_testcoin_coin(@0x111, 1000, &scenario);
            assert_eq_testcoin_coin(@0x222, 2000, &scenario);
            assert_eq_testcoin_coin(@0x333, 3000, &scenario);
            assert_eq_testcoin_coin(PUBLISHER, 9000, &scenario);
        };
        scenario.end();
    }

    /// Asserts that the value of the TESTCOIN coin held by the owner is equal to the expected value.
    fun assert_eq_testcoin_coin(owner: address, expected_value: u64, scenario: &test_scenario::Scenario) {
        test_utils::assert_eq(total_coins(owner, scenario), expected_value);
    }

    /// Returns the total value of the test coins held by the owner.
    fun total_coins(owner: address, scenario: &test_scenario::Scenario): u64 {
        let coin_ids = test_scenario::ids_for_address<coin::Coin<TESTCOIN>>(owner);
        let mut i = 0;
        let mut total = 0;
        while (i < coin_ids.length()) {
            let coin = test_scenario::take_from_address_by_id<coin::Coin<TESTCOIN>>(scenario, owner, coin_ids[i]);
            total = total + coin::value(&coin);
            test_scenario::return_to_address<coin::Coin<TESTCOIN>>(owner, coin);
            i = i + 1;
        };
        total
    }
}
