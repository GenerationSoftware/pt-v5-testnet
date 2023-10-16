// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/console2.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract SetVaultRole is Helpers {
  function _setVaultsRole() internal {
    /* DAI */
    _yieldVaultGrantMinterRole(_getYieldVault("yvDAI-LY"), address(_getVault("PDAI-LY-T")));
    _yieldVaultGrantMinterRole(_getYieldVault("yvDAI-HY"), address(_getVault("PDAI-HY-T")));

    // /* USDC */
    _yieldVaultGrantMinterRole(_getYieldVault("yvUSDC-LY"), address(_getVault("PUSDC-LY-T")));
    _yieldVaultGrantMinterRole(_getYieldVault("yvUSDC-HY"), address(_getVault("PUSDC-HY-T")));

    // /* gUSD */
    _yieldVaultGrantMinterRole(_getYieldVault("yvGUSD"), address(_getVault("PGUSD-T")));

    // /* wBTC */
    _yieldVaultGrantMinterRole(_getYieldVault("yvWBTC"), address(_getVault("PWBTC-T")));

    // /* wETH */
    _yieldVaultGrantMinterRole(_getYieldVault("yvWETH"), address(_getVault("PWETH-T")));
  }

  function run() public {
    vm.startBroadcast();
    _setVaultsRole();
    vm.stopBroadcast();
  }
}
