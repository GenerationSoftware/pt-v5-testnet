// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";

import { UD2x18, ud2x18 } from "prb-math/UD2x18.sol";
import { SD1x18, sd1x18 } from "prb-math/SD1x18.sol";
import { SD59x18, convert } from "prb-math/SD59x18.sol";

abstract contract Constants {

    // Prize Pool
    uint    internal constant FIRST_DRAW_STARTS_AT = 1710343791 + 30 minutes;
    uint32  internal constant DRAW_PERIOD_SECONDS = 2 hours;
    uint24  internal constant GRAND_PRIZE_PERIOD_DRAWS = 84;
    uint8   internal constant MIN_NUMBER_OF_TIERS = 4;
    uint8   internal constant RESERVE_SHARES = 20;
    uint8   internal constant TIER_SHARES = 100;
    uint8   internal constant CANARY_SHARES = 5;
    uint24  internal constant DRAW_TIMEOUT = GRAND_PRIZE_PERIOD_DRAWS - 1;

    // Addresses
    // Defender
    address internal constant GOERLI_DEFENDER_ADDRESS = 0x22f928063d7FA5a90f4fd7949bB0848aF7C79b0A;
    address internal constant GOERLI_DEFENDER_ADDRESS_2 = 0xe6Cb4266474BBf065A822DFf46031bb16eB71264;
    address internal constant ARBITRUM_GOERLI_DEFENDER_ADDRESS = 0xfACeB34EB896d5391ec3211011bD4192C817af8A;
    address internal constant OPTIMISM_GOERLI_DEFENDER_ADDRESS = 0x0B97aEd3d637469721400Ea7B8CD5D8DF83116F4;
    address internal constant SEPOLIA_DEFENDER_ADDRESS = 0xbD764675C2Ffb3E580D3f9c92B0c84c526fe818A;
    address internal constant MUMBAI_DEFENDER_ADDRESS = 0xbCE45a1C2c1eFF18E77f217A62a44f885b26099f;

    // Chainlink
    address internal constant GOERLI_LINK_ADDRESS = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address internal constant GOERLI_VRFV2_WRAPPER_ADDRESS = 0x708701a1DfF4f478de54383E49a627eD4852C816;
    address internal constant SEPOLIA_LINK_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address internal constant SEPOLIA_VRFV2_WRAPPER_ADDRESS = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    // Witnet
    address internal constant WITNET_RANDOMNESS_OPTIMISM_GOERLI = 0x0123456fbBC59E181D76B6Fe8771953d1953B51a;
    address internal constant WITNET_RANDOMNESS_GOERLI = 0x0123456fbBC59E181D76B6Fe8771953d1953B51a;
    address internal constant WITNET_RANDOMNESS_SEPOLIA = 0x0123456fbBC59E181D76B6Fe8771953d1953B51a;

    // MessageExecutor
    address internal constant ERC5164_EXECUTOR_GOERLI_ARBITRUM = 0xe7Ab52219631882f778120c1f19D6086ED390bE1;
    address internal constant ERC5164_EXECUTOR_GOERLI_OPTIMISM = 0x59Ba766ff229c21b97184647292706039aF63dA1;
    address internal constant ERC5164_EXECUTOR_SEPOLIA_ARBITRUM = 0x2B3E6b5c9a6Bdb0e595896C9093fce013490abbD;
    address internal constant ERC5164_EXECUTOR_SEPOLIA_OPTIMISM = 0x6A501383A61ebFBc143Fc4BD41A2356bA71A6964;

    // Prize Pool
    uint256 constant TIER_LIQUIDITY_UTILIZATION_PERCENT = 0.75e18;

    // Chain IDs
    uint256 constant GOERLI_CHAIN_ID = 5;
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ARBITRUM_GOERLI_CHAIN_ID = 421613;
    uint256 constant OPTIMISM_GOERLI_CHAIN_ID = 420;
    uint256 constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;

    // Deploy parameters
    // Chainlink VRF
    uint32 internal constant CHAINLINK_CALLBACK_GAS_LIMIT = 60_000;
    uint16 internal constant CHAINLINK_REQUEST_CONFIRMATIONS = 3;

    // Claimer
    uint256 internal constant CLAIMER_MIN_FEE = 0.0001e18;
    uint256 internal constant CLAIMER_MAX_FEE = 10000e18;
    UD2x18 constant CLAIMER_MAX_FEE_PERCENT = UD2x18.wrap(0.1e18); // 10%

    // Draw manager
    uint48 internal constant AUCTION_DURATION = 40 minutes;
    uint48 internal constant AUCTION_TARGET_SALE_TIME = 15 minutes; // since testnet periods are shorter, we make this a bit longer to account for decreased granularity
    uint256 internal constant AUCTION_MAX_REWARD = 10000e18;
    UD2x18 internal constant AUCTION_TARGET_FIRST_SALE_FRACTION = UD2x18.wrap(0); // 0%

    // Liquidation Pair
    uint104 internal constant ONE_POOL = 1e18;
    uint104 internal constant ONE_WETH = 1e18;
    uint104 internal constant ONE_DAI = 1e18;
    uint104 internal constant ONE_USDC = 1e6;
    uint104 internal constant ONE_GUSD = 1e2;
    uint104 internal constant ONE_WBTC = 1e8;

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

    // Token prices in USD
    uint8 MARKET_RATE_DECIMALS = 8;
    uint256 internal constant E8 = 1e8;
    uint256 internal constant USD_PER_USDC_E8 = 1e8;
    uint256 internal constant USD_PER_ETH_E8 = 3000e8;
    uint256 internal constant USD_PER_POOL_E8 = 0.55e8;
    uint256 internal constant USD_PER_DAI_E8 = 1e8;
    uint256 internal constant USD_PER_GUSD_E8 = 1e8;
    uint256 internal constant USD_PER_WBTC_E8 = 60000e8;

    // Vault
    uint32 internal constant YIELD_FEE_PERCENTAGE = 0; // 0%
    address internal constant YIELD_FEE_RECIPIENT = address(0);

    function _getClaimerTimeToReachMaxFee() internal pure returns (uint256) {
        return (DRAW_PERIOD_SECONDS - (2 * AUCTION_DURATION)) / 2;
    }

    /// @notice The target first sale time for an LP
    function _getTargetFirstSaleTime(uint48 _drawPeriodSeconds) internal pure returns (uint32) {
        return uint32(_drawPeriodSeconds / 2);
    }

    /**
     * @notice Get Liquidation Pair decay constant.
     * @dev This is approximately the maximum decay constant, as the CGDA formula requires computing e^(decayConstant * time).
     *      Since the data type is SD59x18 and e^134 ~= 1e58, we can divide 134 by the draw period to get the max decay constant.
     */
    function _getDecayConstant() internal pure returns (SD59x18) {
        return SD59x18.wrap(134e18).div(convert(int256(uint256(DRAW_PERIOD_SECONDS * 50))));
    }

    function _getWitnetRandomness() internal view returns (address) {
        if (block.chainid == OPTIMISM_GOERLI_CHAIN_ID) {
            return WITNET_RANDOMNESS_OPTIMISM_GOERLI;
        } else if (block.chainid == GOERLI_CHAIN_ID) {
            return WITNET_RANDOMNESS_GOERLI;
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            return WITNET_RANDOMNESS_SEPOLIA;
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
        // hard code the time so that it is consistent between contract deployments
        uint256 time = uint48(FIRST_DRAW_STARTS_AT);
        if (time < block.timestamp){ 
            revert("first draw starts at is in past");
        }
        return uint48(time);
    }

    /// @notice Returns the timestamp of the auction offset, aligned to the draw offset.
    function _getAuctionOffset() internal view returns (uint32) {
        return uint32(_getFirstDrawStartsAt() - DRAW_PERIOD_SECONDS * 10);
    }

}
