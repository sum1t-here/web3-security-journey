# ⚡ ThunderLoan — Audit Scope

> Smart contract security audit scope for the ThunderLoan protocol.

---

## 📋 Audit Checklist

- [ ] Audit started
- [ ] Slither static analysis complete
- [ ] Manual review complete
- [ ] Test suite passing
- [ ] Findings documented
- [ ] Report submitted

---

## 📁 Scope

| Type | File | Logic Contracts | Interfaces | Lines | nLines | nSLOC | Comment Lines | Complexity Score | Capabilities |
|------|------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:--|
| 📝 | `src/audits/thunderLoan/protocol/OracleUpgradeable.sol` | 1 | | 32 | 32 | 23 | 2 | 18 | |
| 📝 | `src/audits/thunderLoan/protocol/ThunderLoan.sol` | 1 | | 295 | 265 | 146 | 94 | 128 | 🌀 🔍 |
| 🔍 | `src/audits/thunderLoan/interfaces/IPoolFactory.sol` | | 1 | 6 | 5 | 3 | 1 | 3 | 🔆 🔍 |
| 🔍 | `src/audits/thunderLoan/interfaces/ITSwapPool.sol` | | 1 | 6 | 5 | 3 | 1 | 3 | 🔆 🔍 |
| 🔍 | `src/audits/thunderLoan/interfaces/IThunderLoan.sol` | | 1 | 6 | 5 | 3 | 1 | 3 | 🔍 |
| 🔍 | `src/audits/thunderLoan/interfaces/IFlashLoanReceiver.sol` | | 1 | 20 | 11 | 4 | 5 | 3 | 🔆 |
| 📝 | `src/audits/thunderLoan/protocol/AssetToken.sol` | 1 | | 105 | 105 | 65 | 24 | 41 | |
| 📝 | `src/audits/thunderLoan/upgradeProtocol/ThunderLoanUpgraded.sol` | 1 | | 288 | 258 | 142 | 91 | 126 | 🌀 |
| | **Totals** | **4** | **4** | **758** | **686** | **389** | **219** | **325** | 🌀 🔆 |

---

## 🔑 Capabilities Legend

| Symbol | Meaning |
|:------:|---------|
| 🌀 | Uses assembly |
| 🔍 | Has external calls |
| 🔆 | Payable functions |

---

## 📊 Findings Tracker

| ID | Title | Severity | Status |
|----|-------|:--------:|:------:|
| H-1 | | 🔴 High | |
| H-2 | | 🔴 High | |
| M-1 | | 🟡 Medium | |
| L-1 | | 🟢 Low | |
| I-1 | | 🔵 Info | |

---

## 🛠️ Tools Used

- [ ] Slither
- [ ] Foundry / Forge
- [ ] Manual Review
- [ ] Echidna / Medusa

---

## 📝 Notes

<!-- Add audit notes here -->

---

*Audit by **Sumit** — Smart Contract Security Auditor*