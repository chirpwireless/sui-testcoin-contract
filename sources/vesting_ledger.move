module testcoin::vesting_ledger {
    // === Imports ===
    use sui::object_table::{Self, ObjectTable};

    // === Constants ===

    // === Errors ===

    // === Structs ===
    public struct AccountEntry has store {
        /// The epoch number.
        epoch: u64,
        /// The balance locked for the entry's epoch.
        balance: u64,
    }

    public struct Account has key, store {
        /// The unique identifier of the account.
        id: UID,
        /// The portion of deposited coins available immediately.
        instant_balance: u64,
        /// The ledger of locked coins.
        entries: vector<AccountEntry>,
    }

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
        let account = ledger.user_mut(user, ctx);
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

}

#[test_only]
module testcoin::vesting_ledger_tests {
    use testcoin::vesting_ledger::{Self};
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
}
