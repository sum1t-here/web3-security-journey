# 🔨 Foundry Cheatcodes Reference

> Personal reference for Foundry cheatcodes used in smart contract testing and security research.
> Updated as I learn new ones throughout the journey.

---

## 📋 Quick Reference

| Cheatcode | Category | Use |
|-----------|----------|-----|
| `vm.prank` | Identity | Spoof next call's msg.sender |
| `vm.startPrank` | Identity | Spoof all calls until stopPrank |
| `vm.stopPrank` | Identity | Stop active prank |
| `vm.expectRevert` | Assertions | Expect next call to revert |
| `vm.expectEmit` | Assertions | Expect next call to emit event |
| `vm.deal` | State | Set ETH balance of address |
| `vm.hoax` | State | deal + prank in one call |
| `vm.warp` | Time | Set block.timestamp |
| `vm.roll` | Time | Set block.number |
| `vm.store` | Storage | Write directly to storage slot |
| `vm.load` | Storage | Read directly from storage slot |
| `vm.assume` | Fuzzing | Skip fuzz run if condition false |
| `bound` | Fuzzing | Constrain fuzz input to range |
| `makeAddr` | Helpers | Create labelled test address |
| `vm.label` | Helpers | Label an address for traces |
| `vm.snapshot` | State | Save EVM state snapshot |
| `vm.revertTo` | State | Restore EVM to snapshot |
| `vm.recordLogs` | Logging | Start recording emitted events |
| `vm.getRecordedLogs` | Logging | Get all recorded events |
| `vm.mockCall` | Mocking | Mock return value of a call |
| `vm.clearMockedCalls` | Mocking | Clear all active mocks |
| `vm.coinbase` | Block | Set block.coinbase |
| `vm.fee` | Block | Set block.basefee |
| `vm.chainId` | Block | Set chain ID |

---

## 🎭 Identity — Spoofing msg.sender

### `vm.prank(address)`
Spoofs `msg.sender` for the **next call only**.

```solidity
vm.prank(alice);
token.transfer(bob, 100); // msg.sender == alice for this call only
```

### `vm.startPrank(address)` / `vm.stopPrank()`
Spoofs `msg.sender` for **all calls** until stopped.

```solidity
vm.startPrank(alice);
token.approve(bob, 500);
token.transfer(bob, 100);
vm.stopPrank();
// back to normal after stopPrank
```

### `vm.prank(address caller, address origin)`
Spoofs both `msg.sender` AND `tx.origin`. Critical for testing tx.origin auth bugs.

```solidity
vm.prank(alice, alice); // msg.sender == alice, tx.origin == alice
vm.prank(address(attackContract), alice); // msg.sender == contract, tx.origin == alice
```

> **Security note:** If a contract uses `tx.origin` for auth, this is how you exploit it in tests.

---

## ✅ Assertions — Expecting Behaviour

### `vm.expectRevert()`
Next call **must** revert. Test fails if it doesn't.

```solidity
// Expect revert with specific message
vm.expectRevert("Insufficient balance");
token.transfer(bob, 99999999);

// Expect revert with custom error
vm.expectRevert(MyToken.InsufficientBalance.selector);
token.transfer(bob, 99999999);

// Expect any revert (no message check)
vm.expectRevert();
token.transfer(address(0), 100);
```

### `vm.expectEmit()`
Next call must emit a specific event.

```solidity
// Arguments: checkTopic1, checkTopic2, checkTopic3, checkData
vm.expectEmit(true, true, false, true);
emit Transfer(alice, bob, 100); // declare expected event
token.transfer(bob, 100);       // must emit this exact event
```

---

## 💰 State — Manipulating Balances

### `vm.deal(address, uint256)`
Sets ETH balance of any address.

```solidity
vm.deal(alice, 10 ether);
assertEq(alice.balance, 10 ether);
```

### `vm.hoax(address, uint256)`
`deal` + `prank` in one call. Useful shorthand.

```solidity
vm.hoax(alice, 10 ether); // give alice 10 ETH and prank as alice
vault.deposit{value: 1 ether}();
```

### `deal(address token, address to, uint256 amount)`
Sets ERC-20 token balance directly (stdcheats version).

```solidity
deal(address(token), alice, 1000e18);
assertEq(token.balanceOf(alice), 1000e18);
```

---

## ⏰ Time & Blocks

### `vm.warp(uint256 timestamp)`
Sets `block.timestamp`. Essential for testing time-locked functions.

```solidity
vm.warp(block.timestamp + 7 days);
// now block.timestamp is 7 days in the future
vault.claimRewards(); // test time-dependent logic
```

### `vm.roll(uint256 blockNumber)`
Sets `block.number`.

```solidity
vm.roll(block.number + 100);
// now 100 blocks have passed
```

### `vm.warp` + `vm.roll` together
Block number and timestamp don't auto-sync — set both if your contract uses both.

```solidity
vm.warp(block.timestamp + 1 days);
vm.roll(block.number + 7200); // ~7200 blocks per day on Ethereum
```

---

## 🗄️ Storage — Direct Slot Manipulation

### `vm.store(address, bytes32 slot, bytes32 value)`
Writes directly to any storage slot. Used to bypass access control in tests.

```solidity
// Force set owner to alice without going through constructor
bytes32 slot = bytes32(uint256(0)); // slot 0
vm.store(address(token), slot, bytes32(uint256(uint160(alice))));
```

