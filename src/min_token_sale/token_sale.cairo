use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn get_name(self: @TContractState) -> felt252;
    fn get_symbol(self: @TContractState) -> felt252;
    fn get_decimals(self: @TContractState) -> u8;
    fn get_total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256);
    fn increase_allowance(ref self: TContractState, spender: ContractAddress, added_value: u256);
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    );
}

#[starknet::contract]
mod TokenSale {
    use starknet::{get_caller_address, get_contract_address, ContractAddress, get_block_timestamp};
    use integer::u256_from_felt252;

    use super::{IERC20DispatcherTrait, IERC20Dispatcher};

    const REGPRICE: felt252 = 1000000000000000;
    const ICO_DURATION: u64 = 86400_u64;

    #[storage]
    struct Storage {
        admin_address: ContractAddress,
        token_address: ContractAddress,
        eth_address: ContractAddress,
        is_registered: LegacyMap<ContractAddress, bool>,
        is_claimed: LegacyMap<ContractAddress, bool>,
        ico_end_time: u64,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _admin_address: ContractAddress,
        _token_address: ContractAddress,
        _eth_address: ContractAddress,
    ) {
        self.admin_address.write(_admin_address);
        self.token_address.write(_token_address);
        self.eth_address.write(_eth_address);

        let current_time = get_block_timestamp();
        let end_time = current_time + ICO_DURATION;
        self.ico_end_time.write(end_time);
    }

    #[external(v0)]
    #[generate_trait]
    impl TokenSaleImpl of TokenSaleTrait {
        fn register(ref self: ContractState) {
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            let token = self.token_address.read();
            let eth = self.eth_address.read();
            let current_time = get_block_timestamp();
            let end_time = self.ico_end_time.read();

            assert(current_time < end_time, 'ICO has ended');
            assert(self.is_registered.read(caller) == false, 'already registered user');

            IERC20Dispatcher { contract_address: eth }
                .transfer_from(caller, this_contract, u256_from_felt252(REGPRICE));

            self.is_registered.write(caller, true);
        }

        fn claim(ref self: ContractState, address: ContractAddress) {
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            let token = self.token_address.read();
            let eth = self.eth_address.read();
            let current_time = get_block_timestamp();
            let end_time = self.ico_end_time.read();
            let claim_amount = u256_from_felt252(20);
            let admin = self.admin_address.read();

            assert(current_time > end_time, 'ICO has not ended');
            assert(self.is_registered.read(address) == true, 'user is not registered');
            assert(self.is_claimed.read(address) == false, 'user has already claimed');

            IERC20Dispatcher { contract_address: token }
                .transfer_from(admin, address, claim_amount);

            self.is_claimed.write(address, true);
        }
    }
}
