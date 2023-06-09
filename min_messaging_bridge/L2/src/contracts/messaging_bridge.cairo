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
mod MessagingBridge {
    ////////////////////////////////
    // library imports
    //////////////////////////////// 
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::EthAddress;
    use starknet::EthAddressIntoFelt252;
    use starknet::syscalls::send_message_to_l1_syscall;
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::Into;
    use integer::u256_from_felt252;
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    struct Storage {
        token_l2_address: ContractAddress,
        bridge_l1_address: felt252,
        admin: ContractAddress
    }

    ////////////////////////////////
    // constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(_token_l2_address: ContractAddress, admin_address: ContractAddress) {
        token_l2_address::write(_token_l2_address);
        admin::write(admin_address);
        return ();
    }

    ////////////////////////////////
    // get_token_balance - retrieves token balance for an address
    ////////////////////////////////
    #[view]
    fn get_token_balance(address: ContractAddress) -> u256 {
        let token_address = token_l2_address::read();

        // call balance_of
        IERC20Dispatcher{ contract_address: token_address }.balance_of(address)
    }

    ////////////////////////////////
    // set_bridge_l1_address - sets l1 bridge address to storage
    ////////////////////////////////
    #[external]
    fn set_bridge_l1_address(address: EthAddress) {
        // check that caller is bridge admin
        let admin_address = admin::read();
        let caller = get_caller_address();
        assert(caller == admin_address, 'caller is not admin!');

        bridge_l1_address::write(address.into());
    }

    ////////////////////////////////
    // withdraw_to_l1 - can be called to bridge tokens to L1
    ////////////////////////////////
    #[external]
    fn withdraw_to_l1(amount: u256, l1_recipient: EthAddress) {
        let caller = get_caller_address();
        let this_contract = get_contract_address();
        let l2_token_address = token_l2_address::read();
        let l1_bridge_address = bridge_l1_address::read();

        // check that the user has beforehand approved the bridge contract to spend the withdrawn amount from his token balance
        let allowance = IERC20Dispatcher {contract_address: l2_token_address}.allowance(caller, this_contract);
        assert(allowance >= amount, 'approve bridge to spend tokens!');

        // lock the withdrawn tokens in the bridge contract
        IERC20Dispatcher{ contract_address: l2_token_address }.transfer_from(caller, this_contract, amount);

        // send message to l1
        let mut message_payload: Array<felt252> = ArrayTrait::new();
        message_payload.append(l1_recipient.into());
        message_payload.append(amount.low.into());
        message_payload.append(amount.high.into());

        send_message_to_l1_syscall(
            to_address: l1_bridge_address, payload: message_payload.span()
        );
    }

    ////////////////////////////////
    // deposit_to_l2 - L1 handler to deposit funds from L1 to Starknet
    ////////////////////////////////
    #[l1_handler]
    fn deposit_to_l2(from_address: felt252, user_address: ContractAddress, amount: u256) {
        let l1_bridge_address = bridge_l1_address::read();
        let l2_token_address = token_l2_address::read();
        assert(from_address == l1_bridge_address, 'incorrect bridge incorrect');

        // transfer amount from locked bridge tokens to the user
        IERC20Dispatcher{ contract_address: l2_token_address }.transfer(user_address, amount);
    }
}