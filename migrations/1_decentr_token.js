// Fetch contract data from the file with the implementation
const Decentr = artifacts.require("./Decentr.sol");
const DecentrSaleContract = artifacts.require("./DecentrSaleContract.sol");

// JavaScript export
module.exports = async (deployer) => {
    // Deployer is the Truffle wrapper for deploying contract to the network

    // Waiting until DecentrSaleContract contract is deployed
    const _decentrSaleContract = await DecentrSaleContract.deployed();

    // Deploying DecentrToken to the network with reference to the DecentrSaleContract
    await deployer.deploy(Decentr, DecentrSaleContract.address);

    // Waiting until DecentrToken contract is deployed
    const _decentrToken = await Decentr.deployed();
};
