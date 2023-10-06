// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { console2 } from "forge-std/console2.sol";

import { UD2x18, ud2x18 } from "prb-math/UD2x18.sol";
import { SD1x18, sd1x18 } from "prb-math/SD1x18.sol";
import { SD59x18 } from "prb-math/SD59x18.sol";

abstract contract Constants {

  // Addresses
  // Defender
  address internal constant GOERLI_DEFENDER_ADDRESS = 0x22f928063d7FA5a90f4fd7949bB0848aF7C79b0A;
  address internal constant GOERLI_DEFENDER_ADDRESS_2 = 0xe6Cb4266474BBf065A822DFf46031bb16eB71264;
  address internal constant OPTIMISM_GOERLI_DEFENDER_ADDRESS =
    0x0B97aEd3d637469721400Ea7B8CD5D8DF83116F4;
  address internal constant SEPOLIA_DEFENDER_ADDRESS = 0xbD764675C2Ffb3E580D3f9c92B0c84c526fe818A;
  address internal constant MUMBAI_DEFENDER_ADDRESS = 0xbCE45a1C2c1eFF18E77f217A62a44f885b26099f;

  // Chainlink
  address internal constant GOERLI_LINK_ADDRESS = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
  address internal constant GOERLI_VRFV2_WRAPPER_ADDRESS = 0x708701a1DfF4f478de54383E49a627eD4852C816;

  // MessageExecutor
  address internal constant ERC5164_EXECUTOR_GOERLI_OPTIMISM = 0xc5165406dB791549f0D2423D1483c1EA10A3A206;

  // Chain IDs
  uint256 constant GOERLI_CHAIN_ID = 5;
  uint256 constant OPTIMISM_GOERLI_CHAIN_ID = 420;

  // Deploy parameters
  // Chainlink VRF
  uint32 internal constant CHAINLINK_CALLBACK_GAS_LIMIT = 50_000;
  uint16 internal constant CHAINLINK_REQUEST_CONFIRMATIONS = 3;

  // Claimer
  uint256 internal constant CLAIMER_MIN_FEE = 0.0001e18;
  uint256 internal constant CLAIMER_MAX_FEE = 10000e18;
  UD2x18 constant CLAIMER_MAX_FEE_PERCENT = UD2x18.wrap(0.1e18);

  function _getClaimerTimeToReachMaxFee() internal pure returns (uint256) {
    return (DRAW_PERIOD_SECONDS - (2 * AUCTION_DURATION)) / 2;
  }

  // Liquidation Pair
  uint104 internal constant ONE_POOL = 1e18;

  /// @notice The target first sale time for an LP
  function _getTargetFirstSaleTime(uint32 _drawPeriodSeconds) internal pure returns (uint32) {
    return _drawPeriodSeconds / 2;
  }

  /**
   * @notice Get Liquidation Pair decay constant.
   * @dev This is approximately the maximum decay constant, as the CGDA formula requires computing e^(decayConstant * time).
   *      Since the data type is SD59x18 and e^134 ~= 1e58, we can divide 134 by the draw period to get the max decay constant.
   */
  function _getDecayConstant() internal pure returns (SD59x18) {
    return SD59x18.wrap(0.000030092592592592e18);
  }

  // Prize Pool
  uint32 internal constant DRAW_PERIOD_SECONDS = 1 days;
  uint24 internal constant GRAND_PRIZE_PERIOD_DRAWS = 365; // Once a year for daily draws
  uint8 internal constant MIN_NUMBER_OF_TIERS = 3;
  uint256 internal constant MIN_TIME_AHEAD = DRAW_PERIOD_SECONDS;
  uint8 internal constant RESERVE_SHARES = 100;
  uint8 internal constant TIER_SHARES = 100;

  function _getContributionsSmoothing() internal pure returns (SD1x18) {
    return sd1x18(0.3e18);
  }

  /// @notice Returns the start timestamp of the first draw.
  /// @dev Configured for 7pm (19th hour) UTC of the next day
  function _getFirstDrawStartsAt() internal view returns (uint48) {
    if (block.timestamp < 1693594800) revert("block timestamp doesn't seem right"); // make sure we're not on some relative script time
    uint48 secondsInDay = 1 days;
    uint48 firstDrawStartsAt = uint48(block.timestamp / secondsInDay + 1) * secondsInDay + (19 * 60 * 60); // next day at 7:00:00 PM UTC
    console2.log("first draw starts at:", firstDrawStartsAt);
    return firstDrawStartsAt;
  }

  // RngAuctions
  uint64 internal constant AUCTION_DURATION = 6 hours;
  uint64 internal constant AUCTION_TARGET_SALE_TIME = 1 hours;
  uint256 internal constant AUCTION_MAX_REWARD = 10000e18;
  UD2x18 internal constant AUCTION_TARGET_FIRST_SALE_FRACTION = UD2x18.wrap(0.5e18); // 50%

  /// @notice Returns the timestamp of the auction offset, aligned to the draw offset.
  function _getAuctionOffset() internal view returns (uint32) {
    return uint32(_getFirstDrawStartsAt() - 3 days);
  }

  // Twab
  // nice round fraction of the draw period
  uint32 internal constant TWAB_PERIOD_LENGTH = 1 hours;

  // Token decimals
  uint8 internal constant DEFAULT_TOKEN_DECIMAL = 18;
  uint8 internal constant USDC_TOKEN_DECIMAL = 6;
  uint8 internal constant GUSD_TOKEN_DECIMAL = 2;
  uint8 internal constant WBTC_TOKEN_DECIMAL = 8;

  // Token names and symbols
  string internal constant POOL_SYMBOL = "POOL";
  string internal constant USDC_SYMBOL = "USDC";
  string internal constant WETH_SYMBOL = "WETH";
  string internal constant GUSD_SYMBOL = "GUSD";
  string internal constant DAI_SYMBOL = "DAI";
  string internal constant WBTC_SYMBOL = "WBTC";

  string internal constant PRIZE_USDC_NAME = "Prize USDC";
  string internal constant PRIZE_USDC_SYMBOL = "PUSDC";

  string internal constant PRIZE_WETH_NAME = "Prize WETH";
  string internal constant PRIZE_WETH_SYMBOL = "PWETH";

  // Token prices in USD
  uint8 MARKET_RATE_DECIMALS = 8;
  uint256 internal constant ONE_USDC_IN_USD_E8 = 1e8;
  uint256 internal constant ONE_ETH_IN_USD_E8 = 1641e8;
  uint256 internal constant ONE_PRIZE_TOKEN_IN_USD_E8 = 0.55e8;
  uint256 internal constant ONE_DAI_IN_USD_E8 = 1e8;
  uint256 internal constant ONE_GUSD_IN_USD_E8 = 1e8;
  uint256 internal constant ONE_WBTC_IN_USD_E8 = 27903e8;

  // Vault
  uint32 internal constant YIELD_FEE_PERCENTAGE = 0; // 0%
  address internal constant YIELD_FEE_RECIPIENT = address(0);

}