module testcoin::vesting_ledger {
    // === Imports ===
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use std::u64::{Self};
    use sui::object_table::{Self, ObjectTable};

    // === Constants ===

    // === Errors ===
    /// Error code indicating invalid amount in request.
    const EInvalidAmount: u64 = 1;

    // === Structs ===
    /// A single entry in the account's ledger.
    public struct AccountEntry has store {
        /// The epoch number.
        epoch: u64,
        /// The balance locked for the entry's epoch.
        balance: u64,
    }

    /// A single account in the vesting ledger.
    public struct Account<phantom T> has key, store {
        /// The unique identifier of the account.
        id: UID,
        /// The portion of deposited coins available immediately.
        instant_balance: u64,
        /// The total locked balance for the account.
        total: Balance<T>,
        /// The ledger of locked coins.
        entries: vector<AccountEntry>,
    }

    /// The vesting ledger for multiple accounts.
    public struct VestingLedger<phantom T> has key, store{
        /// The unique identifier of the ledger.
        id: UID,
        /// The number of epochs ledger tracks coins for each account.
        period: u64,
        /// Initial penalty for claiming coins.
        initial_penalty: u64,
        /// The accounts in the ledger.
        accounts: ObjectTable<address, Account<T>>
    }

    // === Public package functions ===
    public(package) fun create<T>(
        period: u64,
        initial_penalty: u64,
        ctx: &mut TxContext,
    ): VestingLedger<T> {
        VestingLedger {
            id: object::new(ctx),
            period,
            initial_penalty,
            accounts: object_table::new<address, Account<T>>(ctx),
        }
    }

    public(package) fun lock<T>(
        ledger: &mut VestingLedger<T>,
        user: address,
        coin: Coin<T>,
        current_epoch: u64,
        ctx: &mut TxContext,
    ) {
        let period = ledger.period;
        let amount = coin.value();

        let account = ledger.user_mut(user, ctx);
        coin::put(&mut account.total, coin);

        account.prune_epochs(current_epoch, period);

        let len = account.entries.length();
        if (len > 0) {
            let entry = &mut account.entries[len - 1];
            if (entry.epoch == current_epoch) {
                entry.balance = entry.balance + amount;
                return
            };
        };
        account.entries.push_back(AccountEntry {
            epoch: current_epoch,
            balance: amount,
        });
    }

    public(package) fun claim<T>(
        ledger: &mut VestingLedger<T>,
        user: address,
        mut amount: u64,
        current_epoch: u64,
        ctx: &mut TxContext,
    ): (Coin<T>, Coin<T>) {
        assert!(amount > 0, EInvalidAmount);
        let account = &mut ledger.accounts[user];
        let coin = coin::take<T>(&mut account.total, amount, ctx);

        // First get the coins from the instant balance.
        let to_claim = if (amount <= account.instant_balance) {
            amount
        } else {
            account.instant_balance
        };
        account.instant_balance = account.instant_balance - to_claim;

        amount = amount - to_claim;
        let mut i = 0;
        let len = account.entries.length();
        let mut penalty_amount: u64 = 0;
        while(i < len && amount > 0) {
            let entry = &mut account.entries[i];
            let (claimed, penalty) = entry.claim_entry(amount, ledger.initial_penalty, current_epoch, ledger.period);
            penalty_amount = penalty_amount + penalty;
            amount = amount - claimed;
            i = i + 1;
        };
        let penalty = coin::take<T>(&mut account.total, penalty_amount, ctx);
        (coin, penalty)
    }

    public(package) fun available_balance<T>(
        ledger: &VestingLedger<T>,
        user: address,
        current_epoch: u64,
    ): u64 {
        if (!ledger.accounts.contains(user)) {
            return 0
        };
        let account = &ledger.accounts[user];
        let mut total = account.instant_balance;
        let mut i = 0;
        let len = account.entries.length();
        while (i < len) {
            let entry = &account.entries[i];
            total = total + entry.claimable(ledger.initial_penalty, current_epoch, ledger.period);
            i = i + 1;
        };
        total
    }


