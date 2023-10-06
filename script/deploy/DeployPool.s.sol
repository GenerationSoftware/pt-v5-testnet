// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/console2.sol";

import { Script } from "forge-std/Script.sol";

import { PrizePool, ConstructorParams, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { ClaimerFactory } from "pt-v5-claimer/ClaimerFactory.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "pt-v5-cgda-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "pt-v5-cgda-liquidator/LiquidationRouter.sol";
import { VaultFactory } from "pt-v5-vault/VaultFactory.sol";

import { LinkTokenInterface } from "chainlink/interfaces/LinkTokenInterface.sol";
import { VRFV2WrapperInterface } from "chainlink/interfaces/VRFV2WrapperInterface.sol";

import { IRngAuction } from "pt-v5-chainlink-vrf-v2-direct/interfaces/IRngAuction.sol";
import { ChainlinkVRFV2Direct } from "pt-v5-chainlink-vrf-v2-direct/ChainlinkVRFV2Direct.sol";
import { ChainlinkVRFV2DirectRngAuctionHelper } from "pt-v5-chainlink-vrf-v2-direct/ChainlinkVRFV2DirectRngAuctionHelper.sol";

import { RNGInterface } from "rng/RNGInterface.sol";
import { RngAuction, UD2x18 } from "pt-v5-draw-auction/RngAuction.sol";
import { RngAuctionRelayerDirect } from "pt-v5-draw-auction/RngAuctionRelayerDirect.sol";
import { RngRelayAuction } from "pt-v5-draw-auction/RngRelayAuction.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployPool is Helpers {
  function run() public {
    vm.startBroadcast();

    ERC20Mintable prizeToken = _getToken(POOL_SYMBOL, _tokenDeployPath);
    TwabController twabController = new TwabController(
      TWAB_PERIOD_LENGTH,
      _getAuctionOffset() // use auction offset since it's set in the past
    );

    console2.log("constructing rng stuff....");

    ChainlinkVRFV2Direct chainlinkRng = new ChainlinkVRFV2Direct(
      msg.sender, // owner
      _getVrfV2Wrapper(),
      CHAINLINK_CALLBACK_GAS_LIMIT,
      CHAINLINK_REQUEST_CONFIRMATIONS
    );

    RngAuction rngAuction = new RngAuction(
      RNGInterface(chainlinkRng),
      msg.sender,
      DRAW_PERIOD_SECONDS,
      _getFirstDrawStartsAt(),
      AUCTION_DURATION,
      AUCTION_TARGET_SALE_TIME,
      AUCTION_TARGET_FIRST_SALE_FRACTION
    );

    RngAuctionRelayerDirect rngAuctionRelayerDirect = new RngAuctionRelayerDirect(rngAuction);

    new ChainlinkVRFV2DirectRngAuctionHelper(chainlinkRng, IRngAuction(address(rngAuction)));

    console2.log("constructing prize pool....");

    PrizePool prizePool = new PrizePool(
      ConstructorParams(
        prizeToken,
        twabController,
        DRAW_PERIOD_SECONDS,
        _getFirstDrawStartsAt(),
        _getContributionsSmoothing(),
        GRAND_PRIZE_PERIOD_DRAWS,
        MIN_NUMBER_OF_TIERS,
        TIER_SHARES,
        RESERVE_SHARES
      )
    );

    console2.log("constructing auction....");

    RngRelayAuction rngRelayAuction = new RngRelayAuction(
      prizePool,
      AUCTION_DURATION,
      AUCTION_TARGET_SALE_TIME,
      address(rngAuctionRelayerDirect),
      AUCTION_TARGET_FIRST_SALE_FRACTION,
      AUCTION_MAX_REWARD
    );

    prizePool.setDrawManager(address(rngRelayAuction));

    ClaimerFactory claimerFactory = new ClaimerFactory();
    claimerFactory.createClaimer(
      prizePool,
      CLAIMER_MIN_FEE,
      CLAIMER_MAX_FEE,
      _getClaimerTimeToReachMaxFee(),
      CLAIMER_MAX_FEE_PERCENT
    );

    LiquidationPairFactory liquidationPairFactory = new LiquidationPairFactory();
    new LiquidationRouter(liquidationPairFactory);

    new VaultFactory();

    vm.stopBroadcast();
  }
}
