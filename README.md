# Smart contracts written for Ethereum Blockchain

## Docker deployments

***Step 1:*** Fill into .env your data:

* infura.io api key *(register new account, in case if needed)*
* your wallet's mnemonic key *(you can easily get your wallet in metamask)*

***Step 2:*** Install docker & docker-compose (if not installed)

* MacOS: https://docs.docker.com/docker-for-mac/
* Linux: https://docs.docker.com/engine/install/ and https://docs.docker.com/compose/install/
* Windows: https://docs.docker.com/docker-for-windows/install/

***Step 3:*** Launch environment container

* Launch container with `bash start.sh` command. (You can use `bash stop.sh` to stop it, when you'll finish)

***Step 4:*** Perform contract deployment:

* Connect to docker container `docker exec -ti eth_sandbox bash`
* For local (ganache) network: `npm run truffle:deploy:ganache`
* For test (kovan) network **(must have KETH)**: `npm run truffle:deploy:kovan`
* For test (ropsten) network **(must have ETH)**: `npm run truffle:deploy:ropsten`
* For prod (mainnet) network **(must have ETH)**: `npm run truffle:deploy:mainnet`


## Development

Basically represent Tokens and IOC contract with following functionality:

### Prerequisites

Following tools should be installed on the machine:

- [node](https://nodejs.org/en/)
- [npm](https://www.npmjs.com/)
- [truffle](https://www.trufflesuite.com/truffle) (`npm install truffle -g`)
- [ganache](https://github.com/trufflesuite/ganache/releases/tag/v2.4.0)
- [ng](https://angular.io/) (`npm install -g @angular/cli`)
- [solidity (solc)](https://github.com/ethereum/solidity) (`npm install -g solc`)

###### [ganache-cli](https://github.com/trufflesuite/ganache-cli) can be used for cli control of the ganache

#### Docker

Docker integration example can be found [here](https://gitlab.santa-maria.io/smartcontracts/ethereum-blockchain-exploration-with-python/tree/0870cc1dc065acf6e544eb9205060939c934b34b).
[Here](https://hub.docker.com/r/trufflesuite/ganache-cli/dockerfile) is the dockerfile of the ganache-cli container.
