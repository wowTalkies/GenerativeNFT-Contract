require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();
require('@openzeppelin/hardhat-upgrades');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    /***************  Polygon Testnet   ******/

    mumbai: {
      url: process.env.MATIC_TESTNET_URL || '',
      accounts:
        process.env.TEST_PRIVATE_KEY !== undefined
          ? [process.env.TEST_PRIVATE_KEY]
          : [],
    },

    /******   Goerli network   *******/

    goerli: {
      url: process.env.GOERLI_URL || '',
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: '2W3RWX4HKJITRBWKUQ58EKY3H1I68HXCMQ',
      polygon: '2W3RWX4HKJITRBWKUQ58EKY3H1I68HXCMQ',
      goerli: '7HBK89Y9M9SAGDD9H86ETMG8UXUGCXSN66',
    },
  },
};
