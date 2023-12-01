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
    use traits::TryInto;
    use option::OptionTrait;


    ////////////////////////////////
    // transfer function for transferring tokens from one account to another
    ////////////////////////////////
    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) {
        let sender = get_caller_address();
        transfer_helper(sender, recipient, amount);
    }

    ////////////////////////////////
    // transfer_from function for transferring tokens on behalf of another user
    ////////////////////////////////
    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        spend_allowance(sender, caller, amount);
        transfer_helper(sender, recipient, amount);
    }

    ////////////////////////////////
    // approve function for approving another user to spend from an account balance
    ////////////////////////////////
    #[external]
    fn approve(spender: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, amount);
    }

    ////////////////////////////////
    // internal function that contains the tranfer logic
    ////////////////////////////////
    fn tra