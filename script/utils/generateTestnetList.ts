import {
  writeFiles
} from "../helpers/generateContractList";

export function getDeploymentPaths(chainId: number): string[] {
  const rootFolder = `${__dirname}/../..`;
  return [
    `${rootFolder}/broadcast/DeployTestnet.s.sol/${chainId}`
  ];
}

export const rootFolder = `${__dirname}/../..`;

const remap = new Map<string, string>();
remap["PrizeVaultMintRate"] = "PrizeVault";
remap["TpdaLiquidationPairFactory_instance"] = "TpdaLiquidationPair";
remap["ClaimerFactory_instance"] = "Claimer";

writeFiles(rootFolder, getDeploymentPaths(11155420), "optimismSepolia", remap);
writeFiles(rootFolder, getDeploymentPaths(84532), "baseSepolia", remap);
writeFiles(rootFolder, getDeploymentPaths(421614), "arbitrumSepolia", remap);
writeFiles(rootFolder, getDeploymentPaths(11155111), "sepolia", remap);
writeFiles(rootFolder, getDeploymentPaths(534351), "scrollSepolia", remap);
writeFiles(rootFolder, getDeploymentPaths(31337), "local", remap);
