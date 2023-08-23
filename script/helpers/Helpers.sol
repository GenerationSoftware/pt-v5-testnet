// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { strings } from "solidity-stringutils/strings.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";

import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { MarketRate } from "../../src/MarketRate.sol";
import { TokenFaucet } from "../../src/TokenFaucet.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { LinkTokenInterface } from "chainlink/interfaces/LinkTokenInterface.sol";
import { VRFV2WrapperInterface } from "chainlink/interfaces/VRFV2WrapperInterface.sol";

// Testnet deployment paths
string constant ETHEREUM_GOERLI_PATH = "broadcast/Deploy.s.sol/5/";
string constant LOCAL_PATH = "/broadcast/Deploy.s.sol/31337";

abstract contract Helpers is Script {
  using strings for *;
  using stdJson for string;

  /* ============ Constants ============ */
  uint8 internal constant DEFAULT_TOKEN_DECIMAL = 18;
  uint8 internal constant USDC_TOKEN_DECIMAL = 6;
  uint8 internal constant GUSD_TOKEN_DECIMAL = 2;
  uint8 internal constant WBTC_TOKEN_DECIMAL = 8;

  uint256 internal constant DAI_PRICE = 100000000;
  uint256 internal constant USDC_PRICE = 100000000;
  uint256 internal constant GUSD_PRICE = 100000000;
  uint256 internal constant POOL_PRICE = 100000000;
  uint256 internal constant WBTC_PRICE = 2488023943815;
  uint256 internal constant ETH_PRICE = 166876925050;
  uint256 internal constant PRIZE_TOKEN_PRICE = 1e18;

  uint256 internal constant ONE_YEAR_IN_SECONDS = 31557600;

  address internal constant GOERLI_DEFENDER_ADDRESS = 0x22f928063d7FA5a90f4fd7949bB0848aF7C79b0A;
  address internal constant SEPOLIA_DEFENDER_ADDRESS = 0xbD764675C2Ffb3E580D3f9c92B0c84c526fe818A;
  address internal constant MUMBAI_DEFENDER_ADDRESS = 0xbCE45a1C2c1eFF18E77f217A62a44f885b26099f;

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
   * @param _tokenPrice Price of the token represented in 8 decimals
   * @param _decimalOffset Offset between the prize token decimals and the token decimals
   */
  function _getExchangeRate(
    uint256 _tokenPrice,
    uint8 _decimalOffset
  ) internal pure returns (uint128) {
    return uint128((PRIZE_TOKEN_PRICE * 1e8) / (_tokenPrice * (10 ** _decimalOffset)));
  }

  function _tokenGrantMinterRole(ERC20Mintable _token, address _grantee) internal {
    _token.grantRole(_token.MINTER_ROLE(), _grantee);
  }

  function _yieldVaultGrantMinterRole(YieldVaultMintRate _yieldVault, address _grantee) internal {
    _yieldVault.grantRole(_yieldVault.MINTER_ROLE(), _grantee);
  }

  function _tokenGrantMinterRoles(ERC20Mintable _token) internal {
    _tokenGrantMinterRole(_token, address(0x22f928063d7FA5a90f4fd7949bB0848aF7C79b0A));
    _tokenGrantMinterRole(_token, address(0x5E6CC2397EcB33e6041C15360E17c777555A5E63));
    _tokenGrantMinterRole(_token, address(0xA57D294c3a11fB542D524062aE4C5100E0E373Ec));
    _tokenGrantMinterRole(_token, address(0x27fcf06DcFFdDB6Ec5F62D466987e863ec6aE6A0));
  }

  function _yieldVaultGrantMinterRoles(YieldVaultMintRate _yieldVault) internal {
    if (block.chainid == 5) {
      _yieldVaultGrantMinterRole(_yieldVault, GOERLI_DEFENDER_ADDRESS);
    }

    if (block.chainid == 11155111) {
      _yieldVaultGrantMinterRole(_yieldVault, SEPOLIA_DEFENDER_ADDRESS);
    }

    if (block.chainid == 80001) {
      _yieldVaultGrantMinterRole(_yieldVault, MUMBAI_DEFENDER_ADDRESS);
    }

    _yieldVaultGrantMinterRole(_yieldVault, address(0x22f928063d7FA5a90f4fd7949bB0848aF7C79b0A));
    _yieldVaultGrantMinterRole(_yieldVault, address(0x5E6CC2397EcB33e6041C15360E17c777555A5E63));
    _yieldVaultGrantMinterRole(_yieldVault, address(0xA57D294c3a11fB542D524062aE4C5100E0E373Ec));
    _yieldVaultGrantMinterRole(_yieldVault, address(0x27fcf06DcFFdDB6Ec5F62D466987e863ec6aE6A0));
  }

  function _getDeploymentArtifacts(
    string memory _deploymentArtifactsPath
  ) internal returns (string[] memory) {
    string[] memory inputs = new string[](4);
    inputs[0] = "ls";
    inputs[1] = "-m";
    inputs[2] = "-r";
    inputs[3] = string.concat(vm.projectRoot(), _deploymentArtifactsPath);
    bytes memory res = vm.ffi(inputs);

    // Slice ls result
    strings.slice memory s = string(res).toSlice();

    // Remove directory jargon at the beginning of the slice (Fix for Windows Git Bash)
    strings.slice memory dirEnd = "/:".toSlice();
    strings.slice memory sWithoutDirPrefix = s.copy().find(dirEnd).beyond(dirEnd);
    if (!sWithoutDirPrefix.empty()) s = sWithoutDirPrefix;

    // Remove newline and push into array
    strings.slice memory delim = ", ".toSlice();
    strings.slice memory sliceNewline = "\n".toSlice();
    string[] memory filesName = new string[](s.count(delim) + 1);

    for (uint256 i = 0; i < filesName.length; i++) {
      filesName[i] = s.split(delim).beyond(sliceNewline).toString();
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
      bytes[] memory rawTxs = abi.decode(vm.parseJson(jsonFile, ".transactions"), (bytes[]));

      uint256 transactionsLength = rawTxs.length;

      for (uint256 j; j < transactionsLength; j++) {
        string memory contractName = abi.decode(
          stdJson.parseRaw(
            jsonFile,
            string.concat(".transactions[", vm.toString(j), "].contractName")
          ),
          (string)
        );

        if (
          keccak256(abi.encodePacked((contractName))) ==
          keccak256(abi.encodePacked((_contractName)))
        ) {
          address contractAddress = abi.decode(
            stdJson.parseRaw(
              jsonFile,
              string.concat(".transactions[", vm.toString(j), "].contractAddress")
            ),
            (address)
          );

          return contractAddress;
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
    uint256 filesNameLength = filesName.length;

    // Loop through deployment artifacts and find latest deployed `_contractName` address
    for (uint256 i; i < filesNameLength; i++) {
      string memory jsonFile = vm.readFile(
        string.concat(vm.projectRoot(), _artifactsPath, filesName[i])
      );
      bytes[] memory rawTxs = abi.decode(vm.parseJson(jsonFile, ".transactions"), (bytes[]));

      for (uint256 j; j < rawTxs.length; j++) {
        string memory index = vm.toString(j);

        string memory _argumentPositionString = vm.toString(_argumentPosition);

        if (
          keccak256(
            abi.encodePacked(
              (
                abi.decode(
                  stdJson.parseRaw(
                    jsonFile,
                    string.concat(".transactions[", index, "].contractName")
                  ),
                  (string)
                )
              )
            )
          ) ==
          keccak256(abi.encodePacked((_contractName))) &&
          keccak256(
            abi.encodePacked(
              (
                abi.decode(
                  stdJson.parseRaw(
                    jsonFile,
                    string.concat(
                      ".transactions[",
                      index,
                      "].arguments[",
                      _argumentPositionString,
                      "]"
                    )
                  ),
                  (string)
                )
              )
            )
          ) ==
          keccak256(abi.encodePacked((_tokenSymbol)))
        ) {
          address contractAddress = abi.decode(
            stdJson.parseRaw(jsonFile, string.concat(".transactions[", index, "].contractAddress")),
            (address)
          );

          return contractAddress;
        }
      }
    }

    revert(_errorMsg);
  }

  function _getDeployPath(string memory _deployPath) internal view returns (string memory) {
    return string.concat("/broadcast/", _deployPath, "/", Strings.toString(block.chainid), "/");
  }

  /* ============ Getters ============ */

  function _getClaimer() internal returns (Claimer) {
    return
      Claimer(
        _getContractAddress("Claimer", _getDeployPath("DeployPool.s.sol"), "claimer-not-found")
      );
  }

  function _getLiquidationPairFactory() internal returns (LiquidationPairFactory) {
    return
      LiquidationPairFactory(
        _getContractAddress(
          "LiquidationPairFactory",
          _getDeployPath("DeployPool.s.sol"),
          "liquidation-pair-factory-not-found"
        )
      );
  }

  function _getMarketRate() internal returns (MarketRate) {
    return
      MarketRate(
        _getContractAddress(
          "MarketRate",
          _getDeployPath("DeployStableToken.s.sol"),
          "market-rate-not-found"
        )
      );
  }

  function _getPrizePool() internal returns (PrizePool) {
    return
      PrizePool(
        _getContractAddress("PrizePool", _getDeployPath("DeployPool.s.sol"), "prize-pool-not-found")
      );
  }

  function _getTokenFaucet() internal returns (TokenFaucet) {
    return
      TokenFaucet(
        _getContractAddress(
          "TokenFaucet",
          _getDeployPath("DeployStableToken.s.sol"),
          "token-faucet-not-found"
        )
      );
  }

  function _getTwabController() internal returns (TwabController) {
    return
      TwabController(
        _getContractAddress(
          "TwabController",
          _getDeployPath("DeployPool.s.sol"),
          "twab-controller-not-found"
        )
      );
  }

  function _getToken(
    string memory _tokenSymbol,
    string memory _artifactsPath
  ) internal returns (ERC20Mintable) {
    return
      ERC20Mintable(
        _getTokenAddress("ERC20Mintable", _tokenSymbol, 1, _artifactsPath, "token-not-found")
      );
  }

  function _getVault(string memory _tokenSymbol) internal returns (VaultMintRate) {
    return
      VaultMintRate(
        _getTokenAddress(
          "VaultMintRate",
          _tokenSymbol,
          2,
          _getDeployPath("DeployVault.s.sol"),
          "vault-not-found"
        )
      );
  }

  function _getYieldVault(string memory _tokenSymbol) internal returns (YieldVaultMintRate) {
    return
      YieldVaultMintRate(
        _getTokenAddress(
          "YieldVaultMintRate",
          _tokenSymbol,
          2,
          _getDeployPath("DeployYieldVault.s.sol"),
          "yield-vault-not-found"
        )
      );
  }

  function _getLinkToken() internal returns (LinkTokenInterface) {
    if (block.chainid == 5) { // Goerli Ethereum
      return LinkTokenInterface(address(0x326C977E6efc84E512bB9C30f76E30c160eD06FB));
    } else {
      revert "Link token address not set in `_getLinkToken` for this chain.";
    }
  }

  function _getVrfV2Wrapper() internal returns (VRFV2WrapperInterface) {
    if (block.chainid == 5) { // Goerli Ethereum
      return VRFV2WrapperInterface(address(0x708701a1DfF4f478de54383E49a627eD4852C816));
    } else {
      revert "VRF V2 Wrapper address not set in `_getLinkToken` for this chain.";
    }
  }
}
