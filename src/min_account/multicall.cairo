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
    use starknet::ContractAddress;
    use zeroable::Zeroable;
    use serde::ArraySerde;
    use serde::Serde;
    use serde::serialize_array_helper;
    use traits::Into;
    use option::OptionTrait;
    use super::Call;

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
    fn __execute__(calls: Array<Call>) -> Array<Span<felt252>> {
        // check caller is a zero address
        let caller = get_caller_address();
        assert(caller.is_zero(), 'invalid caller!');

        // check transaction is valid
        let tx_info = get_tx_info().unbox();
        assert(tx_info.version != 0, 'invalid tx version!');

        // call internal function `execute_multicall`
        execute_multicall(calls.span())
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

    ////////////////////////////////
    // execute_multicall internal function contains the multicall logic
    ////////////////////////////////
    fn execute_multicall(calls: Span<Call>) -> Array<Span<felt252>> {
        let mut result: Array<Span<felt252>> = ArrayTrait::new();
        let mut calls = calls;

        loop {
            match calls.pop_front() {
                Option::Some(call) => {
                    match call_contract_syscall(*call.to, *call.selector, call.calldata.span()) {
                        Result::Ok(mut retdata) => {
                            result.append(retdata);
                        },
                        Result::Err(revert_reason) => {
                            panic_with_felt252('multicall_failed');
                        },
                    }
                },
                Option::None(_) => {
                    break();
                },
            };
        };
        result
    }

    ////////////////////////////////
    // implement SpanSerde (temp fix till it's added to corelib)
    ////////////////////////////////
    impl SpanSerde<T,
    impl TSerde: Serde<T>,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>> of Serde<Span<T>> {
        fn serialize(self: @Span<T>, ref output: Array<felt252>) {
            (*self).len().serialize(ref output);
            serialize_array_helper(*self, ref output);
        }

        fn deserialize(ref serialized: Span<felt252>) -> Option<Span<T>> {
            Option::Some(ArraySerde::deserialize(ref serialized)?.span())
        }
    }
}
