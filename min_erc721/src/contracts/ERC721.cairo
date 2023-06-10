#[starknet::contract]

mod ERC721Contract {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use starknet::contract_address_to_felt252;
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
        owners: LegacyMap::<u256, ContractAddress>,
        balances: LegacyMap::<ContractAddress, u256>,
        token_approvals: LegacyMap::<u256, ContractAddress>,
        operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
        token_uri: LegacyMap<u256, felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Approval: Approval,
        Transfer: Transfer,
        ApprovalForAll: ApprovalForAll
    }

    ////////////////////////////////
    // Approval event emitted on token approval
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    ////////////////////////////////
    // Transfer event emitted on token transfer
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    ////////////////////////////////
    // ApprovalForAll event emitted on approval for operators
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }


    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: Storage, _name: felt252, _symbol: felt252) {
        self.name.write(_name);
        self.symbol.write(_symbol);
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
    // token_uri returns the token uri
    ////////////////////////////////
    fn get_token_uri(self: @Storage, token_id: u256) -> felt252 {
        assert(_exists(self, token_id), 'ERC721: invalid token ID');
        self.token_uri.read(token_id)
    }

    ////////////////////////////////
    // balance_of function returns token balance
    ////////////////////////////////
    #[view]
    fn balance_of(self: @Storage, account: ContractAddress) -> u256 {
        assert(account.is_non_zero(), 'ERC721: address zero');
        self.balances.read(account)
    }

    ////////////////////////////////
    // owner_of function returns owner of token_id
    ////////////////////////////////
    #[view]
    fn owner_of(self: @Storage, token_id: u256) -> ContractAddress {
        let owner = self.owners.read(token_id);
        assert(owner.is_non_zero(), 'ERC721: invalid token ID');
        owner
    }

    ////////////////////////////////
    // get_approved function returns approved address for a token
    ////////////////////////////////
    #[view]
    fn get_approved(self: @Storage, token_id: u256) -> ContractAddress {
        assert(_exists(self, token_id), 'ERC721: invalid token ID');
        self.token_approvals.read(token_id)
    }

    ////////////////////////////////
    // is_approved_for_all function returns approved operator for a token
    ////////////////////////////////
    #[view]
    fn is_approved_for_all(self: @Storage, owner: ContractAddress, operator: ContractAddress) -> bool {
        self.operator_approvals.read((owner, operator))
    }

    ////////////////////////////////
    // approve function approves an address to spend a token
    ////////////////////////////////
    #[external]
    fn approve(ref self: Storage, to: ContractAddress, token_id: u256) {
        let owner = owner_of(@self, token_id);
        assert(to != owner, 'Approval to current owner');
        assert(get_caller_address() == owner || is_approved_for_all(@self, owner, get_caller_address()), 'Not token owner');
        self.token_approvals.write(token_id, to);
        self.emit(Event::Approval(
            Approval{owner: owner_of(@self, token_id), to: to, token_id: token_id}
        ));
    }

    ////////////////////////////////
    // set_approval_for_all function approves an operator to spend all tokens 
    ////////////////////////////////
    #[external]
    fn set_approval_for_all(ref self: Storage, operator: ContractAddress, approved: bool) {
        let owner = get_caller_address();
        assert(owner != operator, 'ERC721: approve to caller');
        self.operator_approvals.write((owner, operator), approved);
        self.emit(Event::ApprovalForAll(
            ApprovalForAll{owner: owner, operator: operator, approved: approved}
        ));
    }

    ////////////////////////////////
    // transfer_from function is used to transfer a token
    ////////////////////////////////
    #[external]
    fn transfer_from(ref self: Storage, from: ContractAddress, to: ContractAddress, token_id: u256) {
        assert(_is_approved_or_owner(@self, get_caller_address(), token_id), 'neither owner nor approved');
        _transfer(ref self, from, to, token_id);
    }


    ////////////////////////////////
    // internal function to check if a token exists
    ////////////////////////////////
    fn _exists(self: @Storage, token_id: u256) -> bool {
        // check that owner of token is not zero
        owner_of(self, token_id).is_non_zero()
    }

    ////////////////////////////////
    // _is_approved_or_owner checks if an address is an approved spender or owner
    ////////////////////////////////
    fn _is_approved_or_owner(self: @Storage, spender: ContractAddress, token_id: u256) -> bool {
        let owner = self.owners.read(token_id);
        spender == owner
            || is_approved_for_all(self, owner, spender) 
            || get_approved(self, token_id) == spender
    }

    ////////////////////////////////
    // internal function that sets the token uri
    ////////////////////////////////
    fn _set_token_uri(ref self: Storage, token_id: u256, token_uri: felt252) {
        assert(_exists(@self, token_id), 'ERC721: invalid token ID');
        self.token_uri.write(token_id, token_uri)
    }

    ////////////////////////////////
    // internal function that performs the transfer logic
    ////////////////////////////////
    fn _transfer(ref self: Storage, from: ContractAddress, to: ContractAddress, token_id: u256) {
        // check that from address is equal to owner of token
        assert(from == owner_of(@self, token_id), 'ERC721: Caller is not owner');
        // check that to address is not zero
        assert(to.is_non_zero(), 'ERC721: transfer to 0 address');

        // remove previously made approvals
        self.token_approvals.write(token_id, Zeroable::zero());

        // increase balance of to address, decrease balance of from address
        self.balances.write(from, self.balances.read(from) - 1.into());
        self.balances.write(to, self.balances.read(to) + 1.into());

        // update token_id owner
        self.owners.write(token_id, to);

        // emit the Transfer event
        self.emit(Event::Transfer(
            Transfer{from: from, to: to, token_id: token_id}
        ));
    }

    ////////////////////////////////
    // _mint function mints a new token to the to address
    ////////////////////////////////
    fn _mint(ref self: Storage, to: ContractAddress, token_id: u256) {
        assert(to.is_non_zero(), 'TO_IS_ZERO_ADDRESS');

        // Ensures token_id is unique
        assert(!owner_of(@self, token_id).is_non_zero(), 'ERC721: Token already minted');

        // Increase receiver balance
        let receiver_balance = self.balances.read(to);
        self.balances.write(to, receiver_balance + 1.into());

        // Update token_id owner
        self.owners.write(token_id, to);

        // emit Transfer event
        self.emit(Event::Transfer(
            Transfer{from: Zeroable::zero(), to: to, token_id: token_id}
        ));
    }

    ////////////////////////////////
    // _burn function burns token from owner's account
    ////////////////////////////////
    fn _burn(ref self: Storage, token_id: u256) {
        let owner = owner_of(@self, token_id);

        // Clear approvals
        self.token_approvals.write(token_id, Zeroable::zero());

        // Decrease owner balance
        let owner_balance = self.balances.read(owner);
        self.balances.write(owner, owner_balance - 1.into());

        // Delete owner
        self.owners.write(token_id, Zeroable::zero());
        // emit the Transfer event
        self.emit(Event::Transfer(
            Transfer{from: owner, to: Zeroable::zero(), token_id: token_id}
        ));
    }
}