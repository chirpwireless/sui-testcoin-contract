module testcoin::vesting_ledger {
    // === Imports ===
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
    public struct Account has key, store {
        /// The unique identifier of the account.
        id: UID,
        /// The portion of deposited coins available immediately.
        instant_balance: u64,
        /// The ledger of locked coins.
        entries: vector<AccountEntry>,
    }

    /// The vesting ledger for multiple accounts.
    public struct VestingLedger has key, store{
        /// The unique identifier of the ledger.
        id: UID,
        /// The number of epochs ledger tracks coins for each account.
        period: u64,
        /// The current epoch number.
        current_epoch: u64,
        /// The accounts in the ledger.
        accounts: ObjectTable<address, Account>
    }

    // === Public package functions ===
    public(package) fun create(
        period: u64,
        ctx: &mut TxContext,
    ): VestingLedger {
        VestingLedger {
            id: object::new(ctx),
            period,
            current_epoch: 0,
            accounts: object_table::new<address, Account>(ctx),
        }
    }

    public(package) fun deposit(
        ledger: &mut VestingLedger,
        user: address,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        let account = ledger.user_mut(user, ctx);
        account.instant_balance = account.instant_balance + amount;
    }

    public(package) fun lock(
        ledger: &mut VestingLedger,
        user: address,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        let current_epoch = ledger.current_epoch;
        let period = ledger.period;
        let account = ledger.user_mut(user, ctx);
        account.prune_epochs(current_epoch, period);
        let mut i = 0;
        let len = account.entries.length();
        while (i < len) {
            let entry = &mut account.entries[i];
            if (entry.epoch == current_epoch) {
                entry.balance = entry.balance + amount;
                return
            };
            i = i + 1;
        };
        account.entries.push_back(AccountEntry {
            epoch: current_epoch,
            balance: amount,
        });
    }

    public(package) fun claim(
        ledger: &mut VestingLedger,
        user: address,
        mut amount: u64,
    ): u64 {
        assert!(amount > 0, EInvalidAmount);
        let current_epoch = ledger.current_epoch;
        let unlock_per_epoch = 100 / ledger.period;
        let account = &mut ledger.accounts[user];
        let to_claim = if (amount <= account.instant_balance) {
            amount
        } else {
            account.instant_balance
        };
        account.instant_balance = account.instant_balance - to_claim;
        amount = amount - to_claim;
        let mut i = 0;
        let len = account.entries.length();
        let mut penalty: u64 = 0;
        while(i < len && amount > 0) {
            let entry = &mut account.entries[i];
            let elapsed_epochs = current_epoch - entry.epoch;
            let mut claimable_percentage = (elapsed_epochs + 1) * unlock_per_epoch;
            if (claimable_percentage > 100) {
                claimable_percentage = 100;
            };

            let max_claimable = (entry.balance * claimable_percentage) / 100;
            let to_claim = if (amount <= max_claimable) amount else max_claimable;
            let proportional_penalty = (to_claim * (entry.balance - max_claimable)) / max_claimable;
            entry.balance = entry.balance - to_claim - proportional_penalty;
            penalty = penalty + proportional_penalty;
            amount = amount - to_claim;

            i = i + 1;
        };
        penalty
    }

    public(package) fun available_balance(
        ledger: &VestingLedger,
        user: address,
    ): u64 {
        if (!ledger.accounts.contains(user)) {
            return 0
        };
        let unlock_per_epoch = 100 / ledger.period;
        let account = &ledger.accounts[user];
        let mut total = account.instant_balance;
        let mut i = 0;
        let len = account.entries.length();
        while (i < len) {
            let entry = &account.entries[i];
            let elapsed_epochs = ledger.current_epoch - entry.epoch;
            let mut claimable_percentage = (elapsed_epochs + 1) * unlock_per_epoch;
            if (claimable_percentage > 100) {
                claimable_percentage = 100;
            };
            total = total + ((entry.balance * claimable_percentage) / 100);
            i = i + 1;
        };
        total
    }

    public(package) fun advance_epoch(
        ledger: &mut VestingLedger,
    ) {
        ledger.current_epoch = ledger.current_epoch + 1;
    }

    public(package) fun set_vesting_period(
        ledger: &mut VestingLedger,
        period: u64,
    ) {
        ledger.period = period;
    }

    // === Internal functions ===
    fun user_mut(
        ledger: &mut VestingLedger,
        user: address,
        ctx: &mut TxContext,
    ): &mut Account {
        if (!ledger.accounts.contains(user)) {
            ledger.accounts.add(user, Account {
                id: object::new(ctx),
                instant_balance: 0,
                entries: vector::empty(),
            });
        };
        &mut ledger.accounts[user]
    }

    fun prune_epochs(
        account: &mut Account,
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
    public fun account_history_len(
        ledger: &VestingLedger,
        user: address,
    ): u64 {
        ledger.accounts[user].entries.length()
    }
}

#[test_only]
module testcoin::vesting_ledger_tests {
    use testcoin::vesting_ledger::{Self, EInvalidAmount};
    use sui::test_utils;

    const USER: address = @0xB;

    #[test]
    fun test_non_existent_user_has_zero_available_balance() {
        let ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 0);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_coins_are_available_immediately_after_deposit() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.deposit(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 1000);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_more_coins_become_available_with_each_subsequent_epoch() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 100);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 200);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 300);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 400);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 500);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 600);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 700);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 800);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 900);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 1000);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 1000);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_summing_multiple_deposits_in_single_epoch() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.deposit(USER, 100, &mut tx_context::dummy());
        ledger.deposit(USER, 100, &mut tx_context::dummy());
        ledger.deposit(USER, 100, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 300);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_summing_multiple_locks_in_single_epoch() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 100, &mut tx_context::dummy());
        ledger.lock(USER, 100, &mut tx_context::dummy());
        ledger.lock(USER, 100, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 30);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_deposit_and_lock_combination() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.deposit(USER, 1000, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 1000 + 100); 
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_locks_overlap_over_time_correctly() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 1);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 3);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 6);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 10);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 15);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 21);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 28);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 36);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 45);
        ledger.advance_epoch();
        ledger.lock(USER, 10, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 55);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 64);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 72);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 79);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 85);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 90);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 94);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 97);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 99);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 100);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 100);
        test_utils::destroy(ledger);
    }

    #[test]
    #[expected_failure]
    fun test_claiming_fails_for_nonexistent_account() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        let _penalty = ledger.claim(USER, 1000);
        test_utils::destroy(ledger);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidAmount)]
    fun test_claiming_fails_for_zero_amount() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.deposit(USER, 1000, &mut tx_context::dummy());
        let _penalty = ledger.claim(USER, 0);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_claiming_immediately_deposited_coins_reduces_user_account() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.deposit(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 1000);
        let penalty = ledger.claim(USER, 1000);
        test_utils::assert_eq(ledger.available_balance(USER), 0);
        test_utils::assert_eq(penalty, 0);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_partial_claim_reduces_account_proportionally() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.deposit(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 1000);
        let penalty = ledger.claim(USER, 300);
        test_utils::assert_eq(ledger.available_balance(USER), 700);
        test_utils::assert_eq(penalty, 0);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_claiming_locked_coins_too_soon_incurs_penalty() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 100);
        let penalty = ledger.claim(USER, 100);
        test_utils::assert_eq(ledger.available_balance(USER), 0);
        test_utils::assert_eq(penalty, 900);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_partial_claiming_locked_coins_incurs_proportional_penalty() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 100);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 90);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 80);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 70);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 60);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 50);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 40);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 30);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 20);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 10);
        test_utils::assert_eq(penalty, 90);

        let penalty = ledger.claim(USER, 10);
        test_utils::assert_eq(ledger.available_balance(USER), 0);
        test_utils::assert_eq(penalty, 90);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_claiming_on_uneven_period() {
        let mut ledger = vesting_ledger::create(3, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 330);

        let penalty = ledger.claim(USER, 82);
        test_utils::assert_eq(ledger.available_balance(USER), 248);
        test_utils::assert_eq(penalty, 166);

        let penalty = ledger.claim(USER, 82);
        test_utils::assert_eq(ledger.available_balance(USER), 166);
        test_utils::assert_eq(penalty, 166);

        let penalty = ledger.claim(USER, 82);
        test_utils::assert_eq(ledger.available_balance(USER), 84);
        test_utils::assert_eq(penalty, 166);

        // Still can claim all the remaining coins.
        let penalty = ledger.claim(USER, 84);
        test_utils::assert_eq(ledger.available_balance(USER), 0);
        test_utils::assert_eq(penalty, 172);
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_penalty_on_claim_is_reduced_according_to_elapsed_epochs() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 100);

        ledger.advance_epoch();
        ledger.advance_epoch();
        ledger.advance_epoch();
        // Now 40% of coins are available, because each epoch unlocks 10%.
        test_utils::assert_eq(ledger.available_balance(USER), 400);

        // Claiming 100 coins now would incur only 150 coins of penalty
        // (instead of 900) since the penalty is reduced accordingly to elapsed
        // epochs.
        let penalty = ledger.claim(USER, 100);
        test_utils::assert_eq(ledger.available_balance(USER), 300);
        test_utils::assert_eq(penalty, 150);

        test_utils::destroy(ledger);
    }

    #[test]
    fun test_no_penalty_after_all_coins_are_unlocked() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 100);

        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 200);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 300);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 400);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 500);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 600);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 700);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 800);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 900);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 1000);
        let penalty = ledger.claim(USER, 1000);
        test_utils::assert_eq(ledger.available_balance(USER), 0);
        test_utils::assert_eq(penalty, 0);

        test_utils::destroy(ledger);
    }

    #[test]
    fun test_claim_happens_for_first_locks_first() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 100);
        ledger.advance_epoch();
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 300);

        // Now it should be "unloked" to claim 20% of first 1000 coins and,
        // 10% of the second 1000 coins. So 300 coins in total.
        // Now we claim 100 coins, which should be taken from the first lock, so
        // 100 coins from first 1000 + 100 coins from the second 1000 must
        // remain available. And penalty must be deducted from the first 1000
        // only.

        let penalty = ledger.claim(USER, 100);
        test_utils::assert_eq(ledger.available_balance(USER), 200);
        test_utils::assert_eq(penalty, 400);
        
        test_utils::destroy(ledger);
    }

    #[test]
    fun test_penalty_be_deducted_only_for_locked_coins() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.deposit(USER, 1000, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        // User is able to claim full amount of deposited coins, and 10% of
        // locked.
        test_utils::assert_eq(ledger.available_balance(USER), 1000+100);

        // Claiming 1-1000 coins in current situation must not incur any penalties.
        let penalty = ledger.claim(USER, 1000);
        test_utils::assert_eq(ledger.available_balance(USER), 100);
        test_utils::assert_eq(penalty, 0);

        // Claiming 100 coins now, would incur 900 coins of penalty since other
        // coins were "locked" and not "deposited".
        let penalty = ledger.claim(USER, 100);
        test_utils::assert_eq(ledger.available_balance(USER), 0);
        test_utils::assert_eq(penalty, 900);

        test_utils::destroy(ledger);
    }

    #[test]
    fun test_changing_vesting_period_changes_available_balance() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 100);

        ledger.set_vesting_period(5);
        test_utils::assert_eq(ledger.available_balance(USER), 200);

        test_utils::destroy(ledger);
    }

    #[test]
    fun test_update_vesting_period_alters_locked_coins_balance() {
        let mut ledger = vesting_ledger::create(10, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 100);

        ledger.advance_epoch();
        ledger.advance_epoch();
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 400);

        ledger.set_vesting_period(5);
        test_utils::assert_eq(ledger.available_balance(USER), 800);

        test_utils::destroy(ledger);
    }

    #[test]
    fun test_pruning_old_epochs() {
        let mut ledger = vesting_ledger::create(4, &mut tx_context::dummy());
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        ledger.advance_epoch();
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        ledger.advance_epoch();
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        ledger.advance_epoch();
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 2500);
        test_utils::assert_eq(ledger.account_history_len(USER), 4);
        ledger.advance_epoch();

        // Now on each subsequent lock or deposit, on new epochs, the old one
        // are pruned and recorded as instant balance.

        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.available_balance(USER), 3500);
        test_utils::assert_eq(ledger.account_history_len(USER), 4);
        ledger.advance_epoch();
        ledger.lock(USER, 1000, &mut tx_context::dummy());
        test_utils::assert_eq(ledger.account_history_len(USER), 4);
        ledger.advance_epoch();
        test_utils::assert_eq(ledger.available_balance(USER), 5250);

        test_utils::destroy(ledger);
    }
}
