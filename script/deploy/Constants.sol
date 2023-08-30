// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { UD2x18, ud2x18 } from "prb-math/UD2x18.sol";
import { SD1x18, sd1x18 } from "prb-math/SD1x18.sol";

// Prize Pool
uint8 constant TIER_SHARES = 100;
uint8 constant RESERVE_SHARES = 100;
uint24 constant GRAND_PRIZE_PERIOD_DRAWS = 12;
uint32 constant DRAW_PERIOD_SECONDS = 1 hours;
uint256 constant MIN_TIME_AHEAD = DRAW_PERIOD_SECONDS;

// RemoteOwner
address constant ERC5164_EXECUTOR_GOERLI_OPTIMISM = 0xc5165406dB791549f0D2423D1483c1EA10A3A206;

// Twab
// nice round fraction of the draw period
uint32 constant TWAB_PERIOD_LENGTH = 30 minutes;

// RngAuctions
// two auctions should end at the latest halfway through the draw period
uint64 constant AUCTION_DURATION = DRAW_PERIOD_SECONDS / 4;
uint64 constant AUCTION_TARGET_SALE_TIME = AUCTION_DURATION / 3;

// Claimer
uint256 constant CLAIMER_MIN_FEE = 0.0001e18;
uint256 constant CLAIMER_MAX_FEE = 1000e18;
// Claims can begin after the rng auctions end
uint256 constant CLAIM_PERIOD_SECONDS = DRAW_PERIOD_SECONDS - (AUCTION_DURATION * 2);

// Chainlink VRF
uint32 constant CHAINLINK_CALLBACK_GAS_LIMIT = 200_000;
uint16 constant CHAINLINK_REQUEST_CONFIRMATIONS = 3;

uint256 constant MAX_AUCTION_REWARDS = 20_000e18;

library Constants {
  function CLAIMER_MAX_FEE_PERCENT() internal pure returns (UD2x18) {
    return ud2x18(0.5e18);
  }

  /// @notice Returns the timestamp of the start of tomorrow.
  function firstDrawStartsAt() internal view returns (uint64) {
    uint256 startOfTodayInDays = block.timestamp / 1 days;
    uint256 startOfTomorrowInSeconds = (startOfTodayInDays + 1) * 1 days;

    if (startOfTomorrowInSeconds - block.timestamp < MIN_TIME_AHEAD) {
      startOfTomorrowInSeconds += MIN_TIME_AHEAD;
    }
    return uint64(startOfTomorrowInSeconds);
  }

  /// @notice Returns the timestamp of the auction offset, aligned to the draw offset.
  function auctionOffset() internal view returns (uint32) {
    return uint32(firstDrawStartsAt() - 10 * DRAW_PERIOD_SECONDS);
  }
}
