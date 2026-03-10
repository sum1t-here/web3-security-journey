# 🔍 Aderyn — Static Analysis Tool

> *Run it early. Run it often. Let the machine find the obvious so you can find the subtle.*
> Aderyn is a Rust-based Solidity static analyzer that scans your AST for known vulnerability patterns and bad practices.

---

## 🚀 Basic Usage

```bash
aderyn .
```

Scans the entire project from the current directory.

---

## 🎯 Scan a Specific Folder

```bash
aderyn . --src src/audits/puppyRaffle
```

| Part | Meaning |
|---|---|
| `aderyn` | run the tool |
| `.` | project root (where `foundry.toml` lives) |
| `--src` | limit the scan to this source folder only |
| `src/audits/puppyRaffle` | the specific contracts to analyze |

> Always use `--src` during an audit to scope the scan to only the in-scope contracts. Otherwise Aderyn will flag issues in test files, mocks, and dependencies you don't care about.

---

## 📄 Output

By default Aderyn generates a `report.md` in your project root:

```bash
aderyn . --src src/audits/puppyRaffle
# output → report.md
```

To specify a custom output file:

```bash
aderyn . --src src/audits/puppyRaffle --output aderyn-report.md
```

---

## 🛠️ Common Flags

| Flag | Usage | Description |
|---|---|---|
| `--src` | `--src src/` | Scope scan to specific folder |
| `--output` | `--output report.md` | Custom output file name |
| `--skip-update-check` | | Skip version update prompt |
| `--root` | `--root ./myproject` | Set project root explicitly |

---

## 📋 Audit Workflow with Aderyn

```
1. Navigate to project root
       │
       ▼
2. Run scoped scan
   aderyn . --src src/audits/puppyRaffle
       │
       ▼
3. Review generated report.md
       │
       ▼
4. Triage findings
   High/Medium  →  investigate manually
   Low/Info     →  note for report, verify quickly
       │
       ▼
5. Cross-reference with Slither output
       │
       ▼
6. Add confirmed findings to your audit report
```

---

## ⚠️ What Aderyn Finds vs What It Misses

| Finds Well | Misses |
|---|---|
| Reentrancy patterns | Business logic bugs |
| Unsafe ERC20 usage | Cross-contract context |
| Missing access control | Economic attack vectors |
| Floating pragmas | Novel/custom vulnerabilities |
| Uninitialized variables | Protocol-specific invariants |
| Integer issues | Intent vs implementation gaps |

> Aderyn is a starting point, not a finish line. Every flagged issue still needs manual verification before going into a report.

---

## 🔁 Aderyn + Slither Together

Run both for maximum automated coverage:

```bash
# Aderyn — AST-based Rust analyzer
aderyn . --src src/audits/puppyRaffle --output aderyn-report.md

# Slither — Python-based static analyzer
slither src/audits/puppyRaffle
slither src/audits/puppyRaffle > slither-report.txt 2>&1
```

> They use different detection engines and often catch different things. Running both takes 2 minutes and is always worth it.

---

## 📁 Recommended Folder Setup

Keep automated tool outputs separate from your manual notes:

```
audit-notes/
#-- aderyn-report.md       <- aderyn output
#-- slither-report.txt     <- slither output
#-- notes.md               <- your manual findings
#-- report.md              <- final audit report
```

---

*Automated tools find patterns. You find intent.*
*Always verify before you report.*