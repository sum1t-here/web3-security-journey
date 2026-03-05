# 🤖 AI Audit Prompt Library

> *Copy. Paste. Verify. Never skip the last step.*
> A ready-to-use collection of prompts for AI-assisted smart contract auditing.

---

## 🗂️ Table of Contents

- [🔍 Reconnaissance](#-reconnaissance)
- [🐛 Vulnerability Scanning](#-vulnerability-scanning)
- [⚔️ Attack Simulation](#-attack-simulation)
- [🧪 Proof of Concept](#-proof-of-concept)
- [📝 Report Writing](#-report-writing)
- [🧠 Deep Understanding](#-deep-understanding)
- [🔁 Cross-Contract & DeFi](#-cross-contract--defi)
- [✅ Review & Challenge](#-review--challenge)

---

---

## 🔍 Reconnaissance

*Use these first — before touching any vulnerability hunting.*

---

**Explain the contract**
```
Read this smart contract and explain:
1. What does it do in plain English?
2. Who are the actors and what are their roles?
3. What are the most critical functions?
4. What assets does it hold or move?

[PASTE CONTRACT HERE]
```

---

**Map the attack surface**
```
Given this smart contract, identify:
1. All external and public functions
2. All functions that move funds or change ownership
3. All functions with no access control
4. All places where external calls are made

[PASTE CONTRACT HERE]
```

---

**Summarize state variables**
```
List all state variables in this contract. For each one, tell me:
- What it stores
- Who can change it
- What happens if it is manipulated by an attacker

[PASTE CONTRACT HERE]
```

---

**Identify trust assumptions**
```
What trust assumptions does this contract make?
List every assumption about external contracts, oracles, tokens, 
and user behavior that the protocol relies on being true.

[PASTE CONTRACT HERE]
```

---

---

## 🐛 Vulnerability Scanning

*Focused prompts per vulnerability class. Run one at a time.*

---

**Reentrancy**
```
Review this contract specifically for reentrancy vulnerabilities.
- Does it follow the CEI pattern (Checks → Effects → Interactions)?
- Are there any external calls made before state updates?
- Could a malicious receive() or fallback() re-enter any function?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Access Control**
```
Audit this contract for access control issues.
- Are there any privileged functions missing onlyOwner or role checks?
- Can an arbitrary address call functions they should not be able to?
- Are there any functions that should be internal but are public/external?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Integer Overflow / Underflow**
```
Check this contract for integer overflow and underflow vulnerabilities.
- Are there any unchecked blocks used on user-controlled values?
- Are there any subtraction operations that could underflow?
- Are there any multiplication operations that could overflow before division?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Denial of Service (DoS)**
```
Review this contract for Denial of Service vulnerabilities.
- Are there any unbounded loops over dynamic arrays?
- Can an attacker cause a function to permanently revert for other users?
- Are there any push-based payment patterns that could be griefed?
- Can an attacker inflate gas costs to make the contract unusable?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Front-Running & MEV**
```
Analyze this contract for front-running and MEV vulnerabilities.
- Are there any transactions whose outcome changes based on ordering?
- Are there missing slippage controls or deadline checks?
- Can a miner or bot extract value by reordering or sandwiching transactions?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Oracle Manipulation**
```
Review this contract for oracle manipulation vulnerabilities.
- Does it rely on a single oracle source that could be manipulated?
- Does it use spot prices from an AMM that could be flash-loan manipulated?
- Is there a TWAP or multi-source aggregation in place?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Flash Loan Attacks**
```
Analyze this contract for flash loan attack vectors.
- Are there any operations that could be manipulated with a large temporary balance?
- Are there any price checks, collateral checks, or governance votes 
  that could be influenced within a single transaction?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Signature & Replay Attacks**
```
Check this contract for signature and replay vulnerabilities.
- Are signatures validated with a proper nonce to prevent replay?
- Is the chain ID included in the signed message to prevent cross-chain replay?
- Is EIP-712 structured signing used, or raw abi.encodePacked (collision risk)?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Centralization & Admin Risk**
```
Assess the centralization risks in this contract.
- What can the owner/admin do unilaterally?
- Can the owner rug users (drain funds, freeze withdrawals, upgrade maliciously)?
- Are there timelocks or multi-sig requirements on privileged operations?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

**Unsafe ERC20 Handling**
```
Review this contract for unsafe ERC20 token handling.
- Does it use transfer() instead of safeTransfer()?
- Does it handle fee-on-transfer tokens correctly?
- Does it handle rebasing tokens correctly?
- Does it check return values from ERC20 calls?
Point to the exact line number if you find an issue.

[PASTE CONTRACT HERE]
```

---

---

## ⚔️ Attack Simulation

*Think like an attacker.*

---

**Full attacker mindset scan**
```
You are a malicious smart contract auditor trying to steal funds.
Given this contract, describe the top 3 most viable attack paths
an attacker could take to extract value or break the protocol.
For each attack, explain:
1. The vulnerability being exploited
2. The steps to execute the attack
3. The expected outcome

[PASTE CONTRACT HERE]
```

---

**One function deep dive**
```
Focus only on this function and find every possible way to exploit it.
Consider: reentrancy, bad inputs, state manipulation, access bypass,
gas griefing, and any unexpected edge cases.

[PASTE FUNCTION HERE]
```

---

**Invariant violations**
```
Given these protocol invariants:
[LIST YOUR INVARIANTS — e.g. "total supply must always equal sum of balances"]

Review the contract and find any code paths that could violate 
one or more of these invariants.

[PASTE CONTRACT HERE]
```

---

---

## 🧪 Proof of Concept

*After you confirm a bug, generate the test.*

---

**Foundry PoC test**
```
Write a Foundry test in Solidity that proves this vulnerability:
[DESCRIBE THE VULNERABILITY]

The test should:
1. Deploy the vulnerable contract
2. Set up the attacker contract
3. Execute the attack
4. Assert that the attack succeeded (e.g. attacker drained funds)

Use vm.prank, vm.deal, and vm.expectRevert where appropriate.
```

---

**Attacker contract**
```
Write a Solidity attacker contract that exploits this vulnerability:
[DESCRIBE THE VULNERABILITY AND PASTE THE TARGET CONTRACT]

The attacker contract should have:
- An attack() function that initiates the exploit
- A receive() or callback if reentrancy is involved
- Comments explaining each step
```

---

---

## 📝 Report Writing

*Structure your findings fast.*

---

**Full finding report**
```
Write a smart contract audit finding using this exact format:

### [SEVERITY-#] TITLE (Root Cause + Impact)

**Description:**
**Impact:**
**Proof of Concept:**
**Recommended Mitigation:**

Details:
- Severity: [High / Medium / Low]
- Root Cause: [DESCRIBE ROOT CAUSE]
- Impact: [DESCRIBE IMPACT]
- Vulnerable code: [PASTE CODE SNIPPET]
- Fix: [DESCRIBE OR PASTE THE FIX]
```

---

**Title only**
```
Write a concise audit finding title using the format:
"Root Cause + Impact"

Root cause: [DESCRIBE ROOT CAUSE]
Impact: [DESCRIBE IMPACT]

Give me 3 title options, from most to least formal.
```

---

**Mitigation recommendation**
```
Given this vulnerable code:
[PASTE VULNERABLE CODE]

Write a clear and specific recommended mitigation.
Show a before/after code diff using + and - notation.
Explain why the fix works.
```

---

**Executive summary**
```
Write a professional executive summary for a smart contract audit report.

Protocol: [PROTOCOL NAME]
Findings: [X] High, [X] Medium, [X] Low, [X] Informational
Key issues: [LIST 2-3 MAIN ISSUES]
Auditor: Sumit Mazumdar

Keep it under 150 words. Formal, professional tone.
```

---

---

## 🧠 Deep Understanding

*Use when you encounter unfamiliar code or patterns.*

---

**Explain unfamiliar code**
```
Explain this code to me line by line as if I am a senior Solidity auditor
who has never seen this specific pattern before.
Highlight anything unusual, non-standard, or potentially dangerous.

[PASTE CODE HERE]
```

---

**Explain a DeFi primitive**
```
Explain how [AMM / lending protocol / vault / staking mechanism] works 
at the smart contract level.
What are the key invariants that must always hold?
What are the most common ways these are exploited?
```

---

**Math / formula verification**
```
Verify this on-chain math calculation is correct and safe:
[PASTE MATH LOGIC]

Expected behavior: [DESCRIBE WHAT IT SHOULD DO]
Check for: precision loss, rounding errors, overflow, 
division before multiplication, and edge cases at 0 and max values.
```

---

---

## 🔁 Cross-Contract & DeFi

*For protocols with external integrations.*

---

**External dependency audit**
```
This contract interacts with the following external contracts/protocols:
[LIST EXTERNAL DEPENDENCIES]

For each one, identify:
1. What assumptions are made about its behavior?
2. What happens if it is paused, upgraded, or behaves maliciously?
3. Are there any reentrancy risks from callbacks?

[PASTE CONTRACT HERE]
```

---

**Token compatibility check**
```
This contract handles ERC20 tokens. Check if it correctly handles:
- Fee-on-transfer tokens
- Rebasing tokens
- Tokens that return false instead of reverting on failure
- Tokens with blacklists (e.g. USDC)
- Tokens with decimals other than 18
- ERC777 tokens with callbacks

[PASTE CONTRACT HERE]
```

---

---

## ✅ Review & Challenge

*Always run these after any AI output.*

---

**Challenge a finding**
```
You told me this is a vulnerability:
[PASTE AI FINDING]

Play devil's advocate. Argue why this might NOT be a vulnerability.
Could this be intentional protocol design?
Is there any condition that would prevent this from being exploited?
```

---

**Check for missed issues**
```
You reviewed this contract and found: [LIST FINDINGS]

What did you NOT check or potentially miss?
What other vulnerability classes should I manually review
that you may not have covered?
```

---

**Verify a fix**
```
The original vulnerable code was:
[PASTE ORIGINAL CODE]

The proposed fix is:
[PASTE FIXED CODE]

Does this fix fully mitigate the vulnerability?
Does it introduce any new vulnerabilities?
Are there any edge cases the fix does not handle?
```

---

*These prompts are tools — your judgment is the product.*
*Always verify. Always think. AI assists, you decide.*