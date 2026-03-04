[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# 🧪 web3-security-journey

> Raw learning repo. Daily Solidity practice, security experiments, CTF solutions, and notes documenting my path to becoming a smart contract auditor.
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

## 📁 Structure

```
web3-security-journey/
│
├── src/
│   ├── week1/
│   │   ├── MyToken.sol
│   │   └── Vault.sol
│   ├── week2/
│   │   └── DelegateExample.sol
│   ├── week3/
│   │   └── SimpleAMM.sol
│   ├── phase2/
│   │   ├── ReentrancyVulnerable.sol
│   │   └── ReentrancyAttack.sol
│   └── phase3/
│       └── MockAuditTarget.sol
│
├── test/
│   ├── week1/
│   │   ├── MyToken.t.sol
│   │   └── Vault.t.sol
│   ├── week2/
│   └── phase2/
│
├── ctf/
│   ├── ethernaut/
│   │   ├── 01-fallback.md
│   │   ├── 02-fallout.md
│   │   └── ...
│   └── damn-vulnerable-defi/
│       ├── 01-unstoppable.md
│       └── ...
│
├── notes/
│   ├── week1.md
│   ├── week2.md
│   .
│   .
│   .
│   ├── week24.md
│   ├── foundry-notes.md
│   ├── audit-report-patterns.md
│   └── vulnerability-glossary.md
│
├── mock-audits/
│   ├── audit-01/
│   │   └── report.md
│   └── audit-02/
│       └── report.md
│
├── foundry.toml
└── README.md
```

---

## 🗺️ Roadmap

| Phase | Focus | Duration | Status |
|-------|-------|----------|--------|
| 1 | Solidity Refresh | Weeks 1–3 | 🔄 In Progress |
| 2 | Security Fundamentals | Weeks 4–8 | ⏳ Upcoming |
| 3 | Tooling & Methodology | Weeks 9–14 | ⏳ Upcoming |
| 4 | Enter the Arena | Weeks 15–24 | ⏳ Upcoming |

---

## 📅 Weekly Log

### 🔄 Week 1 — Solidity Refresh
> Rebuild muscle memory. Write contracts from scratch without referencing docs.

- [x] ERC-20 token from memory
- [ ] Vault contract with deposit/withdraw
- [ ] Access control and pause mechanism
- [ ] Foundry tests for each contract
- [ ] Blog post: what felt rusty

**Contracts:** [`src/week1/`](./src/week1/)
**Tests:** [`test/week1/`](./test/week1/)

**Reflections:**
<!-- what felt rusty, what clicked, questions to revisit -->

---

### ⏳ Week 2 — Advanced Patterns
> Cover fallback/receive, delegatecall, msg.sender/value deeply.

- [ ] Rebuild contracts using fallback and receive
- [ ] Build a delegatecall example — understand the storage risk
- [ ] msg.sender vs tx.origin — write a test that exploits the difference
- [ ] Edge case fuzz tests

**Contracts:** [`src/week2/`](./src/week2/)

**Reflections:**
<!-- -->

---

### ⏳ Week 3 — DeFi Mechanics
> Understand how protocols handle liquidity and pricing.

- [ ] Implement a simple AMM from scratch
- [ ] Understand constant product formula x*y=k
- [ ] Study how price oracles work and why they can be manipulated
- [ ] Read one real DeFi protocol's source code

**Contracts:** [`src/week3/`](./src/week3/)

**Reflections:**
<!-- -->

---

### ⏳ Week 4 — Attack Patterns
> Learn the classic vulnerability patterns cold.

- [ ] Write a vulnerable reentrancy contract then exploit it
- [ ] Integer overflow/underflow — pre and post 0.8.0
- [ ] Access control issues — missing modifiers, tx.origin auth
- [ ] Read SWC Registry end to end
- [ ] Read 3 audit reports

**Contracts:** [`src/phase2/`](./src/phase2/)

**Reflections:**
<!-- -->

---

### ⏳ Week 5 — DeFi Exploits
> Understand how DeFi-specific attacks work.

- [ ] Flash loan attack — write a simple PoC
- [ ] Oracle manipulation — understand TWAP vs spot price
- [ ] Front-running — write a sandwich attack simulation
- [ ] Read 5 audit reports
- [ ] Study one Rekt News post-mortem in depth

**Reflections:**
<!-- -->

---

### ⏳ Weeks 6–7 — Ethernaut
> Complete all 20 levels. Write notes on every vulnerability.

- [ ] Levels 1–5
- [ ] Levels 6–10
- [ ] Levels 11–15
- [ ] Levels 16–20

**Solutions:** [`ctf/ethernaut/`](./ctf/ethernaut/)

---

### ⏳ Week 8 — Damn Vulnerable DeFi
> Real-world DeFi attack scenarios.

- [ ] Unstoppable
- [ ] Naive Receiver
- [ ] Truster
- [ ] Side Entrance
- [ ] The Rewarder

**Solutions:** [`ctf/damn-vulnerable-defi/`](./ctf/damn-vulnerable-defi/)

---

### ⏳ Week 9 — Foundry Deep Dive
> Fuzz tests, invariant tests, find bugs in your own code.

- [ ] Write fuzz tests for Phase 1 contracts
- [ ] Write invariant tests for the vault
- [ ] Find and fix at least one bug using fuzzing
- [ ] Learn forge coverage

**Reflections:**
<!-- -->

---

### ⏳ Week 10 — Slither
> Static analysis on real codebases.

- [ ] Install and configure Slither
- [ ] Run against your own contracts
- [ ] Run against an open-source protocol
- [ ] Triage and document findings

**Reflections:**
<!-- -->

---

### ⏳ Week 11 — Fuzzing
> Property-based testing with Echidna or Medusa.

- [ ] Install Echidna or Medusa
- [ ] Write invariant tests for vault contract
- [ ] Start Cyfrin Updraft security course
- [ ] Complete first 3 modules

**Reflections:**
<!-- -->

---

### ⏳ Week 12 — Audit Reports Study
> Learn how professional auditors think.

- [ ] Trail of Bits — 3 reports
- [ ] OpenZeppelin — 3 reports
- [ ] Cyfrin — 2 reports
- [ ] Spearbit — 2 reports
- [ ] Document recurring patterns

**Notes:** [`notes/audit-report-patterns.md`](./notes/audit-report-patterns.md)

---

### ⏳ Weeks 13–14 — Mock Audits
> Two full solo audits with written reports.

- [ ] Mock audit #1 — pick small open-source protocol
- [ ] Write full report
- [ ] Mock audit #2 — different protocol
- [ ] Write full report
- [ ] Compare findings to real audits where available

**Reports:** [`mock-audits/`](./mock-audits/)

---

### ⏳ Weeks 15–24 — Arena
> Real bounties and contests. Details tracked in portfolio repo.

- [ ] First Immunefi submission
- [ ] First CodeHawks contest
- [ ] First Code4rena contest
- [ ] First Cantina contest
- [ ] Review and specialise

---

## 🔧 Setup

```bash
# Clone
git clone https://github.com/sum1t-here/web3-security-journey
cd web3-security-journey

# Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Run all tests
forge test -vv

# Run specific week
forge test --match-path "test/week1/*" -vv

# Run with fuzz
forge test --fuzz-runs 1000

# Coverage
forge coverage
```

**`foundry.toml`**
```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[fuzz]
runs = 1000

[invariant]
runs = 256
```

---

## 📊 Progress Tracker

| Metric | Count |
|--------|-------|
| Weeks completed | 0 / 24 |
| Contracts written | 0 |
| CTF challenges solved | 0 |
| Audit reports read | 0 |
| Mock audits completed | 0 |
| Valid findings submitted | 0 |

---

## 📚 Resources

| Resource | Type | Use |
|----------|------|-----|
| [Cyfrin Updraft](https://updraft.cyfrin.io) | Course | Primary learning path |
| [Ethernaut](https://ethernaut.openzeppelin.com) | CTF | Vulnerability practice |
| [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz) | CTF | DeFi attack scenarios |
| [SWC Registry](https://swcregistry.io) | Reference | Vulnerability classification |
| [Solodit](https://solodit.xyz) | Reference | Aggregated audit findings |
| [Rekt News](https://rekt.news) | Reference | Real exploit post-mortems |
| [EVM.codes](https://evm.codes) | Reference | Opcode reference |
| [Immunefi](https://immunefi.com) | Platform | Bug bounties |
| [CodeHawks](https://codehawks.com) | Platform | Audit contests |
| [Code4rena](https://code4rena.com) | Platform | Audit contests |
| [Cantina](https://cantina.xyz) | Platform | Audit contests |
| [Sherlock](https://sherlock.xyz) | Platform | Audit contests |

---

## 📝 Weekly Notes Template

Each week gets a `notes/weekN.md` file:

```markdown
# Week N Notes

## What I built
-

## What felt rusty
-

## What clicked
-

## Bugs I found in my own code
-

## Questions to revisit
-

## Next week focus
-
```

---

> *This repo is the messy work. The polished output lives at [solidity-security-portfolio](https://github.com/sum1t-here/solidity-security-portfolio).*