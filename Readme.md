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

- Go ahead to clone the repo, by running the command below on a terminal:

`git clone git@github.com:Darlington02/min-starknet.git`

**PS: This project has two branches! The `master` branch serves as a guide, the `develop` branch gives a boilerplate for building on your own.**

## Description

### MIN-ENS

Min-ens is a simple implementation of a namespace service in Cairo. It contains a single external function `store_name` and a single view function `get_name`.
A storage variable `names` which is a mapping of **address** to **name**, is also used to store the names assigned to every address, and an event **stored_name** which is emitted each time a name is stored!

### MIN-ERC20

One of the basic things we learn to do whilst starting out with Smart contract development is learning to build and deploy the popular ERC2O token contract. In this repo, we implement the ERC20 standard from scratch.

The goal for this project is to build and deploy a simple ERC20 token contract.

### MIN-ICO

min-ico is a minimal implementation of a presale or ICO in Cairo. An initial coin offerings (ICOs) is the equivalent of an IPO, a popular way to raise funds for products and services usually related to cryptocurrency.

The thought process for this application is a user interested in participating in the ICO needs to first register with 0.001ETH by calling the `register` function, then once the ICO duration specified using the `ICO_DURATION` expires, he can now call the external function claim to claim his share of ICO tokens.

PS: All users partaking in the ICO pays same amount for registration, and claims equal amount of tokens.

Note: Remember to call `approve(, reg_amount)` on the StarkNet ETH contract before calling the `register` function.

### MIN-AMM
MIN-AMM is a minimal implementation of an AMM in Cairo. 
The max amount of token that can belong to the AMM `BALANCE_UPPER_BOUND`, the max amount of token that can belong to a pool `POOL_UPPER_BOUND` and the max amount of token a user account can hold are set as constants to simplify contract codes. We also restrict the pool to accept just two token types; `TOKEN_TYPE_A` and `TOKEN_TYPE_B`

The `get_account_token_balance` and `get_pool_token_balance` functions can be used to get the account and pool balance repspectively. The `set_pool_token_balance` is used to set the pool balance for a specific token type, and the `add_demo_token` can be used to add demo tokens to a user's account for testing the deployed app. Finally the `init_pool` is used to initialize a new AMM pool and the `swap` function is called to perform a swap.

### MIN-COMMIT-REVEAL
In this repo we demonstrate how to implement a commit-reveal scheme by building a blind auction. A blind auction is a sealed bidding auction in which bidders simultaneously submit bids to the auctioneer without having knowledge of what other bidders bidded. This might sound paradoxical in a public system like blockchains, but cryptography comes to the rescue.

During the bidding period a bidder calls the `make_bid` function, a bidder does not actually send their bid, but only a hashed version of it. Since it is currently considered practically impossible to find two (sufficiently long) values whose hash values are equal, the bidder commits to the bid by that. After the end of the bidding period, the bidders have to reveal their bids by calling the `reveal` function: They send their values unencrypted, and the contract checks that the hashed value `bid_hash` is the same as the one provided during the bidding period `bid_commit`.

At the end of the auction, the auctioneer is paid the bid of the highest bidder, and other bidders get refunded their bids by claiming using the `claim_lost_bid` function.



## PLAYGROUND

Deployed contracts coming in soon..

## CONTRIBUTION GUIDELINES
1. Keep implementation as simple and minimalistic as possible.
2. Comment codes in details to enable others understand what your codes do.
3. Keep your codes simple and clean.
4. When opening PRs, give a detailed description of what you are trying to fix or add.
   Let's build a great learning REPO for frens looking to get started with Cairo. 😉

**If this repo was helpful, do give it a STAR!**