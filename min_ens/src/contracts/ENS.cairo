#[starknet::contract]

mod ENS {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    #[storage]
    struct Storage{
        names: LegacyMap::<ContractAddress, felt252>,
    }

    ////////////////////////////////
    // emitted each time a name is stored
    ////////////////////////////////
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredName: StoredName
    }

    #[derive(Drop, starknet::Event)]
    struct StoredName {
        address: ContractAddress,
        name: felt252
    }

    ////////////////////////////////
    // initialized on contract deployment (not necessary in a real life case, but demonstrates how to write constructors)
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: Storage, _name: felt252) {
        let caller = get_caller_address();
        self.names.write(caller, _name)
    }

    ////////////////////////////////
    // function to store/attach a name to an address
    ////////////////////////////////
    #[external]
    fn store_name(ref self: Storage, _name: felt252) {
        let caller = get_caller_address();
        self.names.write(caller, _name);
        self.emit(Event::StoredName(
            StoredName{address: caller, name: _name}
        ));
    }

    ////////////////////////////////
    // function to get name associated with an address
    ////////////////////////////////
    #[view]
    fn get_name(self: @Storage, _address: ContractAddress) -> felt252 {
        self.names.read(_address)
    }
}