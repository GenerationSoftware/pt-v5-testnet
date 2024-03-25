// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/console2.sol";

import { Script } from "forge-std/Script.sol";

import { PrizePool, ConstructorParams, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { ClaimerFactory } from "pt-v5-claimer/ClaimerFactory.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { TpdaLiquidationPair } from "pt-v5-tpda-liquidator/TpdaLiquidationPair.sol";
import { TpdaLiquidationPairFactory } from "pt-v5-tpda-liquidator/TpdaLiquidationPairFactory.sol";
import { TpdaLiquidationRouter } from "pt-v5-tpda-liquidator/TpdaLiquidationRouter.sol";
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
import { RngBlockhash } from "pt-v5-rng-blockhash/RngBlockhash.sol";
import { DrawManager } from "pt-v5-draw-manager/DrawManager.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import {
    OPTIMISM_SEPOLIA_CHAIN_ID,
    POOL_SYMBOL,
    WETH_SYMBOL,
    TWAB_PERIOD_LENGTH,
    TIER_LIQUIDITY_UTILIZATION_PERCENT,
    DRAW_PERIOD_SECONDS,
    GRAND_PRIZE_PERIOD_DRAWS,
    MIN_NUMBER_OF_TIERS,
    TIER_SHARES,
    CANARY_SHARES,
    RESERVE_SHARES,
    DRAW_TIMEOUT,
    AUCTION_DURATION,
    AUCTION_TARGET_SALE_TIME,
    AUCTION_TARGET_FIRST_SALE_FRACTION,
    AUCTION_MAX_REWARD,
    CLAIMER_MIN_FEE,
    CLAIMER_MAX_FEE,
    CLAIMER_MAX_FEE_PERCENT
} from "./Constants.sol";

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

        TpdaLiquidationPairFactory liquidationPairFactory = new TpdaLiquidationPairFactory();
        new TpdaLiquidationRouter(liquidationPairFactory);
        new PrizeVaultFactory();

        IRng rng;
        if (block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) { // if local chain
            rng = new RngWitnet(IWitnetRandomness(_getWitnetRandomness()));
        } else {
            rng = new RngBlockhash();
        }

        console2.log("created Rng");

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
                CANARY_SHARES,
                RESERVE_SHARES,
                DRAW_TIMEOUT
            )
        );

        console2.log("created PrizePool");

        FeeBurner feeBurner = new FeeBurner(
            prizePool,
            address(poolToken),
            msg.sender
        );

        console2.log("created FeeBurner");

        TpdaLiquidationPair feeBurnerPair = liquidationPairFactory.createPair(
            feeBurner,
            address(poolToken),
            address(prizeToken),
            _getTargetFirstSaleTime(prizePool.drawPeriodSeconds()),
            1e18, // 1 POOL
            0.95e18 // heavy smoothing
        );

        console2.log("created FeeBurnerPair");

        feeBurner.setLiquidationPair(address(feeBurnerPair));

        console2.log("set liquidation pair");

        DrawManager drawManager = new DrawManager(
            prizePool,
            rng,
            AUCTION_DURATION,
            AUCTION_TARGET_SALE_TIME,
            AUCTION_TARGET_FIRST_SALE_FRACTION,
            AUCTION_TARGET_FIRST_SALE_FRACTION,
            AUCTION_MAX_REWARD,
            address(feeBurner)
        );

        console2.log("created DrawManager");

        prizePool.setDrawManager(address(drawManager));

        console2.log("set DrawManager");

        ClaimerFactory claimerFactory = new ClaimerFactory();
        claimerFactory.createClaimer(
            prizePool,
            CLAIMER_MIN_FEE,
            CLAIMER_MAX_FEE,
            _getClaimerTimeToReachMaxFee(),
            CLAIMER_MAX_FEE_PERCENT
        );

        console2.log("create CLAIMER");

        vm.stopBroadcast();
    }
}
