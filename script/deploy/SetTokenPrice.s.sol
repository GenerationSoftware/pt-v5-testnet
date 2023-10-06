// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { MarketRate } from "../../src/MarketRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract SetTokenPrice is Helpers {
  function _setTokensPrice() internal {
    string memory _denominator = "USD";
    MarketRate marketRate = _getMarketRate();

    /* DAI */
    ERC20Mintable dai = _getToken(DAI_SYMBOL, _stableTokenDeployPath);
    marketRate.setPrice(address(dai), _denominator, ONE_DAI_IN_USD_E8);

    /* USDC */
    ERC20Mintable usdc = _getToken(USDC_SYMBOL, _stableTokenDeployPath);
    marketRate.setPrice(address(usdc), _denominator, ONE_USDC_IN_USD_E8);

    /* gUSD */
    ERC20Mintable gUSD = _getToken(GUSD_SYMBOL, _stableTokenDeployPath);
    marketRate.setPrice(address(gUSD), _denominator, ONE_GUSD_IN_USD_E8);

    /* wBTC */
    ERC20Mintable wBTC = _getToken(WBTC_SYMBOL, _tokenDeployPath);
    marketRate.setPrice(address(wBTC), _denominator, ONE_WBTC_IN_USD_E8);

    /* wETH */
    ERC20Mintable wETH = _getToken(WETH_SYMBOL, _tokenDeployPath);
    marketRate.setPrice(address(wETH), _denominator, ONE_ETH_IN_USD_E8);
    marketRate.setPrice(address(0), _denominator, ONE_ETH_IN_USD_E8);

    /* prizeToken */
    ERC20Mintable prizeToken = _getToken(POOL_SYMBOL, _tokenDeployPath);
    marketRate.setPrice(address(prizeToken), _denominator, ONE_PRIZE_TOKEN_IN_USD_E8);
  }

  function run() public {
    vm.startBroadcast();
    _setTokensPrice();
    vm.stopBroadcast();
  }
}
