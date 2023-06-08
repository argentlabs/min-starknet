use min_amm::contracts::AMM;
use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;

const ADDR1: felt252 = 134235325;

fn __setup__() -> felt252 {
    let class_hash = declare('MIN_AMM').unwrap();
    let prepared = prepare(class_hash, @ArrayTrait::new()).unwrap();
    let deployed_contract_address = deploy(prepared).unwrap();

    deployed_contract_address
}

#[test]
fn test_init_pool() {
    let deployed_contract_address = __setup__();
    let tokenA = 1;
    let tokenB = 2;

    // construct calldata
    let mut calldata = ArrayTrait::new();
    calldata.append(10000);
    calldata.append(10000);
    invoke(deployed_contract_address, 'init_pool', @calldata).unwrap();

    // check pool balance for TOKEN_TYPE_A was updated
    let mut calldata2 = ArrayTrait::new();
    calldata2.append(tokenA);
    let retdata = call(deployed_contract_address, 'get_pool_token_balance', @calldata2).unwrap();
    assert(*retdata.at(0_u32) == 10000, 'incorrect pool balance');

    // check pool balance for TOKEN_TYPE_B was updated
    let mut calldata3 = ArrayTrait::new();
    calldata3.append(tokenB);
    let retdata2 = call(deployed_contract_address, 'get_pool_token_balance', @calldata3).unwrap();
    assert(*retdata2.at(0_u32) == 10000, 'incorrect pool balance');
}

#[test]
fn test_add_demo_token() {
    let deployed_contract_address = __setup__();
    let token_a_amount = 150;
    let token_b_amount = 300;
    let tokenA = 1;
    let tokenB = 2;

    // start prank
    start_prank(ADDR1, deployed_contract_address).unwrap();

    // construct calldata
    let mut calldata = ArrayTrait::new();
    calldata.append(token_a_amount);
    calldata.append(token_b_amount);

    // add demo token
    invoke(deployed_contract_address, 'add_demo_token', @calldata).unwrap();

    // stop prank
    stop_prank(deployed_contract_address).unwrap();

    // check account balance for token_a was updated
    let mut calldata2 = ArrayTrait::new();
    calldata2.append(ADDR1);
    calldata2.append(tokenA);
    let retdata = call(deployed_contract_address, 'get_account_token_balance', @calldata2).unwrap();
    assert(*retdata.at(0_u32) == 150, 'incorrect account balance');

    // check account balance for token_b was updated
    let mut calldata3 = ArrayTrait::new();
    calldata3.append(ADDR1);
    calldata3.append(tokenB);
    let retdata2 = call(deployed_contract_address, 'get_account_token_balance', @calldata3).unwrap();
    assert(*retdata2.at(0_u32) == 300, 'incorrect account balance');
}

#[test]
fn test_swap() {
    let deployed_contract_address = __setup__();
    let token_a_amount = 1000;
    let token_b_amount = 550;
    let tokenA = 1;
    let tokenB = 2;

    // initialize a new pool
    let mut calldata = ArrayTrait::new();
    calldata.append(10000);
    calldata.append(10000);
    invoke(deployed_contract_address, 'init_pool', @calldata).unwrap();

    // start prank
    start_prank(ADDR1, deployed_contract_address).unwrap();

    // add demo tokens
    let mut calldata2 = ArrayTrait::new();
    calldata2.append(token_a_amount);
    calldata2.append(token_b_amount);
    invoke(deployed_contract_address, 'add_demo_token', @calldata2).unwrap();

    // swap tokenA for tokenB
    let mut calldata3 = ArrayTrait::new();
    calldata3.append(tokenA);
    calldata3.append(100);
    invoke(deployed_contract_address, 'swap', @calldata3).unwrap();

    // stop prank
    stop_prank(deployed_contract_address).unwrap();

    // check tokenB account balance increased by 50
    let mut calldata4 = ArrayTrait::new();
    calldata4.append(ADDR1);
    calldata4.append(tokenB);
    let retdata = call(deployed_contract_address, 'get_account_token_balance', @calldata4).unwrap();
    assert(*retdata.at(0_u32) == token_b_amount + 50, 'incorrect account balance');

    // check tokenA pool balance decreased by 100
    let mut calldata5 = ArrayTrait::new();
    calldata5.append(tokenA);
    let retdata2 = call(deployed_contract_address, 'get_pool_token_balance', @calldata5).unwrap();
    assert(*retdata2.at(0_u32) == 900, 'incorrect pool balance');
}