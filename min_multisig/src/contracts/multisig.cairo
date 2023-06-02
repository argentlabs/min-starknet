#[account_contract]

mod MultiSig {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use starknet::ContractAddress;
    use starknet::get_tx_info;
    use starknet::get_caller_address;
    use starknet::contract_address_try_from_felt252;
    use starknet::contract_address_to_felt252;
    use starknet::VALIDATED;
    use starknet::call_contract_syscall;
    use zeroable::Zeroable;
    use ecdsa::check_ecdsa_signature;
    use array::ArrayTrait;
    use array::SpanTrait;
    use option::OptionTrait;
    use traits::Into;
    use traits::TryInto;
    use box::BoxTrait;
    use serde::Serde;
    use serde::ArraySerde;

    use starknet::StorageAccess;
    use starknet::StorageBaseAddress;
    use starknet::SyscallResult;
    use starknet::storage_address_from_base_and_offset;
    use starknet::storage_base_address_from_felt252;
    use starknet::storage_write_syscall;
    use starknet::storage_read_syscall;

    ////////////////////////////////
    // Call struct
    ////////////////////////////////
    #[derive(Serde, Drop)]
    struct Call {
        to: ContractAddress,
        selector: felt252,
        calldata: Array<felt252>,
        confirmations: usize,
        executed: bool,
    }

    ////////////////////////////////
    // Storage variables
    ////////////////////////////////
    struct Storage {
        num_owners: usize,
        threshold: usize,
        prev_tx: felt252,
        ownership: LegacyMap<ContractAddress, bool>,
        owners_pub_keys: LegacyMap<ContractAddress, felt252>,
        tx_info: LegacyMap<felt252, Call>,
        has_confirmed: LegacyMap<(ContractAddress, felt252), bool>,
    }

    ////////////////////////////////
    // SubmittedTransaction - emitted each time a new tx is submitted
    ////////////////////////////////
    #[event]
    fn SubmittedTransaction(owner: ContractAddress, tx_index: felt252) {}

    ////////////////////////////////
    // ConfirmedTransaction - emitted each time a tx is confirmed
    ////////////////////////////////
    #[event]
    fn ConfirmedTransaction(owner: ContractAddress, tx_index: felt252) {}

    ////////////////////////////////
    // ExecutedTransaction - emitted each time a tx is executed
    ////////////////////////////////
    #[event]
    fn ExecutedTransaction(owner: ContractAddress, tx_index: felt252) {}


    ////////////////////////////////
    // Constructor
    ////////////////////////////////
    #[constructor]
    fn constructor(mut owners: Array<ContractAddress>, _threshold: usize) {
        // check that multisig has min of 2 owners
        assert(owners.len() >= 2_usize, 'mimimum of 2 keys!');
        // check that threshold is less than or equal to no. of owners
        assert(_threshold <= owners.len(), 'invalid threshold!');

        // store num owners and threshold
        num_owners::write(owners.len());
        threshold::write(_threshold);
        // call the _set_owners internal function
        _set_owners(owners);
    }



    ////////////////////////////////
    // get_confirmations - returns no. of confirmation a tx has
    ////////////////////////////////
    #[view]
    fn get_confirmations(tx_index: felt252) -> usize {
        let tx: Call = tx_info::read(tx_index);
        tx.confirmations
    }

    ////////////////////////////////
    // get_num_owners - returns no. of owners in the multisig
    ////////////////////////////////
    #[view]
    fn get_num_owners() -> usize {
        num_owners::read()
    }

    ////////////////////////////////
    // get_owner_pub_key - returns the pub key of an owner
    ////////////////////////////////
    #[view]
    fn get_owner_pub_key(_address: ContractAddress) -> felt252 {
        is_owner(_address);
        owners_pub_keys::read(_address)
    }


    ////////////////////////////////
    // set_pub_key - called by owners to set their public key
    ////////////////////////////////
    #[external]
    fn set_pub_key(public_key: felt252) {
        let caller = get_caller_address();
        is_owner(caller);
        owners_pub_keys::write(caller, public_key);
        return ();
    }

