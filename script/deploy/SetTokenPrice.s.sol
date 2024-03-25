// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { MarketRate } from "../../src/MarketRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

import {
    DAI_SYMBOL,
    USDC_SYMBOL,
    GUSD_SYMBOL,
    WBTC_SYMBOL,
    WETH_SYMBOL,
    POOL_SYMBOL,
    USD_PER_DAI_E8,
    USD_PER_USDC_E8,
    USD_PER_GUSD_E8,
    USD_PER_WBTC_E8,
    USD_PER_ETH_E8,
    USD_PER_POOL_E8
} from "./Constants.sol";

contract SetTokenPrice is Helpers {
    function _setTokensPrice() internal {
        string memory _denominator = "USD";
        MarketRate marketRate = _getMarketRate();

        /* DAI */
        ERC20Mintable dai = _getToken(DAI_SYMBOL, _stableTokenDeployPath);
        marketRate.setPrice(address(dai), _denominator, USD_PER_DAI_E8);

        /* USDC */
        ERC20Mintable usdc = _getToken(USDC_SYMBOL, _stableTokenDeployPath);
        marketRate.setPrice(address(usdc), _denominator, USD_PER_USDC_E8);

        /* gUSD */
        ERC20Mintable gUSD = _getToken(GUSD_SYMBOL, _stableTokenDeployPath);
        marketRate.setPrice(address(gUSD), _denominator, USD_PER_GUSD_E8);

        /* wBTC */
        ERC20Mintable wBTC = _getToken(WBTC_SYMBOL, _tokenDeployPath);
        marketRate.setPrice(address(wBTC), _denominator, USD_PER_WBTC_E8);

        /* wETH */
        ERC20Mintable wETH = _getToken(WETH_SYMBOL, _tokenDeployPath);
        marketRate.setPrice(address(wETH), _denominator, USD_PER_ETH_E8);
        marketRate.setPrice(address(0), _denominator, USD_PER_ETH_E8);

        /* prizeToken */
        ERC20Mintable poolToken = _getToken(POOL_SYMBOL, _tokenDeployPath);
        marketRate.setPrice(address(poolToken), _denominator, USD_PER_POOL_E8);
    }

    function run() public {
        vm.startBroadcast();
        _setTokensPrice();
        vm.stopBroadcast();
    }
}
