---
title: "VaultProtocol Security Audit"
subtitle: "Smart Contract Security Review — v1.0"
date: "March 2026"
---

# Executive Summary

This report presents the findings of a smart contract security review conducted on **VaultProtocol**, a decentralized ETH vault system allowing users to deposit and withdraw funds trustlessly.

The audit was performed on the codebase at the commit hash specified below. The review focused on identifying security vulnerabilities, logical errors, and deviations from best practices.

| Field | Detail |
|---|---|
| Protocol | VaultProtocol |
| Review Type | Smart Contract Security Audit |
| Auditor | Sumit Mazumdar |
| Language | Solidity ^0.8.20 |
| Commit Hash | `a3f9c12e847b...` |
| Audit Period | March 01, 2026 → March 05, 2026 |
| Status | ✅ Complete |

---

# Disclaimer

This audit does not constitute financial or legal advice. The findings represent a best-effort review of the codebase at the specified commit hash. Security reviews cannot guarantee the absence of all vulnerabilities. Sumit Mazumdar assumes no liability for issues arising from use of the audited code in production.

---

# The Rekt Test

| # | Question | Status |
|---|---|---|
| 1 | Do you have all actors, roles, and privileges documented? | ✅ Yes |
| 2 | Do you keep documentation of all external services, contracts, and oracles? | ✅ Yes |
| 3 | Do you have a written and tested incident response plan? | ❌ No |
| 4 | Do you document the best ways to attack your system? | ✅ Yes |
| 5 | Do you perform identity verification and background checks on employees? | ⚠️ Partial |
| 6 | Do you have a team member with security defined in their role? | ✅ Yes |
| 7 | Do you require hardware security keys for production systems? | ❌ No |
| 8 | Does your key management system require multiple humans and physical steps? | ⚠️ Partial |
| 9 | Do you define key invariants and test them on every commit? | ✅ Yes |
| 10 | Do you use the best automated tools to discover security issues? | ✅ Yes |
| 11 | Do you undergo external audits and maintain a bug bounty program? | ⚠️ Partial |
| 12 | Have you considered and mitigated avenues for abusing users? | ✅ Yes |

---

# Protocol Overview

VaultProtocol is a minimalist ETH vault that allows:

- Users to **deposit** ETH into the vault
- Users to **withdraw** ETH from their balance
- An **owner** to pause the contract in emergencies

The vault tracks individual balances using a `mapping(address => uint256)` and enforces withdrawal limits per transaction.

## Roles

| Role | Description |
|---|---|
| `User` | Any address that deposits and withdraws ETH |
| `Owner` | Deployer of the contract; can pause and unpause the vault |

---

# Scope

## In-Scope Contracts

```
src/
├── Vault.sol
├── VaultFactory.sol
└── interfaces/
    └── IVault.sol
```

## Compatibilities

| Field | Value |
|---|---|
| Solc Version | `^0.8.20` |
| Chain(s) | Ethereum Mainnet, Arbitrum |
| ERC20 Tokens | None (ETH only) |
| ERC721 Tokens | None |

## Out of Scope

- `test/` directory
- `script/` deployment scripts
- Frontend interfaces

---

# Findings Summary

| ID | Title | Severity | Status |
|---|---|---|---|
| H-1 | `setPassword` lacks access control, anyone can change the password | 🔴 High | Open |
| H-2 | Reentrancy in `withdraw()` allows draining of vault funds | 🔴 High | Open |
| M-1 | Missing deadline check allows stale transactions to execute | 🟡 Medium | Open |
| M-2 | Integer overflow possible in unchecked balance addition | 🟡 Medium | Open |
| L-1 | Incorrect event emitted on withdrawal | 🟢 Low | Open |
| L-2 | Floating pragma allows compilation with untested compiler versions | 🟢 Low | Open |
| I-1 | Missing NatSpec documentation on public functions | ℹ️ Info | Acknowledged |

---

# Detailed Findings

---

## 🔴 High Severity

---

### [H-1] `setPassword` has no access control, allowing anyone to change the password

**Description:**
The `setPassword` function does not restrict which addresses are permitted to call it. Any external address can invoke the function and overwrite the stored password without any ownership or permission check.

```solidity
// @audit — no access control
function setPassword(string memory newPassword) external {
    s_password = newPassword;
    emit SetNetPassword();
}
```

**Impact:**
A malicious actor can change the password at any time, locking out the legitimate owner and taking control of any password-gated functionality across the protocol.

**Proof of Concept:**

```solidity
function test_anyoneCanSetPassword() public {
    vm.prank(attacker);
    vault.setPassword("hacked");
    assertEq(vault.getPassword(), "hacked"); // passes — attack succeeds
}
```

**Recommended Mitigation:**
Add an `onlyOwner` modifier to restrict access to the owner exclusively.

```solidity
- function setPassword(string memory newPassword) external {
+ function setPassword(string memory newPassword) external onlyOwner {
      s_password = newPassword;
      emit SetNetPassword();
  }
```

---

