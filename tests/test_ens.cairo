use min_ens::contracts::ENS;
use array::ArrayTrait;
use option::OptionTrait;
use result::ResultTrait;

fn __setup__() -> felt252 {
    // constructor calldata
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append('Darlington');
    // declare contract
    let class_hash = declare('ENS').unwrap();
    // prepare contract
    let prepared = prepare(class_hash, @constructor_calldata).unwrap();

    // start prank with a new address
    let owner_address = 123;
    start_prank(owner_address, prepared.contract_address).unwrap();

    // deploy contract
    let deployed_contract_address = deploy(prepared).unwrap();

    deployed_contract_address
}

#[test]
fn test_constructor() {
    let deployed_contract_address = __setup__();
    let owner_address = 123;

    // call get_name function
    let mut calldata = ArrayTrait::new();
    calldata.append(owner_address);
    let retdata = call(deployed_contract_address, 'get_name', @calldata).unwrap();

    // check that retdata is equal to initial constructor arg
    assert(*retdata.at(0_u32) == 'Darlington', 'incorrect name');
    // stop prank
    stop_prank(deployed_contract_address).unwrap();
}

#[test]
fn test_storing_and_retrieving() {
    let deployed_contract_address = __setup__();

    // start prank
    let caller_address = 1234;
    start_prank(caller_address, deployed_contract_address).unwrap();

    // call set_name function
    let mut calldata = ArrayTrait::new();
    calldata.append('Starknet');
    invoke(deployed_contract_address, 'store_name', @calldata).unwrap();

    // call get_name
    let mut calldata = ArrayTrait::new();
    calldata.append(caller_address);
    let retdata = call(deployed_contract_address, 'get_name', @calldata).unwrap();

    // confirm get_name returns the correct name
    assert(*retdata.at(0_u32) == 'Starknet', 'incorrect name');
    // stop prank
    stop_prank(deployed_contract_address).unwrap();
}