const { run } = require('hardhat');
async function main() {
  await run(`verify:verify`, {
    contract: 'contracts/WowTNft721A.sol:WowTNft721A',
    address: '0x2d6326dC0aefd142d5B94915C48E6B47B744293D',
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
