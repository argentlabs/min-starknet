use starknet::ContractAddress;

#[abi]
trait IERC721 {
    #[view]
    fn get_name() -> felt252;

    #[view]
    fn get_symbol() -> felt252;

    #[view]
    fn get_token_uri(token_id: u256) -> felt252;

    #[view]
    fn balance_of(owner: ContractAddress) -> u256;

    #[view]
    fn owner_of(token_id: u256) -> ContractAddress;

    #[view]
    fn get_approved(token_id: u256) -> ContractAddress;

    #[view]
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool;

    #[external]
    fn approve(approved: ContractAddress, token_id: u256);

    #[external]
    fn set_approval_for_all(operator: ContractAddress, approved: bool);

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256);
}
