// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

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
import { LiquidationPair } from "pt-v5-cgda-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "pt-v5-cgda-liquidator/LiquidationRouter.sol";
import { Vault } from "pt-v5-vault/Vault.sol";
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

  Vault public vault;
  string public vaultName = "PoolTogether aEthDAI Prize Token (PTaEthDAI)";
  string public vaultSymbol = "PTaEthDAI";

  YieldVault public yieldVault;
  ERC20Mock public underlyingAsset;
  ERC20Mock public prizeToken;

  LiquidationRouter public liquidationRouter;
  LiquidationPairFactory internal liquidationPairFactory;
  LiquidationPair public liquidationPair;

  Claimer public claimer;
  PrizePool public prizePool;

  uint256 public winningRandomNumber = 123456;
  uint32 public drawPeriodSeconds = 1 days;
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

    uint64 drawStartsAt = uint64(block.timestamp);

    prizePool = new PrizePool(
      ConstructorParams(
        prizeToken,
        twabController,
        address(0),
        drawPeriodSeconds, // drawPeriodSeconds
        drawStartsAt, // drawStartedAt
        sd1x18(0.9e18), // alpha
        12,
        uint8(3), // minimum number of tiers
        100,
        100
      )
    );

    prizePool.setDrawManager(address(this));

    claimer = new Claimer(prizePool, 0.0001e18, 1000e18, drawPeriodSeconds, ud2x18(0.5e18));

    yieldVault = new YieldVault(
      address(underlyingAsset),
      "PoolTogether aEthDAI Yield (PTaEthDAIY)",
      "PTaEthDAIY"
    );

    vault = new Vault(
      underlyingAsset,
      vaultName,
      vaultSymbol,
      twabController,
      yieldVault,
      prizePool,
      address(claimer),
      address(this),
      100000000, // 0.1 = 10%
      address(this)
    );

    liquidationPairFactory = new LiquidationPairFactory();

    uint128 _virtualReserveIn = 10e18;
    uint128 _virtualReserveOut = 5e18;

    // this is approximately the maximum decay constant, as the CGDA formula requires computing e^(decayConstant * time).
    // since the data type is SD59x18 and e^134 ~= 1e58, we can divide 134 by the draw period to get the max decay constant.
    SD59x18 _decayConstant = convert(130).div(convert(int(uint(drawPeriodSeconds))));
    liquidationPair = liquidationPairFactory.createPair(
      ILiquidationSource(vault),
      address(prizeToken),
      address(vault),
      drawPeriodSeconds,
      uint32(drawStartsAt),
      uint32(drawPeriodSeconds / 2),
      _decayConstant,
      uint104(_virtualReserveIn),
      uint104(_virtualReserveOut),
      _virtualReserveOut // just make it up
    );

    vault.setLiquidationPair(liquidationPair);

    liquidationRouter = new LiquidationRouter(liquidationPairFactory);
  }
}
