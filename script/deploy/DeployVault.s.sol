// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/console2.sol";

import { PrizePool, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { SD59x18, wrap, convert } from "prb-math/SD59x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { TpdaLiquidationPair } from "pt-v5-tpda-liquidator/TpdaLiquidationPair.sol";
import { TpdaLiquidationPairFactory } from "pt-v5-tpda-liquidator/TpdaLiquidationPairFactory.sol";
import { TpdaLiquidationRouter } from "pt-v5-tpda-liquidator/TpdaLiquidationRouter.sol";
import { VaultBooster } from "pt-v5-vault-boost/VaultBooster.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { PrizeVaultMintRate } from "../../src/PrizeVaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

import {
    ONE_WETH,
    ONE_DAI,
    ONE_USDC,
    ONE_GUSD,
    ONE_WBTC,
    USD_PER_ETH_E8,
    USD_PER_DAI_E8,
    USD_PER_USDC_E8,
    USD_PER_GUSD_E8,
    USD_PER_WBTC_E8,
    E8
} from "./Constants.sol";

contract DeployVault is Helpers {
    function _deployVault(
        YieldVaultMintRate _yieldVault,
        string memory _nameSuffix,
        string memory _symbolSuffix,
        uint104 _tokenOutPerWeth,
        uint104 _tokenOutPerUsd
    ) internal returns (PrizeVaultMintRate vault) {
        ERC20 _underlyingAsset = ERC20(_yieldVault.asset());

        console2.log("_deployVault _underlyingAsset", address(_underlyingAsset));

        PrizePool prizePool = _getPrizePool();

        console2.log("_deployVault prizePool", address(prizePool));

        vault = new PrizeVaultMintRate(
            string.concat("Prize ", _underlyingAsset.symbol(), _nameSuffix),
            string.concat("p", _underlyingAsset.symbol(), _symbolSuffix, "-T"),
            _yieldVault,
            prizePool,
            address(_getClaimer()),
            msg.sender,
            100000000, // 0.1 = 10%
            msg.sender
        );

        ERC20Mintable prizeToken = _prizeToken();
        prizeToken.mint(address(prizePool), 100e18);
        prizePool.contributePrizeTokens(address(vault), 100e18);

        vault.setLiquidationPair(address(_createPair(prizePool, vault, _tokenOutPerWeth, _tokenOutPerUsd)));

        new VaultBooster(prizePool, address(vault), msg.sender);
    }

    function _createPair(
        PrizePool _prizePool,
        PrizeVaultMintRate _vault,
        uint104 _tokenOutPerWeth,
        uint104 _tokenOutPerUsd
    ) internal returns (TpdaLiquidationPair pair) {
        pair = _getTpdaLiquidationPairFactory().createPair(
            ILiquidationSource(_vault),
            address(_prizeToken()),
            address(_vault),
            _getTargetFirstSaleTime(_prizePool.drawPeriodSeconds()),
            0.001e18, // 1 thousandth of an ETH
            0 // no smoothing
        );
    }

    function _deployVaults() internal {
        /* DAI */
        uint104 daiPerWeth = uint104((ONE_WETH * USD_PER_ETH_E8) / USD_PER_DAI_E8);
        uint104 daiPerUsd = uint104(ONE_DAI * E8 / USD_PER_DAI_E8);
        _deployVault(_getYieldVault("yvDAI-LY"), " Low Yield", "-LY", daiPerWeth, daiPerUsd);

        _deployVault(_getYieldVault("yvDAI-HY"), " High Yield", "-HY", daiPerWeth, daiPerUsd);

        /* USDC */
        uint104 usdcPerWeth = uint104((ONE_WETH * USD_PER_ETH_E8) / USD_PER_USDC_E8);
        uint104 usdcPerUsd = uint104(ONE_USDC * E8 / USD_PER_USDC_E8);

        _deployVault(_getYieldVault("yvUSDC-LY"), " Low Yield", "-LY", usdcPerWeth, usdcPerUsd);

        _deployVault(_getYieldVault("yvUSDC-HY"), " High Yield", "-HY", usdcPerWeth, usdcPerUsd);

        /* gUSD */
        uint104 gusdPerWeth = uint104((ONE_WETH * USD_PER_ETH_E8) / USD_PER_GUSD_E8);
        uint104 gusdPerUsd = uint104(ONE_GUSD * E8 / USD_PER_GUSD_E8);
        _deployVault(_getYieldVault("yvGUSD"), "", "", gusdPerWeth, gusdPerUsd);

        /* wBTC */
        uint104 wBtcPerWeth = uint104((ONE_WETH * USD_PER_ETH_E8) / USD_PER_WBTC_E8);
        uint104 wBtcPerUsd = uint104((ONE_WBTC * E8) / USD_PER_WBTC_E8);
        _deployVault(_getYieldVault("yvWBTC"), "", "", wBtcPerWeth, wBtcPerUsd);

        uint104 wethPerUsd = uint104((ONE_WETH * E8) / USD_PER_ETH_E8);
        _deployVault(_getYieldVault("yvWETH"), "", "", ONE_WETH, wethPerUsd);
    }

    function run() public {
        vm.startBroadcast();
        _deployVaults();
        vm.stopBroadcast();
    }
}
