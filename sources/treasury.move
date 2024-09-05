module testcoin::treasury {
    // === Imports ===
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::clock::{Clock};
    use std::string::{String};

    // === Errors ===
    /// Error code returned when the minting schedule has ended.
    const EMintLimitReached: u64 = 0;
    /// Error code returned when a schedule entry is malformed or does not meet
    /// validation criteria.
    const EInvalidScheduleEntry: u64 = 1;
    /// Error code returned when minting is attempted at a time not allowed by
    /// the minting schedule.
    const EInappropriateTimeToMint: u64 = 2;
    /// Error code returned when the specified index for a schedule operation
    /// is outside the allowable range.
    const EIndexOutOfRange: u64 = 3;

    // === Structs ===
    /// Represents a specific phase within the minting schedule.
    public struct Stage<phantom T> has store, copy, drop {
        /// Time shift in milliseconds from the end of the previous stage,
        /// setting the delay before this stage activates.
        timeshift_ms: u64,
        /// Number of epochs this stage will persist, each epoch represents a
        /// discrete minting event.
        number_of_epochs: u64,
        /// Duration of each epoch within this stage in milliseconds.
        epoch_duration_ms: u64,
        /// Addresses of the pools where the minted tokens are distributed.
        pools: vector<String>,
        /// Specific amounts of tokens to mint per pool per epoch.
        amounts: vector<u64>,
    }

    /// Represents a single entry within the minting schedule of the treasury.
    public struct ScheduleEntry<phantom T> has store, drop {
        /// Start time for this entry in milliseconds, indicating when the
        /// entry was activated. This field can be null if the entry has not
        /// been activated yet.
        start_time_ms: std::option::Option<u64>,
        /// Current count of completed minting epochs within this entry. Each epoch
        /// represents a single minting operation under the defined parameters.
        current_epoch: u64,
        /// Defines the operational parameters for minting including the period,
        /// distribution pools, and the amounts to be minted for each pool over
        /// the specified number of epochs.
        stage: Stage<T>,
    }

    /// Manages minting operations and schedules for a specific token.
    public struct Treasury<phantom T> has key, store{
        /// The unique identifier of the treasury.
        id: UID,
        /// Total supply of the token that can be minted.
        max_supply: u64,
        /// List of schedule entries for managing token minting.
        schedule: vector<ScheduleEntry<T>>,
        /// Capability object that grants the treasury the authority to mint
        /// tokens.
        cap: TreasuryCap<T>,
        /// Index of the active schedule entry.
        current_entry: u64,
    }

    // === Public package functions ===
    /// Creates a new treasury with a defined minting schedule.
    ///
    /// This function creates shared treasury, setting up the minting schedule
    /// and assigning the necessary capabilities for minting. It returns a
    /// ScheduleAdminCap, which grants the holder the ability to modify the
    /// minting schedule as needed.
    ///
    /// ## Parameters:
    /// - `cap`: TreasuryCap object that provides the minting capability.
    /// - `schedule`: List of ScheduleEntry objects defining the minting schedule.
    public(package) fun create<T>(
        cap: TreasuryCap<T>,
        max_supply: u64,
        schedule: vector<ScheduleEntry<T>>,
        ctx: &mut TxContext,
    ): Treasury<T> {
        Treasury {
            id: object::new(ctx),
            max_supply: max_supply,
            schedule: schedule,
            cap: cap,
            current_entry: 0,
        }
    }

    /// Creates a new schedule entry with the specified parameters.
    ///
    /// ## Parameters:
    /// - `pools`: Vector of addresses for the distribution pools.
    /// - `amounts`: Vector of amounts corresponding to each address in the pools.
    /// - `number_of_epochs`: Number of TESTCOIN epochs the entry will be active.
    /// - `epoch_duration_ms`: Duration of each epoch in milliseconds.
    /// - `timeshift_ms`: Initial time shift for the entry start in milliseconds.
    ///
    /// ## Errors:
    /// - `EInvalidScheduleEntry`: If the parameters of the new entry are invalid.
    public(package) fun create_entry<T>(
        pools: vector<String>,
        amounts: vector<u64>,
        number_of_epochs: u64,
        epoch_duration_ms: u64,
        timeshift_ms: u64,
    ): ScheduleEntry<T> {
        assert!(pools.length() == amounts.length(), EInvalidScheduleEntry);
        assert!(number_of_epochs > 0, EInvalidScheduleEntry);
        assert!(epoch_duration_ms > 0, EInvalidScheduleEntry);
        ScheduleEntry {
            stage: Stage {
                timeshift_ms: timeshift_ms,
                number_of_epochs: number_of_epochs,
                epoch_duration_ms: epoch_duration_ms,
                pools: pools,
                amounts: amounts,
            },
            start_time_ms: option::none(),
            current_epoch: 0,
        }
    }
    
    /// Replaces a schedule entry in the `Treasury`.
    ///
    /// This function updates the currently active schedule entry or subsequent
    /// entries. If the contract has been deployed and no minting has occurred,
    /// it permits replacement of any entry.
    ///
    /// ## Parameters:
    /// - `treasury`: Mutable reference to the Treasury<T> managing the minting schedule.
    /// - `index`: Index of the schedule entry to update.
    /// - `entry`: New ScheduleEntry object to replace the existing entry.
    ///
    /// ## Errors:
    /// - `EIndexOutOfRange`: If specified index is out of range or entry is irreplaceable.
    public(package) fun set_entry<T>(
        treasury: &mut Treasury<T>,
        index: u64,
        entry: ScheduleEntry<T>,
    ) {
        assert!(index < treasury.schedule.length(), EIndexOutOfRange);
        assert!(index >= treasury.current_entry, EIndexOutOfRange);
        let target_entry = &mut treasury.schedule[index];
        if (treasury.current_entry == index) {
            assert!(entry.stage.number_of_epochs > target_entry.current_epoch, EInvalidScheduleEntry);
        };
        target_entry.stage = entry.stage;
    }

    /// Inserts a new schedule entry before the specified index in the `Treasury`.
    ///
    /// This function allows the insertion of a new schedule entry at any
    /// position following the current active entry. If no minting has occurred
    /// yet, entries can be inserted at any position.
    ///
    /// ## Parameters:
    /// - `treasury`: Mutable reference to the Treasury<T> managing the minting schedule.
    /// - `index`: The position at which the new entry will be inserted.
    /// - `entry`: New ScheduleEntry object to replace the existing entry.
    ///
    /// ## Errors:
    /// - `EIndexOutOfRange`: If the specified index is out of range for insertion.
    public(package) fun insert_entry<T>(
        treasury: &mut Treasury<T>,
        index: u64,
        entry: ScheduleEntry<T>,
    ) {
        assert!(index <= treasury.schedule.length(), EIndexOutOfRange);
        assert!(treasury.current_entry == 0 || index > treasury.current_entry, EIndexOutOfRange);
        treasury.schedule.insert(entry, index);
    }

    /// Removes a schedule entry at the specified index in the `Treasury`.
    ///
    /// This function allows to remove an existing entry from the minting
    /// schedule. The function can only modify entries that follow the
    /// currently active entry unless no minting has occurred yet, in which
    /// case any entry can be removed.
    ///
    /// ## Parameters:
    /// - `treasury`: Mutable reference to the Treasury<T> managing the minting schedule.
    /// - `index`: The position from which the entry will be removed.
    /// 
    /// ## Errors
    /// - `EIndexOutOfRange`: If the specified index is out of range for removal.
    public(package) fun remove_entry<T>(treasury: &mut Treasury<T>, index: u64) {
        assert!(index < treasury.schedule.length(), EIndexOutOfRange);
        assert!(treasury.current_entry == 0 || index > treasury.current_entry, EIndexOutOfRange);
        treasury.schedule.remove(index);
    }

    /// Mints new tokens according to the predefined schedule.
    ///
    /// This function allows to mint tokens in accordance with the established
    /// minting schedule. It can be called anytime after the designated time in
    /// the schedule, except for the "zero mint," which can occur at any time
    /// after contract deployment.
    ///
    /// ## Parameters:
    /// - `treasury`: Mutable reference to the Treasury<T> managing the minting process.
    /// - `clock`: Reference to the Clock, providing the current time context.
    ///
    /// ## Errors
    /// - `EMintLimitReached`: If the minting has reached its limit or if the schedule is not set.
    /// - `EInappropriateTimeToMint`: If the mint attempt occurs outside the allowable schedule window.
    public(package) fun mint<T>(treasury: &mut Treasury<T>, clock: &Clock, ctx: &mut TxContext): (vector<String>, vector<Coin<T>>){
        assert!(treasury.schedule.length() > 0, EMintLimitReached);
        assert!(treasury.current_entry < treasury.schedule.length(), EMintLimitReached);
        let entry = &mut treasury.schedule[treasury.current_entry];
        let (pools, coins) = mint_entry(entry, treasury.max_supply, &mut treasury.cap, clock, ctx);
        if (entry.current_epoch == entry.stage.number_of_epochs) {
            let next_stage_ms = get_entry_mint_time(entry);
            treasury.current_entry = treasury.current_entry + 1;
            if (treasury.current_entry < treasury.schedule.length()) {
                let next_entry = &mut treasury.schedule[treasury.current_entry];
                let next_timeshift_ms = next_entry.stage.timeshift_ms;
                next_entry.start_time_ms = option::some(next_stage_ms + next_timeshift_ms);
            }
        };
        return (pools, coins)
    }

    // === Internal functions ===

    /// Mint coins following the specified parameters and return the time for
    /// the next stage after all epochs are minted.
    fun mint_entry<T>(
        entry: &mut ScheduleEntry<T>,
        max_supply: u64,
        cap: &mut TreasuryCap<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (vector<String>, vector<Coin<T>>) {
        if (entry.start_time_ms.is_none()) {
            entry.start_time_ms = option::some(clock.timestamp_ms());
        };
        let mint_time = get_entry_mint_time(entry);
        assert!(clock.timestamp_ms() >= mint_time, EInappropriateTimeToMint);
        let mut k = 0;
        let mut coins: vector<Coin<T>> = vector[];
        while (k < entry.stage.pools.length()) {
            let amount = entry.stage.amounts[k];
            assert!(amount <= (max_supply - coin::total_supply(cap)), EMintLimitReached);
            coins.push_back(coin::mint(cap, amount, ctx));
            k = k + 1;
        };
        entry.current_epoch = entry.current_epoch + 1;
        return (entry.stage.pools, coins)
   }

    /// Returns the mint time of the entry
    fun get_entry_mint_time<T>(entry: &ScheduleEntry<T>): u64 {
        let start_time = entry.start_time_ms.get_with_default(0);
        let time_shift = entry.stage.timeshift_ms;
        let time_elapsed_ms = entry.current_epoch * entry.stage.epoch_duration_ms;
        start_time + time_shift + time_elapsed_ms
    }
}

#[test_only]
module testcoin::treasury_tests {
    use std::string::{String};

    use testcoin::treasury::{
        ScheduleEntry,
        Self,
        Treasury, 
        EInappropriateTimeToMint,
        EIndexOutOfRange,
        EInvalidScheduleEntry,
        EMintLimitReached,
    };
    use sui::clock::{Self, Clock};
    use sui::coin::{Self};
    use sui::test_scenario::{Self, Scenario};
    use sui::test_utils;

    const PUBLISHER: address = @0xA;
    const TEST_POOL1: vector<u8> = b"test_pool1";
    const TEST_POOL2: vector<u8> = b"test_pool2";

    public struct TREASURY_TESTS has drop {}

    #[test]
    #[expected_failure(abort_code = EInvalidScheduleEntry)]
    fun test_create_entry_with_invalid_targets() {
        // The number of elements in pools does not match the number of elements in amounts.
        treasury::create_entry<TREASURY_TESTS>(vector[TEST_POOL1.to_string()], vector[], 10, 3600, 0);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidScheduleEntry)]
    fun test_create_entry_with_invalid_number_of_epochs() {
        // The number of epochs is zero.
        treasury::create_entry<TREASURY_TESTS>(vector[TEST_POOL1.to_string()], vector[100], 0, 3600, 0);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidScheduleEntry)]
    fun test_create_entry_with_invalid_epoch_duration() {
        // The epoch duration is zero.
        treasury::create_entry<TREASURY_TESTS>(vector[TEST_POOL1.to_string()], vector[100], 10, 0, 0);
    }

    #[test]
    fun test_create_entry_returns_valid_entry() {
        // Do not errors because the entry is valid.
        treasury::create_entry<TREASURY_TESTS>(vector[TEST_POOL1.to_string()], vector[100], 10, 3600, 0);
    }
    
    #[test]
    #[expected_failure(abort_code = EIndexOutOfRange)]
    fun test_set_entry_fails_for_invalid_index() {
        let mut scenario = setup_scenario(vector[]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            treasury.set_entry(0, treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 10, 3600, 0));
            test_scenario::return_shared(treasury);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EIndexOutOfRange)]
    fun test_set_entry_fails_for_already_minted_stages() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            // Fails because the stage has already finished.
            treasury.set_entry(0, treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 10, 3600, 0));
            test_scenario::return_shared(treasury);
        };
        scenario.end();
    }

    #[test]
    fun test_set_entry_changes_the_stage_parameters() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            treasury.set_entry(0, treasury::create_entry(vector[TEST_POOL1.to_string()], vector[1337], 1, 3600, 0));
            // Should mint 3117 coins
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            assert_eq_pools_and_coins(&pools, &coins, vector[TEST_POOL1.to_string()], vector[1337]);
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidScheduleEntry)]
    fun test_set_entry_fails_on_setting_number_of_epochs_less_or_equal_than_current_epoch() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 2, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            // Fails because the number of epochs is equal to the current epoch.
            treasury.set_entry(0, treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0));
            test_scenario::return_shared(treasury);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EIndexOutOfRange)]
    fun test_insert_entry_fails_on_index_out_of_range() {
        let mut scenario = setup_scenario(vector[]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            // Fails because the index is out of range.
            treasury.insert_entry(1, treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0));
            test_scenario::return_shared(treasury);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EIndexOutOfRange)]
    fun test_insert_entry_fails_on_already_minted_stages() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);

            // Fails because the index is before current stage
            treasury.insert_entry(0, treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0));

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    fun test_insert_entry_allows_to_insert_first_entry_if_the_schedule_was_not_started_yet() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            // Do not errors because the schedule was not started yet.
            treasury.insert_entry(0, treasury::create_entry(vector[TEST_POOL1.to_string()], vector[200], 1, 3600, 0));
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            assert_eq_pools_and_coins(&pools, &coins, vector[TEST_POOL1.to_string()], vector[200]);
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    fun test_insert_entry_allows_to_insert_at_the_end_of_schedule() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let mut clock: Clock = scenario.take_shared();

            // Do not errors because the index is at the end of the schedule.
            treasury.insert_entry(1, treasury::create_entry(vector[TEST_POOL1.to_string()], vector[200], 1, 3600, 0));
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            assert_eq_pools_and_coins(&pools, &coins, vector[TEST_POOL1.to_string()], vector[100]);
            destroy_pools_and_coins(pools, coins);

            clock.increment_for_testing(3600);
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            assert_eq_pools_and_coins(&pools, &coins, vector[TEST_POOL1.to_string()], vector[200]);
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EIndexOutOfRange)]
    fun test_remove_entry_fails_on_index_out_of_range() {
        let mut scenario = setup_scenario(vector[]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            // Fails because the index is out of range.
            treasury.remove_entry(3117);
            test_scenario::return_shared(treasury);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EIndexOutOfRange)]
    fun test_remove_entry_fails_on_removing_past_or_current_entries() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            // Fails because the stage was already minted
            treasury.remove_entry(0);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    fun test_remove_entry_allows_to_remove_first_entry_if_the_schedule_was_not_started_yet() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 3600, 0),
            treasury::create_entry(vector[TEST_POOL2.to_string()], vector[200], 1, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            // Do not errors because the schedule was not started yet.
            treasury.remove_entry(0);
            test_scenario::return_shared(treasury);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EMintLimitReached)]
    fun test_mint_errors_on_empty_schedule() {
        let mut scenario = setup_scenario(vector[]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    fun test_mint_creates_and_transfers_coins_to_targets_specified_in_schedule() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string(), TEST_POOL2.to_string()], vector[100, 200], 1, 3600, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            assert_eq_pools_and_coins(&pools, &coins, vector[TEST_POOL1.to_string(), TEST_POOL2.to_string()], vector[100, 200]);
            destroy_pools_and_coins(pools, coins);
            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInappropriateTimeToMint)]
    fun test_mint_fails_when_minting_time_has_not_come_yet() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 2, 1000, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();

            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            // The minting should fail because the minting time has not come yet.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EMintLimitReached)]
    fun test_mint_creates_and_transfers_coins_until_end_of_schedule(){
        let mut scenario = setup_scenario(vector[
            // The schedule contains a single entry with two epochs, each lasting 1000ms
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 2, 1000, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let mut clock: Clock = scenario.take_shared();

            // The minting for the first epoch should succeed.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            clock.increment_for_testing(1000);
            // The minting for the second epoch should succeed.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            clock.increment_for_testing(1000);
            // The minting should fail because the schedule has ended.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    // The next stage must be initiated after the minting stage is complete
    fun test_mint_starts_the_next_stage() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 1000, 0),
            treasury::create_entry(vector[TEST_POOL2.to_string()], vector[200], 1, 1000, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let mut clock: Clock = scenario.take_shared();
            // The minting for the first epoch of first stage should succeed.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            clock.increment_for_testing(1000);
            assert_eq_pools_and_coins(&pools, &coins, vector[TEST_POOL1.to_string()], vector[100]);
            destroy_pools_and_coins(pools, coins);
            // The minting for the first epoch of the second stage should succeed.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            assert_eq_pools_and_coins(&pools, &coins, vector[TEST_POOL2.to_string()], vector[200]);
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInappropriateTimeToMint)]
    // The next stage starts after duration of previous stage
    fun test_mint_fails_when_minting_time_has_not_come_yet_for_next_stage() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 1000, 0),
            treasury::create_entry(vector[TEST_POOL2.to_string()], vector[200], 1, 1000, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            // Minting must not succeed until at least 1000 ms have passed since the last epoch of the initial stage.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInappropriateTimeToMint)]
    // The next stage might have the optional time shift
    fun test_mint_fails_when_minting_time_has_not_come_yet_for_next_stage_with_time_shift() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[100], 1, 1000, 0),
            // The second stage starts 2000 ms after the end of the first stage.
            treasury::create_entry(vector[TEST_POOL2.to_string()], vector[200], 1, 1000, 2000),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let mut clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            clock.increment_for_testing(1000);
            // Minting must not succeed because the next stage has additional time shift.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EMintLimitReached)]
    fun test_mint_fails_when_max_supply_is_reached() {
        let mut scenario = setup_scenario(vector[
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[5_000], 1, 1000, 0),
            treasury::create_entry(vector[TEST_POOL1.to_string()], vector[5_001], 1, 1000, 0),
        ]);
        scenario.next_tx(PUBLISHER);
        {
            let mut treasury: Treasury<TREASURY_TESTS> = scenario.take_shared();
            let mut clock: Clock = scenario.take_shared();
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);
            clock.increment_for_testing(1000);
            // The minting should fail because the max supply is reached.
            let (pools, coins) = treasury.mint(&clock, scenario.ctx());
            destroy_pools_and_coins(pools, coins);

            test_scenario::return_shared(treasury);
            test_scenario::return_shared(clock);
        };
        scenario.end();
    }


    /// Sets up a scenario with the given minting schedule.
    fun setup_scenario(schedule: vector<ScheduleEntry<TREASURY_TESTS>>): Scenario {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            let otw = test_utils::create_one_time_witness<TREASURY_TESTS>();
            let (cap, metadata) = coin::create_currency(otw, 10, b"TST", b"Test Token", b"Test Token", option::none(), scenario.ctx());
            transfer::public_freeze_object(metadata);
            transfer::public_share_object(treasury::create(cap, 10_000, schedule, scenario.ctx()));
            clock::share_for_testing(clock::create_for_testing(scenario.ctx()));
        };
        scenario
    }

    /// Asserts that the pools and coins are equal to the expected values.
    fun assert_eq_pools_and_coins(
        pools: &vector<String>,
        coins: &vector<coin::Coin<TREASURY_TESTS>>,
        expected_pools: vector<String>,
        expected_coins: vector<u64>,
    ) {
        test_utils::assert_eq(pools.length(), expected_pools.length());
        test_utils::assert_eq(coins.length(), expected_coins.length());
        let mut i = 0;
        while (i < pools.length()) {
            test_utils::assert_eq(pools[i], expected_pools[i]);
            test_utils::assert_eq(coin::value(&coins[i]), expected_coins[i]);
            i = i + 1;
        }
    }
    
    /// Destroys the pools and coins.
    fun destroy_pools_and_coins(
        mut pools: vector<String>,
        mut coins: vector<coin::Coin<TREASURY_TESTS>>,
    ) {
        while(!pools.is_empty()) {
            pools.pop_back();
        };
        pools.destroy_empty();
        while(!coins.is_empty()) {
            let coin = coins.pop_back();
            coin.burn_for_testing();
        };
        coins.destroy_empty();
    }
}
