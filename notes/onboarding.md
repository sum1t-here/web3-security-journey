# 🔐 Smart Contract Security — Audit Framework

> *"Security is not a checklist. It's a culture."*
> A structured guide for preparing, executing, and following up on smart contract security reviews.

---

## 🗂️ Table of Contents

- [🧪 The Rekt Test](#-the-rekt-test)
- [📋 Audit Onboarding](#-audit-onboarding)
  - [Basic Info](#-basic-info)
  - [Code Details](#-code-details)
  - [Protocol Details](#-protocol-details)
  - [Protocol Risks](#-protocol-risks)
  - [Known Issues](#-known-issues)
  - [Previous Audits](#-previous-audits)
  - [Resources](#-resources)
- [📁 Minimal Onboarding Template](#-minimal-onboarding-template)
  - [About the Project](#about-the-project--documentation)
  - [Stats](#stats)
  - [Setup](#setup)
  - [Security Review Scope](#security-review-scope)
  - [Roles](#roles)
- [🚀 Post Deployment Planning](#-post-deployment-planning)

---

---

## 🧪 The Rekt Test

> Answer honestly. If you can't say yes to most of these, you're not ready for production.

| # | Question | ✅ / ❌ |
|---|---|---|
| 1 | Do you have all actors, roles, and privileges documented? | |
| 2 | Do you keep documentation of all external services, contracts, and oracles you rely on? | |
| 3 | Do you have a written and tested incident response plan? | |
| 4 | Do you document the best ways to attack your own system? | |
| 5 | Do you perform identity verification and background checks on all employees? | |
| 6 | Do you have a team member with security defined in their role? | |
| 7 | Do you require hardware security keys for production systems? | |
| 8 | Does your key management system require multiple humans and physical steps? | |
| 9 | Do you define key invariants for your system and test them on every commit? | |
| 10 | Do you use the best automated tools to discover security issues in your code? | |
| 11 | Do you undergo external audits and maintain a vulnerability disclosure or bug bounty program? | |
| 12 | Have you considered and mitigated avenues for abusing users of your system? | |

---

---

## 📋 Audit Onboarding

*Complete this before engaging an auditor. The more detail here, the better the review.*

---

### 🪪 Basic Info

| Field | Answer |
|---|---|
| Protocol Name | |
| Website | |
| Link to Documentation | |
| Key Point of Contact (Name, Email, Telegram) | |
| Link to Whitepaper *(optional)* | |

---

### 💻 Code Details

| Field | Answer |
|---|---|
| Link to Repo to be audited | |
| Commit hash | |
| Number of contracts in scope | |
| Total SLOC for contracts in scope | |
| Complexity Score | |
| How many external protocols does the code interact with | |
| Overall test coverage for code under audit | |

#### In-Scope Contracts

> Run the following to generate a clean file tree:
> ```bash
> tree ./src/ | sed 's/└/#/g; s/──/--/g; s/├/#/g; s/│ /|/g; s/│/|/g'
> ```

```
[ Place in-scope contracts here ]
```

---

### ⚙️ Protocol Details

| Field | Answer |
|---|---|
| Current Status | |
| Is the project a fork of an existing protocol? | |
| If yes, which protocol? | |
| Does the project use rollups? | |
| Will the protocol be multi-chain? | |
| Chain(s) to deploy on | |
| Does the protocol use external oracles? | |
| Does the protocol use external AMMs? | |
| Does the protocol use zero-knowledge proofs? | |
| Which ERC20 tokens do you expect to interact with? | |
| Which ERC721 tokens do you expect to interact with? | |
| Are ERC777 tokens expected to interact with the protocol? | |
| Are there any off-chain processes (keeper bots, etc.)? | |
| If yes, explain | |

---

### ⚠️ Protocol Risks

> Tell the auditor what risks are in scope. Out-of-scope risks will not be evaluated.

| Risk Area | Evaluate? |
|---|---|
| Centralization risks | |
| Rogue protocol admin capturing user funds | |
| Deflationary / inflationary ERC20 tokens | |
| Fee-on-transfer tokens | |
| Rebasing tokens | |
| Pausing of any external contracts | |
| External oracle risks | |
| Blacklisted users for specific tokens | |
| Compliance with specific EIPs | |
| If yes to EIPs, list them | |

---

### 🐛 Known Issues

> List issues the team is already aware of and will not be fixing or acknowledging.

| Issue | Description |
|---|---|
| Issue #1 | |
| Issue #2 | |

---

### 📁 Previous Audits

| Field | Answer |
|---|---|
| Number of previous audits | |
| Link(s) to audit report(s) | |

---

### 📚 Resources

*Help the auditor understand your protocol faster.*

#### Flow Charts / Design Docs
-

#### Explainer Videos
-

#### Articles / Blogs
-

---

---

## 📁 Minimal Onboarding Template

*A leaner version for quick onboarding. Fill this out at minimum.*

---

### About the Project / Documentation

*Summary of the project. The more documentation, the better.*

---

### Stats

> Use `solidity-metrics` or `cloc` to generate these.

| Metric | Value |
|---|---|
| nSLOC | |
| Complexity Score | |
| Security Review Timeline | Date → Date |

---

### Setup

#### Requirements

*What tools are needed to set up the codebase and test suite?*

```bash
forge init
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install vectorized/solady --no-commit
forge build
```

#### Testing

*How to run tests and check coverage.*

```bash
forge test
```

---

### Security Review Scope

| Field | Detail |
|---|---|
| Commit Hash | |
| Repo URL | |
| In-scope contracts | |
| Out-of-scope contracts | |

#### Compatibilities

| Field | Value |
|---|---|
| Solc Version | |
| Chain(s) | e.g. ETH, Arbitrum |
| ERC20 Tokens | e.g. LINK: `<address>`, USDC: `<address>` |
| ERC721 Tokens | e.g. CryptoKitties: `<address>` |

> *List expected tokens explicitly. If the protocol works with any token of a standard, note "All ERC20s".*

---

### Roles

*Who are the actors? What can they do? What should they never do?*

```
Example:

Actors:
  Buyer   — The purchaser of services (e.g. a project buying an audit)
  Seller  — The seller of services (e.g. an auditor)
  Arbiter — Impartial trusted actor who resolves disputes.
            Only compensated arbiterFee if a dispute occurs.
```

---

---

## 🚀 Post Deployment Planning

> Security doesn't end at deployment. Plan for what happens after.

| Question | Answer |
|---|---|
| Are you planning on using a bug bounty program? Which one? | |
| What is your monitoring solution? | |
| What are you monitoring for? | |
| Who is your incident response team? | |

---

*Security reviews are only as good as the preparation behind them.*
*Document everything. Assume nothing. Test relentlessly.*