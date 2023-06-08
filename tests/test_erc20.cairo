use min_erc20::contracts::ERC20;
use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;

const OWNER: felt252 = 12345;
const ADDR1: felt252 = 45678;
const ADDR2: felt252 = 97858;

fn __setup__() -> felt252 {
    // constructor calldata
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append('MIN-STARKNET');
    constructor_calldata.append('MST');
    constructor_calldata.append(18);
    constructor_calldata.append(1000);
    constructor_calldata.append(0);
    constructor_calldata.append(OWNER);

    // declare contract
    let class_hash = declare('ERC20').unwrap();
    // prepare contract
    let prepared = prepare(class_hash, @constructor_calldata).unwrap();
    // deploy contract
    let deployed_contract_address = deploy(prepared).unwrap();

    deployed_contract_address
}

#[test]
fn test_get_name() {
    let deployed_contract_address = __setup__();

    // call get_name function
    let retdata = call(deployed_contract_address, 'get_name', @ArrayTrait::new()).unwrap();

    // check the retdata is the same as initial constructor arg
    assert(*retdata.at(0_u32) == 'MIN-STARKNET', 'incorrect name');
}

#[test]
fn test_get_symbol() {
    let deployed_contract_address = __setup__();

    // call get_symbol function
    let retdata = call(deployed_contract_address, 'get_symbol', @ArrayTrait::new()).unwrap();

    // check the retdata is the same as initial constructor arg
    assert(*retdata.at(0_u32) == 'MST', 'incorrect symbol');
}

#[test]
fn test_get_decimals() {
    let deployed_contract_address = __setup__();

    // call get_decimals function
    let retdata = call(deployed_contract_address, 'get_decimals', @ArrayTrait::new()).unwrap();

    // check the retdata is the same as initial constructor arg
    assert(*retdata.at(0_u32) == 18, 'incorrect decimals');
}

#[test]
fn test_get_total_supply() {
    let deployed_contract_address = __setup__();

    // call get_total_supply function
    let retdata = call(deployed_contract_address, 'get_total_supply', @ArrayTrait::new()).unwrap();

    // check the retdata is the same as initial constructor arg
    assert(*retdata.at(0_u32) == 1000, 'incorrect total_supply');
}

#[test]
fn test_balance_of() {
    let deployed_contract_address = __setup__();

    // call balance_of function
    let mut calldata = ArrayTrait::new();
    calldata.append(OWNER);
    let retdata = call(deployed_contract_address, 'balance_of', @calldata).unwrap();

    // check the retdata is the same as initial constructor arg
    assert(*retdata.at(0_u32) == 1000, 'incorrect balance');
}

#[test]
fn test_approve_and_allowance() {
    let deployed_contract_address = __setup__();

    // start prank
    start_prank(OWNER, deployed_contract_address).unwrap();

    // call approve function
    let mut calldata = ArrayTrait::new();
    calldata.append(ADDR2);
    calldata.append(100);
    calldata.append(0);
    invoke(deployed_contract_address, 'approve', @calldata).unwrap();

    // stop prank
    stop_prank(deployed_contract_address).unwrap();

    // call allowance function
    let mut calldata2 = ArrayTrait::new();
    calldata2.append(OWNER);
    calldata2.append(ADDR2);
    let retdata = call(deployed_contract_address, 'allowance', @calldata2).unwrap();

    // check the retdata is the same as initial constructor arg
    assert(*retdata.at(0_u32) == 100, 'incorrect allowance');
}

#[test]
fn test_transfer() {
    let deployed_contract_address = __setup__();

    // start prank
    start_prank(OWNER, deployed_contract_address).unwrap();

    // call transfer function as OWNER
    let mut calldata = ArrayTrait::new();
    calldata.append(ADDR1);
    calldata.append(200);
    calldata.append(0);
    invoke(deployed_contract_address, 'transfer', @calldata).unwrap();

    // stop prank
    stop_prank(deployed_contract_address).unwrap();

    // check balance of sender decreased
    let mut calldata2 = ArrayTrait::new();
    calldata2.append(OWNER);
    let retdata = call(deployed_contract_address, 'balance_of', @calldata2).unwrap();
    assert(*retdata.at(0_u32) == 800, 'incorrect sender balance');

    // check balance of recipient increased
    let mut calldata3 = ArrayTrait::new();
    calldata3.append(ADDR1);
    let retdata = call(deployed_contract_address, 'balance_of', @calldata3).unwrap();
    assert(*retdata.at(0_u32) == 200, 'incorrect recipient balance');
}

#[test]
fn transfer_from() {
    let deployed_contract_address = __setup__();

    // start prank
    start_prank(OWNER, deployed_contract_address).unwrap();

    // call approve function as OWNER
    let mut calldata = ArrayTrait::new();
    calldata.append(ADDR2);
    calldata.append(100);
    calldata.append(0);
    invoke(deployed_contract_address, 'approve', @calldata).unwrap();

    // stop prank
    stop_prank(deployed_contract_address).unwrap();

    // start prank
    start_prank(ADDR2, deployed_contract_address).unwrap();

    // call transfer_from function as ADDR2
    let mut calldata2 = ArrayTrait::new();
    calldata2.append(OWNER);
    calldata2.append(ADDR1);
    calldata2.append(50);
    calldata2.append(0);
    invoke(deployed_contract_address, 'transfer_from', @calldata2).unwrap();

    // stop prank
    stop_prank(deployed_contract_address).unwrap();

    // check balance of sender decreased
    let mut calldata3 = ArrayTrait::new();
    calldata3.append(OWNER);
    let retdata = call(deployed_contract_address, 'balance_of', @calldata3).unwrap();
    assert(*retdata.at(0_u32) == 950, 'incorrect sender balance');

    // check balance of recipient increased
    let mut calldata4 = ArrayTrait::new();
    calldata4.append(ADDR1);
    let retdata = call(deployed_contract_address, 'balance_of', @calldata4).unwrap();
    assert(*retdata.at(0_u32) == 50, 'incorrect recipient balance');

    // check allowance of spender decreased
    let mut calldata5 = ArrayTrait::new();
    calldata5.append(OWNER);
    calldata5.append(ADDR2);
    let retdata = call(deployed_contract_address, 'allowance', @calldata5).unwrap();
    assert(*retdata.at(0_u32) == 50, 'incorrect allowance');
}
