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

contract RedeployL2RelayListener is Helpers {
    function run() public {
        vm.startBroadcast();

        PrizePool prizePool = _getPrizePool();

        console2.log("re-deploying remote owner....");

        address newRelayerAddress = _getContractAddress(
            "RngAuctionRelayerRemoteOwner",
            _getDeployPathWithChainId("RedeployL1Relayer.s.sol", GOERLI_CHAIN_ID),
            "new-rng-relayer-not-found"
        );
        RemoteOwner remoteOwner = new RemoteOwner(GOERLI_CHAIN_ID, ERC5164_EXECUTOR_GOERLI_OPTIMISM, newRelayerAddress);

        console2.log("re-deploying relay auction....");

        RngRelayAuction rngRelayAuction = new RngRelayAuction(
            prizePool,
            AUCTION_DURATION,
            AUCTION_TARGET_SALE_TIME,
            address(remoteOwner),
            AUCTION_TARGET_FIRST_SALE_FRACTION,
            AUCTION_MAX_REWARD
        );

        // Uncomment to set relay auction as new draw manager right away:
        // console2.log("setting draw manager....");
        // prizePool.setDrawManager(address(rngRelayAuction));

        vm.stopBroadcast();
    }
}
