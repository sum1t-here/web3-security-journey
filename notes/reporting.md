# 🐛 Audit Findings — Writing & Classification Guide

> *"A finding is only as good as how clearly it's communicated."*
> Structure every vulnerability the same way — root cause, impact, proof, fix.

---

## 📝 Finding Template

```markdown
### [S-#] TITLE (Root Cause + Impact)

**Description:**

**Impact:**

**Proof of Concept:**

**Recommended Mitigation:**
```

---

## 🏷️ Crafting the Title

Every finding title follows one simple rule:

> **Root Cause + Impact**

Ask yourself two questions before writing any title:

| Question | Example Answer |
|---|---|
| What is the root cause? | `setPassword` has no access control |
| What is the impact? | Non-owner can change the password |

**Result:**

```
[H-1] `setPassword` has no access control, allowing anyone to change the password
```

> Keep it precise. A good title tells the reader exactly what broke and what it costs.

---

## 🎯 Severity & Likelihood

### Likelihood Levels

| Level | When to Use | Example |
|---|---|---|
| 🔴 **High** | Highly probable to happen | A hacker can call a function directly and extract funds |
| 🟡 **Medium** | Occurs under specific conditions | A peculiar ERC20 token is used on the platform |
| 🟢 **Low** | Unlikely to occur | A hard-to-change variable must be set to a unique value at a specific time |

---

## 🗂️ Finding ID Format

```
[SEVERITY-NUMBER]  →  [H-1], [M-2], [L-3]
 │        │
 │        └── Finding number (order within severity)
 └─────────── H = High  |  M = Medium  |  L = Low
```

**Example:**

```
[H-1] Storing the password on-chain makes it visible to everyone
[H-2] `setPassword` has no access control, allowing anyone to change the password
[M-1] Missing deadline check allows stale transactions to execute
[L-1] Incorrect event emitted on withdrawal
```

---

## 📊 Report Ordering

> 💡 **Pro tip:** Always arrange findings from most to least severe.

```
High Severity    →   Worst impact, fix immediately
   │
Medium Severity  →   Conditional risk, fix before launch
   │
Low Severity     →   Minor issues, informational
```

Within each severity level, order from **worst offender → least offender**.

---

## ✅ Full Example Finding

```markdown
### [H-1] `setPassword` has no access control, allowing anyone to change the password

**Description:**
The `setPassword` function does not restrict who can call it. Any external
address can invoke it and overwrite the stored password, regardless of ownership.

**Impact:**
A malicious actor can change the password at any time, completely locking out
the legitimate owner and taking control of any password-gated functionality.

**Proof of Concept:**
function test_anyoneCanSetPassword() public {
    vm.prank(attacker);
    vault.setPassword("hacked");
    assertEq(vault.getPassword(), "hacked");
}

**Recommended Mitigation:**
Add an `onlyOwner` modifier to restrict access:

+ function setPassword(string memory newPassword) external onlyOwner {
      s_password = newPassword;
  }
```

---

*Document every finding with the same structure.*
*Consistency in reports builds trust with clients.*