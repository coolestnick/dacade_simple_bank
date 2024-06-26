#[test_only]
module yoy::dacade_simple_bank_tests {
    use std::option::Option;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::test_scenario;

    use yoy::dacade_simple_bank::{Self, SimpleBank, AdminCap};

    #[test]
    fun test_simple_bank() {
        let admin = @0x1;
        let alice = @0xa;
        let bob = @0xb;

        let mut scenario_val = test_scenario::begin(admin);
        let mut scenario = &mut scenario_val;

        // ====================
        //  init
        // ====================
        {
            dacade_simple_bank::init(test_scenario::ctx(scenario));
        };

        // ====================
        //  register alice
        // ====================
        test_scenario::next_tx(scenario, alice);
        {
            let mut simpleBank = test_scenario::take_shared<SimpleBank>(scenario);

            dacade_simple_bank::register(&mut simpleBank, test_scenario::ctx(scenario));

            assert!(vec_set::contains(dacade_simple_bank::get_registering_user_set(&simpleBank), &alice), 0);
            assert!(!vec_set::contains(dacade_simple_bank::get_registered_user_set(&simpleBank), &alice), 0);

            test_scenario::return_shared(simpleBank);
        };

        // ====================
        //  register bob
        // ====================
        test_scenario::next_tx(scenario, bob);
        {
            let mut simpleBank = test_scenario::take_shared<SimpleBank>(scenario);

            dacade_simple_bank::register(&mut simpleBank, test_scenario::ctx(scenario));

            assert!(vec_set::contains(dacade_simple_bank::get_registering_user_set(&simpleBank), &alice), 0);
            assert!(vec_set::contains(dacade_simple_bank::get_registering_user_set(&simpleBank), &bob), 0);
            assert!(!vec_set::contains(dacade_simple_bank::get_registered_user_set(&simpleBank), &alice), 0);
            assert!(!vec_set::contains(dacade_simple_bank::get_registered_user_set(&simpleBank), &bob), 0);

            test_scenario::return_shared(simpleBank);
        };

        // ====================
        //  admin approve alice
        // ====================
        test_scenario::next_tx(scenario, admin);
        {
            let mut simpleBank = test_scenario::take_shared<SimpleBank>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let mut users = vector::empty();
            vector::push_back(&mut users, alice);

            dacade_simple_bank::approve(&admin_cap, &mut simpleBank, users);

            assert!(!vec_set::contains(dacade_simple_bank::get_registering_user_set(&simpleBank), &alice), 0);
            assert!(vec_set::contains(dacade_simple_bank::get_registered_user_set(&simpleBank), &alice), 0);
            assert!(vec_set::contains(dacade_simple_bank::get_registering_user_set(&simpleBank), &bob), 0);

            test_scenario::return_shared(simpleBank);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        // ====================
        //  alice deposit
        // ====================
        test_scenario::next_tx(scenario, alice);
        {
            let mut simpleBank = test_scenario::take_shared<SimpleBank>(scenario);

            let mut payment_coin = coin::mint_for_testing<SUI>(1000, test_scenario::ctx(scenario));

            dacade_simple_bank::deposit(&mut simpleBank, &mut payment_coin, test_scenario::ctx(scenario));

            let balances = dacade_simple_bank::get_balances(&simpleBank);

            assert!(vec_map::contains(balances, &alice), 0);
            assert_eq(balance::value(vec_map::get(balances, &alice)), 1000);

            coin::burn_for_testing(payment_coin);
            test_scenario::return_shared(simpleBank);
        };

        // ====================
        //  alice withdraw
        // ====================
        test_scenario::next_tx(scenario, alice);
        {
            let mut simpleBank = test_scenario::take_shared<SimpleBank>(scenario);

            dacade_simple_bank::withdraw(&mut simpleBank, 800, test_scenario::ctx(scenario));

            let balances = dacade_simple_bank::get_balances(&simpleBank);

            assert!(vec_map::contains(balances, &alice), 0);
            assert_eq(balance::value(vec_map::get(balances, &alice)), 200);

            test_scenario::return_shared(simpleBank);
        };

        // ====================
        //  get total balance
        // ====================
        test_scenario::next_tx(scenario, admin);
        {
            let simpleBank = test_scenario::take_shared<SimpleBank>(scenario);

            let total_balance = dacade_simple_bank::get_total_balance(&simpleBank);
            assert_eq(total_balance, 200);

            test_scenario::return_shared(simpleBank);
        };

        // ====================
        //  get user balance
        // ====================
        test_scenario::next_tx(scenario, admin);
        {
            let simpleBank = test_scenario::take_shared<SimpleBank>(scenario);

            let alice_balance = dacade_simple_bank::get_user_balance(&simpleBank, alice);
            assert_eq(alice_balance, some(200));

            let bob_balance = dacade_simple_bank::get_user_balance(&simpleBank, bob);
            assert_eq(bob_balance, none());

            test_scenario::return_shared(simpleBank);
        };

        test_scenario::end(scenario_val);
    }
}