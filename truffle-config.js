// Deployment network configuration

/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() {
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>')
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */
require('dotenv').config();
require('babel-register');
require('babel-polyfill');
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
    networks: {
         mainnet: {
          provider: function() {
            return new HDWalletProvider(
              process.env.MNEMONIC,
              `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`
            )
          },
          gas: 5000000,
          gasPrice: 90000000000,
          confirmations: 2,
          network_id: 1
        },
         ropsten: {
          provider: function() {
            return new HDWalletProvider(
              process.env.MNEMONIC,
              `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`
            )
          },
          gas: 5000000,
          gasPrice: 40000000000,
          network_id: 3
        },
        kovan: {
          provider: function() {
            return new HDWalletProvider(
              process.env.MNEMONIC,
              `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`
            )
          },
          gas: 5000000,
          gasPrice: 25000000000,
          network_id: 42
        },
        ganache: {
            host: 'localhost',
            port: 7545, // By default Ganache runs on this port.
            network_id: '*' // network_id for ganache is 5777. However, by keeping * as value you can run this node on any network
        }
    },
    compilers: {
        solc: {
            version: "^0.6.0"
        }
    }
};
