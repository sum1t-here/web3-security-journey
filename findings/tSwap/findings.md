## High

### [H-1] Incorrect fee calculation in `TSwapPool::getInputAmountBasedOnOutput`, causes protocol to charge too much fee from users, leading to loss of funds

**Description:** The `getInputAmountBasedOnOutput` function calculates the amount of input tokens required to receive a certain amount of output tokens. When calculating the fee it scales the output amount by 10000, which is incorrect. It should scale by 1000.

**Impact:** Protocol charges too much fee from users.

**Proof of concept:** Add the following test to `TSwapPoolTest.t.sol`

<details>
<summary>Proof of Code</summary>

```javascript
    function test_WrongFeeChargedInSwapExactOutput() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        uint256 outputWeth = 1e17;

        // correct formula (0.3% fee) uses 1000 not 10000
        uint256 correctInputAmount = (
            (poolToken.balanceOf(address(pool)) * outputWeth * 1000) /
            ((weth.balanceOf(address(pool)) - outputWeth) * 997)
        );

        // what the contract actually charges (10000 instead of 1000)
        uint256 actualInputAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );

        console.log("correct input (0.3% fee) :", correctInputAmount);
        console.log("actual input  (91.3% fee):", actualInputAmount);
        console.log("overcharge               :", actualInputAmount - correctInputAmount);

        assertGt(actualInputAmount, correctInputAmount);

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);
        poolToken.mint(user, 100e18);

        uint256 userPoolTokenBefore = poolToken.balanceOf(user);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        uint256 userPoolTokenAfter = poolToken.balanceOf(user);

        uint256 actualPaid = userPoolTokenBefore - userPoolTokenAfter;

        console.log("user paid poolTokens     :", actualPaid);
        console.log("user should have paid    :", correctInputAmount);

        assertGt(actualPaid, correctInputAmount);
        vm.stopPrank();
    }
```
</details>

**Recommended mitigation:** Change the fee calculation to scale by 1000 instead of 10000.

```diff
function getInputAmountBasedOnOutput(
        IERC20 tokenIn,
        uint256 outputAmount
    ) external view returns (uint256 inputAmount) {
         uint256 inputReserves = tokenIn.balanceOf(address(this));
         uint256 outputReserves = i_poolToken.balanceOf(address(this));
         inputAmount =
-            ((inputReserves * outputAmount) * 10000) /
+            ((inputReserves * outputAmount) * 10000) /
             ((outputReserves - outputAmount) * 997);
    }
```

### [H-2] Lack of slippage protection in `TSwapPool::swapExactOutput` causes users to potentially receive less tokens than expected

**Description** The `swapExactOutput` function doesn't include any sort of slippage protection. This function is similar to what it does in `TSwapPool::swapExactInput`, but it doesn't include any sort of slippage protection. The `swapExactInput` function has a `minOutputAmount` parameter, which is used to ensure that the swap will not result in receiving less tokens than expected. However, the `swapExactOutput` function does not have this parameter, which means that it is possible for the swap to result in receiving less tokens than expected.

**Impact:** If market conditions changes before the transaction processes, the user could get a much worse swap.

**Proof of concept:** 
1. The price of 1 WETH right now is 1000 USDC.
2. User inputs a `swapExactOutput` looking for 1 WETH.
    1. inputToken = USDC
    2. outputToken = WETH
    3. outputAmount = 1
    4. deadline = whatever
3. The function doesn't offer a maxInput amount
4. As the transaction is pending in the mempool, the market changes!
And the price moves HUGE -> 1 WETH = 1000000 USDC
5. The transaction completes, but the user sends way too much USDC.

<detail>
<summary>Proof of Code</summary>

