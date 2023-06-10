#[starknet::contract]
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
    // storage variables
    ////////////////////////////////
    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        total_supply: u256,
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval
    }

    ////////////////////////////////
    // Transfer event emitted on token transfer
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u256
    }

    ////////////////////////////////
    // Approval event emitted on token approval
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256
    }

    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(
        ref self: Storage,
        name_: felt252,
        symbol_: felt252,
        decimals_: u8,
        initial_supply: u256,
        recipient: ContractAddress
    ){
        self.name.write(name_);
        self.symbol.write(symbol_);
        self.decimals.write(decimals_);
        assert(recipient.is_non_zero(), 'ERC20: mint to the 0 address');
        self.total_supply.write(initial_supply);
        self.balances.write(recipient, initial_supply);
        self.emit(Event::Transfer(
            Transfer {from: Zeroable::zero(), to: recipient, value: initial_supply}
        ));
    }

    ////////////////////////////////
    // get_name function returns token name
    ////////////////////////////////
    #[view]
    fn get_name(self: @Storage) -> felt252 {
        self.name.read()
    }

    ////////////////////////////////
    // get_symbol function returns token symbol
    ////////////////////////////////
    #[view]
    fn get_symbol(self: @Storage) -> felt252 {
        self.symbol.read()
    }

    ////////////////////////////////
    // get_decimals function returns token decimals
    ////////////////////////////////
    #[view]
    fn get_decimals(self: @Storage) -> u8 {
        self.decimals.read()
    }

    ////////////////////////////////
    // get_total_supply function returns token total total_supply
    ////////////////////////////////
    #[view]
    fn get_total_supply(self: @Storage) -> u256 {
        self.total_supply.read()
    }

    ////////////////////////////////
    // balance_of function returns balance of an account
    ////////////////////////////////
    #[view]
    fn balance_of(self: @Storage, account: ContractAddress) -> u256 {
        self.balances.read(account)
    }

    ////////////////////////////////
    // allowance function returns total allowamnce given to an account
    ////////////////////////////////
    #[view]
    fn allowance(self: @Storage, owner: ContractAddress, spender: ContractAddress) -> u256 {
        self.allowances.read((owner, spender))
    }

    ////////////////////////////////
    // transfer function for transferring tokens from one account to another
    ////////////////////////////////
    #[external]
    fn transfer(ref self: Storage, recipient: ContractAddress, amount: u256) {
        let sender = get_caller_address();
        transfer_helper(ref self, sender, recipient, amount);
    }

    ////////////////////////////////
    // transfer_from function for transferring tokens on behalf of another user
    ////////////////////////////////
    #[external]
    fn transfer_from(ref self: Storage, sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        spend_allowance(ref self, sender, caller, amount);
        transfer_helper(ref self, sender, recipient, amount);
    }

    ////////////////////////////////
    // approve function for approving another user to spend from an account balance
    ////////////////////////////////
    #[external]
    fn approve(ref self: Storage, spender: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        approve_helper(ref self, caller, spender, amount);
    }

    ////////////////////////////////
    // internal function that contains the tranfer logic
    ////////////////////////////////
    fn transfer_helper(ref self: Storage, sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        assert(!sender.is_zero(), 'ERC20: transfer from 0');
        assert(!recipient.is_zero(), 'ERC20: transfer to 0');
        self.balances.write(sender, self.balances.read(sender) - amount);
        self.balances.write(recipient, self.balances.read(recipient) + amount);
        self.emit(Event::Transfer(
            Transfer{from: sender, to: recipient, value: amount}
        ));
    }

    ////////////////////////////////
    // internal function implementing checks against unlimited allowance
    ////////////////////////////////
    fn spend_allowance(ref self: Storage, owner: ContractAddress, spender: ContractAddress, amount: u256) {
        let current_allowance = self.allowances.read((owner, spender));
        let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;
        let is_unlimited_allowance =
            current_allowance.low == ONES_MASK && current_allowance.high == ONES_MASK;
        if !is_unlimited_allowance {
            approve_helper(ref self, owner, spender, current_allowance - amount);
        }
    }

    ////////////////////////////////
    // internal function containing the approval logic
    ////////////////////////////////
    fn approve_helper(ref self: Storage, owner: ContractAddress, spender: ContractAddress, amount: u256) {
        assert(!spender.is_zero(), 'ERC20: approve from 0');
        self.allowances.write((owner, spender), amount);
        self.emit(Event::Approval(
            Approval{owner: owner, spender: spender, value: amount}
        ));
    }
}