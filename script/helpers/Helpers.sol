// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/console2.sol";

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { strings } from "solidity-stringutils/strings.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";

import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { RngAuction } from "pt-v5-draw-auction/RngAuction.sol";
import { RngAuctionRelayer } from "pt-v5-draw-auction/abstract/RngAuctionRelayer.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { MarketRate } from "../../src/MarketRate.sol";
import { TokenFaucet } from "../../src/TokenFaucet.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { LinkTokenInterface } from "chainlink/interfaces/LinkTokenInterface.sol";
import { VRFV2Wrapper } from "chainlink/vrf/VRFV2Wrapper.sol";

import { Constants } from "../deploy/Constants.sol";

// Testnet deployment paths
string constant ETHEREUM_GOERLI_PATH = "broadcast/Deploy.s.sol/5/";
string constant LOCAL_PATH = "/broadcast/Deploy.s.sol/31337";

abstract contract Helpers is Constants, Script {
    using strings for *;
    using stdJson for string;

    /* ============ Constants ============ */
    uint256 internal constant ONE_YEAR_IN_SECONDS = 31557600;

    string DEPLOY_POOL_SCRIPT;

    constructor() {
        if (block.chainid == GOERLI_CHAIN_ID || block.chainid == SEPOLIA_CHAIN_ID) {
            DEPLOY_POOL_SCRIPT = "DeployPool.s.sol";
        } else if (
            block.chainid == ARBITRUM_GOERLI_CHAIN_ID ||
            block.chainid == OPTIMISM_GOERLI_CHAIN_ID ||
            block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID ||
            block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID
        ) {
            DEPLOY_POOL_SCRIPT = "DeployL2PrizePool.s.sol";
        }
    }

    /* ============ Helpers ============ */

    string internal _tokenDeployPath = _getDeployPath("DeployToken.s.sol");
    string internal _stableTokenDeployPath = _getDeployPath("DeployStableToken.s.sol");

    function _toDecimals(uint256 _amount, uint8 _decimals) internal pure returns (uint256) {
        return _amount * (10 ** _decimals);
    }

    function _getRatePerSeconds(uint256 _rate) internal pure returns (uint256) {
        return _rate / ONE_YEAR_IN_SECONDS;
    }

    /**
     * @notice Get exchange rate for liquidation pair `virtualReserveOut`.
     * @param _tokenPrice Price of the token represented in MARKET_RATE_DECIMALS decimals
     * @param _decimalOffset Offset between the prize token decimals and the token decimals
     */
    function _getExchangeRate(uint256 _tokenPrice, uint8 _decimalOffset) internal view returns (uint128) {
        return uint128((1e18 * (10 ** MARKET_RATE_DECIMALS)) / (_tokenPrice * (10 ** _decimalOffset)));
    }

    function _tokenGrantMinterRole(ERC20Mintable _token, address _grantee) internal {
        _token.grantRole(_token.MINTER_ROLE(), _grantee);
    }

    function _yieldVaultGrantMinterRole(YieldVaultMintRate _yieldVault, address _grantee) internal {
        _yieldVault.grantRole(_yieldVault.MINTER_ROLE(), _grantee);
    }

    function _tokenGrantMinterRoles(ERC20Mintable _token) internal {
        if (block.chainid == GOERLI_CHAIN_ID) {
            _tokenGrantMinterRole(_token, address(GOERLI_DEFENDER_ADDRESS));
            _tokenGrantMinterRole(_token, address(GOERLI_DEFENDER_ADDRESS_2));
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            _tokenGrantMinterRole(_token, address(SEPOLIA_DEFENDER_ADDRESS));
        } else if (block.chainid == ARBITRUM_GOERLI_CHAIN_ID) {
            _tokenGrantMinterRole(_token, address(ARBITRUM_GOERLI_DEFENDER_ADDRESS));
        } else if (block.chainid == OPTIMISM_GOERLI_CHAIN_ID) {
            _tokenGrantMinterRole(_token, address(OPTIMISM_GOERLI_DEFENDER_ADDRESS));
        } else if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            // _tokenGrantMinterRole(_token, address(ARBITRUM_SEPOLIA_DEFENDER_ADDRESS));
        } else if (block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            // _tokenGrantMinterRole(_token, address(OPTIMISM_SEPOLIA_DEFENDER_ADDRESS));
        }

        // EOAs
        _tokenGrantMinterRole(_token, address(0x5E6CC2397EcB33e6041C15360E17c777555A5E63));
        _tokenGrantMinterRole(_token, address(0xA57D294c3a11fB542D524062aE4C5100E0E373Ec));
        _tokenGrantMinterRole(_token, address(0x27fcf06DcFFdDB6Ec5F62D466987e863ec6aE6A0));
        _tokenGrantMinterRole(_token, address(0x49ca801A80e31B1ef929eAB13Ab3FBbAe7A55e8F)); // Bot
    }

    function _yieldVaultGrantMinterRoles(YieldVaultMintRate _yieldVault) internal {
        if (block.chainid == GOERLI_CHAIN_ID) {
            _yieldVaultGrantMinterRole(_yieldVault, GOERLI_DEFENDER_ADDRESS);
            _yieldVaultGrantMinterRole(_yieldVault, GOERLI_DEFENDER_ADDRESS_2);
        }

        if (block.chainid == SEPOLIA_CHAIN_ID) {
            _yieldVaultGrantMinterRole(_yieldVault, SEPOLIA_DEFENDER_ADDRESS);
        }

        if (block.chainid == 80001) {
            _yieldVaultGrantMinterRole(_yieldVault, MUMBAI_DEFENDER_ADDRESS);
        }

        if (block.chainid == ARBITRUM_GOERLI_CHAIN_ID) {
            _yieldVaultGrantMinterRole(_yieldVault, ARBITRUM_GOERLI_DEFENDER_ADDRESS);
        }

        if (block.chainid == OPTIMISM_GOERLI_CHAIN_ID) {
            _yieldVaultGrantMinterRole(_yieldVault, OPTIMISM_GOERLI_DEFENDER_ADDRESS);
        }

        if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            // _yieldVaultGrantMinterRole(_yieldVault, address(ARBITRUM_SEPOLIA_DEFENDER_ADDRESS));
        }

        if (block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            // _yieldVaultGrantMinterRole(_yieldVault, address(OPTIMISM_SEPOLIA_DEFENDER_ADDRESS));
        }

        _yieldVaultGrantMinterRole(_yieldVault, address(0x5E6CC2397EcB33e6041C15360E17c777555A5E63));
        _yieldVaultGrantMinterRole(_yieldVault, address(0xA57D294c3a11fB542D524062aE4C5100E0E373Ec));
        _yieldVaultGrantMinterRole(_yieldVault, address(0x27fcf06DcFFdDB6Ec5F62D466987e863ec6aE6A0));
        _yieldVaultGrantMinterRole(_yieldVault, address(0x49ca801A80e31B1ef929eAB13Ab3FBbAe7A55e8F)); // Bot
    }

    function _getDeploymentArtifacts(string memory _deploymentArtifactsPath) internal returns (string[] memory) {
        string[] memory inputs = new string[](4);
        inputs[0] = "ls";
        inputs[1] = "-r";
        inputs[2] = "-1";
        inputs[3] = string.concat(vm.projectRoot(), _deploymentArtifactsPath);
        bytes memory res = vm.ffi(inputs);

        // Slice ls result
        strings.slice memory s = string(res).toSlice();

        // Remove directory jargon at the beginning of the slice (Fix for Windows Git Bash)
        strings.slice memory dirEnd = "/:".toSlice();
        strings.slice memory sWithoutDirPrefix = s.copy().find(dirEnd).beyond(dirEnd);
        if (!sWithoutDirPrefix.empty()) s = sWithoutDirPrefix;

        // Remove newline and push into array
        strings.slice memory delim = "\n".toSlice();
        string[] memory filesName = new string[](s.count(delim) + 1);

        for (uint256 i = 0; i < filesName.length; i++) {
            filesName[i] = string.concat(
                "run",
                s.split(delim).beyond("run".toSlice()).until(".json".toSlice()).toString(),
                ".json"
            );
        }

        return filesName;
    }

    function _getContractAddress(
        string memory _contractName,
        string memory _artifactsPath,
        string memory _errorMsg
    ) internal returns (address) {
        string[] memory filesName = _getDeploymentArtifacts(_artifactsPath);
        uint256 filesNameLength = filesName.length;

        // Loop through deployment artifacts and find latest deployed `_contractName` address
        for (uint256 i; i < filesNameLength; i++) {
            string memory filePath = string.concat(vm.projectRoot(), _artifactsPath, filesName[i]);
            string memory jsonFile = vm.readFile(filePath);
            uint256 transactionsLength = abi.decode(vm.parseJson(jsonFile, ".transactions"), (bytes[])).length;

            for (uint256 j; j < transactionsLength; j++) {
                string memory contractName = abi.decode(
                    stdJson.parseRaw(jsonFile, string.concat(".transactions[", vm.toString(j), "].contractName")),
                    (string)
                );

                if (keccak256(abi.encodePacked((contractName))) == keccak256(abi.encodePacked((_contractName)))) {
                    address contractAddress = abi.decode(
                        stdJson.parseRaw(
                            jsonFile,
                            string.concat(".transactions[", vm.toString(j), "].contractAddress")
                        ),
                        (address)
                    );

                    return contractAddress;
                }

                // check factory creations
                if (
                    keccak256(abi.encodePacked(contractName)) == keccak256(abi.encodePacked(_contractName, "Factory"))
                ) {
                    console2.log("Checking factory...");
                    string memory factoryTransactionType = abi.decode(
                        stdJson.parseRaw(
                            jsonFile,
                            string.concat(".transactions[", vm.toString(j), "]", ".transactionType")
                        ),
                        (string)
                    );
                    if (keccak256(abi.encodePacked(factoryTransactionType)) == keccak256(abi.encodePacked("CALL"))) {
                        string memory transactionType = abi.decode(
                            stdJson.parseRaw(
                                jsonFile,
                                string.concat(
                                    ".transactions[",
                                    vm.toString(j),
                                    "].additionalContracts[0].transactionType"
                                )
                            ),
                            (string)
                        );
                        console2.log("Additional contract found!");
                        if (keccak256(abi.encodePacked(transactionType)) == keccak256(abi.encodePacked("CREATE"))) {
                            address contractAddress = abi.decode(
                                stdJson.parseRaw(
                                    jsonFile,
                                    string.concat(
                                        ".transactions[",
                                        vm.toString(j),
                                        "].additionalContracts",
                                        "[0].address"
                                    )
                                ),
                                (address)
                            );

                            return contractAddress;
                        }
                    }
                }
            }
        }

        revert(_errorMsg);
    }

    function _getTokenAddress(
        string memory _contractName,
        string memory _tokenSymbol,
        uint256 _argumentPosition,
        string memory _artifactsPath,
        string memory _errorMsg
    ) internal returns (address) {
        string[] memory filesName = _getDeploymentArtifacts(_artifactsPath);

        // Loop through deployment artifacts and find latest deployed `_contractName` address
        for (uint256 i; i < filesName.length; i++) {
            string memory jsonFile = vm.readFile(string.concat(vm.projectRoot(), _artifactsPath, filesName[i]));
            bytes[] memory rawTxs = abi.decode(vm.parseJson(jsonFile, ".transactions"), (bytes[]));

            for (uint256 j; j < rawTxs.length; j++) {
                string memory index = vm.toString(j);

                string memory _argumentPositionString = vm.toString(_argumentPosition);

                if (
                    _matches(
                        abi.decode(
                            stdJson.parseRaw(jsonFile, string.concat(".transactions[", index, "].transactionType")),
                            (string)
                        ),
                        "CREATE"
                    ) &&
                    _matches(
                        abi.decode(
                            stdJson.parseRaw(jsonFile, string.concat(".transactions[", index, "].contractName")),
                            (string)
                        ),
                        _contractName
                    ) &&
                    _matches(
                        abi.decode(
                            stdJson.parseRaw(
                                jsonFile,
                                string.concat(".transactions[", index, "].arguments[", _argumentPositionString, "]")
                            ),
                            (string)
                        ),
                        _tokenSymbol
                    )
                ) {
                    return
                        abi.decode(
                            stdJson.parseRaw(jsonFile, string.concat(".transactions[", index, "].contractAddress")),
                            (address)
                        );
                }
            }
        }

        revert(_errorMsg);
    }

    function _matches(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b)));
    }

    function _getDeployPath(string memory _deployPath) internal view returns (string memory) {
        return _getDeployPathWithChainId(_deployPath, block.chainid);
    }

    function _getDeployPathWithChainId(
        string memory _deployPath,
        uint256 chainId
    ) internal pure returns (string memory) {
        return string.concat("/broadcast/", _deployPath, "/", Strings.toString(chainId), "/");
    }

    /* ============ Getters ============ */

    function _getClaimer() internal returns (Claimer) {
        return Claimer(_getContractAddress("Claimer", _getDeployPath(DEPLOY_POOL_SCRIPT), "claimer-not-found"));
    }

    function _getL1ChainId() internal view returns (uint256) {
        // Check if we are on L1
        if (block.chainid == GOERLI_CHAIN_ID) return GOERLI_CHAIN_ID;
        if (block.chainid == SEPOLIA_CHAIN_ID) return SEPOLIA_CHAIN_ID;

        // Get associated L1 chain ID from L2 chain ID
        if (block.chainid == ARBITRUM_GOERLI_CHAIN_ID || block.chainid == OPTIMISM_GOERLI_CHAIN_ID) {
            return GOERLI_CHAIN_ID;
        } else if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID || block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            return SEPOLIA_CHAIN_ID;
        }

        revert("Failed to determine L1 chain ID");
    }

    function _getL1RngAuction() internal returns (RngAuction) {
        return
            RngAuction(
                _getContractAddress(
                    "RngAuction",
                    _getDeployPathWithChainId("DeployL1RngAuction.s.sol", _getL1ChainId()),
                    "rng-auction-not-found"
                )
            );
    }

    function _getL1RngAuctionRelayerRemote() internal returns (RngAuctionRelayer) {
        string memory contractName;
        string memory deployPath;
        uint256 chainIdL1 = _getL1ChainId();
        if (block.chainid == ARBITRUM_GOERLI_CHAIN_ID || block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            contractName = "RngAuctionRelayerRemoteOwnerArbitrum";
            deployPath = "DeployL1RelayerArbitrum.s.sol";
        } else if (block.chainid == OPTIMISM_GOERLI_CHAIN_ID || block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            contractName = "RngAuctionRelayerRemoteOwnerOptimism";
            deployPath = "DeployL1RelayerOptimism.s.sol";
        }
        return
            RngAuctionRelayer(
                _getContractAddress(
                    contractName,
                    _getDeployPathWithChainId(deployPath, chainIdL1),
                    "rng-auction-relayer-not-found"
                )
            );
    }

    function _getLiquidationPairFactory() internal returns (LiquidationPairFactory) {
        return
            LiquidationPairFactory(
                _getContractAddress(
                    "LiquidationPairFactory",
                    _getDeployPath(DEPLOY_POOL_SCRIPT),
                    "liquidation-pair-factory-not-found"
                )
            );
    }

    function _getMarketRate() internal returns (MarketRate) {
        return
            MarketRate(
                _getContractAddress("MarketRate", _getDeployPath("DeployStableToken.s.sol"), "market-rate-not-found")
            );
    }

    function _getPrizePool() internal returns (PrizePool) {
        return PrizePool(_getContractAddress("PrizePool", _getDeployPath(DEPLOY_POOL_SCRIPT), "prize-pool-not-found"));
    }

    function _getTokenFaucet() internal returns (TokenFaucet) {
        return
            TokenFaucet(
                _getContractAddress("TokenFaucet", _getDeployPath("DeployStableToken.s.sol"), "token-faucet-not-found")
            );
    }

    function _getTwabController() internal returns (TwabController) {
        return
            TwabController(
                _getContractAddress("TwabController", _getDeployPath(DEPLOY_POOL_SCRIPT), "twab-controller-not-found")
            );
    }

    function _getToken(string memory _tokenSymbol, string memory _artifactsPath) internal returns (ERC20Mintable) {
        return ERC20Mintable(_getTokenAddress("ERC20Mintable", _tokenSymbol, 1, _artifactsPath, "token-not-found"));
    }

    function _getVault(string memory _tokenSymbol) internal returns (VaultMintRate) {
        string memory deployPath = _getDeployPath("DeployVault.s.sol");
        console2.log("looking for", _tokenSymbol);
        address tokenAddress = _getTokenAddress("VaultMintRate", _tokenSymbol, 2, deployPath, "vault-not-found");
        return VaultMintRate(tokenAddress);
    }

    function _getYieldVault(string memory _tokenSymbol) internal returns (YieldVaultMintRate) {
        string memory deployPath = _getDeployPath("DeployYieldVault.s.sol");
        address tokenAddress = _getTokenAddress(
            "YieldVaultMintRate",
            _tokenSymbol,
            2,
            deployPath,
            "yield-vault-not-found"
        );
        return YieldVaultMintRate(tokenAddress);
    }

    function _getLinkToken() internal view returns (LinkTokenInterface) {
        if (block.chainid == GOERLI_CHAIN_ID) {
            // Goerli Ethereum
            return LinkTokenInterface(GOERLI_LINK_ADDRESS);
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            // Sepolia Ethereum
            return LinkTokenInterface(SEPOLIA_LINK_ADDRESS);
        } else if (block.chainid == 31337) {
            return LinkTokenInterface(address(GOERLI_LINK_ADDRESS)); // bogus localhost address
        } else {
            revert("Link token address not set in `_getLinkToken` for this chain.");
        }
    }

    function _getVrfV2Wrapper() internal view returns (VRFV2Wrapper) {
        if (block.chainid == GOERLI_CHAIN_ID) {
            // Goerli Ethereum
            return VRFV2Wrapper(address(GOERLI_VRFV2_WRAPPER_ADDRESS));
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            // Sepolia Ethereum
            return VRFV2Wrapper(address(SEPOLIA_VRFV2_WRAPPER_ADDRESS));
        } else if (block.chainid == 31337) {
            return VRFV2Wrapper(address(GOERLI_VRFV2_WRAPPER_ADDRESS)); // bogus localhost address
        } else {
            revert("VRF V2 Wrapper address not set in `_getLinkToken` for this chain.");
        }
    }
}