```javascript
    function test_SwapExactOutputNoSlippageProtection() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        // mint user enough poolTokens to handle price change
        poolToken.mint(user, 100e18);

        uint256 outputWeth = 1e18;

        uint256 expectedInputAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );
        console.log("expected input at current price:", expectedInputAmount);

        // simulate large trade that drains weth reserves (price impact)
        address frontrunner = makeAddr("frontrunner");
        poolToken.mint(frontrunner, 1000e18);
        vm.startPrank(frontrunner);
        poolToken.approve(address(pool), type(uint256).max);
        // frontrunner buys a lot of weth, moving the price
        pool.swapExactInput(
            poolToken,
            70e18,
            weth,
            1,
            uint64(block.timestamp)
        );
        vm.stopPrank();

        // no maxInputAmount param means user has no protection
        uint256 actualInputAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );
        console.log("actual input after price move :", actualInputAmount);
        console.log("extra poolTokens paid         :", actualInputAmount - expectedInputAmount);

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);

        uint256 userPoolTokenBefore = poolToken.balanceOf(user);
        // user has no way to set a maxInputAmount — tx goes through at any price
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        uint256 userPoolTokenAfter = poolToken.balanceOf(user);

        uint256 actualPaid = userPoolTokenBefore - userPoolTokenAfter;
        console.log("user actually paid            :", actualPaid);
        console.log("user expected to pay          :", expectedInputAmount);

        // user paid more than they expected — no slippage protection
        assertGt(actualPaid, expectedInputAmount);
        vm.stopPrank();
    }
```
</detail>

**Recommended mitigation:** 

```diff
    function swapExactOutput(
        IERC20 inputToken,
        IERC20 outputToken,
        uint256 outputAmount,
        uint64 deadline,
+       uint256 maxInputAmount
    )
.
.
.    
        inputAmount = getInputAmountBasedOnOutput(
            outputAmount,
            inputReserves,
            outputReserves
        );

+       if (inputAmount > maxInputAmount) {
+           revert ();
+       }

        _swap(inputToken, inputAmount, outputToken, outputAmount);
```

### [H-3]  `TSwapPool::sellPoolTokens` mismatches input and output tokens causing users to receive the incorrect amount of tokens

**Description** The `sellPoolTokens` function is intended to allow users to easily sell pool tokens and receive WETH in exchange. Users indicate how many pool tokens they are willing to sell in the `poolTokenAmount` parameter. However, the function currently miscalculates the swapped amount.

This is due to the fact that `swapExactOutput` is called instead of `swapExactInput` function. Because user specify the amount of input tokens, not output.

**Impact** Users will swap the wrong amount of tokens, which is a severe disruption of protocol functionality.

**Proof of Concept** 
When a user calls `sellPoolTokens(10e18)` expecting to sell exactly 10e18 pool tokens, the contract attempts to pull 111e18 pool tokens from the user — 11x more than specified.

```
Trace:

ERC20Mock::transferFrom(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], TSwapPool: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 111445447453471525688 [1.114e20])
```

<details>
<summary>Proof of Code</summary>

```javascript
    function test_SellPoolTokensMismatch() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        
        uint256 poolTokensToSell = 10e18;

        uint256 expectedWeth = pool.getOutputAmountBasedOnInput(
            poolTokensToSell,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );

        console.log("expected weth out        :", expectedWeth);
        console.log("pool tokens user has     :", poolToken.balanceOf(user));

        uint256 userPoolTokenBefore = poolToken.balanceOf(user);
        uint256 userWethBefore = weth.balanceOf(user);

        pool.sellPoolTokens(poolTokensToSell);

        uint256 userPoolTokenAfter = poolToken.balanceOf(user);
        uint256 userWethAfter = weth.balanceOf(user);

        uint256 actualPoolTokensSold = userPoolTokenBefore - userPoolTokenAfter;
        uint256 actualWethReceived = userWethAfter - userWethBefore;

        console.log("actual poolTokens sold   :", actualPoolTokensSold);
        console.log("actual weth received     :", actualWethReceived);
        console.log("expected weth            :", expectedWeth);

        assertNotEq(actualPoolTokensSold, poolTokensToSell);
        assertEq(actualWethReceived, poolTokensToSell);

        console.log("extra poolTokens taken   :", actualPoolTokensSold - poolTokensToSell);
        vm.stopPrank();
    }
```
</details>

**Recommended Mitigation** Consider changing the implementation to use `swapExactInput` instead of `swapExactOutput`.

## [H-4] In `TSwapPool::_swap` the extra tokens given to every user after 10 swaps breaks the invariant of `x * y = k`

**Description** The protocol follows a strict invariant of `x * y = k`. Where:
- `x`: The balance of the pool token
- `y`: The balance of WETH
- `k`: The constant product of the two balances

This means, that whatever the balances change in the protocol, the ratio between the two amounts should remain constant, hence the `k`. However, this is broken due to the extra incentive in the `_swap` function. Meaning that over the time the protocol funds will be drained.

The following code block causes the issue

```javascript
        swap_count++;
        if (swap_count >= SWAP_COUNT_MAX) {
            swap_count = 0;
            outputToken.safeTransfer(msg.sender, 1_000_000_000_000_000_000);
        }
```

