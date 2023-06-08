use starknet::ContractAddress;
#[abi]
trait IERC20 {
    #[view]
    fn get_name() -> felt252;

    #[view]
    fn get_symbol() -> felt252;

    #[view]
    fn get_total_supply() -> felt252;

    #[view]
    fn balance_of(account: ContractAddress) -> u256;

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;

    #[external]
    fn transfer(recipient: ContractAddress, amount: u256);

    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256);

    #[external]
    fn approve(spender: ContractAddress, amount: u256);
}

#[contract]
mod TokenSale {
    ////////////////////////////////
    // library imports
    //////////////////////////////// 
    use starknet::ContractAddress;
    use starknet::get_block_timestamp;
    use starknet::get_contract_address;
    use starknet::get_caller_address;
    use starknet::contract_address_try_from_felt252;
    use traits::TryInto;
    use option::OptionTrait;
    use integer::u256_from_felt252;

    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;

    ////////////////////////////////
    // constants
    ////////////////////////////////
    const REGPRICE: felt252 = 1000000000000000;
    const ICO_DURATION: u64 = 86400_u64;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    struct Storage {
        token_address: ContractAddress,
        admin_address: ContractAddress,
        eth_address: ContractAddress,
        registered_address: LegacyMap::<ContractAddress, bool>,
        claimed_address: LegacyMap::<ContractAddress, bool>,
        ico_start_time: u64,
        ico_end_time: u64,
    }

    ////////////////////////////////
    // constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(_token_address: ContractAddress, _admin_address: ContractAddress, _eth_address: ContractAddress) {
        admin_address::write(_admin_address);
        token_address::write(_token_address);
        eth_address::write(_eth_address);

        let current_time: u64 = get_block_timestamp();
        let end_time: u64 = current_time + ICO_DURATION;
        ico_start_time::write(current_time);
        ico_end_time::write(end_time);

        return ();
    }

    ////////////////////////////////
    // is_registered function returns the registration status of an address
    ////////////////////////////////
    #[view]
    fn is_registered(_address: ContractAddress) -> bool {
        registered_address::read(_address)
    }

    ////////////////////////////////
    // register function registers an address for the ICO
    ////////////////////////////////
    #[external]
    fn register() {
        let this_contract = get_contract_address();
        let caller = get_caller_address();
        let token = token_address::read();
        let end_time: u64 = ico_end_time::read();
        let current_time: u64 = get_block_timestamp();
        let eth_contract: ContractAddress = eth_address::read();

        // check that ICO has not ended
        //assert(current_time < end_time, 'ICO has been completed');
        // check that user is not already registered
        assert(is_registered(caller) == false, 'You have already registered!');
        // check that the user has beforehand approved the address of the ICO contract to spend the registration amount from his ETH balance
        // let allowance = IERC20Dispatcher {contract_address: eth_contract}.allowance(caller, this_contract);
        // assert(allowance >= u256_from_felt252(REGPRICE), 'approve at least 0.001 ETH!');

        IERC20Dispatcher {contract_address: eth_contract}.transfer_from(caller, this_contract, u256_from_felt252(REGPRICE));

        registered_address::write(caller, true);
        return ();
    }

    ////////////////////////////////
    // claim function is used to claim token distribution after ICO has ended
    ////////////////////////////////
    fn claim(_address: ContractAddress) {
        let claim_amount = u256_from_felt252(20);
        let token = token_address::read();
        let end_time: u64 = ico_end_time::read();
        let current_time: u64 = get_block_timestamp();

        // check that user is registered
        assert(is_registered(_address) == true, 'You are not eligible!');
        // check that ICO has ended
        assert(current_time > end_time, 'ICO is not yet ended!');
        // check that user has not previously claimed
        let claim_status = claimed_address::read(_address);
        assert(claim_status == false, 'You already claimed!');

        IERC20Dispatcher {contract_address: token}.transfer(_address, claim_amount);

        claimed_address::write(_address, true);
        return ();
    }
}