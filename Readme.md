<div align="center">
  <h1>MIN-STARKNET - Cairo 1.0🐺 </h1>
  <h2> ⚡ Learn Cairo by building 🧑🏽‍💻 </h2>
<div align="center">
<br />
</div>
</div>

---

## MIN-STARKNET

Min-StarkNet is a side project aimed at creating minimal, intentionally-limited implementations of different protocols, standards and concepts to help a Cairo beginner learn and become familiar with basic Cairo syntaxes, quickly advancing from beginner to intermediate😉. This repo should help you get up to speed and make you comfortable with writing the new Cairo.

## Getting Started

### Prerequisites

- Install and setup [Rust](https://www.rust-lang.org/tools/install)

- Install and setup [Scarb](https://docs.swmansion.com/scarb/download)

- Install and setup [Protostar](https://docs.swmansion.com/protostar/docs/cairo-1/installation)

- Go ahead to clone the repo, by running the command below on a terminal:

`git clone git@github.com:Darlington02/min-starknet.git`

## Description

### MIN-ENS

Min-ens is a simple implementation of a namespace service in Cairo. It contains a single external function `store_name` and a single view function `get_name`.
A storage variable `names` which is a mapping of **address** to **name**, is also used to store the names assigned to every address, and an event **stored_name** which is emitted each time a name is stored!

### MIN-ERC20

One of the basic things we learn to do whilst starting out with Smart contract development is learning to build and deploy the popular ERC2O token contract. In this repo, we implement the ERC20 standard from scratch.

The goal for this project is to build and deploy a simple ERC20 token contract.

### MIN-TOKEN-SALE

min-token-sale is a minimal implementation of a token presale in Cairo. A presale (formerly known as ICO) is the equivalent of an IPO, a popular way to raise funds for products and services usually related to cryptocurrency.

The thought process for this application is a user interested in participating in the presale needs to first register with 0.001ETH by calling the `register` function, then once the ICO duration specified using the `ICO_DURATION` expires, he can now call the external function claim to claim his share of tokens.

PS: All users partaking in the presale pays same amount for registration, and claims equal amount of tokens.

Note: Remember to call `approve(, reg_amount)` on the StarkNet ETH contract before calling the `register` function.

### MIN-AMM
MIN-AMM is a minimal implementation of an AMM in Cairo. 
The max amount of token that can belong to the AMM `BALANCE_UPPER_BOUND`, the max amount of token that can belong to a pool `POOL_UPPER_BOUND` and the max amount of token a user account can hold are set as constants to simplify contract codes. We also restrict the pool to accept just two token types; `TOKEN_TYPE_A` and `TOKEN_TYPE_B`

The `get_account_token_balance` and `get_pool_token_balance` functions can be used to get the account and pool balance repspectively. The `set_pool_token_balance` is used to set the pool balance for a specific token type, and the `add_demo_token` can be used to add demo tokens to a user's account for testing the deployed app. Finally the `init_pool` is used to initialize a new AMM pool and the `swap` function is called to perform a swap.

### MIN-COMMIT-REVEAL
In this section we demonstrate how to implement a commit-reveal scheme by building a blind auction. A blind auction is a sealed bidding auction in which bidders simultaneously submit bids to the auctioneer without having knowledge of what other bidders bidded. This might sound paradoxical in a public system like blockchains, but cryptography comes to the rescue.

During the bidding period a bidder calls the `make_bid` function, a bidder does not actually send their bid, but only a hashed version of it. Since it is currently considered practically impossible to find two (sufficiently long) values whose hash values are equal, the bidder commits to the bid by that. After the end of the bidding period, the bidders have to reveal their bids by calling the `reveal` function: They send their values unencrypted, and the contract checks that the hashed value `bid_hash` is the same as the one provided during the bidding period `bid_commit`.

At the end of the auction, the auctioneer is paid the bid of the highest bidder, and other bidders get refunded their bids by claiming using the `claim_lost_bid` function.

### MIN-ERC721

In this section, we demonstrate how to build an ERC721(NFT) contract, by implementing one from scratch. By the time you are done, you should be able to build and deploy your own cool NFTs on Starknet.

The goal for this project is to build and deploy a simple ERC721 contract.

### MIN-ACCOUNT-MULTICALL
Min-account-multicall aims to teach you how to write AA accounts on Starknet. All Starknet accounts are expected to include two major functions:
1. __validate__
2. __execute__

The `__validate__` function simply ensures txns submitted to the sequencer, was indeed intitatied by the account owner. Basically signature validation happens here…you could write custom logics to use any signature or verification scheme of your choice, while the `__execute__` function is responsible for executing the txn logic - calls to functions in the target smart contract. In here, the developer can control the flow of the txn, such as enabling multi calls (aggregating multiple tens into one), multisig logic, etc.

In this example, we are going to implement an account with multicall capabilities on Starknet. This account will be able to execute multiple transactions in one call.

### MIN-ACCOUNT-MULTISIG
In this example, we are going to be implementing a simple multisig on Starknet. A multisig wallet requires more than one signature to execute a transaction.

The flow of this multisig account is:
- First multisig owners are added on account deployment.
- To submit a transaction, any of the owners can call the `submit_transaction` function. 
- Submitted transactions can further then be confirmed by the owners of the multisig using the `confirm_transaction`.
- The transaction will be successfully executed if the number of confirmations, is greater than or equal to the threshold number of signatures, else it fails.

### MIN-MESSAGING-BRIDGE
The ability to create custom messaging bridges on StarkNet for data and asset transfers, is one of the major features that makes StarkNet stand out from other existing rollups.

In this project, we are going to be creating a simple custom ERC20 Messaging bridge that can help a user transfer an ERC20 token between StarkNet and Ethereum.

The thought process for this application, is we have an ERC20 token deployed on StarkNet, which we intend bridging to Ethereum, to enable users send their tokens between layers. We first have to deploy a clone of our ERC20 token on Ethereum, with zero initial supply (this is done to ensure that the total supply across the different layers when summed up, remains constant). We then deploy our token bridge on both layers, setting the ERC20 token we want to particularly bridge.

Each time a bridge happens from L2 -> L1, the bridged tokens are locked in the L2 bridge contract, and same amount of the bridged tokens are minted on L1 for the user, and each time a bridge happens from L1 -> L2, the bridged tokens are burnt, and the same amount of bridged tokens is released or transferred from the L2 bridge contract to the user, thereby always keeping total supply constant.

## CONTRIBUTION GUIDELINES
1. Keep implementation as simple and minimalistic as possible.
2. Comment codes in details to enable others understand what your codes do.
3. Keep your codes simple and clean.
4. When opening PRs, give a detailed description of what you are trying to fix or add.
   Let's build a great learning REPO for frens looking to get started with Cairo. 😉

**If this repo was helpful, do give it a STAR!**