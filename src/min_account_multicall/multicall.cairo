#[starknet::contract]
mod AccountContract {
    use starknet::{get_caller_address, account::Call, get_tx_info, VALIDATED, call_contract_syscall};
    use box::BoxTrait;
    use array::{ArrayTrait, SpanTrait};
    use ecdsa::check_ecdsa_signature;
    use zeroable::Zeroable;

    #[storage]
    struct Storage {
        public_key: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _public_key: felt252) {
        self.public_key.write(_public_key);
    }

    #[external(v0)]
    fn __validate_deploy__(self: @ContractState, contract_address_salt: felt252, entry_point_selector: felt252, public_key: felt252) -> felt252 {
        self.validate_transaction()
    }

    #[external(v0)]
    #[generate_trait]
    impl ContractAccountImpl of ContractAccountTrait {
        fn __validate_declare__(self: @ContractState, class_hash: felt252) -> felt252 {
            self.validate_transaction()
        }

        fn __validate__(ref self: ContractState, mut calls: Array<Call>) -> felt252 {
            self.validate_transaction()
        }

        fn __execute__(ref self: ContractState, mut calls: Array<Call>) -> Array<Span<felt252>> {
            let caller = get_caller_address();
            assert(caller.is_zero(), 'invalid caller');

            let tx_info = get_tx_info().unbox();
            assert(tx_info.version != 0, 'invalid tx version');

            self.execute_multicall(calls.span())
        }
    }

    #[generate_trait]
    impl AccountHelperImpl of AccountHelperTrait {
        fn validate_transaction(self: @ContractState) -> felt252 {
            let tx_info = get_tx_info().unbox();
            let signature = tx_info.signature;
            assert(signature.len() == 2_u32, 'invalid signature length');

            let _public_key = self.public_key.read();
            assert(
                check_ecdsa_signature(
                    message_hash: tx_info.transaction_hash,
                    public_key: _public_key,
                    signature_r: *signature[0_u32],
                    signature_s: *signature[1_u32],
                ),
                'invalid transaction'
            );
            VALIDATED
        }

        fn execute_multicall(ref self: ContractState, mut calls: Span<Call>) -> Array<Span<felt252>> {
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
                            }
                        }
                    },
                    Option::None(_) => {
                        break();
                    }
                };
            };
            result
        }
    }
}