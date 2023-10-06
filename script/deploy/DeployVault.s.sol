// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { PrizePool, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { SD59x18, wrap, convert } from "prb-math/SD59x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "pt-v5-cgda-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "pt-v5-cgda-liquidator/LiquidationRouter.sol";
import { VaultBooster } from "pt-v5-vault-boost/VaultBooster.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployVault is Helpers {
  function _deployVault(
    YieldVaultMintRate _yieldVault,
    string memory _nameSuffix,
    string memory _symbolSuffix,
    uint128 _tokenOutPerPool
  ) internal returns (VaultMintRate vault) {
    ERC20 _underlyingAsset = ERC20(_yieldVault.asset());

    PrizePool prizePool = _getPrizePool();

    vault = new VaultMintRate(
      _underlyingAsset,
      string.concat("Prize ", _underlyingAsset.symbol(), _nameSuffix),
      string.concat("P", _underlyingAsset.symbol(), _symbolSuffix, "-T"),
      _yieldVault,
      prizePool,
      _getClaimer(),
      msg.sender,
      100000000, // 0.1 = 10%
      msg.sender
    );

    ERC20Mintable prizeToken = _getToken(POOL_SYMBOL, _tokenDeployPath);
    prizeToken.mint(address(prizePool), 100e18);
    prizePool.contributePrizeTokens(address(vault), 100e18);

    vault.setLiquidationPair(address(_createPair(prizePool, vault, _tokenOutPerPool)));

    new VaultBooster(prizePool, address(vault), msg.sender);
  }

  function _createPair(
    PrizePool _prizePool,
    VaultMintRate _vault,
    uint128 _tokenOutPerPool
  ) internal returns (LiquidationPair pair) {
    pair = _getLiquidationPairFactory().createPair(
      ILiquidationSource(_vault),
      address(_getToken(POOL_SYMBOL, _tokenDeployPath)),
      address(_vault),
      _prizePool.drawPeriodSeconds(),
      uint32(_prizePool.firstDrawOpensAt()),
      _getTargetFirstSaleTime(_prizePool.drawPeriodSeconds()),
      _getDecayConstant(),
      uint104(ONE_POOL),
      uint104(_tokenOutPerPool),
      uint104(_tokenOutPerPool) // Assume min is 1 POOL worth of the token
    );
  }

  function _deployVaults() internal {
    /* DAI */
    uint128 daiPerPool = _getExchangeRate(ONE_DAI_IN_USD_E8, 0);

    _deployVault(_getYieldVault("yvDAI-LY"), " Low Yield", "-LY", daiPerPool);

    _deployVault(_getYieldVault("yvDAI-HY"), " High Yield", "-HY", daiPerPool);

    /* USDC */
    uint128 usdcPerPool = _getExchangeRate(
      ONE_USDC_IN_USD_E8,
      DEFAULT_TOKEN_DECIMAL - USDC_TOKEN_DECIMAL
    );

    _deployVault(_getYieldVault("yvUSDC-LY"), " Low Yield", "-LY", usdcPerPool);

    _deployVault(_getYieldVault("yvUSDC-HY"), " High Yield", "-HY", usdcPerPool);

    /* gUSD */
    uint128 gusdPerPool = _getExchangeRate(
      ONE_GUSD_IN_USD_E8,
      DEFAULT_TOKEN_DECIMAL - GUSD_TOKEN_DECIMAL
    );

    _deployVault(_getYieldVault("yvGUSD"), "", "", gusdPerPool);

    /* wBTC */
    uint128 wBtcPerPool = _getExchangeRate(
      ONE_WBTC_IN_USD_E8,
      DEFAULT_TOKEN_DECIMAL - WBTC_TOKEN_DECIMAL
    );

    _deployVault(_getYieldVault("yvWBTC"), "", "", wBtcPerPool);

    /* wETH */
    uint128 wEthPerPool = _getExchangeRate(ONE_ETH_IN_USD_E8, 0);

    _deployVault(_getYieldVault("yvWETH"), "", "", wEthPerPool);
  }

  function run() public {
    vm.startBroadcast();
    _deployVaults();
    vm.stopBroadcast();
  }
}
