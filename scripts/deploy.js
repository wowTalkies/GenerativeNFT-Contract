const { ethers, upgrades } = require('hardhat');
const hre = require('hardhat');

async function main() {
  const factory = await ethers.getContractFactory('WowTNft721A');
  const contract = await upgrades.deployProxy(factory, [
    'GenerativeNFTs',
    'wowT',
    'https://wowtalkiestestbucket.s3.ap-south-1.amazonaws.com/collections/GenerativeNfts/contract.json', // contractUri
    'https://wowtalkiestestbucket.s3.ap-south-1.amazonaws.com/collections/GenerativeNfts/preRevealUri.json',
    5000,
    '0x26BA546b581f859BFeE6821958097E8bA1C24444',
    3555, // mumbai network
    '0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed', // mumbai network
    '0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f', // mumbai network
  ]);

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
