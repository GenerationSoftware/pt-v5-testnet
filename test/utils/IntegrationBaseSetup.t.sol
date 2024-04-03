// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { ERC20Mock } from "openzeppelin/mocks/ERC20Mock.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";

import { PrizePool, ConstructorParams, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { convert } from "prb-math/SD59x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { TpdaLiquidationPair } from "pt-v5-tpda-liquidator/TpdaLiquidationPair.sol";
import { TpdaLiquidationPairFactory } from "pt-v5-tpda-liquidator/TpdaLiquidationPairFactory.sol";
import { TpdaLiquidationRouter } from "pt-v5-tpda-liquidator/TpdaLiquidationRouter.sol";
import { PrizeVault } from "pt-v5-vault/PrizeVault.sol";
import { YieldVault } from "pt-v5-vault-mock/YieldVault.sol";

import { Utils } from "./Utils.t.sol";

contract IntegrationBaseSetup is Test {
    /* ============ Variables ============ */
    Utils internal utils;

    address payable[] internal users;
    address internal owner;
    address internal manager;
    address internal alice;
    address internal bob;

    address public constant SPONSORSHIP_ADDRESS = address(1);

    PrizeVault public vault;
    string public vaultName = "PoolTogether aEthDAI Prize Token (PTaEthDAI)";
    string public vaultSymbol = "PTaEthDAI";

    YieldVault public yieldVault;
    ERC20Mock public underlyingAsset;
    ERC20Mock public prizeToken;

    TpdaLiquidationRouter public liquidationRouter;
    TpdaLiquidationPairFactory internal liquidationPairFactory;
    TpdaLiquidationPair public liquidationPair;

    Claimer public claimer;
    PrizePool public prizePool;

    uint256 public winningRandomNumber = 123456;
    uint32 public drawPeriodSeconds = 1 days;
    uint48 drawStartsAt;
    TwabController public twabController;

    /* ============ setUp ============ */
    function setUp() public virtual {
        utils = new Utils();

        users = utils.createUsers(4);
        owner = users[0];
        manager = users[1];
        alice = users[2];
        bob = users[3];

        vm.label(owner, "Owner");
        vm.label(manager, "Manager");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");

        underlyingAsset = new ERC20Mock();
        prizeToken = new ERC20Mock();

        twabController = new TwabController(1 days, uint32(block.timestamp));

        drawStartsAt = uint48(block.timestamp);

        prizePool = new PrizePool(
            ConstructorParams(
                prizeToken,
                twabController,
                address(this),
                1e18,
                drawPeriodSeconds, // drawPeriodSeconds
                drawStartsAt, // drawStartedAt
                12,
                uint8(4), // minimum number of tiers
                100,
                5,
                20,
                10 // draw timeout
            )
        );

        prizePool.setDrawManager(address(this));

        claimer = new Claimer(prizePool, drawPeriodSeconds, ud2x18(0.1e18));

        yieldVault = new YieldVault(address(underlyingAsset), "PoolTogether aEthDAI Yield (PTaEthDAIY)", "PTaEthDAIY");

        vault = new PrizeVault(
            vaultName,
            vaultSymbol,
            yieldVault,
            prizePool,
            address(claimer),
            address(this),
            100000000, // 0.1 = 10%
            1000,
            address(this)
        );

        liquidationPairFactory = new TpdaLiquidationPairFactory();

        liquidationPair = liquidationPairFactory.createPair(
            ILiquidationSource(vault),
            address(prizeToken),
            address(vault),
            uint32(drawPeriodSeconds / 4),
            1e18,
            0
        );

        vault.setLiquidationPair(address(liquidationPair));

        liquidationRouter = new TpdaLiquidationRouter(liquidationPairFactory);
    }
}
