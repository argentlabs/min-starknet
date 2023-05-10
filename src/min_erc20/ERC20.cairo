#[contract]

mod ERC20Contract {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;
    use starknet::contract_address_try_from_felt252;
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        total_supply: u256,
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
    }

    ////////////////////////////////
    // Transfer event emitted on token transfer
    ////////////////////////////////
    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    ////////////////////////////////
    // Approval event emitted on token approval
    ////////////////////////////////
    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(
        name_: felt252,
        symbol_: felt252,
        decimals_: u8,
        initial_supply: u256,
        recipient: ContractAddress
    ){
        name::write(name_);
        symbol::write(symbol_);
        decimals::write(decimals_);
        assert(recipient.is_non_zero(), 'ERC20: mint to the 0 address');
        total_supply::write(initial_supply);
        balances::write(recipient, initial_supply);
        Transfer(ContractAddressZeroable::zero(), recipient, initial_supply);
    }

    ////////////////////////////////
    // get_name function returns token name
    ////////////////////////////////
    #[view]
    fn get_name() -> felt252 {
        name::read()
    }

    ////////////////////////////////
    // get_symbol function returns token symbol
    ////////////////////////////////
    #[view]
    fn get_symbol() -> felt252 {
        symbol::read()
    }

    ////////////////////////////////
    // get_decimals function returns token decimals
    ////////////////////////////////
    #[view]
    fn get_decimals() -> u8 {
        decimals::read()
    }

    ////////////////////////////////
    // get_total_supply function returns token total total_supply
    ////////////////////////////////
    #[view]
    fn get_total_supply() -> u256 {
        total_supply::read()
    }

    ////////////////////////////////
    // balance_of function returns balance of an account
    ////////////////////////////////
    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        balances::read(account)
    }

    ////////////////////////////////
    // allowance function returns total allowamnce given to an account
    ////////////////////////////////
    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        allowances::read((owner, spender))
    }

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
    fn transfer_helper(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        assert(!sender.is_zero(), 'ERC20: transfer from 0');
        assert(!recipient.is_zero(), 'ERC20: transfer to 0');
        balances::write(sender, balances::read(sender) - amount);
        balances::write(recipient, balances::read(recipient) + amount);
        Transfer(sender, recipient, amount);
    }

    ////////////////////////////////
    // internal function implementing checks against unlimited allowance
    ////////////////////////////////
    fn spend_allowance(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        let current_allowance = allowances::read((owner, spender));
        let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;
        let is_unlimited_allowance =
            current_allowance.low == ONES_MASK & current_allowance.high == ONES_MASK;
        if !is_unlimited_allowance {
            approve_helper(owner, spender, current_allowance - amount);
        }
    }

    ////////////////////////////////
    // internal function containing the approval logic
    ////////////////////////////////
    fn approve_helper(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        assert(!spender.is_zero(), 'ERC20: approve from 0');
        allowances::write((owner, spender), amount);
        Approval(owner, spender, amount);
    }
}