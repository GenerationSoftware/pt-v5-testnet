import {
  generateContractList,
  generateVaultList,
  rootFolder,
  writeList,
} from "../helpers/generateContractList";

function getDeploymentPaths(chainId: number) {
  return [
    `${rootFolder}/broadcast/DeployStableToken.s.sol/${chainId}`,
    `${rootFolder}/broadcast/DeployToken.s.sol/${chainId}`,
    `${rootFolder}/broadcast/DeployPool.s.sol/${chainId}`,
    `${rootFolder}/broadcast/DeployYieldVault.s.sol/${chainId}`,
    `${rootFolder}/broadcast/DeployTwabDelegator.s.sol/${chainId}`,
    `${rootFolder}/broadcast/DeployTwabRewards.s.sol/${chainId}`,
    `${rootFolder}/broadcast/DeployVault.s.sol/${chainId}`,
  ];
}

function writeFiles(chainId: number, chainName: string) {
  const deploymentPaths = getDeploymentPaths(chainId);
  const contractList = generateContractList(deploymentPaths);

  writeList(
    contractList,
    `deployments/${chainName}`,
    `contracts`
  );
  
  writeList(
    generateVaultList(
      deploymentPaths,
      contractList
    ),
    `deployments/${chainName}`,
    `vaults`
  );
}

// writeFiles(11155420, "optimismSepolia");
writeFiles(420, "optimismGoerli");
