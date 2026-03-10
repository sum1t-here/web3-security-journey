# ⚡ Reentrancy Attacks in Solidity

> *"The contract called out — and the attacker called back."*
> The most infamous class of smart contract vulnerability, responsible for the 2016 DAO hack and millions in drained ETH.

---

## 🧠 What is Reentrancy?

Reentrancy occurs when a contract calls an **external address before updating its internal state**, allowing the external contract to **re-enter the same function** and manipulate the contract state repeatedly.

The most famous example is the **2016 DAO hack** — attackers drained millions of ETH using this exact technique.

---

## 🗂️ Types of Reentrancy Attacks

| # | Type | Re-enters | Risk Level |
|---|---|---|---|
| 1 | **Single-Function** | Same function | 🔴 High |
| 2 | **Cross-Function** | Different function, same contract | 🔴 High |
| 3 | **Cross-Contract** | External contract → back in | 🔴 Critical |
| 4 | **Cross-Chain** | External contract → back in | 🔴 Critical |
| 5 | **Read-Only** | View function, stale state | 🟠 Medium |

---

[Historical collections of reentrancy attacks](https://github.com/pcaversaccio/reentrancy-attacks)

---

# 1️⃣ Single-Function Reentrancy

> The attacker re-enters the **exact same function** before it finishes executing.

---

## 🔄 The Broken Execution Order

When operations happen in this order, you're vulnerable:

```
1️⃣  Check conditions
2️⃣  External interaction   ← ⚠️ attack happens here
3️⃣  State update
```

The external contract calls back into the function **before** state changes, looping the withdrawal infinitely.

---

## ✅ The CEI Pattern — Your Shield

**Checks → Effects → Interactions**

```
1️⃣  Check        — validate conditions
2️⃣  Effects      — update all internal state
3️⃣  Interactions — make external calls
```

> Always update balances **before** sending ETH. Always.

---

## 🏦 The Vault Contract

A simple ETH vault — deposit, withdraw, track balances.

```solidity
mapping(address => uint256) private _balances;

// Users deposit Ether
function deposit() public payable {
    _balances[msg.sender] += msg.value;
}

// Withdraw — follows CEI Pattern ✅
function withdraw(uint256 amount) public {
    require(amount > 0, "Amount must be greater than 0");
    require(_balances[msg.sender] >= amount, "Insufficient balance");

    _balances[msg.sender] -= amount;                        // 🔷 Effect first
    (bool success, ) = msg.sender.call{value: amount}("");  // 🔷 Then interact
    require(success, "Withdrawal failed");
}
```

> The balance is deducted **before** ETH is sent — this is what makes it safe.

---

## ⚔️ The Attacker Contract

The attacker tries to exploit the vault through **recursive withdrawals**.

```solidity
receive() external payable {
    vault.withdraw(1 ether);   // 🔴 Re-enters on every ETH receive
}
```

**Attack flow:**

```
Attacker.attack()
      │
      ▼
Vault.withdraw()
      │
      ▼
send ETH to attacker
      │
      ▼
Attacker.receive()    ← 🔴 triggered automatically
      │
      ▼
Vault.withdraw() again
      │
      ▼
  ... loops ...
```

> If balance wasn't reduced first, this loop would drain the vault completely.

---

## 🛡️ Why the Attack Fails Here

Because the Vault follows CEI, the balance is already zeroed when the re-entry hits:

```solidity
_balances[msg.sender] -= amount;   // ✅ Updated BEFORE the call
```

When the attacker's `receive()` triggers `withdraw()` again:

```solidity
require(_balances[msg.sender] >= amount)   // ❌ FAILS — balance is 0
```

The entire transaction **reverts**:

```
Withdrawal failed
```

---

## 🔬 Testing the Attack

Foundry test confirming the defense works:

```solidity
vm.expectRevert("Withdrawal failed");
attacker.attack{value: 1 ether}();
```

> Write attack simulations in your tests — if you can break your own contract, an attacker can too.

---

## 🔒 Extra Defense — ReentrancyGuard

Even with CEI, best practice is to layer in OpenZeppelin's `ReentrancyGuard`:

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    function withdraw(uint256 amount) public nonReentrant {
        // ...
    }
}
```

The `nonReentrant` modifier blocks **any** reentrant call at the function level, regardless of state order.

> CEI protects logic. `nonReentrant` protects execution. Use both.

---

## 📌 Key Takeaways

| Principle | Detail |
|---|---|
| 🔴 **Root cause** | External call before state update |
| ✅ **Fix** | Follow CEI — Effects before Interactions |
| 🔒 **Best practice** | Add `ReentrancyGuard` on top of CEI |
| 🧪 **Validate** | Write attack simulations in your test suite |
| 📖 **Remember** | The 2016 DAO hack — $60M drained via reentrancy |

---

## 🗺️ Quick Reference

```
VULNERABLE                    SAFE
─────────────────────         ─────────────────────
1. Check balance      →       1. Check balance
2. Send ETH           →       2. ✅ Update balance
3. Update balance     →       3. Send ETH
      ↑
   attacker re-enters here    (attacker re-enters but balance = 0)
```

---

---

# 2️⃣ Cross-Function Reentrancy

> *Coming soon — notes in progress.*

The attacker re-enters a **different function** within the same contract that shares the same vulnerable state variable.

```
┌─────────────────────────────────────┐
│                                     │
│   [ Notes to be added here ]        │
│                                     │
│   Topics to cover:                  │
│   • How shared state enables this   │
│   • Example: withdraw() + transfer()│
│   • Why CEI alone may not suffice   │
│   • Defense strategies              │
│                                     │
└─────────────────────────────────────┘
```

---

---

# 3️⃣ Cross-Contract Reentrancy

> *Coming soon — notes in progress.*

The attack spans **multiple contracts** — state is shared across contracts, and the callback is routed through a third party.

```
┌─────────────────────────────────────┐
│                                     │
│   [ Notes to be added here ]        │
│                                     │
│   Topics to cover:                  │
│   • Multi-contract state sharing    │
│   • Real-world DeFi examples        │
│   • Attack flow diagram             │
│   • Defense at architecture level   │
│                                     │
└─────────────────────────────────────┘
```

---

---

# 4️⃣ Read-Only Reentrancy

> *Coming soon — notes in progress.*

No state change needed — the attacker re-enters during a **view call** to read stale/mid-execution state, typically to manipulate price oracles in DeFi protocols.

```
┌─────────────────────────────────────┐
│                                     │
│   [ Notes to be added here ]        │
│                                     │
│   Topics to cover:                  │
│   • Why view functions aren't safe  │
│   • Oracle manipulation via stale   │
│     state reads                     │
│   • Real DeFi protocol examples     │
│   • Mitigation patterns             │
│                                     │
└─────────────────────────────────────┘
```

---

*Smart contract security isn't optional — it's foundational.*
*Audit like an attacker. Build like a defender.*