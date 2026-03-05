# 🚀 Getting Started — Audit Setup Guide

> A step-by-step walkthrough for setting up your local audit environment from the client's quickstart.

---

## 📋 Prerequisites

Make sure you have the following installed before beginning:

| Tool | Purpose | Install |
|---|---|---|
| `git` | Clone and manage the repo | [git-scm.com](https://git-scm.com) |
| `VS Code` | Code editor for review | [code.visualstudio.com](https://code.visualstudio.com) |
| `cloc` | Count source lines of code | `brew install cloc` / `sudo apt install cloc` |
| `foundry` | Build and test Solidity | [getfoundry.sh](https://getfoundry.sh) |

---

## 1️⃣ Clone the Repository

Start by cloning the client's codebase and navigating into it:

```bash
git clone https://github.com/Cyfrin/3-passwordstore-audit
cd 3-passwordstore-audit
```

Then open it in VS Code:

```bash
code .
```

> This opens a new VS Code window scoped to the project directory.

---

## 2️⃣ Checkout the Audit Commit Hash

Switch to the **exact commit hash** specified in your audit scope. This ensures you are reviewing the precise code the client intends to deploy.

```bash
git checkout <commithash>
```

> ⚠️ This puts you in a **detached HEAD** state — changes here won't be saved to any branch.

---

## 3️⃣ Create Your Audit Working Branch

To safely work and save notes without affecting the client's code, create a dedicated audit branch:

```bash
git switch -c passwordstore-audit
```

Confirm you're on the right branch:

```bash
git branch
```

You should see:

```
* passwordstore-audit
```

> The `*` indicates your active branch. You're now ready to annotate, add notes, and work safely.

---

## 4️⃣ Count Lines of Code (nSLOC)

One of the required **Stats** fields in your audit report is `nSLOC` — the number of source lines of code. Use `cloc` to generate this:

```bash
cloc ./src
```

**Example output:**

```
-------------------------------------------------------------------------------
Language     files          blank        comment           code
-------------------------------------------------------------------------------
Solidity         2             18             42             87
-------------------------------------------------------------------------------
```

> The `code` column is your **nSLOC** value. Record this in the Stats section of your audit report.

For a quick one-liner that extracts just the number:

```bash
cloc ./src --quiet | tail -2 | awk '{print "nSLOC:", $NF}'
```

---

## 5️⃣ Build & Run Tests

Verify the codebase compiles and tests pass before starting your review:

```bash
forge build
forge test
```

For test coverage:

```bash
forge coverage
```

> Take note of coverage gaps — untested code paths are prime areas to focus your review.

---

## 6️⃣ Generate the Audit Report PDF

Once your `report.md` is complete, compile it into a professional PDF using Pandoc with the Eisvogel template:

```bash
pandoc report.md -o report.pdf --from markdown --template=eisvogel --listings
```

> Make sure the `eisvogel.latex` template is placed in your Pandoc templates directory:
> ```bash
> # Find your templates path
> pandoc --version | grep "User data"
>
> # Then place the template there, e.g.:
> ~/.local/share/pandoc/templates/eisvogel.latex
> ```

For a full compile with your custom Sumit template directly:

```bash
pandoc report.md \
  --template=sumit-eisvogel-template.tex \
  --pdf-engine=xelatex \
  --listings \
  -o ProtocolName-Audit-Report.pdf
```

---

## ✅ Setup Checklist

| Step | Done |
|---|---|
| Repo cloned | ⬜ |
| Correct commit hash checked out | ⬜ |
| Audit branch created (`passwordstore-audit`) | ⬜ |
| nSLOC counted and recorded | ⬜ |
| `forge build` passes with no errors | ⬜ |
| `forge test` passes | ⬜ |
| Coverage report reviewed | ⬜ |
| Report PDF compiled successfully | ⬜ |

---

## 📁 Recommended Folder Structure

Keep your audit work organized from day one:

```
3-passwordstore-audit/
#-- src/                  <- client contracts (do not modify)
#-- test/                 <- client tests
#-- audit-notes/
#   #-- notes.md          <- your running findings and observations
#   #-- report.md         <- final audit report (from your template)
#   #-- poc/              <- proof of concept exploit scripts
#-- GETTING-STARTED.md    <- this file
```

---

*Start every audit the same way — clean setup, correct commit, your own branch.*
*Consistency in process leads to consistency in quality.*