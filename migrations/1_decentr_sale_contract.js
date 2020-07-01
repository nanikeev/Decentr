// Fetch contract data from the file with the implementation
const DecentrSaleContract = artifacts.require("./DecentrSaleContract.sol");

// JavaScript export
module.exports = async (deployer) => {
    // Deployer is the Truffle wrapper for deploying contract to the network

    // Deploying DecentrSaleContract to the network
    await deployer.deploy(DecentrSaleContract);

    // Waiting until DecentrSaleContract contract is deployed
    const _decentrSaleContract = await DecentrSaleContract.deployed();
};
