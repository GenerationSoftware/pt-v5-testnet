// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { ERC20Mock } from "openzeppelin/mocks/ERC20Mock.sol";

import { IntegrationBaseSetup } from "../utils/IntegrationBaseSetup.t.sol";
import { Helpers } from "../utils/Helpers.t.sol";

contract LiquidateIntegrationTest is IntegrationBaseSetup, Helpers {
    /* ============ setUp ============ */
    function setUp() public override {
        super.setUp();
    }

    /* ============ Tests ============ */
    function testLiquidate() external {
        uint256 _amount = 1000e18;

        underlyingAsset.mint(address(this), _amount);
        _sponsor(underlyingAsset, vault, _amount);

        uint256 _yield = 10e18;
        _accrueYield(underlyingAsset, yieldVault, _yield);

        vm.startPrank(alice);

        prizeToken.mint(alice, 1000e18);

        vm.warp(block.timestamp + 36 hours);

        uint24 openDrawId = prizePool.getOpenDrawId();

        uint256 maxAmountOut = liquidationPair.maxAmountOut();

        (uint256 _alicePrizeTokenBalanceBefore, uint256 _prizeTokenContributed) = _liquidate(
            liquidationRouter,
            liquidationPair,
            prizeToken,
            maxAmountOut,
            alice
        );

        assertEq(prizeToken.balanceOf(address(prizePool)), _prizeTokenContributed, "prize pool balance");
        assertEq(prizeToken.balanceOf(alice), _alicePrizeTokenBalanceBefore - _prizeTokenContributed, "alice balance");

        // Because of the yield smoothing, only 10% of the prize tokens contributed can be awarded.
        assertEq(
            prizePool.getContributedBetween(address(vault), openDrawId, openDrawId),
            _prizeTokenContributed,
            "contributed between"
        );

        assertEq(IERC20(vault).balanceOf(alice), maxAmountOut, "alice vault balance ERC20");
        assertEq(vault.balanceOf(alice), maxAmountOut, "alice vault balance");

        vm.stopPrank();
    }
}
