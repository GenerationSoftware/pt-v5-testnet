import {
  generateContractList,
  generateVaultList,
  rootFolder,
  writeList,
} from "../helpers/generateContractList";

const ethGoerliDeploymentPaths = [`${rootFolder}/broadcast/DeployL1RngAuction.s.sol/5`];
writeList(generateContractList(ethGoerliDeploymentPaths), "deployments/ethGoerli", "contracts");

// const ethSepoliaStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/11155111`;
// const ethSepoliaTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/11155111`;
// const ethSepoliaVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/11155111`;

// const ethSepoliaDeploymentPaths = [
//   ethSepoliaStableTokenDeploymentPath,
//   ethSepoliaTokenDeploymentPath,
//   `${rootFolder}/broadcast/DeployPool.s.sol/11155111`,
//   `${rootFolder}/broadcast/DeployYieldVault.s.sol/11155111`,
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

const optimismGoerliStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/420`;
const optimismGoerliTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/420`;
const optimismGoerliVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/420`;

const optimismGoerliDeploymentPaths = [
  optimismGoerliStableTokenDeploymentPath,
  optimismGoerliTokenDeploymentPath,
  `${rootFolder}/broadcast/DeployL2PrizePool.s.sol/420`,
  `${rootFolder}/broadcast/DeployYieldVault.s.sol/420`,
  `${rootFolder}/broadcast/DeployTwabDelegator.s.sol/420`,
  optimismGoerliVaultDeploymentPath,
];

const optimismGoerliTokenDeploymentPaths = [
  optimismGoerliStableTokenDeploymentPath,
  optimismGoerliTokenDeploymentPath,
];

writeList(
  generateContractList(optimismGoerliDeploymentPaths),
  "deployments/optimismGoerli",
  "contracts"
);
writeList(
  generateVaultList(optimismGoerliVaultDeploymentPath, optimismGoerliTokenDeploymentPaths),
  "deployments/optimismGoerli",
  "vaults"
);

// const mumbaiStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/80001`;
// const mumbaiTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/80001`;
// const mumbaiVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/80001`;

// const mumbaiDeploymentPaths = [
//   mumbaiStableTokenDeploymentPath,
//   mumbaiTokenDeploymentPath,
//   `${rootFolder}/broadcast/DeployPool.s.sol/80001`,
//   `${rootFolder}/broadcast/DeployYieldVault.s.sol/80001`,
//   mumbaiVaultDeploymentPath,
// ];

// const mumbaiTokenDeploymentPaths = [mumbaiStableTokenDeploymentPath, mumbaiTokenDeploymentPath];

// writeList(generateContractList(mumbaiDeploymentPaths), "deployments/mumbai", "contracts");
// writeList(
//   generateVaultList(mumbaiVaultDeploymentPath, mumbaiTokenDeploymentPaths),
//   "deployments/mumbai",
//   "vaults"
// );
