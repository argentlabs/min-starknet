use min_token_sale::contracts::token_sale;
use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;

const TOKEN_ADDR: felt252 = 12345678;
const ADMIN_ADDR: felt252 = 95027522;
const USER1: felt252 = 2548294;

fn __setup__() -> Array<felt252> {
    // deploy dummy eth token
    let deployed_eth_address = __deploy_ethereum__();

    // constructor calldata
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(TOKEN_ADDR);
    constructor_calldata.append(ADMIN_ADDR);
    constructor_calldata.append(deployed_eth_address);

    // declare contract
    let class_hash = declare('TOKEN_SALE').unwrap();

    // prepare contract
    let prepared = prepare(class_hash, @constructor_calldata).unwrap();

    // start warp
    start_warp(100, prepared.contract_address).unwrap();

    // deploy contract
    let deployed_contract_address = deploy(prepared).unwrap();

    // stop warp
    stop_warp(deployed_contract_address).unwrap();

    // construct and return an array of deployed_contract_address and deployed_eth_address
    let mut array = ArrayTrait::new();
    array.append(deployed_contract_address);
    array.append(deployed_eth_address);
    array
}

fn __deploy_ethereum__() -> felt252 {
    // constructor calldata
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append('Ether');
    constructor_calldata.append('ETH');
    constructor_calldata.append(18);
    constructor_calldata.append(10000000000000000000000000);
    constructor_calldata.append(0);
    constructor_calldata.append(ADMIN_ADDR);

    // declare contract
    let class_hash = declare('ERC20').unwrap();
    // prepare contract
    let prepared = prepare(class_hash, @constructor_calldata).unwrap();
    // deploy contract
    let deployed_contract_address = deploy(prepared).unwrap();

    // transfer ETH from ADMIN_ADDR to USER1 for further test cases
    start_prank(ADMIN_ADDR, deployed_contract_address).unwrap();
    let mut calldata = ArrayTrait::new();
    calldata.append(USER1);
    calldata.append(10000000000000000);
    calldata.append(0);
    invoke(deployed_contract_address, 'transfer', @calldata).unwrap();

    stop_prank(deployed_contract_address).unwrap();
    deployed_contract_address
}

#[test]
fn test_is_registered() {
    // deploy contract
    let retdata: Array<felt252> = __setup__();
    let deployed_contract_address = *retdata.at(0_u32);

    // construct calldata
    let mut calldata = ArrayTrait::new();
    calldata.append(USER1);

    // call the is_registered function
    let retdata = call(deployed_contract_address, 'is_registered', @calldata).unwrap();
    
    // assert retdata = false
    assert(*retdata.at(0_u32) == 0, 'incorrect status');
}

#[test] // this test fails for now, will amend soon
fn test_register() {
    // deploy contract
    let retdata: Array<felt252> = __setup__();
    let deployed_contract_address = *retdata.at(0_u32);
    let deployed_eth_address = *retdata.at(1_u32);

    // start prank and warp
    start_prank(USER1, deployed_contract_address).unwrap();
    start_warp(120, deployed_contract_address).unwrap();

    // approve to spend 0.01 ETH
    let mut calldata = ArrayTrait::new();
    calldata.append(deployed_contract_address);
    calldata.append(1000000000000000);
    calldata.append(0);
    invoke(deployed_eth_address, 'approve', @calldata).unwrap();

    // invoke register function
    invoke(deployed_contract_address, 'register', @ArrayTrait::new()).unwrap();

    // stop prank
    stop_prank(deployed_contract_address);

    // call is_registered and assert status is true
    let mut calldata2 = ArrayTrait::new();
    calldata2.append(USER1);
    let retdata2 = call(deployed_contract_address, 'is_registered', @calldata2).unwrap();
    assert(*retdata2.at(0_u32) == 1, 'incorrect status');
}