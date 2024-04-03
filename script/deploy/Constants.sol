// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";

import { UD2x18, ud2x18 } from "prb-math/UD2x18.sol";
import { SD1x18, sd1x18 } from "prb-math/SD1x18.sol";
import { SD59x18, convert } from "prb-math/SD59x18.sol";

// Prize Pool
uint32  constant DRAW_PERIOD_SECONDS = 2 hours;
uint24  constant GRAND_PRIZE_PERIOD_DRAWS = 84;
uint8   constant MIN_NUMBER_OF_TIERS = 4;
uint8   constant RESERVE_SHARES = 20;
uint8   constant TIER_SHARES = 100;
uint8   constant CANARY_SHARES = 5;
uint24  constant DRAW_TIMEOUT = GRAND_PRIZE_PERIOD_DRAWS - 1;

// Addresses
// Defender
address constant GOERLI_DEFENDER_ADDRESS = 0x22f928063d7FA5a90f4fd7949bB0848aF7C79b0A;
address constant GOERLI_DEFENDER_ADDRESS_2 = 0xe6Cb4266474BBf065A822DFf46031bb16eB71264;
address constant ARBITRUM_GOERLI_DEFENDER_ADDRESS = 0xfACeB34EB896d5391ec3211011bD4192C817af8A;
address constant OPTIMISM_GOERLI_DEFENDER_ADDRESS = 0x0B97aEd3d637469721400Ea7B8CD5D8DF83116F4;
address constant SEPOLIA_DEFENDER_ADDRESS = 0xbD764675C2Ffb3E580D3f9c92B0c84c526fe818A;
address constant MUMBAI_DEFENDER_ADDRESS = 0xbCE45a1C2c1eFF18E77f217A62a44f885b26099f;

// Chainlink
address constant GOERLI_LINK_ADDRESS = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
address constant GOERLI_VRFV2_WRAPPER_ADDRESS = 0x708701a1DfF4f478de54383E49a627eD4852C816;
address constant SEPOLIA_LINK_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
address constant SEPOLIA_VRFV2_WRAPPER_ADDRESS = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

// Witnet
address constant WITNET_RANDOMNESS_OPTIMISM_SEPOLIA = 0xc0ffee84FD3B533C3fA408c993F59828395319A1;

// MessageExecutor
address constant ERC5164_EXECUTOR_GOERLI_ARBITRUM = 0xe7Ab52219631882f778120c1f19D6086ED390bE1;
address constant ERC5164_EXECUTOR_GOERLI_OPTIMISM = 0x59Ba766ff229c21b97184647292706039aF63dA1;
address constant ERC5164_EXECUTOR_SEPOLIA_ARBITRUM = 0x2B3E6b5c9a6Bdb0e595896C9093fce013490abbD;
address constant ERC5164_EXECUTOR_SEPOLIA_OPTIMISM = 0x6A501383A61ebFBc143Fc4BD41A2356bA71A6964;

// Prize Pool
uint256 constant TIER_LIQUIDITY_UTILIZATION_PERCENT = 0.5e18;

// Chain IDs
uint256 constant GOERLI_CHAIN_ID = 5;
uint256 constant SEPOLIA_CHAIN_ID = 11155111;
uint256 constant ARBITRUM_GOERLI_CHAIN_ID = 421613;
uint256 constant OPTIMISM_GOERLI_CHAIN_ID = 420;
uint256 constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
uint256 constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;

// Deploy parameters
// Chainlink VRF
uint32 constant CHAINLINK_CALLBACK_GAS_LIMIT = 60_000;
uint16 constant CHAINLINK_REQUEST_CONFIRMATIONS = 3;

// Claimer
UD2x18 constant CLAIMER_MAX_FEE_PERCENT = UD2x18.wrap(0.1e18); // 10%

// Draw manager
uint48 constant AUCTION_DURATION = 40 minutes;
uint48 constant AUCTION_TARGET_SALE_TIME = 15 minutes; // since testnet periods are shorter, we make this a bit longer to account for decreased granularity
uint256 constant AUCTION_MAX_REWARD = 10000e18;
UD2x18 constant AUCTION_TARGET_FIRST_SALE_FRACTION = UD2x18.wrap(0); // 0%

// Liquidation Pair
uint104 constant ONE_POOL = 1e18;
uint104 constant ONE_WETH = 1e18;
uint104 constant ONE_DAI = 1e18;
uint104 constant ONE_USDC = 1e6;
uint104 constant ONE_GUSD = 1e2;
uint104 constant ONE_WBTC = 1e8;

// Twab
// nice round fraction of the draw period
uint32 constant TWAB_PERIOD_LENGTH = 1 hours;

// Token decimals
uint8 constant DEFAULT_TOKEN_DECIMAL = 18;
uint8 constant USDC_TOKEN_DECIMAL = 6;
uint8 constant GUSD_TOKEN_DECIMAL = 2;
uint8 constant WBTC_TOKEN_DECIMAL = 8;

// Token names and symbols
string constant POOL_SYMBOL = "POOL";
string constant USDC_SYMBOL = "USDC";
string constant WETH_SYMBOL = "WETH";
string constant GUSD_SYMBOL = "GUSD";
string constant DAI_SYMBOL = "DAI";
string constant WBTC_SYMBOL = "WBTC";

// Token prices in USD
uint8 constant MARKET_RATE_DECIMALS = 8;
uint256 constant E8 = 1e8;
uint256 constant USD_PER_USDC_E8 = 1e8;
uint256 constant USD_PER_ETH_E8 = 3000e8;
uint256 constant USD_PER_POOL_E8 = 0.55e8;
uint256 constant USD_PER_DAI_E8 = 1e8;
uint256 constant USD_PER_GUSD_E8 = 1e8;
uint256 constant USD_PER_WBTC_E8 = 60000e8;

// Vault
uint32 constant YIELD_FEE_PERCENTAGE = 0; // 0%
address constant YIELD_FEE_RECIPIENT = address(0);

abstract contract Constants {

    function _getClaimerTimeToReachMaxFee() internal pure returns (uint256) {
        return (DRAW_PERIOD_SECONDS - (2 * AUCTION_DURATION)) / 2;
    }

    /// @notice The target first sale time for an LP
    function _getTargetFirstSaleTime(uint48 _drawPeriodSeconds) internal pure returns (uint32) {
        return uint32(_drawPeriodSeconds / 2);
    }

    function _getWitnetRandomness() internal view returns (address) {
        if (block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            return WITNET_RANDOMNESS_OPTIMISM_SEPOLIA;
        } else {
            revert("Witnet RNG Not Supported on this chain");
        }
    }

    function _getContributionsSmoothing() internal pure returns (SD1x18) {
        return sd1x18(0.3e18);
    }

    /// @notice Returns the start timestamp of the first draw.
    /// @dev Configured for 7pm (19th hour) UTC of the next day
    function _getFirstDrawStartsAt() internal view returns (uint48) {
        return uint48(block.timestamp + 30 minutes);
    }

    /// @notice Returns the timestamp of the auction offset, aligned to the draw offset.
    function _getAuctionOffset() internal view returns (uint32) {
        return uint32(_getFirstDrawStartsAt() - DRAW_PERIOD_SECONDS * 10);
    }

}
