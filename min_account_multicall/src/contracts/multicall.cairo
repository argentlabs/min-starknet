use starknet::ContractAddress;
use array::ArrayTrait;

////////////////////////////////
// Call struct
////////////////////////////////
#[derive(Drop, Serde)]
struct Call {
    to: ContractAddress,
    selector: felt252,
    calldata: Array<felt252>,
}