    ////////////////////////////////
    // submit transaction - called by any owner to submit a tx
    ////////////////////////////////
    #[external]
    fn submit_transaction(contract_address: ContractAddress, entry_point_selector: felt252, calldata: Array<felt252>) {
        let caller = get_caller_address();
        // check that caller is owner and has set pub key
        is_owner(caller);
        has_set_pub_key();

        // create call
        let call = Call { to: contract_address, selector: entry_point_selector, calldata: calldata, confirmations: 0_usize, executed: false };
        // get the previous tx ID
        let tx_id = prev_tx::read() + 1;

        // store call in tx_info
        tx_info::write(tx_id, call);
        // update prev_tx to new tx ID
        prev_tx::write(tx_id);

        // emit SubmittedTransaction
        SubmittedTransaction(caller, tx_id);
        return ();
    }

    ////////////////////////////////
    // confirm_transaction - called by owners to confirm a tx
    ////////////////////////////////
    #[external]
    fn confirm_transaction(tx_index: felt252) {
        let caller = get_caller_address();

        // check caller is owner, tx exists, caller has set pub key and he hasn't confirmed before
        is_owner(caller);
        tx_exists(tx_index);
        has_set_pub_key();
        has_not_confirmed(caller, tx_index);

        // get and deserialize call
        let Call {to, selector, calldata, confirmations, executed} = tx_info::read(tx_index);
        // update no of confirmations by 1
        let no_of_confirmation = confirmations + 1_usize;
        // create an updated call with the new no of confirmations
        let updated_call = Call { to: to, selector: selector, calldata: calldata, confirmations: no_of_confirmation, executed: executed };

        // update tx info and has_confirmed status to prevent caller from confirming twice
        tx_info::write(tx_index, updated_call);
        has_confirmed::write((caller, tx_index), true);

        // emit ConfirmedTransaction
        ConfirmedTransaction(caller, tx_index);
        return ();   
    }

    ////////////////////////////////
    // __validate_declare__ validates account declare tx - enforces fee payment
    ////////////////////////////////
    #[external]
    fn __validate_declare__(class_hash: felt252) -> felt252 {
        let caller = get_caller_address();
        let _public_key = owners_pub_keys::read(caller);
        // dedicate logic to an internal function
        validate_transaction(_public_key)
    }

    ////////////////////////////////
    // __validate_deploy__ validates account deployment tx
    ////////////////////////////////
    #[external]
    fn __validate_deploy__(class_hash: felt252, contract_address_salt: felt252, _public_key: felt252) -> felt252 {
        validate_transaction(_public_key)
    }

    ////////////////////////////////
    // __validate__ validates a tx before execution
    ////////////////////////////////
    #[external]
    fn __validate__(contract_address: ContractAddress, entry_point_selector: felt252, calldata: Array<felt252>) -> felt252 {
        let caller = get_caller_address();
        let _public_key = owners_pub_keys::read(caller);
        validate_transaction(_public_key)
    }

    ////////////////////////////////
    // __execute__ executes the tx if no. of confirmations is above or equal to threshold
    ////////////////////////////////
    #[external]
    #[raw_output]
    fn __execute__(tx_index: felt252) -> Span<felt252> {
        let caller = get_caller_address();
        // check tx exists
        tx_exists(tx_index);
        // get and deserialize call
        let Call {to, selector, calldata, confirmations, executed} = tx_info::read(tx_index);
        // check no. of confirmations is greater than or equal to threshold
        assert(confirmations >= threshold::read(), 'min threshold not attained');

        // make contract call using the low-level call_contract_syscall
        let retdata: Span<felt252> = call_contract_syscall(
            address: to, entry_point_selector: selector, calldata: calldata.span()
        ).unwrap_syscall();

        // change tx status to executed
        let updated_call = Call { to: to, selector: selector, calldata: calldata, confirmations: confirmations, executed: true };
        // update tx info
        tx_info::write(tx_index, updated_call);

        // emit ExecutedTransaction
        ExecutedTransaction(caller, tx_index);
        // return data
        retdata
    }


