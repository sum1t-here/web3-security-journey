[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# 🧪 web3-security-journey

> Raw learning repo. Daily Solidity practice, security experiments, audit targets, and notes documenting my path to becoming a smart contract auditor.
>
> **Portfolio & Audit Reports** → [solidity-security-portfolio](https://github.com/sum1t-here/solidity-security-portfolio)

---

## 📌 Context

- **Background:** Full Stack Blockchain Developer, Solidity level 3/5
- **Goal:** Competitive smart contract auditor in 6 months
- **Time commitment:** 1–2 focused hours daily alongside full-time job
- **Started:** 04-03-2026

This repo is intentionally raw. It's where I think out loud, make mistakes, and document what I learn. Clean audit reports and findings live in the portfolio repo above.

---

## 📂 What's Inside

### 🔰 Weekly Practice
Foundational Solidity and EVM concepts built week by week.

| Order | Topic | Link |
|------|-------|------|
| 1| Token from memory and Vault | [week-1](./src/week1/) |
| 2| Delegate call, Fallback, TxOrigin | [week-2](./src/week2/) |
| 3| Cyfrin Smart Contract Security | [audits](./src/audits/) |
| 4| Invariant Testing | [Invariant](./test/Invariant.t.sol) |
| 5| Fuzz tests | [Fuzz](./test/passwordStore/PasswordStore.t.sol) |
| 6| Rareskill Cross Contract | [CrossContract](./src/rareskill/crossContract/CrossContract.sol) |
| 7| Rareskill Decoder & Encoder | [Decoder](./src/rareskill/decoder/Decoder.sol) & [Encoder](./src/rareskill/encoder/Encoder.sol) |
| 8| Rareskill Excercise - Token Gated NFT | [TokenGatedNFT](./src/contracts/TokenGatedNft.sol) & [Tests](./test/contracts/TokenGatedNft) |
| 9| Adv Smart Contract Security - Huff and yul | [HorseStore](./src/horseStore) & [Differential Testing](./test/horseStore) |
| 10| Certora | [GasBad Spec](./certora/spec/GasBad.spec), [GasBad Config](./certora/conf/GasBad.conf), [GasBadNft contract](./src/audits/gasBadNft), [NftMock Spec](./certora/spec/NftMock.spec), [NftMock Config](./certora/conf/NftMock.conf), [NftMock](./src/audits/nftMock) & [MathMaster contract](./src/audits/mathMaster), [Mulwad Spec](./certora/spec/Mulwad.spec), [Mulwad Config](./certora/conf/Mulwad.conf), [Sqrt Spec](./certora/spec/Sqrt.spec), [Sqrt Config](./certora/conf/Sqrt.conf)|
| 11| Halmos | [Halmos Fuzzing](./test/mathMaster/MathMaster.t.sol) Line 72-79|

---

### 🔍 Audit Targets
Cyfrin Updraft audit practice targets. Each one has manual review notes, PoC tests, and a findings report.

| Protocol | Type | Key Vulnerability Classes | Findings |
|----------|------|--------------------------|----------|
| PasswordStore | Simple storage | Access control, visibility | [report](./findings/passwordStore/findings.md) |
| PuppyRaffle | ERC721 raffle | Reentrancy, randomness, DoS | [report](./findings/puppyRaffle/findings.md) |
| TSwap | AMM / DEX | AMM invariant, oracle manipulation | [report](./findings/tswap/findings.md) |
| ThunderLoan | Flash loans + UUPS | Upgrade storage collision, oracle attack | [report](./findings/thunderLoan/findings.md) |
| BossBridge | L1 cross-chain bridge | ECDSA replay, vault authorization | [report](./findings/bossBridge/findings.md) |

---

### 🏴 CTF Solutions

| Platform | Link |
|----------|------|
| Ethernaut | [ctf/ethernaut/](./ctf/ethernaut/) |
| Damn Vulnerable DeFi | [ctf/damn-vulnerable-defi/](./ctf/damn-vulnerable-defi/) |

---

### 📓 Notes

| Topic | Link |
|-------|------|
| Getting started in an Audit | [notes/getting-started.md](./notes/getting-started.md) |
| Onboarding questions | [notes/onboarding.md](./notes/onboarding.md) |
| Prompts for audits | [notes/prompts.md](./notes/prompts.md) |
| Report Sample | [notes/report-sample.md](./notes/report-sample.md) |
| Report Format | [notes/reporting.md](./notes/reporting.md) |
| Hans Checklist | [notes/hans.checklist.json](./notes/hans.checklist.json) |
| My Latex Template | [notes/sumit.latex](./notes/sumit.latex) |
| Foundry reference | [notes/foundry-notes.md](./notes/foundry-notes.md) |
| Tools | [notes/tools.md](./notes/tools.md) |

---

## 🔧 Setup

```bash
git clone https://github.com/sum1t-here/web3-security-journey
cd web3-security-journey

curl -L https://foundry.paradigm.xyz | bash
foundryup

forge install
forge test -vv
forge test --fuzz-runs 1000
forge test --match-contract Invariant -vv
forge coverage
```

---

## 📚 Resources

| Resource | Type | Use |
|----------|------|-----|
| [Cyfrin Updraft](https://updraft.cyfrin.io) | Course | Primary learning path |
| [Ethernaut](https://ethernaut.openzeppelin.com) | CTF | Vulnerability practice |
| [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz) | CTF | DeFi attack scenarios |
| [EVM.codes](https://evm.codes) | Reference | Opcode reference |
| [SWC Registry](https://swcregistry.io) | Reference | Vulnerability classification |
| [Solodit](https://solodit.xyz) | Reference | Aggregated audit findings |
| [Rekt News](https://rekt.news) | Reference | Real exploit post-mortems |
| [RareSkill Blog](https://www.rareskills.io/blog) | Reference | Deep EVM/Solidity topics |
| [Immunefi](https://immunefi.com) | Platform | Bug bounties |
| [CodeHawks](https://codehawks.com) | Platform | Audit contests |
| [Code4rena](https://code4rena.com) | Platform | Audit contests |
| [Cantina](https://cantina.xyz) | Platform | Audit contests |
| [Sherlock](https://sherlock.xyz) | Platform | Audit contests |
| [Reentrancy Attacks](https://github.com/pcaversaccio/reentrancy-attacks) | Reference | Reentrancy attacks |
| [ExcessivelySafeCall](https://github.com/nomad-xyz/ExcessivelySafeCall) | Solidity Library | call untrusted contracts safely |

---

> *This repo is the messy work. The polished output lives at [solidity-security-portfolio](https://github.com/sum1t-here/solidity-security-portfolio).*