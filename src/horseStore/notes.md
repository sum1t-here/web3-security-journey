## What it does

This contract does exactly two things:
1. **Store** a number → `updateHorseNumber(uint256)`
2. **Read** that number back → `readNumberOfHorses()`

No Solidity. No abstractions. Pure EVM opcodes.

---

## Stack Notation

Throughout these notes, the stack is shown after every opcode:

```
[top, next, bottom]
```

The leftmost item is always the top of the stack — the one opcodes operate on first.

---

## Interface

```huff
#define function updateHorseNumber(uint256) nonpayable returns()
#define function readNumberOfHorses() view returns(uint256)
```

These are **compile-time declarations only** — not deployed bytecode. Huff uses them to compute 4-byte function selectors via `__FUNC_SIG()`.

Equivalent Solidity:
```solidity
function updateHorseNumber(uint256) external;
function readNumberOfHorses() external view returns (uint256);
```

---

## Storage Layout

```huff
#define constant NUMBER_OF_HORSES_STORAGE_SLOT = FREE_STORAGE_POINTER() // slot 0
```

`FREE_STORAGE_POINTER()` assigns the next available storage slot at compile time.

- First call → slot `0`
- Second call → slot `1`
- And so on...

Equivalent Solidity:
```solidity
uint256 numberOfHorses; // slot 0
```

---

## Calldata Layout

Every function call sends calldata in this format:

```
byte 0-3   → function selector   (4 bytes)
byte 4-35  → first argument      (32 bytes)
byte 36-67 → second argument     (32 bytes)
...
```

Example — calling `updateHorseNumber(1)`:
```
0xCAAECECA                                    ← 4-byte selector
0000000000000000000000000000000000000000000000000000000000000001  ← uint256(1)
```

---

## MAIN() — Entry Point

Every call lands here first. Reads the selector, routes to the right macro.

```huff
#define macro MAIN() = takes(0) returns(0) {
    0x00 calldataload 0xe0 shr  // [function_selector]
    ...
}
```

### Extracting the function selector

```
0x00 calldataload   → loads 32 bytes from calldata[0:32]
0xe0 shr            → shifts right by 224 bits (0xe0 = 224)
                      keeps only the top 4 bytes
```

Why shift by 224?
```
32 bytes total = 256 bits
256 - 32 (4 bytes we want) = 224 bits to shift away
```

Before shift: `0xCAAECECA000000000000000000000000000000000000000000000000000000001`
After shift:  `0x00000000000000000000000000000000000000000000000000000000CAAECECA`

### Routing to the right function

```huff
dup1 __FUNC_SIG(updateHorseNumber) eq updateJump jumpi   // [selector]
__FUNC_SIG(readNumberOfHorses) eq readJump jumpi          // []
0x00 0x00 revert
```

| Opcode | What it does |
|--------|-------------|
| `dup1` | Copies selector — `eq` consumes top two items, so we need a copy for the second check |
| `__FUNC_SIG(x)` | Compile-time: pushes the 4-byte selector of function `x` |
| `eq` | Pops two values, pushes `1` if equal, `0` if not |
| `jumpi(dest, cond)` | Jumps to `dest` if `cond != 0` |
| `revert` | No match found → revert with no data |

Flow:
```
calldata arrives
    │
    ├── selector == updateHorseNumber? → jump to SET_NUMBER_OF_HORSE()
    ├── selector == readNumberOfHorses? → jump to GET_NUMBER_OF_HORSE()
    └── no match → revert(0, 0)
```

---

## SET_NUMBER_OF_HORSE() — Write to Storage

Called when `updateHorseNumber(uint256)` is invoked.

```huff
#define macro SET_NUMBER_OF_HORSE() = takes(0) returns(0) {
    0x04 calldataload           // [input]
    [NUMBER_OF_HORSES_STORAGE_SLOT]  // [slot, input]
    sstore                      // []
    stop
}
```

### Step by step

**1. Load the argument from calldata**
```
0x04 calldataload   → load 32 bytes starting at byte 4
                      (skips the 4-byte selector)
                      stack: [input]
```

