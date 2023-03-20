const { ethers, upgrades } = require('hardhat');
const hre = require('hardhat');

async function main() {
  const factory = await ethers.getContractFactory('WowTNft721A');
  // const contract = await upgrades.deployProxy(factory, [
  //   'GenerativeNFTs',
  //   'wowT',
  //   'https://wowtalkiestestbucket.s3.ap-south-1.amazonaws.com/collections/GenerativeNfts/contract.json', // contractUri
  //   'https://wowtalkiestestbucket.s3.ap-south-1.amazonaws.com/collections/GenerativeNfts/preRevealUri.json',
  //   '1000000000000000',
  //   5000,
  //   '0x26BA546b581f859BFeE6821958097E8bA1C24444',
  //   10484, // goerli network
  //   '0x2ca8e0c643bde4c2e08ab1fa0da3401adad7734d', // goerli network
  //   '0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15', // goerli network
  // ]);

  // const contract = await upgrades.upgradeProxy(
  //   '0x157777194851d31ca2d304b4b02bad25ec4289b7',
  //   factory
  // );

  const [owner] = await hre.ethers.getSigners();

  await contract.deployed();
  console.log('Contract deployed to: ', contract.address);
  console.log('Contract deployed by (Owner): ', owner.address, '\n');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