    public(package) fun claimable(
        entry: &AccountEntry,
        initial_penalty: u64,
        current_epoch: u64,
        claim_period: u64,
    ): u64 {
        let elapsed_epochs = u64::min(current_epoch - entry.epoch, claim_period);
        let scale: u128 = 10_000_000_000;
        let scale_claim_period = scale * (claim_period as u128);
        let penalty_factor_passed_time: u128 = (initial_penalty as u128) * ((claim_period as u128) - (elapsed_epochs as u128));
        assert!(penalty_factor_passed_time <= scale_claim_period, 31337);
        let numerator_claimable: u128 = scale_claim_period - penalty_factor_passed_time;
        let claimable_u128: u128 = (entry.balance as u128) * numerator_claimable / scale_claim_period;
        let claimable: u64 = claimable_u128 as u64;
        claimable
    }

    public(package) fun claim_entry(
        entry: &mut AccountEntry,
        claim_amount: u64,
        initial_penalty: u64,
        current_epoch: u64,
        claim_period: u64,
    ): (u64, u64) {
        assert!(entry.balance <= 300000000 * 10_000_000_000, 31337);
        assert!(initial_penalty <= 10_000_000_000, 31337);
        let elapsed_epochs = u64::min(current_epoch - entry.epoch, claim_period);
        assert!(elapsed_epochs <= 1800, 31337);
        assert!(claim_period <= 1800, 31337);
        let max_claimable = entry.claimable(initial_penalty, current_epoch, claim_period);
        let claim_amount = u64::min(claim_amount, max_claimable);
        let scale: u128 = 10_000_000_000;
        let scale_claim_period = scale * (claim_period as u128);
        let penalty_factor_passed_time: u128 = (initial_penalty as u128) * ((claim_period as u128) - (elapsed_epochs as u128));
        let penalty = (claim_amount as u128 * scale_claim_period as u128) / ( scale_claim_period - penalty_factor_passed_time) - (claim_amount as u128);
        entry.balance = entry.balance - claim_amount - (penalty as u64);
        (claim_amount, penalty as u64)
    }

    public(package) fun set_vesting_period<T>(
        ledger: &mut VestingLedger<T>,
        period: u64,
    ) {
        ledger.period = period;
    }

    public(package) fun set_initial_penalty<T>(
        ledger: &mut VestingLedger<T>,
        penalty: u64,
    ) {
        ledger.initial_penalty = penalty;
    }

    // === Internal functions ===
    fun user_mut<T>(
        ledger: &mut VestingLedger<T>,
        user: address,
        ctx: &mut TxContext,
    ): &mut Account<T> {
        if (!ledger.accounts.contains(user)) {
            ledger.accounts.add(user, Account {
                id: object::new(ctx),
                instant_balance: 0,
                total: balance::zero(),
                entries: vector::empty(),
            });
        };
        &mut ledger.accounts[user]
    }

    fun prune_epochs<T>(
        account: &mut Account<T>,
        current_epoch: u64,
        period: u64,
    ) {
        let mut last_valid_epoch = 0;
        let mut i = 0;
        let len = account.entries.length();
        while (i < len) {
            let entry = &account.entries[i];
            let epoch = entry.epoch;
            let balance = entry.balance;
            if (balance > 0 && current_epoch < epoch + period) {
                if (i != last_valid_epoch) {
                    account.entries.swap(i, last_valid_epoch);
                };
                last_valid_epoch = last_valid_epoch + 1;
            };
            i = i + 1;
        };
        let mut old_items = len - last_valid_epoch;
        while (old_items > 0) {
            let AccountEntry{ epoch: _, balance } = account.entries.pop_back();
            account.instant_balance = account.instant_balance + balance;
            old_items = old_items - 1;
        };
    }

