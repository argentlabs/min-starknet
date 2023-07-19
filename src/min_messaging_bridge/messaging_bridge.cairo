use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    #[view]
    fn get_name(self: @TContractState) -> felt252;

    #[view]
    fn get_symbol(self: @TContractState) -> felt252;

    #[view]
    fn get_total_supply(self: @TContractState) -> felt252;

    #[view]
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;

    #[view]
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;

    #[external]
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);

    #[external]
    fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256);

    #[external]
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256);
}

#[starknet::contract]
mod MessagingBridge {
    ////////////////////////////////
    // library imports
    //////////////////////////////// 
    use starknet::{ContractAddress, get_caller_address, get_contract_address, EthAddress, EthAddressIntoFelt252, syscalls::send_message_to_l1_syscall};
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::Into;
    use integer::u256_from_felt252;
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    #[storage]
    struct Storage {
        token_l2_address: ContractAddress,
        bridge_l1_address: felt252,
        admin: ContractAddress
    }

    ////////////////////////////////
    // constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: ContractState, _token_l2_address: ContractAddress, admin_address: ContractAddress) {
        self.token_l2_address.write(_token_l2_address);
        self.admin.write(admin_address);
    }

    #[external(v0)]
    #[generate_trait]
    impl MessagingBridgeImpl of MessagingBridgeTrait {
        ////////////////////////////////
        // get_token_balance - retrieves token balance for an address
        ////////////////////////////////
        fn get_token_balance(self: @ContractState, address: ContractAddress) -> u256 {
            let token_address = self.token_l2_address.read();

            // call balance_of
            IERC20Dispatcher{ contract_address: token_address }.balance_of(address)
        }

        ////////////////////////////////
        // set_bridge_l1_address - sets l1 bridge address to storage
        ////////////////////////////////
        fn set_bridge_l1_address(ref self: ContractState, address: EthAddress) {
            // check that caller is bridge admin
            let admin_address = self.admin.read();
            let caller = get_caller_address();
            assert(caller == admin_address, 'caller is not admin!');

            self.bridge_l1_address.write(address.into());
        }

        ////////////////////////////////
        // withdraw_to_l1 - can be called to bridge tokens to L1
        ////////////////////////////////
        fn withdraw_to_l1(ref self: ContractState, amount: u256, l1_recipient: EthAddress) {
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            let l2_token_address = self.token_l2_address.read();
            let l1_bridge_address = self.bridge_l1_address.read();

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
        fn deposit_to_l2(ref self: ContractState, from_address: felt252, user_address: ContractAddress, amount: u256) {
            let l1_bridge_address = self.bridge_l1_address.read();
            let l2_token_address = self.token_l2_address.read();
            assert(from_address == l1_bridge_address, 'incorrect bridge incorrect');

            // transfer amount from locked bridge tokens to the user
            IERC20Dispatcher{ contract_address: l2_token_address }.transfer(user_address, amount);
        }
    }
}