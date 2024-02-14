import {
  generateContractList,
  generateVaultList,
  rootFolder,
  writeList,
} from "../helpers/generateContractList";

// const ethSepoliaDeploymentPaths = [
  // `${rootFolder}/broadcast/DeployL1RngAuction.s.sol/11155111`,
  // `${rootFolder}/broadcast/DeployL1RelayerArbitrum.s.sol/11155111`, // uncomment if redeployed to Arbitrum
  // `${rootFolder}/broadcast/DeployL1RelayerOptimism.s.sol/11155111`, // uncomment if redeployed to Optimism
// ];
// writeList(
//   generateContractList(ethSepoliaDeploymentPaths),
//   "deployments/ethSepolia",
//   "contracts"
// );

// Extra L1 Deployment Paths

// const ethSepoliaStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/11155111`;
// const ethSepoliaTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/11155111`;
// const ethSepoliaVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/11155111`;

// const ethSepoliaDeploymentPaths = [
//   ethSepoliaStableTokenDeploymentPath,
//   ethSepoliaTokenDeploymentPath,
//   `${rootFolder}/broadcast/DeployPool.s.sol/11155111`,
//   `${rootFolder}/broadcast/DeployYieldVault.s.sol/11155111`,
//   `${rootFolder}/broadcast/DeployTwabDelegator.s.sol/11155111`,
//   `${rootFolder}/broadcast/DeployTwabRewards.s.sol/11155111`,
//   ethSepoliaVaultDeploymentPath,
// ];

// const ethSepoliaTokenDeploymentPaths = [
//   ethSepoliaStableTokenDeploymentPath,
//   ethSepoliaTokenDeploymentPath,
// ];

// writeList(generateContractList(ethSepoliaDeploymentPaths), "deployments/ethSepolia", "contracts");
// writeList(
//   generateVaultList(ethSepoliaVaultDeploymentPath, ethSepoliaTokenDeploymentPaths),
//   "deployments/ethSepolia",
//   "vaults"
// );

// Arbitrum
// const arbitrumSepoliaStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/421614`;
// const arbitrumSepoliaTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/421614`;
// const arbitrumSepoliaVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/421614`;

// const arbitrumSepoliaDeploymentPaths = [
//   arbitrumSepoliaStableTokenDeploymentPath,
//   arbitrumSepoliaTokenDeploymentPath,
//   `${rootFolder}/broadcast/DeployL2PrizePool.s.sol/421614`,
//   `${rootFolder}/broadcast/DeployYieldVault.s.sol/421614`,
//   `${rootFolder}/broadcast/DeployTwabDelegator.s.sol/421614`,
//   `${rootFolder}/broadcast/DeployTwabRewards.s.sol/421614`,
//   arbitrumSepoliaVaultDeploymentPath,
// ];

// const arbitrumSepoliaTokenDeploymentPaths = [
//   arbitrumSepoliaStableTokenDeploymentPath,
//   arbitrumSepoliaTokenDeploymentPath,
// ];

// writeList(
//   generateContractList(arbitrumSepoliaDeploymentPaths),
//   "deployments/arbitrumSepolia",
//   "contracts"
// );

// writeList(
//   generateVaultList(
//     arbitrumSepoliaVaultDeploymentPath,
//     arbitrumSepoliaTokenDeploymentPaths
//   ),
//   "deployments/arbitrumSepolia",
//   "vaults"
// );

// Optimism
const optimismSepoliaStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/11155420`;
const optimismSepoliaTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/11155420`;
const optimismSepoliaVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/11155420`;

const optimismSepoliaDeploymentPaths = [
  optimismSepoliaStableTokenDeploymentPath,
  optimismSepoliaTokenDeploymentPath,
  `${rootFolder}/broadcast/DeployPool.s.sol/11155420`,
  `${rootFolder}/broadcast/DeployYieldVault.s.sol/11155420`,
  `${rootFolder}/broadcast/DeployTwabDelegator.s.sol/11155420`,
  `${rootFolder}/broadcast/DeployTwabRewards.s.sol/11155420`,
  optimismSepoliaVaultDeploymentPath,
];

const optimismSepoliaTokenDeploymentPaths = [
  optimismSepoliaStableTokenDeploymentPath,
  optimismSepoliaTokenDeploymentPath,
];

const optimismSepoliaContractList = generateContractList(optimismSepoliaDeploymentPaths)

writeList(
  optimismSepoliaContractList,
  "deployments/optimismSepolia",
  "contracts"
);

writeList(
  generateVaultList(
    optimismSepoliaDeploymentPaths,
    optimismSepoliaContractList
  ),
  "deployments/optimismSepolia",
  "vaults"
);
