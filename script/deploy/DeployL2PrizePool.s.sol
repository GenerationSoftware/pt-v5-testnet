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

import { RemoteOwner } from "remote-owner/RemoteOwner.sol";
import { RngRelayAuction, UD2x18 } from "pt-v5-draw-auction/RngRelayAuction.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployL2PrizePool is Helpers {
    function run() public {
        vm.startBroadcast();

        console2.log("getting POOL....");

        ERC20Mintable prizeToken = _getToken(POOL_SYMBOL, _tokenDeployPath);

        console2.log("constructing twab controller....");

        TwabController twabController = new TwabController(
            TWAB_PERIOD_LENGTH,
            _getAuctionOffset() // use auction offset since it's set in the past
        );

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

        RemoteOwner remoteOwner;
        address _rngAuctionRemoteOwner = address(_getL1RngAuctionRelayerRemote());

        if (block.chainid == ARBITRUM_GOERLI_CHAIN_ID) {
            remoteOwner = new RemoteOwner(GOERLI_CHAIN_ID, ERC5164_EXECUTOR_GOERLI_ARBITRUM, _rngAuctionRemoteOwner);
        } else if (block.chainid == OPTIMISM_GOERLI_CHAIN_ID) {
            remoteOwner = new RemoteOwner(GOERLI_CHAIN_ID, ERC5164_EXECUTOR_GOERLI_OPTIMISM, _rngAuctionRemoteOwner);
        } else if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            remoteOwner = new RemoteOwner(SEPOLIA_CHAIN_ID, ERC5164_EXECUTOR_SEPOLIA_ARBITRUM, _rngAuctionRemoteOwner);
        } else if (block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            remoteOwner = new RemoteOwner(SEPOLIA_CHAIN_ID, ERC5164_EXECUTOR_SEPOLIA_OPTIMISM, _rngAuctionRemoteOwner);
        }

        require(address(remoteOwner) != address(0), "remoteOwner-not-zero-address");

        RngRelayAuction rngRelayAuction = new RngRelayAuction(
            prizePool,
            AUCTION_DURATION,
            AUCTION_TARGET_SALE_TIME,
            address(remoteOwner),
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
