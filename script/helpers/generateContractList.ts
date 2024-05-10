import * as fs from "fs";
import npmPackage from "../../package.json";

import { Contract, ContractList, VaultInfo, VaultList, Version } from "./types";

const versionSplit = npmPackage.version.split(".");
const patchSplit = versionSplit[2].split("-");

const PACKAGE_VERSION: Version = {
  major: Number(versionSplit[0]),
  minor: Number(versionSplit[1]),
  patch: Number(patchSplit[0]),
};

const getAbi = (rootFolder: string, type: string) =>
  JSON.parse(
    fs.readFileSync(`${rootFolder}/out/${type}.sol/${type}.json`, "utf8")
  ).abi;

const getBlob = (path: string) =>
  JSON.parse(fs.readFileSync(`${path}/run-latest.json`, "utf8"));

const formatContract = (
  rootFolder: string,
  chainId: number,
  name: string,
  address: `0x${string}`,
  contractNameRemappings: Map<string, string>
): Contract => {
  const regex = /V[1-9+]((.{0,2}[0-9+]){0,2})$/g;
  const version = name.match(regex)?.[0]?.slice(1).split(".") || [1, 0, 0];
  const splitName = name.split(regex)[0];
  const type = contractNameRemappings[splitName] ? contractNameRemappings[splitName] : splitName;

  const defaultContract = {
    chainId,
    address,
    version: {
      major: Number(version[0]),
      minor: Number(version[1]) || 0,
      patch: Number(version[2]) || 0,
    },
    type: type,
    abi: getAbi(rootFolder, type),
  };

  return defaultContract;
};

export const generateContractList = (
  rootFolder: string,
  deploymentPaths: string[],
  contractNameRemappings: Map<string, string>
): ContractList => {
  const contractList: ContractList = {
    name: "Hyperstructure Testnet",
    version: PACKAGE_VERSION,
    timestamp: new Date().toISOString(),
    contracts: [],
  };

  // Map to reference deployed contract names by address
  const contractAddressToName = new Map<string, string>();

  const { transactions: stableTokenTransactions } = getBlob(deploymentPaths[0]);
  let tokenTransactions = [];
  if (deploymentPaths[1]) {
    let { transactions } = getBlob(deploymentPaths[1]);
    tokenTransactions = transactions;
  }

  tokenTransactions = stableTokenTransactions.concat(tokenTransactions);

  deploymentPaths.forEach((deploymentPath) => {
    const deploymentBlob = getBlob(deploymentPath);
    const chainId = deploymentBlob.chain;
    const transactions = deploymentBlob.transactions;

    transactions.forEach(
      ({
        transactionType,
        contractName,
        contractAddress,
        arguments: deployArguments,
        additionalContracts,
      }) => {
        const createdContract = additionalContracts[0];

        // Store name of contract for reference later
        if (contractName)
          contractAddressToName.set(contractAddress, contractName);

        if (
          transactionType == "CALL" &&
          createdContract &&
          createdContract.transactionType === "CREATE"
        ) {
          // Handle case when contract name isn't available on CALL
          if (!contractName) {
            const storedName = contractAddressToName.get(contractAddress);
            if (storedName) contractName = storedName;
          }

          // Set contract info to the created contract
          transactionType = "CREATE";
          contractAddress = createdContract.address;

          contractName = contractName + "_instance";
        }

        if (transactionType === "CREATE") {
          contractList.contracts.push(
            formatContract(
              rootFolder,
              chainId,
              contractName,
              contractAddress,
              contractNameRemappings
            )
          );
        }
      }
    );
  });

  return contractList;
};

export const findConstructorArguments = (deploymentPaths: string[], targetContractAddress: string): string[] => {
  let result: string[];

  for (let d = 0; d < deploymentPaths.length; d++) {
    const deploymentPath = deploymentPaths[d];
    const deploymentBlob = getBlob(deploymentPath);
    const transactions = deploymentBlob.transactions;

    for (let i = 0; i < transactions.length; i++) {
      const {
        transactionType,
        contractAddress,
        arguments: deployArguments,
        additionalContracts,
      } = transactions[i];

      if (
        transactionType === "CREATE" &&
        contractAddress === targetContractAddress.toLowerCase()
      ) {
        result = deployArguments;
        break;
      }
      if (
        transactionType == "CALL" &&
        additionalContracts.length > 0 &&
        additionalContracts[0].address === targetContractAddress.toLowerCase()
      ) {
        result = deployArguments;
        break;
      }
    }
  }

  return result;
};

export const generateVaultList = (
  deploymentPaths: string[],
  contractList: ContractList
): VaultList => {
  const vaultList: VaultList = {
    name: "PoolTogether Testnet Vault List",
    keywords: ["pooltogether"],
    version: PACKAGE_VERSION,
    timestamp: new Date().toISOString(),
    tokens: [],
  };
  contractList.contracts.filter((contract) => contract.type === "PrizeVault").forEach((contract) => {
    const args = findConstructorArguments(deploymentPaths, contract.address);
    const yieldVaultAddress = args[2];
    const yieldVaultArgs = findConstructorArguments(deploymentPaths, yieldVaultAddress);
    let assetAddress = yieldVaultArgs[0];
    if (yieldVaultArgs.length == 3) {
      // staking vault
      assetAddress = yieldVaultArgs[2];
    }
    const assetArguments = findConstructorArguments(deploymentPaths, assetAddress);
    vaultList.tokens.push({
      chainId: contract.chainId,
      address: contract.address,
      name: stripQuotes(args[0]),
      decimals: parseInt(assetArguments[2]),
      symbol: stripQuotes(args[1]),
      extensions: {
        underlyingAsset: {
          address: assetAddress,
          symbol: stripQuotes(assetArguments[1]),
          name: stripQuotes(assetArguments[0])
        }
      }
    });
  })

  return vaultList;
};

export const writeList = (
  rootFolder: string,
  list: ContractList | VaultList,
  folderName: string,
  fileName: string
) => {
  const dirpath = `${rootFolder}/${folderName}`;

  fs.mkdirSync(dirpath, { recursive: true });
  fs.writeFile(`${dirpath}/${fileName}.json`, JSON.stringify(list, null, 2), (err) => {
    if (err) {
      console.error(err);
      return;
    }
  });
};

function stripQuotes(str) {
  return str.replace(/['"]+/g, '');
}


export function writeFiles(
  rootFolder: string,
  deploymentPaths: string[],
  chainName: string,
  contractNameRemappings: Map<string, string> = new Map()
) {

  if (!fs.existsSync(deploymentPaths[0])) {
    console.error(`No files for chainName ${chainName}`)
    return;
  }

  const contractList = generateContractList(rootFolder, deploymentPaths, contractNameRemappings);

  writeList(
    rootFolder,
    contractList,
    `deployments/${chainName}`,
    `contracts`
  );
  
  writeList(
    rootFolder,
    generateVaultList(
      deploymentPaths,
      contractList
    ),
    `deployments/${chainName}`,
    `vaults`
  );
}
