// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployYieldVault is Helpers {
  function _deployYieldVault(
    ERC20Mintable _underlyingAsset,
    string memory _nameSuffix,
    string memory _symbolSuffix
  ) internal returns (YieldVaultMintRate) {
    string memory _underlyingAssetSymbol = _underlyingAsset.symbol();

    return
      new YieldVaultMintRate(
        _underlyingAsset,
        string.concat("Prize Yield Vault ", _underlyingAssetSymbol, " ", _nameSuffix),
        string.concat("yvP", _underlyingAssetSymbol, _symbolSuffix),
        msg.sender
      );
  }

  function _deployYieldVaults() internal {
    /* DAI */
    ERC20Mintable dai = _getToken(DAI_SYMBOL, _stableTokenDeployPath);
    _deployYieldVault(dai, "Low Yield", "-LY");
    _deployYieldVault(dai, "High Yield", "-HY");

    /* USDC */
    ERC20Mintable usdc = _getToken(USDC_SYMBOL, _stableTokenDeployPath);
    _deployYieldVault(usdc, "Low Yield", "-LY");
    _deployYieldVault(usdc, "High Yield", "-HY");

    /* gUSD */
    ERC20Mintable gUSD = _getToken(GUSD_SYMBOL, _stableTokenDeployPath);
    _deployYieldVault(gUSD, "", "");

    /* wBTC */
    ERC20Mintable wBTC = _getToken(WBTC_SYMBOL, _tokenDeployPath);
    _deployYieldVault(wBTC, "", "");

    /* wETH */
    ERC20Mintable wETH = _getToken(WETH_SYMBOL, _tokenDeployPath);
    _deployYieldVault(wETH, "", "");
  }

  function run() public {
    vm.startBroadcast();
    _deployYieldVaults();
    vm.stopBroadcast();
  }
}
