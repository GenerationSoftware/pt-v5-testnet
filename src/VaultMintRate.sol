// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { IERC4626, IERC20 } from "openzeppelin/mocks/ERC4626Mock.sol";

import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { Vault } from "pt-v5-vault/Vault.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";

import { YieldVaultMintRate } from "./YieldVaultMintRate.sol";

contract VaultMintRate is Vault {
  constructor(
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    TwabController _twabController,
    IERC4626 _yieldVault,
    PrizePool _prizePool,
    Claimer _claimer,
    address _yieldFeeRecipient,
    uint32 _yieldFeePercentage,
    address _owner
  )
    Vault(
      _asset,
      _name,
      _symbol,
      _yieldVault,
      _prizePool,
      address(_claimer),
      _yieldFeeRecipient,
      _yieldFeePercentage,
      _owner
    )
  {}

  function transferTokensOut(
    address _sender,
    address _receiver,
    address _tokenOut,
    uint256 _amountOut
  ) public override returns (bytes memory) {
    YieldVaultMintRate(yieldVault()).mintRate(); // Updates the accrued yield in the YieldVaultMintRate
    return
      super.transferTokensOut(
        _sender,
        _receiver,
        _tokenOut,
        _amountOut
      );
  }

}
