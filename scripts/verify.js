const { run } = require('hardhat');
async function main() {
  await run(`verify:verify`, {
    contract: 'contracts/WowTNft721A.sol:WowTNft721A',
    address: '0x7643c879adFC9FdAFfdcF6f7F7a4fC8eC4CFb55A',
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