### `vm.load(address, bytes32 slot)`
Reads directly from any storage slot.

```solidity
bytes32 value = vm.load(address(token), bytes32(uint256(0)));
```

> **Security use:** If a contract has a private variable you need to read or manipulate in a test, use vm.load/vm.store. Private doesn't mean hidden on-chain.

---

## 🎲 Fuzzing — Property Based Testing

### `bound(uint256 value, uint256 min, uint256 max)`
Constrains fuzz input to a valid range. Always use this instead of `vm.assume` for numeric ranges.

```solidity
function testFuzz_Transfer(uint256 amount) public {
    amount = bound(amount, 1, token.balanceOf(address(this)));
    token.transfer(alice, amount);
    assertEq(token.balanceOf(alice), amount);
}
```

### `vm.assume(bool condition)`
Skips the fuzz run if condition is false. Use sparingly — too many assumes reduce coverage.

```solidity
function testFuzz_Transfer(address to, uint256 amount) public {
    vm.assume(to != address(0));      // skip zero address runs
    vm.assume(amount > 0);            // skip zero amount runs
    // prefer bound() over assume() for numeric values
}
```

> **Rule of thumb:** Use `bound` for numbers, `vm.assume` for addresses and booleans.

---

## 🏷️ Helpers — Labels & Addresses

### `makeAddr(string memory name)`
Creates a deterministic labelled address. Shows up by name in traces.

```solidity
address alice = makeAddr("alice");
address bob = makeAddr("bob");
address attacker = makeAddr("attacker");
```

### `vm.label(address, string memory name)`
Labels an existing address for readable traces.

```solidity
vm.label(address(token), "MyToken");
vm.label(alice, "alice");
```

---

## 📸 Snapshots — Save & Restore State

### `vm.snapshot()` / `vm.revertTo(uint256)`
Save and restore EVM state. Useful for testing multiple scenarios from the same starting point.

```solidity
uint256 snap = vm.snapshot();

// test scenario A
token.transfer(alice, 100);
assertEq(token.balanceOf(alice), 100);

vm.revertTo(snap); // back to state before transfer

// test scenario B from same starting point
token.transfer(bob, 200);
assertEq(token.balanceOf(bob), 200);
```

---

## 📡 Event Logging

### `vm.recordLogs()` / `vm.getRecordedLogs()`
Capture all emitted events for inspection.

```solidity
vm.recordLogs();
token.transfer(alice, 100);
token.transfer(bob, 200);

Vm.Log[] memory logs = vm.getRecordedLogs();
assertEq(logs.length, 2); // two Transfer events emitted
```

---

## 🎭 Mocking — Fake Return Values

### `vm.mockCall(address, bytes calldata, bytes calldata)`
Mocks a specific call to return a specific value. Useful for testing oracle-dependent contracts without real oracles.

```solidity
// Mock a price oracle to return $2000
vm.mockCall(
    address(oracle),
    abi.encodeWithSelector(IOracle.getPrice.selector),
    abi.encode(2000e18)
);

uint256 price = oracle.getPrice(); // returns 2000e18
```

### `vm.clearMockedCalls()`
Removes all active mocks.

```solidity
vm.clearMockedCalls();
```

---

## ⛓️ Block Context

### `vm.chainId(uint256)`
```solidity
vm.chainId(1); // mainnet
vm.chainId(137); // polygon
```

### `vm.coinbase(address)`
```solidity
vm.coinbase(address(miner));
```

### `vm.fee(uint256)`
```solidity
vm.fee(100 gwei); // set basefee
```

---

## 🧪 Common Test Patterns

### Testing access control
```solidity
function test_OnlyOwner() public {
    vm.prank(alice); // alice is not owner
    vm.expectRevert("Not owner");
    token.mint(alice, 1000);
}
```

### Testing time locks
```solidity
function test_CannotWithdrawEarly() public {
    vault.deposit{value: 1 ether}();
    vm.expectRevert("Too early");
    vault.withdraw();

    vm.warp(block.timestamp + 7 days);
    vault.withdraw(); // should pass now
}
```

### Testing with ETH
```solidity
function test_Deposit() public {
    vm.deal(alice, 5 ether);
    vm.prank(alice);
    vault.deposit{value: 1 ether}();
    assertEq(vault.balanceOf(alice), 1 ether);
}
```

### Testing reentrancy (Phase 2)
```solidity
function test_ReentrancyAttack() public {
    AttackContract attacker = new AttackContract(address(vault));
    vm.deal(address(attacker), 1 ether);
    attacker.attack();
    // assert vault was drained
}
```

---

## 🔧 foundry.toml Config

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[fuzz]
runs = 1000        # number of fuzz runs per test
seed = 0x1        # reproducible fuzz seed

[invariant]
runs = 256         # number of invariant test sequences
depth = 15         # calls per sequence
```

---

## 📌 Commands Quick Reference

```bash
# Run all tests
forge test -vv

# Run specific test
forge test --match-test test_Transfer -vv

# Run exact test (regex)
forge test --match-test "^test_Transfer$" -vvvv

# Run by contract
forge test --match-contract MyTokenTest -vv

# Run by file
forge test --match-path "test/week1/MyToken.t.sol" -vv

# Run with fuzz
forge test --fuzz-runs 10000

# Coverage report
forge coverage

# Gas report
forge test --gas-report
```

---