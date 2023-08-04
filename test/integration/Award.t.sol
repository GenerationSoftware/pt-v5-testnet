// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { ERC20Mock } from "openzeppelin/mocks/ERC20Mock.sol";

import { IntegrationBaseSetup } from "../utils/IntegrationBaseSetup.t.sol";
import { Helpers } from "../utils/Helpers.t.sol";

contract AwardIntegrationTest is IntegrationBaseSetup, Helpers {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */
  function testAward() external {
    uint256 _amount = 1000e18;
    uint256 _yield = 10e18;

    vm.startPrank(alice);

    underlyingAsset.mint(alice, _amount);
    _deposit(underlyingAsset, vault, _amount, alice);

    vm.stopPrank();

    _accrueYield(underlyingAsset, yieldVault, _yield);
    prizeToken.mint(alice, 1000e18);

    vm.warp(block.timestamp + 36 hours);

    uint256 maxAmountOut = liquidationPair.maxAmountOut();

    vm.startPrank(alice);

    (uint256 _alicePrizeTokenBalanceBefore, uint256 _prizeTokenContributed) = _liquidate(
      liquidationRouter,
      liquidationPair,
      prizeToken,
      maxAmountOut,
      alice
    );

    vm.stopPrank();

    _award(prizePool, winningRandomNumber);

    // TODO: add tests
    // assertEq(prizePool.prizeTokenPerShare().unwrap(), 0.045454545454545454e18);
    // assertEq(prizePool.reserve(), uint256(_prizeTokenContributed / 220e18) + 120); // remainder of the complex fraction
    // assertEq(prizePool.totalDrawLiquidity(), 10e18 - 120); // ensure not a single wei is lost!
  }
}