### [H-2] Reentrancy in `withdraw()` allows an attacker to drain vault funds

**Description:**
The `withdraw()` function sends ETH to the caller before updating the internal balance. This violates the Checks-Effects-Interactions (CEI) pattern and opens the contract to a reentrancy attack where a malicious contract's `receive()` function repeatedly re-enters `withdraw()` before the balance is zeroed.

```solidity
// @audit — CEI violation: ETH sent before balance update
function withdraw(uint256 amount) public {
    require(_balances[msg.sender] >= amount, "Insufficient balance");
    (bool success, ) = msg.sender.call{value: amount}(""); // interaction first
    require(success, "Withdrawal failed");
    _balances[msg.sender] -= amount; // state update last — too late
}
```

**Impact:**
An attacker can recursively drain the entire vault balance in a single transaction.

**Proof of Concept:**

```solidity
contract Attacker {
    IVault vault;

    function attack() external payable {
        vault.deposit{value: 1 ether}();
        vault.withdraw(1 ether);
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            vault.withdraw(1 ether); // re-enter before balance is updated
        }
    }
}
```

**Recommended Mitigation:**
Follow the CEI pattern — update state before making external calls. Additionally, add OpenZeppelin's `ReentrancyGuard` as a second layer of defense.

```solidity
function withdraw(uint256 amount) public nonReentrant {
    require(_balances[msg.sender] >= amount, "Insufficient balance");
+   _balances[msg.sender] -= amount;  // effect first
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Withdrawal failed");
-   _balances[msg.sender] -= amount;
}
```

---

## 🟡 Medium Severity

---

### [M-1] Missing deadline check allows stale transactions to execute

**Description:**
The `withdraw()` function does not include a deadline or expiry parameter. A transaction signed by a user can remain in the mempool indefinitely and execute at an unfavorable time chosen by a miner or MEV bot.

**Impact:**
Users may have withdrawals executed at unexpected times, potentially leading to fund loss in edge-case market conditions or front-running scenarios.

**Recommended Mitigation:**
Add a `deadline` parameter and validate it against `block.timestamp`:

```solidity
function withdraw(uint256 amount, uint256 deadline) public {
    require(block.timestamp <= deadline, "Transaction expired");
    // ...
}
```

---

### [M-2] Integer overflow possible in unchecked balance addition

**Description:**
The `deposit()` function uses an `unchecked` block when adding to `_balances`, which bypasses Solidity's built-in overflow protection introduced in `^0.8.0`.

**Impact:**
A crafted deposit amount could overflow the balance mapping, effectively zeroing a user's balance and allowing griefing or fund theft.

**Recommended Mitigation:**
Remove the `unchecked` block from balance arithmetic, or add explicit overflow bounds checking.

---

## 🟢 Low Severity

---

### [L-1] Incorrect event emitted on withdrawal

**Description:**
The `withdraw()` function emits `Deposited` instead of `Withdrawn`, causing off-chain indexers and monitoring tools to misinterpret contract activity.

**Recommended Mitigation:**

```solidity
- emit Deposited(msg.sender, amount);
+ emit Withdrawn(msg.sender, amount);
```

---

### [L-2] Floating pragma allows compilation with untested compiler versions

**Description:**
The contract uses `pragma solidity ^0.8.20`, which permits compilation with any `0.8.x` version above `0.8.20`. Future compiler versions may introduce breaking changes or bugs.

**Recommended Mitigation:**
Lock the pragma to a specific tested version:

```solidity
- pragma solidity ^0.8.20;
+ pragma solidity 0.8.20;
```

---

## ℹ️ Informational

---

### [I-1] Missing NatSpec documentation on public functions

**Description:**
Public functions `deposit()`, `withdraw()`, and `setPassword()` lack NatSpec comments (`@notice`, `@param`, `@return`). This reduces readability and makes external integrations harder.

**Recommended Mitigation:**
Add NatSpec to all public and external functions following the Solidity documentation standard.

---

# Tools Used

| Tool | Purpose |
|---|---|
| Foundry / Forge | Unit testing and fuzz testing |
| Slither | Static analysis |
| Aderyn | Solidity AST-based analysis |
| Manual Review | Logic and business rule analysis |

---

# Recommendations Summary

1. **Immediately** fix H-1 and H-2 — both are exploitable with zero preconditions.
2. Add `ReentrancyGuard` to all state-changing functions that send ETH.
3. Enforce CEI pattern across the entire codebase as a baseline standard.
4. Add a bug bounty program before mainnet deployment.
5. Set up an on-chain monitoring solution (e.g. OpenZeppelin Defender) post-deployment.

---

# Post Deployment Checklist

| Item | Status |
|---|---|
| Bug bounty program live | ⬜ |
| On-chain monitoring configured | ⬜ |
| Incident response plan documented | ⬜ |
| Multi-sig key management in place | ⬜ |
| Emergency pause mechanism tested | ⬜ |

---

*This report was prepared by **Sumit Mazumdar** and is intended solely for the VaultProtocol team.*
*Unauthorized distribution is prohibited.*