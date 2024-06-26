// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import { IERC4626, IERC20 } from "openzeppelin/mocks/ERC4626Mock.sol";

import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { PrizeVault } from "pt-v5-vault/PrizeVault.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";

import { YieldVaultMintRate } from "./YieldVaultMintRate.sol";

contract PrizeVaultMintRate is PrizeVault {
    YieldVaultMintRate private immutable _yieldVault;

    constructor(
        string memory _name,
        string memory _symbol,
        YieldVaultMintRate yieldVault_,
        PrizePool _prizePool,
        address _claimer,
        address _yieldFeeRecipient,
        uint32 _yieldFeePercentage,
        address _owner
    )
        PrizeVault(
            _name,
            _symbol,
            IERC4626(address(yieldVault_)),
            _prizePool,
            _claimer,
            _yieldFeeRecipient,
            _yieldFeePercentage,
            1e5,
            _owner
        )
    {
        _yieldVault = yieldVault_;
    }

    function _mint(address _receiver, uint256 _shares) internal virtual override {
        super._mint(_receiver, _shares);
        _yieldVault.mintRate(); // Updates the accrued yield in the YieldVaultMintRate
    }
}
