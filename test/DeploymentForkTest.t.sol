// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";

import { Test } from "forge-std/Test.sol";
import { TestnetAddressBook, ERC20Mintable, PrizeVaultMintRate, PrizePool } from "../script/DeployTestnet.s.sol";
import { IERC20 } from "pt-v5-prize-pool/PrizePool.sol";
import {
    AlreadyStartedDraw,
    StaleRngRequest
} from "pt-v5-draw-manager/DrawManager.sol";

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

    function testClaim() public {
        // Make a deposit
        ERC20Mintable depositAsset = ERC20Mintable(address(addressBook.prizeVault.asset()));
        vm.startPrank(addressBook.minter);
        depositAsset.mint(address(this), 1e18);
        vm.stopPrank();
        depositAsset.approve(address(addressBook.prizeVault), 1e18);
        addressBook.prizeVault.deposit(1e18, address(this));

        // Make a contribution
        ERC20Mintable prizeToken = ERC20Mintable(address(addressBook.prizePool.prizeToken()));
        vm.startPrank(addressBook.minter);
        prizeToken.mint(address(addressBook.prizePool), 1e18);
        vm.stopPrank();
        addressBook.prizePool.contributePrizeTokens(address(addressBook.prizeVault), 1e18);

        // Award the draw
        vm.warp(addressBook.prizePool.drawClosesAt(1));
        vm.startPrank(addressBook.prizePool.drawManager());
        addressBook.prizePool.awardDraw(12345);
        vm.stopPrank();
        assertEq(addressBook.prizePool.getLastAwardedDrawId(), 1);

        // Claim prizes
        address[] memory winners = new address[](1);
        winners[0] = address(this);
        uint32[] memory winnerPrizeIndices = new uint32[](4);
        winnerPrizeIndices[0] = 0;
        winnerPrizeIndices[1] = 1;
        winnerPrizeIndices[2] = 2;
        winnerPrizeIndices[3] = 3;
        uint32[][] memory prizeIndices = new uint32[][](1);
        prizeIndices[0] = winnerPrizeIndices;

        vm.expectEmit(true, true, true, false);
        emit PrizePool.ClaimedPrize(
            address(addressBook.prizeVault),
            address(this),
            address(this),
            0,
            0,
            0,
            0,
            0,
            address(0)
        );
        addressBook.claimer.claimPrizes(
            addressBook.prizeVault,
            1,
            winners,
            prizeIndices,
            address(this),
            0
        );
    }

    function test_rngFailure() public {
        // console2.log("1 pendingReserveContributions() ", addressBook.prizePool.pendingReserveContributions());
        // console2.log("1 reserve() ", addressBook.prizePool.reserve());
        // console2.log("1 getTotalContributedBetween(1, 1) ", addressBook.prizePool.getTotalContributedBetween(1, 1));
        // console2.log("1 getTotalContributedBetween(2, 2) ", addressBook.prizePool.getTotalContributedBetween(2, 2));

        IERC20 prizeToken = addressBook.prizePool.prizeToken();
        deal(address(prizeToken), address(this), 100e18);
        prizeToken.transfer(address(addressBook.prizePool), 100e18);
        addressBook.prizePool.contributePrizeTokens(address(addressBook.stakingPrizeVault), 100e18);

        // console2.log("2 pendingReserveContributions() ", addressBook.prizePool.pendingReserveContributions());
        // console2.log("2 reserve() ", addressBook.prizePool.reserve());
        // console2.log("2 getTotalContributedBetween(1, 1) ", addressBook.prizePool.getTotalContributedBetween(1, 1));
        // console2.log("2 getTotalContributedBetween(2, 2) ", addressBook.prizePool.getTotalContributedBetween(2, 2));

        vm.warp(addressBook.prizePool.drawClosesAt(1));
        assertTrue(addressBook.drawManager.canStartDraw(), "can start draw");
        
        vm.warp(block.timestamp + addressBook.drawManager.auctionTargetTime());
        mock_requestedAtBlock(11, block.number);
        addressBook.drawManager.startDraw(address(this), 11);

        mock_isRequestFailed(11, false);
        vm.expectRevert(abi.encodeWithSelector(AlreadyStartedDraw.selector));
        addressBook.drawManager.startDraw(address(this), 11);

        mock_isRequestFailed(11, true);
        vm.expectRevert(abi.encodeWithSelector(StaleRngRequest.selector));
        addressBook.drawManager.startDraw(address(this), 11);

        vm.warp(block.timestamp + addressBook.drawManager.auctionTargetTime());
        vm.roll(block.number + 1);
        mock_requestedAtBlock(12, block.number);
        addressBook.drawManager.startDraw(address(this), 12);

        vm.warp(block.timestamp + addressBook.drawManager.auctionTargetTime());
        mock_isRequestComplete(12, true);
        mock_randomNumber(12, 12345);
        addressBook.drawManager.finishDraw(address(this));

        // console2.log("3 pendingReserveContributions() ", addressBook.prizePool.pendingReserveContributions());
        // console2.log("3 reserve() ", addressBook.prizePool.reserve());
        // console2.log("3 getTotalContributedBetween(1, 1) ", addressBook.prizePool.getTotalContributedBetween(1, 1));
        // console2.log("3 getTotalContributedBetween(2, 2) ", addressBook.prizePool.getTotalContributedBetween(2, 2));


    }

    function mock_requestedAtBlock(uint32 requestId, uint256 blockNumber) internal {
        vm.mockCall(
            address(addressBook.rng),
            abi.encodeWithSelector(addressBook.rng.requestedAtBlock.selector, requestId),
            abi.encode(blockNumber)
        );
    }

    function mock_isRequestFailed(uint32 requestId, bool failed) internal {
        vm.mockCall(
            address(addressBook.rng),
            abi.encodeWithSelector(addressBook.rng.isRequestFailed.selector, requestId),
            abi.encode(failed)
        );
    }

    function mock_isRequestComplete(uint32 requestId, bool complete) internal {
        vm.mockCall(
            address(addressBook.rng),
            abi.encodeWithSelector(addressBook.rng.isRequestComplete.selector, requestId),
            abi.encode(complete)
        );
    }

    function mock_randomNumber(uint32 requestId, uint256 randomNumber) internal {
        vm.mockCall(
            address(addressBook.rng),
            abi.encodeWithSelector(addressBook.rng.randomNumber.selector, requestId),
            abi.encode(randomNumber)
        );
    }

}