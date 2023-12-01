#[contract]
mod ERC20Contract {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::contract_address_try_from_felt252;
    use traits::Into;
    u