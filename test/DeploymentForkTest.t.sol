// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { TestnetAddressBook, ERC20Mintable, PrizeVaultMintRate } from "../script/DeployTestnet.s.sol";
import { ILiquidationPair } from "pt-v5-liquidator-interfaces/ILiquidationPair.sol";

/// @notice Runs some basic fork tests against a deployment
contract LocalForkTest is Test {

    uint256 deployFork;

    TestnetAddressBook addressBook;
    
    function setUp() public {
        deployFork = vm.createFork(vm.envString("SCRIPT_RPC_URL"));
        vm.selectFork(deployFork);

        addressBook = abi.decode(
            vm.parseBytes(
                vm.readFile(
                    string.concat("config/runs/", vm.toString(block.chainid), "/addressBook.txt")
                )
            ),
            (TestnetAddressBook)
        );

        vm.warp(addressBook.prizePool.firstDrawOpensAt());
    }

    function testAddressBook() public view {
        assertNotEq(address(addressBook.prizePool), address(0));
        assertNotEq(address(addressBook.prizeVault), address(0));
        assertNotEq(address(addressBook.claimer), address(0));
        assertNotEq(address(addressBook.minter), address(0));

        assertEq(addressBook.prizeVault.claimer(), address(addressBook.claimer));
        assertEq(address(addressBook.prizeVault.prizePool()), address(addressBook.prizePool));
    }

    function testDepositAndWithdraw() public {
        PrizeVaultMintRate prizeVault = addressBook.prizeVault;
        ERC20Mintable asset = ERC20Mintable(prizeVault.asset());

        uint256 amount = 100e6;
        vm.startPrank(addressBook.minter);
        asset.mint(address(this), amount);
        vm.stopPrank();

        asset.approve(address(prizeVault), amount);
        prizeVault.deposit(amount, address(this));
        assertEq(prizeVault.balanceOf(address(this)), amount);
        assertGe(prizeVault.totalAssets(), amount);
        assertGe(prizeVault.totalPreciseAssets(), amount);
        assertGe(prizeVault.totalSupply(), amount);

        prizeVault.withdraw(amount, address(this), address(this));
        assertEq(asset.balanceOf(address(this)), amount);
        assertEq(prizeVault.balanceOf(address(this)), 0);
    }

    function testLiquidation() public {
        PrizeVaultMintRate prizeVault = addressBook.prizeVault;
        ILiquidationPair lp = ILiquidationPair(prizeVault.liquidationPair());
        ERC20Mintable asset = ERC20Mintable(prizeVault.asset());

        uint256 amount = 100000e6;
        vm.startPrank(addressBook.minter);
        asset.mint(address(this), amount);
        vm.stopPrank();

        asset.approve(address(prizeVault), amount);
        prizeVault.deposit(amount / 2, address(this));
        
        // let time pass and trigger another mintRate by depositing more
        vm.warp(block.timestamp + 1 days);
        prizeVault.deposit(amount / 2, address(this));

        // check liquidation
        uint256 liquidBalance = prizeVault.liquidatableBalanceOf(address(prizeVault));
        assertGt(liquidBalance, 0, "liquid balance");
        uint256 maxAmountOut = lp.maxAmountOut();
        assertGt(maxAmountOut, 0);
        assertGe(liquidBalance, maxAmountOut, "max amount out");

        // liquidate
        uint256 amountIn = lp.computeExactAmountIn(maxAmountOut);
        vm.startPrank(addressBook.minter);
        ERC20Mintable(address(addressBook.prizePool.prizeToken())).mint(lp.target(), amountIn);
        vm.stopPrank();
        lp.swapExactAmountOut(address(this), maxAmountOut, amountIn, "");

        assertEq(prizeVault.liquidatableBalanceOf(address(prizeVault)), liquidBalance - maxAmountOut, "no more liquid balance");
        assertEq(prizeVault.balanceOf(address(this)), amount + maxAmountOut, "received amount out");
        assertEq(addressBook.prizePool.getContributedBetween(address(prizeVault), 1, addressBook.prizePool.getOpenDrawId()), amountIn, "contributed");
    }

}