**Impact** A user could maliciously drain the protocol of funds by doing a lot of swaps and collecting the extra incentive given out by the protocol.

**Proof of Concept** 

1. A user swaps 10 times, and collect the incentive
2. That users continues to swap until all the protocol funds are released

<details>
<summary>Proof of Code</summary>

Place the following into `TSwapPoolTest.t.sol`

```javascript
   function test_InvariantBroken() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        uint256 outputWeth = 1e17;

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        poolToken.mint(user, 100e18);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

        int256 startingY = int256(weth.balanceOf(address(pool)));
        int256 expectedDeltaY = int256(-1) * int256(outputWeth); 

        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

        uint256 endingY = weth.balanceOf(address(pool));
        int256 actualDeltaY = int256(endingY) - int256(startingY);
        assertEq(actualDeltaY, expectedDeltaY);
    }
```

</details>

**Recommended Mitigation** Remove the extra incentive. If you want to keep this in, we should account for the change in `x * y = k` protocol invariant. Or, we should set aside tokens in the same way.


## Medium

### [M-1] `TSwapPool::deposit` is missing deadline check causing transaction to complete even after the deadline

**Description:** The `deposit` function accepts a deadline parameter, which according to the documentation is the "The deadline for the transaction to be completed by". However, the deadline is not checked in the function. As a consequence operations that add liquidity to the pool might be executed at unexpected times, in market conditions where the deposit rate is unfavorable.

<!-- MEV Attack -->

**Impact:** Transaction could be sent when the conditions are unfavorable to deposit, even when adding a deadline parameter.

**Proof of concept:** The `deadline` parameter is unused

**Recommended mitigation:** Consider making following change to the function

```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint,
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        external
        revertIfZero(wethToDeposit)
+       revertIfDeadlinePassed(deadline)
        returns (uint256 liquidityTokensToMint)
    {
```

### [M-1] Rebase, fee-on-transfer, ERC-777, and centralized ERC20s can break core invariant

**Description** The core invariant of the protocol is `x * y = k`. 
`PoolFactory::createPool` accepts any token address with no validation, 
allowing incompatible token types to be used as pool tokens. Each category 
breaks the invariant differently:

- **Fee-on-transfer tokens** (e.g. USDT, PAXG) — deduct a fee during 
  `transferFrom`, so the pool receives less than `inputAmount` but sends 
  `outputAmount` calculated for the full amount
- **Rebase tokens** (e.g. stETH, AMPL) — automatically adjust balances 
  externally, changing pool reserves without any swap occurring
- **ERC-777 tokens** (e.g. imBTC) — fire hooks on the recipient during 
  transfer, enabling reentrancy since `_swap` has no `nonReentrant` guard
- **Centralized ERC20s** (e.g. USDC, USDT) — have admin functions like 
  `blacklist` and `pause` that can freeze pool funds or block swaps entirely
```javascript
// @audit no token validation — any token type accepted
function createPool(address tokenAddress) external returns (address) {
    if (s_pools[tokenAddress] != address(0)) {
        revert PoolFactory__PoolAlreadyExists(tokenAddress);
    }
    // no check for weird ERC20 compatibility
    TSwapPool tPool = new TSwapPool(tokenAddress, i_wethToken, ...);
}
```

**Impact** 

| Token Type | How `x * y = k` breaks | Who loses |
|---|---|---|
| Fee-on-transfer | Pool receives less than calculated, sends correct output — reserves leak every swap | Liquidity providers |
| Rebase | Pool balance changes externally, `k` drifts silently | LPs via arbitrage |
| ERC-777 | Reentrancy during transfer manipulates reserves mid-swap | Everyone in pool |
| Centralized ERC20 | Admin can blacklist pool address or pause transfers, permanently locking funds | Everyone in pool |

**Proof of Concept**

Fee-on-transfer (1% fee token):
1. Pool has `100e18 tokenA` and `100e18 WETH` — `k = 10,000`
2. User calls `swapExactInput` with `inputAmount = 10e18`
3. `outputAmount` calculated assuming pool receives `10e18`
4. Token transfers only `9.9e18` to pool after 1% fee
5. Pool sends `outputAmount` for `10e18` — overpaying by `0.1e18`
6. `k` is now less than `10,000` — broken silently

