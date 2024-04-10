// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import { DeployPrizePool, TpdaLiquidationPair, PrizePool } from "../lib/pt-v5-mainnet/script/DeployPrizePool.s.sol";

// RNG
import { IRng } from "pt-v5-draw-manager/interfaces/IRng.sol";
import { RngBlockhash } from "pt-v5-rng-blockhash/RngBlockhash.sol";
import { RngWitnet, IWitnetRandomness } from "pt-v5-rng-witnet/RngWitnet.sol";

// Tokens
import { ERC20Mintable } from "../src/ERC20Mintable.sol";
import { TokenFaucet } from "../src/TokenFaucet.sol";

// Vaults
import { YieldVaultMintRate, PrizeVaultMintRate } from "../src/PrizeVaultMintRate.sol";
import { TwabDelegator } from "pt-v5-twab-delegator/TwabDelegator.sol";
import { Claimer } from "pt-v5-claimer/Claimer.sol";

struct TokenInfo {
    string name;
    string symbol;
    uint8 decimals;
    uint256 initialSupply;
    address deployedAddress;
}

struct VaultInfo {
    string symbol;
    string assetSymbol;
    uint ratePerYear;
}

struct TestnetConfig {
    // Token Choices
    string prizeTokenSymbol;
    string stakedTokenSymbol;

    // Tokens to deploy
    string[] tokenSymbols;

    // Token minters
    address[] tokenMinters;

    // vaults
    string[] vaultSymbols;
}

/// @dev Used by the test script to run some fork tests after deployment
struct TestnetAddressBook {
    PrizePool prizePool;
    PrizeVaultMintRate prizeVault;
    Claimer claimer;
    address minter;
}

