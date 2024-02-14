// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/console2.sol";

import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";

import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { TwabDelegator } from "pt-v5-twab-delegator/TwabDelegator.sol";

import { PrizeVaultMintRate } from "../../src/PrizeVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployTwabDelegator is Helpers {
    function _deployTwabDelegator(
        TwabController _twabController,
        PrizeVaultMintRate _vault,
        string memory _nameSuffix,
        string memory _symbolSuffix
    ) internal {
        ERC20 _underlyingAsset = ERC20(_vault.asset());

        console2.log("_deployTwabDelegator _underlyingAsset", address(_underlyingAsset));

        new TwabDelegator(
            string.concat("Staked Prize ", _underlyingAsset.symbol(), _nameSuffix),
            string.concat("stkP", _underlyingAsset.symbol(), _symbolSuffix, "-T"),
            _twabController,
            _vault
        );
    }

    function _deployTwabDelegators() internal {
        console2.log("_deployTwabDelegators");

        TwabController _twabController = _getTwabController();

        console2.log("_deployTwabDelegators _twabController", address(_twabController));

        /* DAI */
        _deployTwabDelegator(_twabController, _getVault("pDAI-LY-T"), " Low Yield", "LY");
        _deployTwabDelegator(_twabController, _getVault("pDAI-HY-T"), " High Yield", "HY");

        /* USDC */
        _deployTwabDelegator(_twabController, _getVault("pUSDC-LY-T"), " Low Yield", "LY");
        _deployTwabDelegator(_twabController, _getVault("pUSDC-HY-T"), " High Yield", "HY");

        /* gUSD */
        _deployTwabDelegator(_twabController, _getVault("pGUSD-T"), "", "");

        /* wBTC */
        _deployTwabDelegator(_twabController, _getVault("pWBTC-T"), "", "");

        /* wETH */
        _deployTwabDelegator(_twabController, _getVault("pWETH-T"), "", "");
    }

    function run() public {
        vm.startBroadcast();
        _deployTwabDelegators();
        vm.stopBroadcast();
    }
}
