module testcoin::schedule {
    // === Imports ===
    use testcoin::treasury::{Self, ScheduleEntry};

    // === Constants ===
    const STRATEGIC_SUPPORTERS: vector<u8> = b"strategic_supporters";
    const KEEPERS: vector<u8> = b"keepers";
    const ECOSYSTEM_GROWTH_POOL: vector<u8> = b"ecosystem_growth_pool";
    const ADVISORS: vector<u8> = b"advisors";
    const TEAM: vector<u8> = b"team";
    const TOKEN_TREASURY: vector<u8> = b"token_treasury";
    const LIQUIDITY: vector<u8> = b"liquidity";

    // === Public package functions ===
    /// Returns the default minting schedule
    public(package) fun default<T>(): vector<ScheduleEntry<T>> {
        vector[
            // Stage 0
            treasury::create_entry(
                vector[STRATEGIC_SUPPORTERS.to_string(), TOKEN_TREASURY.to_string(), LIQUIDITY.to_string()],
                vector[96_000_000_000_000_000, 127_500_000_000_000_000, 150_000_000_000_000_000],
                1, 3600000, 0,
            ),

            // Stage 1
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), STRATEGIC_SUPPORTERS.to_string(), TOKEN_TREASURY.to_string()],
                vector[605_000_000_000_000, 600_000_000_000_000, 1_920_000_000_000_000, 404_761_904_761_904],
                45, 3600000, 0,
            ),

            // Stage 2
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), STRATEGIC_SUPPORTERS.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[605_000_000_000_000, 600_000_000_000_000, 1_653_333_333_333_330, 50_000_000_000_000, 375_000_000_000_000, 404_761_904_761_904],
                45, 3600000, 0,
            ),

            // Stage 3
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), STRATEGIC_SUPPORTERS.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[602_500_000_000_000, 600_000_000_000_000, 1_653_333_333_333_330, 50_000_000_000_000, 375_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 4
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), STRATEGIC_SUPPORTERS.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[602_500_000_000_000, 600_000_000_000_000, 1_653_333_333_333_330, 50_000_000_000_000, 375_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 5
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), STRATEGIC_SUPPORTERS.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[595_000_000_000_000, 550_000_000_000_000, 1_653_333_333_333_330, 50_000_000_000_000, 375_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 6
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[587_500_000_000_000, 500_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 7
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[580_000_000_000_000, 450_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 8
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[572_500_000_000_000, 425_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 9
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[565_000_000_000_000, 400_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 10
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[557_500_000_000_000, 375_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 11
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[550_000_000_000_000, 350_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 12
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[542_500_000_000_000, 325_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 13
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[535_000_000_000_000, 300_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 14
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[527_500_000_000_000, 275_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 15
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), ADVISORS.to_string(), TEAM.to_string(), TOKEN_TREASURY.to_string()],
                vector[520_000_000_000_000, 250_000_000_000_000, 113_333_333_333_333, 850_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 16
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), TOKEN_TREASURY.to_string()],
                vector[512_500_000_000_000, 225_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 17
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), TOKEN_TREASURY.to_string()],
                vector[505_000_000_000_000, 200_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 18
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), TOKEN_TREASURY.to_string()],
                vector[497_500_000_000_000, 175_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 19
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), TOKEN_TREASURY.to_string()],
                vector[490_000_000_000_000, 150_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 20
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), TOKEN_TREASURY.to_string()],
                vector[482_500_000_000_000, 125_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 21
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string(), TOKEN_TREASURY.to_string()],
                vector[479_170_000_000_000, 125_000_000_000_000, 404_761_904_761_905],
                45, 3600000, 0,
            ),

            // Stage 22
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[475_840_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 23
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[472_510_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 24
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[469_180_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 25
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[465_850_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 26
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[462_520_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 27
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[459_190_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 28
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[455_860_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 29
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[452_530_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 30
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[449_200_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 31
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[445_870_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 32
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[442_540_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 33
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[439_210_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 34
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[435_880_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 35
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[432_550_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 36
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[429_220_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 37
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[425_890_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 38
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[422_560_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 39
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[419_230_000_000_000, 125_000_000_000_000],
                45, 3600000, 0,
            ),

            // Stage 40
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[415_900_000_000_000, 125_000_000_000_000],
                44, 3600000, 0,
            ),

            // Stage 41
            treasury::create_entry(
                vector[KEEPERS.to_string(), ECOSYSTEM_GROWTH_POOL.to_string()],
                vector[415_900_000_000_000, 125_000_000_000_000],
                1, 3600000, 0,
            ),

        ]
    }
}

#[test_only]
module testcoin::schedule_tests {
    use testcoin::testcoin::{Self, TESTCOIN, Vault};
    use std::string::{String};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self};
    use sui::test_scenario::{Self, Scenario};
    use sui::test_utils;

    const STRATEGIC_SUPPORTERS: vector<u8> = b"strategic_supporters";
    const KEEPERS: vector<u8> = b"keepers";
    const ECOSYSTEM_GROWTH_POOL: vector<u8> = b"ecosystem_growth_pool";
    const ADVISORS: vector<u8> = b"advisors";
    const TEAM: vector<u8> = b"team";
    const TOKEN_TREASURY: vector<u8> = b"token_treasury";
    const LIQUIDITY: vector<u8> = b"liquidity";

    const PUBLISHER: address = @0xA;
    const RANDOM_PERSON: address = @0xB;

    #[test]
    fun test_default_schedule() {
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            testcoin::init_for_testing(scenario.ctx());
            clock::share_for_testing(clock::create_for_testing(scenario.ctx()));
        };
        batch_mint(1, &mut scenario); // stage 0
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 0, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 0, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 96_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 0, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 0, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 127_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 1
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 27_225_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 27_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 182_400_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 0, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 0, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 145_714_285_714_285_680, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 2
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 54_450_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 54_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 256_799_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 2_250_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 16_875_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 163_928_571_428_571_360, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 3
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 81_562_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 81_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 331_199_999_999_999_700, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 4_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 33_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 182_142_857_142_857_085, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 4
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 108_675_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 108_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 405_599_999_999_999_550, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 6_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 50_625_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 200_357_142_857_142_810, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 5
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 135_450_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 132_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 9_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 67_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 218_571_428_571_428_535, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 6
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 161_887_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 155_250_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 14_099_999_999_999_985, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 105_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 236_785_714_285_714_260, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 7
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 187_987_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 175_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 19_199_999_999_999_970, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 144_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 254_999_999_999_999_985, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 8
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 213_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 194_625_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 24_299_999_999_999_955, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 182_250_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 273_214_285_714_285_710, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 9
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 239_175_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 212_625_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 29_399_999_999_999_940, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 220_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 291_428_571_428_571_435, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 10
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 264_262_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 229_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 34_499_999_999_999_925, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 258_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 309_642_857_142_857_160, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 11
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 289_012_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 245_250_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 39_599_999_999_999_910, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 297_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 327_857_142_857_142_885, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 12
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 313_425_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 259_875_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 44_699_999_999_999_895, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 335_250_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 346_071_428_571_428_610, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 13
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 337_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 273_375_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 49_799_999_999_999_880, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 373_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 364_285_714_285_714_335, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 14
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 361_237_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 285_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 54_899_999_999_999_865, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 411_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 382_500_000_000_000_060, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 15
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 384_637_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 297_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 400_714_285_714_285_785, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 16
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 407_700_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 307_125_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 418_928_571_428_571_510, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 17
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 430_425_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 316_125_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 437_142_857_142_857_235, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 18
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 452_812_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 324_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 455_357_142_857_142_960, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 19
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 474_862_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 330_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 473_571_428_571_428_685, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 20
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 496_575_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 336_375_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 491_785_714_285_714_410, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 21
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 518_137_650_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 342_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 22
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 539_550_450_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 347_625_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 23
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 560_813_400_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 353_250_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 24
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 581_926_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 358_875_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 25
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 602_889_750_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 364_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 26
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 623_703_150_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 370_125_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 27
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 644_366_700_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 375_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 28
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 664_880_400_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 381_375_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 29
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 685_244_250_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 387_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 30
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 705_458_250_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 392_625_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 31
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 725_522_400_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 398_250_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 32
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 745_436_700_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 403_875_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 33
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 765_201_150_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 409_500_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 34
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 784_815_750_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 415_125_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 35
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 804_280_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 420_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 36
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 823_595_400_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 426_375_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 37
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 842_760_450_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 432_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 38
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 861_775_650_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 437_625_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(45, &mut scenario); // stage 39
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 880_641_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 443_250_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(44, &mut scenario); // stage 40
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 898_940_600_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 448_750_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            test_scenario::return_shared(vault);
        };
        batch_mint(1, &mut scenario); // stage 41
        scenario.next_tx(RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            assert_pool_eq_test_coin(&mut vault, KEEPERS.to_string(), 899_356_500_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, ECOSYSTEM_GROWTH_POOL.to_string(), 448_875_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, STRATEGIC_SUPPORTERS.to_string(), 479_999_999_999_999_400, &scenario);
            assert_pool_eq_test_coin(&mut vault, ADVISORS.to_string(), 59_999_999_999_999_850, &scenario);
            assert_pool_eq_test_coin(&mut vault, TEAM.to_string(), 450_000_000_000_000_000, &scenario);
            assert_pool_eq_test_coin(&mut vault, TOKEN_TREASURY.to_string(), 510_000_000_000_000_135, &scenario);
            assert_pool_eq_test_coin(&mut vault, LIQUIDITY.to_string(), 150_000_000_000_000_000, &scenario);
            // Totally minted: 2_998_231_499_999_999_385 (1_768_500_000_000_615 left, or 176850.000000062 TESTCOIN)
            test_scenario::return_shared(vault);
        };
        scenario.end();
    }

    /// Asserts that the TESTCOIN pool's value matches the expected value.
    fun assert_pool_eq_test_coin(vault: &mut Vault, name: String, expected_value: u64, scenario: &Scenario) {
        let owner = vault.get_address_pool(name);
        test_utils::assert_eq(total_coins(owner, scenario), expected_value);
    }

    /// Mints the specified number of epochs of TESTCOIN coins.
    fun batch_mint(mut number_of_epochs: u64, scenario: &mut test_scenario::Scenario) {
        test_scenario::next_tx(scenario, RANDOM_PERSON);
        {
            let mut vault: Vault = scenario.take_shared();
            let mut clock: Clock = scenario.take_shared();

            while (number_of_epochs > 0) {
                testcoin::mint(&mut vault, &clock, scenario.ctx());
                clock.increment_for_testing(3600000);
                number_of_epochs = number_of_epochs - 1;
            };

            test_scenario::return_shared(vault);
            test_scenario::return_shared(clock);
        };
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
