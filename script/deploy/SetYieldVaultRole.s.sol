// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract SetYieldVaultRole is Helpers {
  function _setYieldVaultsRole() internal {
    /* DAI */
    ERC20Mintable dai = _getToken(DAI_SYMBOL, _stableTokenDeployPath);

    YieldVaultMintRate daiLowYieldVault = _getYieldVault("yvDAI-LY");
    _tokenGrantMinterRole(dai, address(daiLowYieldVault));
    _yieldVaultGrantMinterRoles(daiLowYieldVault);
    daiLowYieldVault.setRatePerSecond(_getRatePerSeconds(6600000000000000)); // 0.66%

    YieldVaultMintRate daiHighYieldVault = _getYieldVault("yvDAI-HY");
    _tokenGrantMinterRole(dai, address(daiHighYieldVault));
    _yieldVaultGrantMinterRoles(daiHighYieldVault);
    daiHighYieldVault.setRatePerSecond(_getRatePerSeconds(250000000000000000)); // 25%

    /* USDC */
    ERC20Mintable usdc = _getToken(USDC_SYMBOL, _stableTokenDeployPath);

    YieldVaultMintRate usdcLowYieldVault = _getYieldVault("yvUSDC-LY");
    _tokenGrantMinterRole(usdc, address(usdcLowYieldVault));
    _yieldVaultGrantMinterRoles(usdcLowYieldVault);
    usdcLowYieldVault.setRatePerSecond(_getRatePerSeconds(13300000000000000)); // 1.33%

    YieldVaultMintRate usdcHighYieldVault = _getYieldVault("yvUSDC-HY");
    _tokenGrantMinterRole(usdc, address(usdcHighYieldVault));
    _yieldVaultGrantMinterRoles(usdcHighYieldVault);
    usdcHighYieldVault.setRatePerSecond(_getRatePerSeconds(500000000000000000)); // 50%

    /* gUSD */
    ERC20Mintable gUSD = _getToken(GUSD_SYMBOL, _stableTokenDeployPath);

    YieldVaultMintRate gUSDYieldVault = _getYieldVault("yvGUSD");
    _tokenGrantMinterRole(gUSD, address(gUSDYieldVault));
    _yieldVaultGrantMinterRoles(gUSDYieldVault);
    gUSDYieldVault.setRatePerSecond(_getRatePerSeconds(12700000000000000)); // 1.27%

    /* wBTC */
    ERC20Mintable wBTC = _getToken(WBTC_SYMBOL, _tokenDeployPath);

    YieldVaultMintRate wBTCYieldVault = _getYieldVault("yvWBTC");
    _tokenGrantMinterRole(wBTC, address(wBTCYieldVault));
    _yieldVaultGrantMinterRoles(wBTCYieldVault);
    wBTCYieldVault.setRatePerSecond(_getRatePerSeconds(400000000000000)); // 0.04%

    /* wETH */
    ERC20Mintable wETH = _getToken(WETH_SYMBOL, _tokenDeployPath);

    YieldVaultMintRate wETHYieldVault = _getYieldVault("yvWETH");
    _tokenGrantMinterRole(wETH, address(wETHYieldVault));
    _yieldVaultGrantMinterRoles(wETHYieldVault);
    wETHYieldVault.setRatePerSecond(_getRatePerSeconds(29300000000000000)); // 2.93%
  }

  function run() public {
    vm.startBroadcast();
    _setYieldVaultsRole();
    vm.stopBroadcast();
  }
}
