// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/console2.sol";

import { RngAuction } from "pt-v5-draw-auction/RngAuction.sol";
import { RngAuctionRelayerRemoteOwnerOptimism } from "pt-v5-draw-auction/RngAuctionRelayerRemoteOwnerOptimism.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployL1RelayerOptimism is Helpers {
    function run() public {
        vm.startBroadcast();

        console2.log("Deploying L1 Relayer for Optimism...");

        RngAuction rngAuction = _getL1RngAuction();

        RngAuctionRelayerRemoteOwnerOptimism relayer = new RngAuctionRelayerRemoteOwnerOptimism(rngAuction);

        console2.log("RngAuctionRelayerRemoteOwnerOptimism address: ", address(relayer));

        vm.stopBroadcast();
    }
}
