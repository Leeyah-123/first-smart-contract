/** @type import('hardhat/config').HardhatUserConfig */

require('dotenv').config();

require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-truffle5');

module.exports = {
  solidity: '0.8.19',
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: { mnemonic: process.env.MNEMONIC },
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${'Jm3a7O_i7BhOb0WpD82wCz55ovxUV605'}`,
      accounts: [process.env.SEPOLIA_PRIVATE_KEY],
    },
  },
};
