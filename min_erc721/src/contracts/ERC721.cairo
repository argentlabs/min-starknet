#[contract]

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
    struct Storage {
        name: felt252,
        symbol: felt252,
        owners: LegacyMap::<u256, ContractAddress>,
        balances: LegacyMap::<ContractAddress, u256>,
        token_approvals: LegacyMap::<u256, ContractAddress>,
        operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
        token_uri: LegacyMap<u256, felt252>,
    }

    ////////////////////////////////
    // Approval event emitted on token approval
    ////////////////////////////////
    #[event]
    fn Approval(owner: ContractAddress, to: ContractAddress, token_id: u256) {}

    ////////////////////////////////
    // Transfer event emitted on token transfer
    ////////////////////////////////
    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {}

    ////////////////////////////////
    // ApprovalForAll event emitted on approval for operators
    ////////////////////////////////
    #[event]
    fn ApprovalForAll(owner: ContractAddress, operator: ContractAddress, approved: bool) {}


    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(_name: felt252, _symbol: felt252) {
        name::write(_name);
        symbol::write(_symbol);
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
    // token_uri returns the token uri
    ////////////////////////////////
    fn get_token_uri(token_id: u256) -> felt252 {
        assert(_exists(token_id), 'ERC721: invalid token ID');
        token_uri::read(token_id)
    }

    ////////////////////////////////
    // balance_of function returns token balance
    ////////////////////////////////
    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        assert(account.is_non_zero(), 'ERC721: address zero');
        balances::read(account)
    }

    ////////////////////////////////
    // owner_of function returns owner of token_id
    ////////////////////////////////
    #[view]
    fn owner_of(token_id: u256) -> ContractAddress {
        let owner = owners::read(token_id);
        assert(owner.is_non_zero(), 'ERC721: invalid token ID');
        owner
    }

    ////////////////////////////////
    // get_approved function returns approved address for a token
    ////////////////////////////////
    #[view]
    fn get_approved(token_id: u256) -> ContractAddress {
        assert(_exists(token_id), 'ERC721: invalid token ID');
        token_approvals::read(token_id)
    }

    ////////////////////////////////
    // is_approved_for_all function returns approved operator for a token
    ////////////////////////////////
    #[view]
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool {
        operator_approvals::read((owner, operator))
    }

    ////////////////////////////////
    // approve function approves an address to spend a token
    ////////////////////////////////
    #[external]
    fn approve(to: ContractAddress, token_id: u256) {
        let owner = owner_of(token_id);
        assert(to != owner, 'Approval to current owner');
        assert(get_caller_address() == owner | is_approved_for_all(owner, get_caller_address()), 'Not token owner');
        token_approvals::write(token_id, to);
        Approval(owner_of(token_id), to, token_id);
    }

    ////////////////////////////////
    // set_approval_for_all function approves an operator to spend all tokens 
    ////////////////////////////////
    #[external]
    fn set_approval_for_all(operator: ContractAddress, approved: bool) {
        let owner = get_caller_address();
        assert(owner != operator, 'ERC721: approve to caller');
        operator_approvals::write((owner, operator), approved);
        ApprovalForAll(owner, operator, approved);
    }

    ////////////////////////////////
    // transfer_from function is used to transfer a token
    ////////////////////////////////
    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        assert(_is_approved_or_owner(get_caller_address(), token_id), 'neither owner nor approved');
        _transfer(from, to, token_id);
    }


    ////////////////////////////////
    // internal function to check if a token exists
    ////////////////////////////////
    fn _exists(token_id: u256) -> bool {
        // check that owner of token is not zero
        owner_of(token_id).is_non_zero()
    }

    ////////////////////////////////
    // _is_approved_or_owner checks if an address is an approved spender or owner
    ////////////////////////////////
    fn _is_approved_or_owner(spender: ContractAddress, token_id: u256) -> bool {
        let owner = owners::read(token_id);
        spender == owner
            | is_approved_for_all(owner, spender) 
            | get_approved(token_id) == spender
    }

    ////////////////////////////////
    // internal function that sets the token uri
    ////////////////////////////////
    fn _set_token_uri(token_id: u256, token_uri: felt252) {
        assert(_exists(token_id), 'ERC721: invalid token ID');
        token_uri::write(token_id, token_uri)
    }

    ////////////////////////////////
    // internal function that performs the transfer logic
    ////////////////////////////////
    fn _transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {
        // check that from address is equal to owner of token
        assert(from == owner_of(token_id), 'ERC721: Caller is not owner');
        // check that to address is not zero
        assert(to.is_non_zero(), 'ERC721: transfer to 0 address');

        // remove previously made approvals
        token_approvals::write(token_id, Zeroable::zero());

        // increase balance of to address, decrease balance of from address
        balances::write(from, balances::read(from) - 1.into());
        balances::write(to, balances::read(to) + 1.into());

        // update token_id owner
        owners::write(token_id, to);

        // emit the Transfer event
        Transfer(from, to, token_id);
    }

    ////////////////////////////////
    // _mint function mints a new token to the to address
    ////////////////////////////////
    fn _mint(to: ContractAddress, token_id: u256) {
        assert(to.is_non_zero(), 'TO_IS_ZERO_ADDRESS');

        // Ensures token_id is unique
        assert(!owner_of(token_id).is_non_zero(), 'ERC721: Token already minted');

        // Increase receiver balance
        let receiver_balance = balances::read(to);
        balances::write(to, receiver_balance + 1.into());

        // Update token_id owner
        owners::write(token_id, to);
        Transfer(Zeroable::zero(), to, token_id);
    }

    ////////////////////////////////
    // _burn function burns token from owner's account
    ////////////////////////////////
    fn _burn(token_id: u256) {
        let owner = owner_of(token_id);

        // Clear approvals
        token_approvals::write(token_id, Zeroable::zero());

        // Decrease owner balance
        let owner_balance = balances::read(owner);
        balances::write(owner, owner_balance - 1.into());

        // Delete owner
        owners::write(token_id, Zeroable::zero());
        // emit the Transfer event
        Transfer(owner, Zeroable::zero(), token_id);
    }
}