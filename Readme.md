<div align="center">
  <h1>MIN-STARKNET - Cairo 1.0🐺 </h1>
  <h2> ⚡ Learn Cairo by building 🧑🏽‍💻 </h2>
<div align="center">
<br />

[![GitHub Workflow Status](https://github.com/starkware-libs/cairo/actions/workflows/ci.yml/badge.svg)](https://github.com/starkware-libs/cairo/actions/workflows/ci.yml)
[![Project license](https://img.shields.io/github/license/starkware-libs/cairo.svg?style=flat-square)](LICENSE)
[![Pull Requests welcome](https://img.shields.io/badge/PRs-welcome-ff69b4.svg?style=flat-square)](https://github.com/starkware-libs/cairo/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)

</div>
</div>

---

## MIN-STARKNET

Min-StarkNet is a side project influenced by Miguel Piedrafita's [Lil-Web3](https://github.com/m1guelpf/lil-web3), aimed at creating minimal, intentionally-limited implementations of different protocols, standards and concepts to help a Cairo beginner learn and become familiar with basic Cairo syntaxes, quickly advancing from beginner to intermediate😉.

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

## PLAYGROUND

Deployed contracts coming in soon..

## CONTRIBUTION GUIDELINES
1. Keep implementation as simple and minimalistic as possible.
2. Comment codes in details to enable others understand what your codes do.
3. Keep your codes simple and clean.
4. When opening PRs, give a detailed description of what you are trying to fix or add.
   Let's build a great learning REPO for frens looking to get started with Cairo. 😉

**If this repo was helpful, do give it a STAR!**