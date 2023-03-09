const { ethers, upgrades } = require('hardhat');
const hre = require('hardhat');

async function main() {
  const factory = await ethers.getContractFactory('WowTNft721A');
  // const contract = await upgrades.deployProxy(factory, [
  //   'GenerativeNFTs',
  //   'wowT',
  //   'https://wowt.mypinata.cloud/ipfs/Qmf7QC6z39qRatQF5YnjWgGtGRndCFCZeHrYtbf52TG46t', // contractUri
  //   5000,
  //   '0x26BA546b581f859BFeE6821958097E8bA1C24444',
  //   10484,
  //   '0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D',
  //   '0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15',
  // ]);

  const contract = await upgrades.upgradeProxy(
    '0x7643c879adFC9FdAFfdcF6f7F7a4fC8eC4CFb55A',
    factory
  );

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