**2. Push the storage slot**
```
[NUMBER_OF_HORSES_STORAGE_SLOT]  → pushes constant 0
                                   stack: [0, input]
```

**3. Write to storage**
```
sstore   → pops slot (0), pops value (input)
           writes: storage[0] = input
           stack: []
```

`sstore(slot, value)` — note the order: slot is popped first, value second.

Equivalent Solidity:
```solidity
numberOfHorses = input;
```

---

## GET_NUMBER_OF_HORSE() — Read from Storage

Called when `readNumberOfHorses()` is invoked.

```huff
#define macro GET_NUMBER_OF_HORSE() = takes(0) returns(0) {
    [NUMBER_OF_HORSES_STORAGE_SLOT]  // [slot]
    sload                            // [value]
    0x00                             // [0, value]
    mstore                           // []
    0x20                             // [32]
    0x00                             // [0, 32]
    return                           // []
}
```

### Why we can't return directly from the stack

The EVM's `return` opcode reads from **memory**, not the stack. So the pipeline is always:

```
storage → stack → memory → return
```

### Step by step

**1. Load value from storage**
```
[NUMBER_OF_HORSES_STORAGE_SLOT]  → push slot 0
                                   stack: [0]

sload   → pops slot, loads storage[0]
          stack: [value]
```

**2. Write value to memory**
```
0x00    → push memory offset 0
          stack: [0, value]

mstore  → pops offset (0), pops value
          writes 32 bytes: memory[0:32] = value
          stack: []
```

Memory layout after `mstore`:
```
memory[0x00 - 0x1F] = value (32 bytes, left-padded)
```

**3. Return from memory**
```
0x20    → push length = 32 bytes
          stack: [32]

0x00    → push offset = 0
          stack: [0, 32]

return  → returns memory[0 : 0+32]
          the caller receives the 32-byte value
```

Equivalent Solidity:
```solidity
return numberOfHorses;
```

---

## Full Execution Trace

### updateHorseNumber(1)

```
Calldata: 0xCAAECECA 0000...0001

MAIN():
  calldataload(0) → 0xCAAECECA000...001
  shr(0xe0)       → 0xCAAECECA              [selector]
  dup1            → 0xCAAECECA, 0xCAAECECA  [selector, selector]
  FUNC_SIG(update)→ matches → jump

SET_NUMBER_OF_HORSE():
  calldataload(4) → 1                        [input=1]
  push slot 0     → 0, 1                     [slot, input]
  sstore          → storage[0] = 1           []
  stop
```

### readNumberOfHorses()

```
Calldata: 0x4E5F4E5F (no arguments)

MAIN():
  calldataload(0) → 0x4E5F4E5F000...000
  shr(0xe0)       → 0x4E5F4E5F              [selector]
  dup1 + eq       → no match for update
  eq readJump     → matches → jump

GET_NUMBER_OF_HORSE():
  push slot 0     → 0                        [slot]
  sload           → 1                        [value=1]
  push 0x00       → 0, 1                     [offset, value]
  mstore          → memory[0] = 1            []
  push 0x20       → 32                       [length]
  push 0x00       → 0, 32                    [offset, length]
  return          → returns memory[0:32] = 1
```

---

## Key Concepts to Remember

| Concept | Detail |
|---------|--------|
| Function selector | First 4 bytes of calldata — keccak256(signature)[0:4] |
| `0xe0 shr` | Extracts selector by shifting 32-byte load right by 224 bits |
| `dup1` before first `eq` | Preserves selector for second check — `eq` consumes it |
| `calldataload(0x04)` | Skips 4-byte selector, loads first argument |
| `sstore(slot, value)` | Slot popped first, value second |
| `mstore` before `return` | EVM returns from memory — stack values must be moved first |
| `FREE_STORAGE_POINTER()` | Compile-time slot assignment — first = 0, second = 1 |

---

## The Mental Model

```
Every Huff contract = a jump table

Calldata in
    │
    ├── extract selector (calldataload + shr)
    ├── compare with each known selector (eq + jumpi)
    └── route to the right logic block

Write path:  calldata → stack → sstore
Read path:   sload → stack → mstore → memory → return
```