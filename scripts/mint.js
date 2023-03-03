const { ethers } = require('hardhat');

async function main() {
  const NFT = await ethers.getContractFactory('RandomNft721A');

  let nftAddress = '0x9004A8B8dAf56aBB7C3717efa5832F0f2350a426';
  let deployed = await NFT.attach(nftAddress);

  console.log(deployed);

  //   let nft = deployed
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
