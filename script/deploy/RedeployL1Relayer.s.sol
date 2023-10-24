// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/console2.sol";

import { IRngAuction } from "pt-v5-chainlink-vrf-v2-direct/interfaces/IRngAuction.sol";
import { ChainlinkVRFV2Direct } from "pt-v5-chainlink-vrf-v2-direct/ChainlinkVRFV2Direct.sol";
import {
    ChainlinkVRFV2DirectRngAuctionHelper
} from "pt-v5-chainlink-vrf-v2-direct/ChainlinkVRFV2DirectRngAuctionHelper.sol";

import { RNGInterface } from "rng/RNGInterface.sol";
import { RngAuction, UD2x18 } from "pt-v5-draw-auction/RngAuction.sol";
import { RngAuctionRelayerRemoteOwner } from "pt-v5-draw-auction/RngAuctionRelayerRemoteOwner.sol";
import { RngRelayAuction } from "pt-v5-draw-auction/RngRelayAuction.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract RedeployL1Relayer is Helpers {
    function run() public {
        vm.startBroadcast();

        console2.log("Re-deploying L1 Relayer...");

        RngAuction rngAuction = _getL1RngAuction();

        RngAuctionRelayerRemoteOwner newRelayer = new RngAuctionRelayerRemoteOwner(rngAuction);

        console2.log("RngAuctionRelayerRemoteOwner address: ", address(newRelayer));

        vm.stopBroadcast();
    }
}
