use serde::Serde;
use starknet::ContractAddress;
use array::ArrayTrait;
use option::OptionTrait;

////////////////////////////////
// Call struct
////////////////////////////////
#[derive(Drop, Serde)]
struct Call {
    to: ContractAddress,
    selector: felt252,
    calldata: Array<felt252>,
}

#[account_contract]
mod Account {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use starknet::get_caller_address;
    use starknet::get_tx_info;
    use starknet::call_contract_syscall;
    use starknet::VALIDATED;
    use array::ArrayTrait;
    use array::SpanTrait;
    use box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use option::OptionTrait;
    use super::Call;
    use starknet::ContractAddress;
    use zeroable::Zeroable;
    use serde::ArraySerde;

    ////////////////////////////////
    // Storage variables
    ////////////////////////////////
    struct Storage {
        public_key: felt252,
    }

    ////////////////////////////////
    // constructor - sets the account public key
    ////////////////////////////////
    #[constructor]
    fn constructor(_public_key: felt252) {
        public_key::write(_public_key);
    }

    ////////////////////////////////
    // __validate_declare__ validates account declare tx - enforces fee payment
    ////////////////////////////////
    #[external]
    fn __validate_declare__(class_hash: felt252) -> felt252 {
        // dedicate logic to an internal function
        validate_transaction()
    }

    ////////////////////////////////
    // __validate_deploy__ validates account deployment tx
    ////////////////////////////////
    #[external]
    fn __validate_deploy__(class_hash: felt252, contract_address_salt: felt252, _public_key: felt252) -> felt252 {
        validate_transaction()
    }

    ////////////////////////////////
    // __validate__ validates a tx before execution
    ////////////////////////////////
    #[external]
    fn __validate__(contract_address: ContractAddress, entry_point_selector: felt252, calldata: Array<felt252>) -> felt252 {
        validate_transaction()
    }

    ////////////////////////////////
    // __execute__ execute txs
    ////////////////////////////////
    #[external]
    #[raw_output]
    fn __execute__(mut calls: Array<Call>) -> Span<felt252> {
        // check caller is a zero address
        let caller = get_caller_address();
        assert(caller.is_zero(), 'invalid caller!');

        // check transaction is valid
        let tx_info = get_tx_info().unbox();
        assert(tx_info.version != 0, 'invalid tx version!');

        // to keep implementation minimal, no extra feature e.g multicall is supported. can be implemented with adding a few lines of code if you want to.
        // since multicall is not supported, check array does not contain multiple elements
        assert(calls.len() == 1_u32, 'multicall not supported!');

        // get first element in calls array and destructure it
        let Call{to, selector, calldata} = calls.pop_front().unwrap();
        // make contract call using the low-level call_contract_syscall
        call_contract_syscall(
            address: to, entry_point_selector: selector, calldata: calldata.span()
        ).unwrap_syscall()
    }


    ////////////////////////////////
    // validate_transaction internal function that checks transaction signature is valid
    ////////////////////////////////
    fn validate_transaction() -> felt252 {
        let tx_info = get_tx_info().unbox();
        let signature = tx_info.signature;
        assert(signature.len() == 2_u32, 'invalid signature length!');
        
        assert(
            check_ecdsa_signature(
                message_hash: tx_info.transaction_hash,
                public_key: public_key::read(),
                signature_r: *signature[0_u32],
                signature_s: *signature[1_u32],
            ),
            'invalid signature!',
        );
        VALIDATED
    }
}