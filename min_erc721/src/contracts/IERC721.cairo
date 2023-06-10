use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TStorage> {
    #[view]
    fn get_name(self: @TStorage) -> felt252;

    #[view]
    fn get_symbol(self: @TStorage) -> felt252;

    #[view]
    fn get_token_uri(self: @TStorage, token_id: u256) -> felt252;

    #[view]
    fn balance_of(self: @TStorage, owner: ContractAddress) -> u256;

    #[view]
    fn owner_of(self: @TStorage, token_id: u256) -> ContractAddress;

    #[view]
    fn get_approved(self: @TStorage, token_id: u256) -> ContractAddress;

    #[view]
    fn is_approved_for_all(self: @TStorage, owner: ContractAddress, operator: ContractAddress) -> bool;

    #[external]
    fn approve(ref self: TStorage, approved: ContractAddress, token_id: u256);

    #[external]
    fn set_approval_for_all(ref self: TStorage, operator: ContractAddress, approved: bool);

    #[external]
    fn transfer_from(ref self: TStorage, from: ContractAddress, to: ContractAddress, token_id: u256);
}
