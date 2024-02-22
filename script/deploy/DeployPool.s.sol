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
import { PrizeVaultFactory } from "pt-v5-vault/PrizeVaultFactory.sol";

import { LinkTokenInterface } from "chainlink/interfaces/LinkTokenInterface.sol";
import { VRFV2WrapperInterface } from "chainlink/interfaces/VRFV2WrapperInterface.sol";

import { IRngAuction } from "pt-v5-chainlink-vrf-v2-direct/interfaces/IRngAuction.sol";
import { ChainlinkVRFV2Direct } from "pt-v5-chainlink-vrf-v2-direct/ChainlinkVRFV2Direct.sol";
import {
    ChainlinkVRFV2DirectRngAuctionHelper
} from "pt-v5-chainlink-vrf-v2-direct/ChainlinkVRFV2DirectRngAuctionHelper.sol";

import { FeeBurner } from "pt-v5-fee-burner/FeeBurner.sol";
import { IRng } from "pt-v5-draw-manager/interfaces/IRng.sol";
import { RngWitnet, IWitnetRandomness } from "pt-v5-rng-witnet/RngWitnet.sol";
import { DrawManager } from "pt-v5-draw-manager/DrawManager.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployPool is Helpers {
    function run() public {
        vm.startBroadcast();

        console2.log("POOL_SYMBOL: ", POOL_SYMBOL);
        ERC20Mintable poolToken = _getToken(POOL_SYMBOL, _tokenDeployPath);
        ERC20Mintable prizeToken = _getToken(WETH_SYMBOL, _tokenDeployPath);
        console2.log("prizeToken: ", address(prizeToken));
        TwabController twabController = new TwabController(
            TWAB_PERIOD_LENGTH,
            _getAuctionOffset() // use auction offset since it's set in the past
        );

        LiquidationPairFactory liquidationPairFactory = new LiquidationPairFactory();
        new LiquidationRouter(liquidationPairFactory);
        new PrizeVaultFactory();

        RngWitnet rngWitnet = new RngWitnet(IWitnetRandomness(_getWitnetRandomness()));

        PrizePool prizePool = new PrizePool(
            ConstructorParams(
                prizeToken,
                twabController,
                msg.sender,
                TIER_LIQUIDITY_UTILIZATION_PERCENT,
                DRAW_PERIOD_SECONDS,
                _getFirstDrawStartsAt(),
                GRAND_PRIZE_PERIOD_DRAWS,
                MIN_NUMBER_OF_TIERS,
                TIER_SHARES,
                RESERVE_SHARES,
                DRAW_TIMEOUT
            )
        );

        FeeBurner feeBurner = new FeeBurner(
            prizePool,
            address(_getToken(POOL_SYMBOL, _tokenDeployPath)),
            msg.sender
        );

        uint128 wEthPerPool = _getExchangeRate(ONE_ETH_IN_USD_E8, 0);
        LiquidationPair feeBurnerPair = liquidationPairFactory.createPair(
            feeBurner,
            address(_getToken(POOL_SYMBOL, _tokenDeployPath)),
            address(prizeToken),
            uint32(prizePool.drawPeriodSeconds()),
            uint32(prizePool.firstDrawOpensAt()),
            _getTargetFirstSaleTime(prizePool.drawPeriodSeconds()),
            _getDecayConstant(),
            uint104(wEthPerPool),
            uint104(ONE_POOL),
            uint104(ONE_POOL) // Assume min is 1 POOL worth of the token
        );

        feeBurner.setLiquidationPair(address(feeBurnerPair));

        DrawManager drawManager = new DrawManager(
            prizePool,
            rngWitnet,
            AUCTION_DURATION,
            AUCTION_TARGET_SALE_TIME,
            AUCTION_TARGET_FIRST_SALE_FRACTION,
            AUCTION_TARGET_FIRST_SALE_FRACTION,
            AUCTION_MAX_REWARD,
            address(feeBurner)
        );

        prizePool.setDrawManager(address(drawManager));

        ClaimerFactory claimerFactory = new ClaimerFactory();
        claimerFactory.createClaimer(
            prizePool,
            CLAIMER_MIN_FEE,
            CLAIMER_MAX_FEE,
            _getClaimerTimeToReachMaxFee(),
            CLAIMER_MAX_FEE_PERCENT
        );

        vm.stopBroadcast();
    }
}
