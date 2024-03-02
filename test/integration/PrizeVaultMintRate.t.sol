// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { ERC20Mock } from "openzeppelin/mocks/ERC20Mock.sol";

import { IntegrationBaseSetup } from "../utils/IntegrationBaseSetup.t.sol";
import { Helpers } from "../utils/Helpers.t.sol";

import { YieldVaultMintRate, ERC20Mintable } from "../../src/YieldVaultMintRate.sol";
import { PrizeVaultMintRate } from "../../src/PrizeVaultMintRate.sol";

contract PrizeVaultMintRateTest is IntegrationBaseSetup, Helpers {
    YieldVaultMintRate public yieldVaultMintRate;
    PrizeVaultMintRate public prizeVaultMintRate;

    /* ============ setUp ============ */
    function setUp() public override {
        super.setUp();

        yieldVaultMintRate = new YieldVaultMintRate(
            ERC20Mintable(address(underlyingAsset)),
            "Yield Vault",
            "YV",
            address(this)
        );
        yieldVaultMintRate.setRatePerSecond(uint256(250000000000000000) / 365 days); // ~25% APR
        prizeVaultMintRate = new PrizeVaultMintRate(
            vaultName,
            vaultSymbol,
            yieldVaultMintRate,
            prizePool,
            address(claimer),
            address(this),
            0, // 0%
            address(this)
        );
        yieldVaultMintRate.grantRole(yieldVaultMintRate.MINTER_ROLE(), address(prizeVaultMintRate));
    }

    /* ============ Deposit Works ============ */

    function testDepositWorks() public {
        underlyingAsset.mint(alice, 2e18);

        vm.startPrank(alice);

        underlyingAsset.approve(address(prizeVaultMintRate), 1e18);
        prizeVaultMintRate.deposit(1e18, alice);
        assertEq(prizeVaultMintRate.balanceOf(alice), 1e18);

        vm.warp(block.timestamp + 100); // time passes

        underlyingAsset.approve(address(prizeVaultMintRate), 1e18);
        prizeVaultMintRate.deposit(1e18, alice);
        assertEq(prizeVaultMintRate.balanceOf(alice), 2e18);
        assertGt(prizeVaultMintRate.totalAssets(), 2e18);

        vm.stopPrank();
    }
}
