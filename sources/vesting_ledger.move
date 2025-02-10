module testcoin::vesting_ledger {
    // === Imports ===
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
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
            let (claimed, penalty) = entry.claim_entry(current_epoch, ledger.period, amount);
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
            total = total + entry.claimable(current_epoch, ledger.period);
            i = i + 1;
        };
        total
    }


    public(package) fun claimable(
        entry: &AccountEntry,
        current_epoch: u64,
        claim_period: u64,
    ): u64 {
        let unlock_per_epoch = 10000000000 / claim_period;
        let elapsed_epochs = current_epoch - entry.epoch;
        let mut claimable_percentage = (elapsed_epochs + 1) * unlock_per_epoch;
        if (claimable_percentage > 10000000000) {
            claimable_percentage = 10000000000;
        };
        (entry.balance * claimable_percentage) / 10000000000
    }

    public(package) fun claim_entry(
        entry: &mut AccountEntry,
        current_epoch: u64,
        period: u64,
        amount: u64,
    ): (u64, u64) {
            let max_claimable = entry.claimable(current_epoch, period);

            let to_claim = if (amount <= max_claimable) amount else max_claimable;

            let proportional_penalty = (to_claim * (entry.balance - max_claimable)) / max_claimable;
            entry.balance = entry.balance - to_claim - proportional_penalty;

            (to_claim, proportional_penalty)
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
        test_utils::assert_eq(ledger.available_balance(USER, 1), 200);
        test_utils::assert_eq(ledger.available_balance(USER, 2), 300);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 400);
        test_utils::assert_eq(ledger.available_balance(USER, 4), 500);
        test_utils::assert_eq(ledger.available_balance(USER, 5), 600);
        test_utils::assert_eq(ledger.available_balance(USER, 6), 700);
        test_utils::assert_eq(ledger.available_balance(USER, 7), 800);
        test_utils::assert_eq(ledger.available_balance(USER, 8), 900);
        test_utils::assert_eq(ledger.available_balance(USER, 9), 1000);
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
        test_utils::assert_eq(ledger.available_balance(USER, 1), 3);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 2, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 2), 6);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 3, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 10);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 4, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 4), 15);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 5, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 5), 21);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 6, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 6), 28);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 7, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 7), 36);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 8, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 8), 45);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(10, &mut ctx), 9, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 9), 55);
        test_utils::assert_eq(ledger.available_balance(USER, 10), 64);
        test_utils::assert_eq(ledger.available_balance(USER, 11), 72);
        test_utils::assert_eq(ledger.available_balance(USER, 12), 79);
        test_utils::assert_eq(ledger.available_balance(USER, 13), 85);
        test_utils::assert_eq(ledger.available_balance(USER, 14), 90);
        test_utils::assert_eq(ledger.available_balance(USER, 15), 94);
        test_utils::assert_eq(ledger.available_balance(USER, 16), 97);
        test_utils::assert_eq(ledger.available_balance(USER, 17), 99);
        test_utils::assert_eq(ledger.available_balance(USER, 18), 100);
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
        test_utils::assert_eq(ledger.available_balance(USER, 0), 333);

        let (locked, penalty) = ledger.claim(USER, 82, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 251);
        test_utils::assert_eq(penalty.value(), 164);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 82, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 169);
        test_utils::assert_eq(penalty.value(), 164);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        let (locked, penalty) = ledger.claim(USER, 82, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 87);
        test_utils::assert_eq(penalty.value(), 164);
        test_utils::destroy(locked);
        test_utils::destroy(penalty);

        // Still can claim all the remaining coins.
        let (locked, penalty) = ledger.claim(USER, 87, 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 0);
        test_utils::assert_eq(penalty.value(), 175);
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
        test_utils::assert_eq(ledger.available_balance(USER, 3), 400);

        // Claiming 100 coins now would incur only 150 coins of penalty
        // (instead of 900) since the penalty is reduced accordingly to elapsed
        // epochs.
        let (locked, penalty) = ledger.claim(USER, 100, 3, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 300);
        test_utils::assert_eq(locked.value(), 100);
        test_utils::assert_eq(penalty.value(), 150);
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

        test_utils::assert_eq(ledger.available_balance(USER, 1), 200);
        test_utils::assert_eq(ledger.available_balance(USER, 2), 300);
        test_utils::assert_eq(ledger.available_balance(USER, 3), 400);
        test_utils::assert_eq(ledger.available_balance(USER, 4), 500);
        test_utils::assert_eq(ledger.available_balance(USER, 5), 600);
        test_utils::assert_eq(ledger.available_balance(USER, 6), 700);
        test_utils::assert_eq(ledger.available_balance(USER, 7), 800);
        test_utils::assert_eq(ledger.available_balance(USER, 8), 900);
        test_utils::assert_eq(ledger.available_balance(USER, 9), 1000);
        let (locked, penalty) = ledger.claim(USER, 1000, 9, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 9), 0);
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
        test_utils::assert_eq(ledger.available_balance(USER, 1), 300);

        // Now it should be "unloked" to claim 20% of first 1000 coins and,
        // 10% of the second 1000 coins. So 300 coins in total.
        // Now we claim 100 coins, which should be taken from the first lock, so
        // 100 coins from first 1000 + 100 coins from the second 1000 must
        // remain available. And penalty must be deducted from the first 1000
        // only.

        let (locked, penalty) = ledger.claim(USER, 100, 1, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 1), 200);
        test_utils::assert_eq(locked.value(), 100);
        test_utils::assert_eq(penalty.value(), 400);

        test_utils::destroy(locked);
        test_utils::destroy(penalty);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_changing_vesting_period_changes_available_balance() {
        let mut ctx = tx_context::dummy();
        let mut ledger = vesting_ledger::create<VESTING_LEDGER_TESTS>(PERIOD, INITIAL_PENALTY, &mut ctx);
        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 0, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 100);

        ledger.set_vesting_period(5);
        test_utils::assert_eq(ledger.available_balance(USER, 0), 200);

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
        test_utils::assert_eq(ledger.available_balance(USER, 3), 2500);
        test_utils::assert_eq(ledger.account_history_len(USER), 4);

        // Now on each subsequent lock or deposit, on new epochs, the old one
        // are pruned and recorded as instant balance.

        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 4, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 4), 3500);
        test_utils::assert_eq(ledger.account_history_len(USER), 4);

        ledger.lock(USER, coin::mint_for_testing<VESTING_LEDGER_TESTS>(1000, &mut ctx), 5, &mut ctx);
        test_utils::assert_eq(ledger.available_balance(USER, 5), 4500);
        test_utils::assert_eq(ledger.account_history_len(USER), 4);

        test_utils::destroy(ledger);
    }
}
