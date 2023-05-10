#[contract]

mod ENS {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    struct Storage{
        names: LegacyMap::<ContractAddress, felt252>,
    }

    ////////////////////////////////
    // emitted each time a name is stored
    ////////////////////////////////
    #[event]
    fn StoredName(address: ContractAddress, name: felt252) {}

    ////////////////////////////////
    // initialized on contract deployment (not necessary in a real life case, but demonstrates how to write constructors)
    ////////////////////////////////
    #[constructor]
    fn constructor(_name: felt252) {
        let caller = get_caller_address();
        names::write(caller, _name)
    }

    ////////////////////////////////
    // function to store/attach a name to an address
    ////////////////////////////////
    #[external]
    fn store_name(_name: felt252) {
        let caller = get_caller_address();
        names::write(caller, _name);
        StoredName(caller, _name)
    }

    ////////////////////////////////
    // function to get name associated with an address
    ////////////////////////////////
    #[view]
    fn get_name(_address: ContractAddress) -> felt252 {
        names::read(_address)
    }
}