    #[test_only]
    public fun account_history_len<T>(
        ledger: &VestingLedger<T>,
        user: address,
    ): u64 {
        ledger.accounts[user].entries.length()
    }
}

#[test_only]
module testcoin::vesting_ledger_tests {
    use testcoin::vesting_ledger::{Self, EInvalidAmount};
    use sui::coin::{Self};
    use sui::test_utils;

    const USER: address = @0xB;
    const PERIOD: u64 = 10;
    const INITIAL_PENALTY: u64 = 9_000_000_000;

    public struct VESTING_LEDGER_TESTS has drop {}

    #[test]
    fun test_non_existent_user_has_zero_available_balance() {
        let ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER, 0), 0);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_more_coins_become_available_with_each_subsequent_epoch() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 100);
        test_utils::assert_eq(ledger.available_balance(USER, 1), 190);
        test_utils::assert_eq(ledger.available_balance(USER, 2), 280);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 370);
        test_utils::assert_eq(ledger.available_balance(USER, 4), 460);
        test_utils::assert_eq(ledger.available_balance(USER, 5), 550);
        test_utils::assert_eq(ledger.available_balance(USER, 6), 640);
        test_utils::assert_eq(ledger.available_balance(USER, 7), 730);
        test_utils::assert_eq(ledger.available_balance(USER, 8), 820);
        test_utils::assert_eq(ledger.available_balance(USER, 9), 910);
        test_utils::assert_eq(ledger.available_balance(USER, 10), 1000);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_summing_multiple_locks_in_single_epoch() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(100, &mut ctx), 0, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(100, &mut ctx), 0, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(100, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 30);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_locks_overlap_over_time_correctly() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 1);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 1, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 1), 2);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 2, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 2), 4);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 3, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 7);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 4, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 4), 11);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 5, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 5), 16);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 6, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 6), 22);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 7, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 7), 29);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 8, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 8), 37);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 9, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 9), 46);
        test_utils::assert_eq(ledger.available_balance(USER, 10), 55);
        test_utils::assert_eq(ledger.available_balance(USER, 11), 64);
        test_utils::assert_eq(ledger.available_balance(USER, 12), 72);
        test_utils::assert_eq(ledger.available_balance(USER, 13), 79);
        test_utils::assert_eq(ledger.available_balance(USER, 14), 85);
        test_utils::assert_eq(ledger.available_balance(USER, 15), 90);
        test_utils::assert_eq(ledger.available_balance(USER, 16), 94);
        test_utils::assert_eq(ledger.available_balance(USER, 17), 97);
        test_utils::assert_eq(ledger.available_balance(USER, 18), 99);
        test_utils::assert_eq(ledger.available_balance(USER, 19), 100);
        test_utils::destroy(ledger);
    }

    #[test]
    #[expected_failure]
    fun test_claiming_fails_for_nonexistent_account() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);

        let (_locked, _penalty) = ledger.claim(USER, 1000, 0, &mut ctx);

        test_utils::destroy(_locked);
        test_utils::destroy(_penalty);
        test_utils::destroy(ledger);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidAmount)]
    fun test_claiming_fails_for_zero_amount() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);

        let (_locked, _penalty) = ledger.claim(USER, 0, 0, &mut ctx);

        test_utils::destroy(_locked);
        test_utils::destroy(_penalty);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_claiming_locked_coins_too_soon_incurs_penalty() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 100);

        let (locked, penalty) = ledger.claim(USER, 100, 0, &mut ctx);

        test_utils::assert_eq(ledger.available_balance(USER, 0), 0);
        test_utils::assert_eq(locked.value(), 100);
        test_utils::assert_eq(penalty.value(), 900);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_partial_claiming_locked_coins_incurs_proportional_penalty() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 100);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 90);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 80);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 70);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 60);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 50);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 40);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 30);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 20);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 10);
        test_utils::assert_eq(penalty.value(), 90);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 10, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 0);
        test_utils::assert_eq(penalty.value(), 90);

        test_utils::destroy(locked);
        test_utils::destroy(penalty);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_claiming_on_uneven_period() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(3, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 100);

        let (locked, penalty) = ledger.claim(USER, 25, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 75);
        test_utils::assert_eq(penalty.value(), 225);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 25, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 50);
        test_utils::assert_eq(penalty.value(), 225);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 25, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 25);
        test_utils::assert_eq(penalty.value(), 225);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        // Still can claim all the remaining coins.
        let (locked, penalty) = ledger.claim(USER, 25, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 0);
        test_utils::assert_eq(penalty.value(), 225);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_penalty_on_claim_is_reduced_according_to_elapsed_epochs() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 100);

        // Now 40% of coins are available, because each epoch unlocks 10%.
        test_utils::assert_eq(ledger.available_balance(USER, 3), 370);

        // Claiming 100 coins now would incur only 150 coins of penalty
        // (instead of 900) since the penalty is reduced accordingly to elapsed
        // epochs.
        let (locked, penalty) = ledger.claim(USER, 100, 3, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 270);
        test_utils::assert_eq(locked.value(), 100);
        test_utils::assert_eq(penalty.value(), 170);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        test_utils::destroy(ledger);
    }

    #[test]
    fun test_no_penalty_after_all_coins_are_unlocked() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 100);
        test_utils::assert_eq(ledger.available_balance(USER, 1), 190);
        test_utils::assert_eq(ledger.available_balance(USER, 2), 280);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 370);
        test_utils::assert_eq(ledger.available_balance(USER, 4), 460);
        test_utils::assert_eq(ledger.available_balance(USER, 5), 550);
        test_utils::assert_eq(ledger.available_balance(USER, 6), 640);
        test_utils::assert_eq(ledger.available_balance(USER, 7), 730);
        test_utils::assert_eq(ledger.available_balance(USER, 8), 820);
        test_utils::assert_eq(ledger.available_balance(USER, 9), 910);
        let (locked, penalty) = ledger.claim(USER, 1000, 10, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 10), 0);
        test_utils::assert_eq(locked.value(), 1000);
        test_utils::assert_eq(penalty.value(), 0);

        test_utils::destroy(locked);
        test_utils::destroy(penalty);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_claim_happens_for_first_locks_first() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 100);

        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 1, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 1), 290);

        // Now it should be "unloked" to claim 20% of first 1000 coins and,
        // 10% of the second 1000 coins. So 300 coins in total.
        // Now we claim 100 coins, which should be taken from the first lock, so
        // 100 coins from first 1000 + 100 coins from the second 1000 must
        // remain available. And penalty must be deducted from the first 1000
        // only.

        let (locked, penalty) = ledger.claim(USER, 100, 1, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 1), 190);
        test_utils::assert_eq(locked.value(), 100);
        test_utils::assert_eq(penalty.value(), 426);

        test_utils::destroy(locked);
        test_utils::destroy(penalty);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_changing_vesting_period_changes_available_balance() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 1), 190);

        ledger.set_vesting_period(5);
        test_utils::assert_eq(ledger.available_balance(USER, 1), 280);

        test_utils::destroy(ledger);
    }

    #[test]
    fun test_pruning_old_epochs() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(4/*period*/, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 1, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 2, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 3, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 1750);
        test_utils::assert_eq(ledger.account_history_len(USER), 4);

        // Now on each subsequent lock or deposit, on new epochs, the old one
        // are pruned and recorded as instant balance.

        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 4, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 4), 2750);
        test_utils::assert_eq(ledger.account_history_len(USER), 4);

        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 5, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 5), 3750);
        test_utils::assert_eq(ledger.account_history_len(USER), 4);

        test_utils::destroy(ledger);
    }
}
