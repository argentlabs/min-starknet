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