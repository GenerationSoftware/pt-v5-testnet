// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/console2.sol";

import { RngAuction } from "pt-v5-draw-auction/RngAuction.sol";
import { RngAuctionRelayerRemoteOwnerArbitrum } from "pt-v5-draw-auction/RngAuctionRelayerRemoteOwnerArbitrum.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployL1RelayerArbitrum is Helpers {
    function run() public {
        vm.startBroadcast();

        console2.log("Deploying L1 Relayer for Arbitrum...");

        RngAuction rngAuction = _getL1RngAuction();

        RngAuctionRelayerRemoteOwnerArbitrum relayer = new RngAuctionRelayerRemoteOwnerArbitrum(rngAuction);

        console2.log("RngAuctionRelayerRemoteOwnerArbitrum address: ", address(relayer));

        vm.stopBroadcast();
    }
}
