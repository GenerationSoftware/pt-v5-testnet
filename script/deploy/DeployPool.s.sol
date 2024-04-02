// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/console2.sol";

import { Script } from "forge-std/Script.sol";

import { PrizePool, ConstructorParams, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { ClaimerFactory, Claimer } from "pt-v5-claimer/ClaimerFactory.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { TpdaLiquidationPair } from "pt-v5-tpda-liquidator/TpdaLiquidationPair.sol";
import { TpdaLiquidationPairFactory } from "pt-v5-tpda-liquidator/TpdaLiquidationPairFactory.sol";
import { TpdaLiquidationRouter } from "pt-v5-tpda-liquidator/TpdaLiquidationRouter.sol";
import { PrizeVaultFactory } from "pt-v5-vault/PrizeVaultFactory.sol";
import { PrizeVault, IERC4626 } from "pt-v5-vault/PrizeVault.sol";

import { StakingVault, IERC20 } from "pt-v5-staking-vault/StakingVault.sol";
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

        ClaimerFactory claimerFactory = new ClaimerFactory();
        Claimer claimer = claimerFactory.createClaimer(
            prizePool,
            _getClaimerTimeToReachMaxFee(),
            CLAIMER_MAX_FEE_PERCENT
        );

        console2.log("create CLAIMER");

        StakingVault poolStakingVault = new StakingVault("Staked POOL", "sPOOL", IERC20(address(poolToken)));

        console2.log("create POOL staking vault");

        PrizeVault poolPrizeVault = new PrizeVault(
            "Prize POOL",
            "pPOOL",
            IERC4626(address(poolStakingVault)),
            prizePool,
            address(claimer),
            address(0), // no yield fee recipient
            0, // 0 yield fee %
            0, // 0 yield buffer
            address(0) // no owner
        );

        console2.log("create POOL prize vault");

        DrawManager drawManager = new DrawManager(
            prizePool,
            rng,
            AUCTION_DURATION,
            AUCTION_TARGET_SALE_TIME,
            AUCTION_TARGET_FIRST_SALE_FRACTION,
            AUCTION_TARGET_FIRST_SALE_FRACTION,
            AUCTION_MAX_REWARD,
            address(poolPrizeVault)
        );

        console2.log("created DrawManager");

        prizePool.setDrawManager(address(drawManager));

        console2.log("set DrawManager");

        vm.stopBroadcast();
    }
}
