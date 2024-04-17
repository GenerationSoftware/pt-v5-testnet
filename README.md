# Foundry template

Template to kickstart a Foundry project.

## Getting started

The easiest way to get started is by clicking the [Use this template](https://github.com/pooltogether/foundry-template/generate) button at the top right of this page.

If you prefer to go the CLI way:

```
forge init my-project --template https://github.com/pooltogether/foundry-template
```

## Development

### Installation

You may have to install the following tools to use this repository:

- [Foundry](https://github.com/foundry-rs/foundry) to compile and test contracts
- [direnv](https://direnv.net/) to handle environment variables
- [lcov](https://github.com/linux-test-project/lcov) to generate the code coverage report

Install dependencies:

```
npm i
```

### Env

Copy `.envrc.example` and write down the env variables needed to run this project.

```
cp .envrc.example .envrc
```

Once your env variables are setup, load them with:

```
direnv allow
```

### Compile

Run the following command to compile the contracts:

```
npm run compile
```

## Deployment

First setup npm:

```
nvm use
npm i
```

### Local

Start anvil:

```
anvil
```

In another terminal window, run the following command: `npm run deploy:local`

### Testnet

Use one of the following commands to deploy on the testnet of your choice.

#### Arbitrum Sepolia

`npm run deploy:arbitrumSepolia`

#### Optimism Sepolia

`npm run deploy:optimismSepolia`

### Contract List

To generate the local contract list, run the following command: `npm run gen:deployments`