Centralized ERC20:
1. Pool is created with USDC as `poolToken`
2. Circle blacklists the pool address
3. All `safeTransfer` and `safeTransferFrom` calls revert
4. Liquidity providers cannot withdraw — funds permanently locked

**Recommended Mitigation**

Add layered mitigations:

**1. Balance diff check for fee-on-transfer:**
```diff
function _swap(...) private {
+   uint256 balanceBefore = inputToken.balanceOf(address(this));
    inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
+   if (inputToken.balanceOf(address(this)) - balanceBefore != inputAmount) {
+       revert TSwapPool__FeeOnTransferNotSupported();
+   }
    outputToken.safeTransfer(msg.sender, outputAmount);
}
```

**2. Reentrancy guard for ERC-777:**
```diff
- contract TSwapPool is ERC20 {
+ contract TSwapPool is ERC20, ReentrancyGuard {

-     function _swap(...) private {
+     function _swap(...) private nonReentrant {
```

**3. Stored reserves for rebase tokens (Uniswap V2 pattern):**
```diff
+ uint256 private reserve0;
+ uint256 private reserve1;

// use reserve0/reserve1 for pricing instead of live balanceOf
// only update reserves through controlled pool interactions
```

**4. Minimum — add NatSpec documentation:**
```diff
+ /// @notice This pool does not support fee-on-transfer tokens,
+ /// rebase tokens, ERC-777 tokens, or centralized ERC20s with
+ /// admin controls. Using such tokens will result in loss of
+ /// funds for liquidity providers.
function createPool(address tokenAddress) external returns (address) {
```

## Low

### [L-1] `TSwapPool::LiquidityAdded` event emits parameters in wrong order, causing event data to be misrepresented

**Description:** When the `LiquidityAdded` event is emitted in the `TSwapPool::_addLiquidityMintAndTransfer` function, the parameters are emitted in the wrong order. The event is defined as `LiquidityAdded(address indexed liquidityProvider, uint256 wethDeposited, uint256 poolTokensDeposited)`, but the parameters are emitted as `LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit)`, which is the opposite of what is expected.

**Impact:** Event emission is incorrect, leading to off-chain function potentially malfunctioning.

**Proof of concept:** The `LiquidityAdded` event is emitted in the `TSwapPool::_addLiquidityMintAndTransfer` function as follows:

```javascript
emit LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit);
```

**Recommended mitigation:** Change the event emission to emit the parameters in the correct order.

```diff
-    emit LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit);
+    emit LiquidityAdded(msg.sender, wethToDeposit, poolTokensToDeposit);
```

### [L-2] Default value returned by `TSwapPool::swapExactInput` results in incorrect return value given

**Description** The `swapExactInput` function is expected to return the actual amount of token bought by the caller. However, while it declares the named return value `output` it is never assigned a value, nor uses an explicit return statement.

**Impact** The returned value will always be 0, giving incorrect information to the caller.

**Proof of Concept** Place the following test in `TswapPoolTest.t.sol`

<detail>
<summary>Proof of Code</summary>

```javascript
    function test_SwapExactInputReturnsZero() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);

        uint256 expectedOutput = pool.getOutputAmountBasedOnInput(
            10e18,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );
        console.log("expected output :", expectedOutput);

        uint256 actualReturn = pool.swapExactInput(
        poolToken,
            10e18,
            weth,
            1,
            uint64(block.timestamp)
        );
        console.log("actual return   :", actualReturn);
        assertEq(actualReturn, 0);

        assertGt(weth.balanceOf(user), 0);
        console.log("weth received   :", weth.balanceOf(user));
        vm.stopPrank();
    }
```

```javascript
Logs:
  expected output : 9066108938801491315
  actual return   : 0
  weth received   : 19066108938801491315
```
</detail>

**Recommended mitigation**

```diff
    function swapExactInput(
        IERC20 inputToken,
        uint256 inputAmount,
        IERC20 outputToken,
        uint256 minOutputAmount,
        uint64 deadline
    )
        public
        revertIfZero(inputAmount)
        revertIfDeadlinePassed(deadline)
        returns (
            // written
            uint256 output)
    {
        uint256 inputReserves = inputToken.balanceOf(address(this));
        uint256 outputReserves = outputToken.balanceOf(address(this));

-       uint256 outputAmount = getOutputAmountBasedOnInput(
+       output = getOutputAmountBasedOnInput(
            inputAmount,
            inputReserves,
            outputReserves
        );

-       if (outputAmount < minOutputAmount) {
+       if (output < minOutputAmount) {
-           revert TSwapPool__OutputTooLow(outputAmount, minOutputAmount);
+           revert TSwapPool__OutputTooLow(output, minOutputAmount);
        }

-        _swap(inputToken, inputAmount, outputToken, outputAmount);
+        _swap(inputToken, inputAmount, outputToken, output);
    }
```

