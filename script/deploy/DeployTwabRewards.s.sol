// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";

import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { TwabRewards } from "pt-v5-twab-rewards/TwabRewards.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployTwabRewards is Helpers {

  function _deployTwabRewards() internal {
    TwabController _twabController = _getTwabController();
    new TwabRewards(_twabController);
  }

  function run() public {
    vm.startBroadcast();
    _deployTwabRewards();
    vm.stopBroadcast();
  }
}
