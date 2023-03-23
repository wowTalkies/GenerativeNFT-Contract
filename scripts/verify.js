const { run } = require('hardhat');
async function main() {
  await run(`verify:verify`, {
    contract: 'contracts/WowTNft721A.sol:WowTNft721A',
    address: '0xE2acE91e24CE707a63ad4071068C82a3F49B78c1',
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