contract DeployTestnet is DeployPrizePool {

    TestnetConfig internal testnetConfig;
    mapping (string assetSymbol => TokenInfo) internal tokens;
    mapping (string vaultSymbol => VaultInfo) internal vaults;
    mapping (string assetSymbol => PrizeVaultMintRate) internal prizeVaults;

    constructor() {
        loadTestnetConfig(vm.envString("CONFIG"));
    }

    function run() public override {
        vm.startBroadcast();

        // deploy the RNG and testnet tokens
        deployRng();
        deployTokens();

        // deploy core contracts
        deployCore();

        // deploy the extra testnet contracts
        deployPeripherals();

        vm.stopBroadcast();

        // dump some addresses for the fork tests to use
        string memory addressBookPath = string.concat("config/runs/", vm.toString(block.chainid), "/");
        vm.createDir(addressBookPath, true);
        vm.writeFile(
            string.concat(addressBookPath, "addressBook.txt"),
            vm.toString(
                abi.encode(
                    TestnetAddressBook({
                        prizePool: prizePool,
                        prizeVault: prizeVaults["USDC"], // assuming we'll always deploy a USDC test vault
                        claimer: Claimer(claimer),
                        minter: msg.sender // should be able to mint any assets
                    })
                )
            )
        );
    }

    function deployRng() public {
        if (eq(config.rngType, "blockhash")) {
            standardizedRng = new RngBlockhash();
        } else if (eq(config.rngType, "witnet-randomness-v2")) {
            standardizedRng = new RngWitnet(IWitnetRandomness(config.rng));
        } else if (eq(config.rngType, "standardized")) {
            standardizedRng = IRng(config.rng);
        } else {
            revert("Unsupported RNG type...");
        }
    }

    function deployTokens() public {
        address faucetAddress = address(new TokenFaucet());
        for (uint i = 0; i < testnetConfig.tokenSymbols.length; i++) {
            TokenInfo storage token = tokens[testnetConfig.tokenSymbols[i]];

            ERC20Mintable mintable = new ERC20Mintable(token.name, token.symbol, token.decimals, msg.sender);
            token.deployedAddress = address(mintable);
            mintable.mint(faucetAddress, token.initialSupply);

            // check if prize token or staking token and overwrite config placeholder
            if (eq(token.symbol, testnetConfig.prizeTokenSymbol)) {
                config.prizeToken = token.deployedAddress;
            }
            if (eq(token.symbol, testnetConfig.stakedTokenSymbol)) {
                config.stakedAsset = token.deployedAddress;
            }

            // grant minter roles
            for (uint j = 0; j < testnetConfig.tokenMinters.length; j++) {
                address minter = testnetConfig.tokenMinters[j];
                mintable.grantRole(mintable.MINTER_ROLE(), minter);
            }
        }
    }

    function deployPeripherals() public {
        // Vaults & TWAB delegators
        for (uint i = 0; i < testnetConfig.vaultSymbols.length; i++) {
            VaultInfo memory vaultInfo = vaults[testnetConfig.vaultSymbols[i]];
            TokenInfo memory tokenInfo = tokens[vaultInfo.assetSymbol];

            YieldVaultMintRate yieldVault = new YieldVaultMintRate(
                ERC20Mintable(tokenInfo.deployedAddress),
                string.concat(tokenInfo.symbol, " Yield Vault"),
                string.concat("yv", tokenInfo.symbol),
                msg.sender
            );
            ERC20Mintable(tokenInfo.deployedAddress).grantRole(
                ERC20Mintable(tokenInfo.deployedAddress).MINTER_ROLE(),
                address(yieldVault)
            );
            yieldVault.setRatePerSecond(vaultInfo.ratePerYear / 365 days);

            PrizeVaultMintRate prizeVault = new PrizeVaultMintRate(
                string.concat("Prize ", tokenInfo.symbol),
                vaultInfo.symbol,
                yieldVault,
                prizePool,
                claimer,
                msg.sender,
                0,
                msg.sender
            );

            ERC20Mintable(tokenInfo.deployedAddress).mint(address(prizeVault), prizeVault.yieldBuffer());
            prizeVaults[tokenInfo.symbol] = prizeVault;
            yieldVault.grantRole(yieldVault.MINTER_ROLE(), address(prizeVault));

            TpdaLiquidationPair lp = liquidationPairFactory.createPair(
                prizeVault,
                address(prizePool.prizeToken()),
                address(prizeVault),
                prizePool.drawPeriodSeconds() / 2,
                0.001e18, // 1 thousandth of an ETH
                0.95e18 // 95% smoothing
            );
            prizeVault.setLiquidationPair(address(lp));

            new TwabDelegator(
                string.concat("Staked Prize ", tokenInfo.name),
                string.concat("stkp", tokenInfo.symbol),
                twabController,
                prizeVault
            );
        }

        {
            // Add a staked asset depositor
            ERC20Mintable stakedAsset = ERC20Mintable(tokens[testnetConfig.stakedTokenSymbol].deployedAddress);
            uint256 amount = 10 ** stakedAsset.decimals();
            stakedAsset.mint(msg.sender, amount);
            stakedAsset.approve(address(stakingPrizeVault), amount);
            stakingPrizeVault.deposit(amount, msg.sender);
        }
    }

    function loadTestnetConfig(string memory filepath) public {
        string memory file = vm.readFile(filepath);

        // Token Choices
        testnetConfig.prizeTokenSymbol = vm.parseJsonString(file, "$.testnet.prize_token_symbol");
        testnetConfig.stakedTokenSymbol = vm.parseJsonString(file, "$.testnet.staked_token_symbol");

        // Tokens to Deploy
        testnetConfig.tokenSymbols = vm.parseJsonKeys(file, "$.testnet.tokens");
        for (uint i = 0; i < testnetConfig.tokenSymbols.length; i++) {
            string memory symbol = testnetConfig.tokenSymbols[i];
            TokenInfo storage info = tokens[symbol];

            info.symbol = symbol;
            info.name = vm.parseJsonString(file, string.concat("$.testnet.tokens.", symbol, ".name"));
            info.decimals = uint8(vm.parseJsonUint(file, string.concat("$.testnet.tokens.", symbol, ".decimals")));

            uint256 supply = vm.parseJsonUint(file, string.concat("$.testnet.tokens.", symbol, ".supply"));
            info.initialSupply = supply * (10 ** info.decimals);
        }

        // Vaults to Deploy
        testnetConfig.vaultSymbols = vm.parseJsonKeys(file, "$.testnet.vaults");
        for (uint i = 0; i < testnetConfig.vaultSymbols.length; i++) {
            string memory symbol = testnetConfig.vaultSymbols[i];
            VaultInfo storage info = vaults[symbol];

            info.symbol = symbol;
            info.assetSymbol = vm.parseJsonString(file, string.concat("$.testnet.vaults.", symbol, ".asset_symbol"));
            info.ratePerYear = vm.parseJsonUint(file, string.concat("$.testnet.vaults.", symbol, ".rate_per_year"));
        }

        // Token Minters
        testnetConfig.tokenMinters = vm.parseJsonAddressArray(file, "$.testnet.minters");
    }

    function eq(string memory a, string memory b) public pure returns(bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
}