    ////////////////////////////////
    // _set_owners - internal function that sets multisig owners on deployment
    ////////////////////////////////
    fn _set_owners(_owners: Array<ContractAddress>) {
        let mut multisig_owners = _owners;

        loop {
            match multisig_owners.pop_front() {
                Option::Some(owner) => {
                    ownership::write(owner, true);
                },
                Option::None(_) => {
                    break();
                }
            };
        };
    }

    ////////////////////////////////
    // is_owner - internal function that checks that an address is a valid owner
    ////////////////////////////////
    fn is_owner(address: ContractAddress) {
        assert(ownership::read(address) == true, 'not a member of multisig');
        return ();
    }

    ////////////////////////////////
    // has_set_pub_key - internal function that checks that an owner has set his pub key
    ////////////////////////////////
    fn has_set_pub_key() {
        let caller = get_caller_address();
        assert(owners_pub_keys::read(caller) != 0, 'set your pub key first');
        return ();
    }

    ////////////////////////////////
    // tx_exists - internal function that checks if a tx exists
    ////////////////////////////////
    fn tx_exists(tx_index: felt252) {
        let prev: u8 = prev_tx::read().try_into().unwrap();
       assert(tx_index.try_into().unwrap() <= prev, 'tx does not exist!');
       return ();
    }

    ////////////////////////////////
    // tx_not_executed - internal function that checks that a tx is not executed
    ////////////////////////////////
    fn tx_not_executed(tx_index: felt252) {
        let tx: Call = tx_info::read(tx_index);
        assert(tx.executed == false, 'tx already executed');
        return ();
    }

    ////////////////////////////////
    // has_not_confirmed - internal function that checks that an owner has not confirmed tx before
    ////////////////////////////////
    fn has_not_confirmed(caller: ContractAddress, tx_index: felt252) {
        let status: bool = has_confirmed::read((caller, tx_index));
        assert(status != true, 'already confirmed tx');
        return ();
    }

    ////////////////////////////////
    // validate_transaction internal function that checks transaction signature is valid
    ////////////////////////////////
    fn validate_transaction(_public_key: felt252) -> felt252 {
        let tx_info = get_tx_info().unbox();
        let signature = tx_info.signature;
        assert(signature.len() == 2_u32, 'invalid signature length!');
        
        assert(
            check_ecdsa_signature(
                message_hash: tx_info.transaction_hash,
                public_key: _public_key,
                signature_r: *signature[0_u32],
                signature_s: *signature[1_u32],
            ),
            'invalid signature!',
        );
        VALIDATED
    }

    ////////////////////////////////
    // Storage Access implementation for Call Struct - such a PITA, hopefully we won't need to do this in the future
    ////////////////////////////////
    impl CallStorageAccess of StorageAccess::<Call> {
        fn write(address_domain: u32, base: StorageBaseAddress, value: Call) -> SyscallResult::<()> {
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 0_u8),
                contract_address_to_felt252(value.to)
            );
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 1_u8),
                value.selector
            );
            let mut calldata_span = value.calldata.span();
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 2_u8),
                Serde::deserialize(ref calldata_span).unwrap()
            );
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 3_u8),
                value.confirmations.into()
            );
            let executed_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 4_u8).into());
            StorageAccess::write(address_domain, executed_base, value.executed)
        }

        fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Call> {
            let to_result = storage_read_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 1_u8)
            )?;

            let selector_result = storage_read_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 2_u8)
            )?;

            let calldata_result = storage_read_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 3_u8)
            )?;

            let confirmations_result = storage_read_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 4_u8)
            )?;

            let executed_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 5_u8).into());
            let executed_result: bool = StorageAccess::read(address_domain, executed_base)?;

            let mut calldata_arr = ArrayTrait::new();
            calldata_result.serialize(ref calldata_arr);

            Result::Ok(
                Call {
                    to: contract_address_try_from_felt252(to_result).unwrap(),
                    selector: selector_result,
                    calldata: calldata_arr,
                    confirmations: confirmations_result.try_into().unwrap(),
                    executed: executed_result
                }
            )
        }
    }
}
