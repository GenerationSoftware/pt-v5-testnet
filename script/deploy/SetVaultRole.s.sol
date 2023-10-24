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
        _yieldVaultGrantMinterRole(_getYieldVault("yvDAI-LY"), address(_getVault("pDAI-LY-T")));
        _yieldVaultGrantMinterRole(_getYieldVault("yvDAI-HY"), address(_getVault("pDAI-HY-T")));

        // /* USDC */
        _yieldVaultGrantMinterRole(_getYieldVault("yvUSDC-LY"), address(_getVault("pUSDC-LY-T")));
        _yieldVaultGrantMinterRole(_getYieldVault("yvUSDC-HY"), address(_getVault("pUSDC-HY-T")));

        // /* gUSD */
        _yieldVaultGrantMinterRole(_getYieldVault("yvGUSD"), address(_getVault("pGUSD-T")));

        // /* wBTC */
        _yieldVaultGrantMinterRole(_getYieldVault("yvWBTC"), address(_getVault("pWBTC-T")));

        // /* wETH */
        _yieldVaultGrantMinterRole(_getYieldVault("yvWETH"), address(_getVault("pWETH-T")));
    }

    function run() public {
        vm.startBroadcast();
        _setVaultsRole();
        vm.stopBroadcast();
    }
}