## Informational

### [I-1] `PoolFactory::PoolFactory__PoolDoesNotExist` is not used and can be removed

```diff
-     error PoolFactory__PoolDoesNotExist(address tokenAddress);
```

### [I-2] Lacking zero address check

file: PoolFactory.sol

```diff
constructor(address wethToken) {
+    if (wethToken == address(0)) {
+        revert();
+    }
     i_wethToken = wethToken;
}
```

file: TSwapPool.sol

```diff
constructor(
        address poolToken,
        address wethToken,
        string memory liquidityTokenName,
        string memory liquidityTokenSymbol
    ) ERC20(liquidityTokenName, liquidityTokenSymbol) {
+    if (wethToken == address(0)) {
+        revert();
+    }
+    if (poolToken == address(0)) {
+        revert();
+    }
     i_wethToken = IERC20(wethToken);
     i_poolToken = IERC20(poolToken);
}
```

### [I-3] `PoolFactory::createPool` should use `.symbol()` instead of `.name()`

```diff
string memory liquidityTokenSymbol = string.concat("ts", IERC20(tokenAddress)
-   .name()
+   .symbol()
);
```

### [I-4] `TSwapPool::TSwapPool__WethDepositAmountTooLow` emits `MINIMUM_WETH_LIQUIDITY`, which is a constant and therefore not required to be emitted

```diff
-    emit TSwapPool__WethDepositAmountTooLow(MINIMUM_WETH_LIQUIDITY, wethToDeposit);
+    emit TSwapPool__WethDepositAmountTooLow(wethToDeposit);
```

### [I-5] In `TSwapPool::deposit` the else block doesn't follow the CEI pattern

```diff
else 
    {
    // This will be the "initial" funding of the protocol. We are starting from blank here!
    // We just have them send the tokens in, and we mint liquidity tokens based on the weth
-    _addLiquidityMintAndTransfer(
-            wethToDeposit,
-            maximumPoolTokensToDeposit,
-            wethToDeposit
-        );

     liquidityTokensToMint = wethToDeposit;
+    _addLiquidityMintAndTransfer(
+            wethToDeposit,
+            maximumPoolTokensToDeposit,
+            wethToDeposit
+        );
    }
```

### [I-6] `TSwapPool::getOutputAmountBasedOnInput` & `TSwapPool::getInputAmountBasedOnOutput` has magic numbers respectively, consider using constants

```javascript
uint256 inputAmountMinusFee = inputAmount * 997;
uint256 numerator = inputAmountMinusFee * outputReserves;
uint256 denominator = (inputReserves * 1000) + inputAmountMinusFee;
return numerator / denominator;
```

```javascript
((inputReserves * outputAmount) * 10000) /
((outputReserves - outputAmount) * 997);
```

### [I-7] Consider adding natspec for `TSwapPool::swapExactInput` function

### [I-8] `TSwapPool::swapExactOutput` uses `deadline` as a parameter, but it is not added in natspec, update the natspec according to the parameters passed

### [I-9] In `TSwapPool::_swap` comparison of variables of contract type is deprecated and scheduled for removal. Use an explicit cast to address type and compare the addresses instead.

```diff
if (
    _isUnknown(inputToken) ||
    _isUnknown(outputToken) ||
-   inputToken == outputToken
+   address(inputToken) == address(outputToken)
    ) 
```

### [I-10] In `TSwapPool::_isUnknown` comparison of variables of contract type is deprecated and scheduled for removal. Use an explicit cast to address type and compare the addresses instead.

```diff
-    if (token != i_wethToken && token != i_poolToken) {
+    if (address(token) != address(i_wethToken) && address(token) != address(i_poolToken)) { 
        return true;
    }
```

### [I-11] Consider making `TSwapPool::totalLiquidityTokenSupply` external

## Gas

### [G-1] In `TSwapPool::deposit` get rid of `uint256 poolTokenReserves = i_poolToken.balanceOf(address(this));` as it is not used, which in turn saves gas

```diff
-    uint256 poolTokenReserves = i_poolToken.balanceOf(address(this));
```
