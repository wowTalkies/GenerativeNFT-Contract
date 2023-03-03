const { run } = require('hardhat');
async function main() {
  await run(`verify:verify`, {
    contract: 'contracts/WowTNft721A.sol:WowTNft721A',
    address: '0xC82C2b9C65B74D5B5af5CAEC735935DDB4a15c3d',
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
