// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { IERC20, IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { LinkTokenInterface } from "chainlink/interfaces/LinkTokenInterface.sol";
import { VRFV2Wrapper } from "chainlink/vrf/VRFV2Wrapper.sol";

import { IRngAuction } from "pt-v5-chainlink-vrf-v2-direct/interfaces/IRngAuction.sol";
import { ChainlinkVRFV2Direct } from "pt-v5-chainlink-vrf-v2-direct/ChainlinkVRFV2Direct.sol";
import {
    ChainlinkVRFV2DirectRngAuctionHelper
} from "pt-v5-chainlink-vrf-v2-direct/ChainlinkVRFV2DirectRngAuctionHelper.sol";

import { RNGInterface } from "rng/RNGInterface.sol";
import { RngAuction, UD2x18 } from "pt-v5-draw-auction/RngAuction.sol";
import { RngAuctionRelayerDirect } from "pt-v5-draw-auction/RngAuctionRelayerDirect.sol";
import { RngRelayAuction } from "pt-v5-draw-auction/RngRelayAuction.sol";

import { PrizePool, ConstructorParams, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { convert } from "prb-math/SD59x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "pt-v5-cgda-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "pt-v5-cgda-liquidator/LiquidationRouter.sol";
import { Vault } from "pt-v5-vault/Vault.sol";
import { YieldVault } from "pt-v5-vault-mock/YieldVault.sol";

import { Utils } from "./Utils.t.sol";
import { Helpers } from "../../script/helpers/Helpers.sol";

contract ForkBaseSetup is Helpers, Test {
    /* ============ Variables ============ */
    Utils internal utils;

    address payable[] internal users;
    address internal owner;
    address internal manager;
    address internal alice;
    address internal bob;

    address public constant SPONSORSHIP_ADDRESS = address(1);

    LinkTokenInterface public linkToken;
    VRFV2Wrapper public vrfV2Wrapper;
    ChainlinkVRFV2Direct public rng;
    ChainlinkVRFV2DirectRngAuctionHelper public chainlinkRngAuctionHelper;
    RngAuction public rngAuction;
    RngAuctionRelayerDirect public rngAuctionRelayerDirect;
    RngRelayAuction public rngRelayAuction;

    Vault public vault;
    string public vaultName = "PoolTogether aEthDAI Prize Token (PTaEthDAI)";
    string public vaultSymbol = "PTaEthDAI";

    address public underlyingAssetAddress;
    IERC20 public underlyingAsset;

    address public prizeTokenAddress;
    IERC20 public prizeToken;

    LiquidationPairFactory public liquidationPairFactory;
    LiquidationRouter public liquidationRouter;
    LiquidationPair public liquidationPair;

    Claimer public claimer;
    PrizePool public prizePool;

    uint256 public winningRandomNumber = 123456;
    TwabController public twabController;

    /* ============ setUp ============ */
    function forkSetUp(IERC4626 _yieldVault) public {
        utils = new Utils();

        users = utils.createUsers(4);
        owner = users[0];
        manager = users[1];
        alice = users[2];
        bob = users[3];

        vm.label(owner, "Owner");
        vm.label(manager, "Manager");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");

        underlyingAssetAddress = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC token on Ethereum
        underlyingAsset = IERC20(underlyingAssetAddress);

        prizeTokenAddress = address(0x0cEC1A9154Ff802e7934Fc916Ed7Ca50bDE6844e); // POOL token on Ethereum
        prizeToken = IERC20(prizeTokenAddress);

        twabController = new TwabController(TWAB_PERIOD_LENGTH, uint32(block.timestamp));

        uint48 drawStartsAt = uint48(block.timestamp);

        linkToken = LinkTokenInterface(address(0x514910771AF9Ca656af840dff83E8264EcF986CA)); // LINK on Ethereum
        vrfV2Wrapper = VRFV2Wrapper(address(0x5A861794B927983406fCE1D062e00b9368d97Df6)); // VRF V2 Wrapper on Ethereum

        rng = new ChainlinkVRFV2Direct(
            address(this), // owner
            vrfV2Wrapper,
            CHAINLINK_CALLBACK_GAS_LIMIT,
            CHAINLINK_REQUEST_CONFIRMATIONS
        );

        rngAuction = new RngAuction(
            RNGInterface(rng),
            address(this),
            DRAW_PERIOD_SECONDS,
            drawStartsAt,
            AUCTION_DURATION,
            AUCTION_TARGET_SALE_TIME,
            AUCTION_TARGET_FIRST_SALE_FRACTION
        );

        rngAuctionRelayerDirect = new RngAuctionRelayerDirect(rngAuction);

        chainlinkRngAuctionHelper = new ChainlinkVRFV2DirectRngAuctionHelper(rng, IRngAuction(address(rngAuction)));

        prizePool = new PrizePool(
            ConstructorParams(
                prizeToken,
                twabController,
                DRAW_PERIOD_SECONDS,
                drawStartsAt,
                sd1x18(0.9e18), // alpha
                12,
                uint8(3), // minimum number of tiers
                100,
                100
            )
        );

        rngRelayAuction = new RngRelayAuction(
            prizePool,
            AUCTION_DURATION,
            AUCTION_TARGET_SALE_TIME,
            address(rngAuctionRelayerDirect),
            AUCTION_TARGET_FIRST_SALE_FRACTION,
            CHAINLINK_CALLBACK_GAS_LIMIT
        );

        claimer = new Claimer(prizePool, 0.0001e18, 1000e18, DRAW_PERIOD_SECONDS, ud2x18(0.5e18));

        vault = new Vault(
            underlyingAsset,
            vaultName,
            vaultSymbol,
            _yieldVault,
            prizePool,
            address(claimer),
            address(this),
            100000000, // 0.1 = 10%
            address(this)
        );

        vm.makePersistent(address(vault));

        liquidationPairFactory = new LiquidationPairFactory();
        liquidationRouter = new LiquidationRouter(liquidationPairFactory);

        uint128 _virtualReserveIn = 10e18;
        uint128 _virtualReserveOut = 5e18;

        // this is approximately the maximum decay constant, as the CGDA formula requires computing e^(decayConstant * time).
        // since the data type is SD59x18 and e^134 ~= 1e58, we can divide 134 by the draw period to get the max decay constant.
        SD59x18 _decayConstant = convert(130).div(convert(int(uint(DRAW_PERIOD_SECONDS))));
        liquidationPair = liquidationPairFactory.createPair(
            ILiquidationSource(vault),
            address(prizeToken),
            address(vault),
            DRAW_PERIOD_SECONDS,
            uint32(drawStartsAt),
            uint32(DRAW_PERIOD_SECONDS / 2),
            _decayConstant,
            uint104(_virtualReserveIn),
            uint104(_virtualReserveOut),
            _virtualReserveOut // just make it up
        );

        vault.setLiquidationPair(address(liquidationPair));
    }
}
