const { run } = require('hardhat');
async function main() {
  await run(`verify:verify`, {
    contract: 'contracts/WowTNft721A.sol:WowTNft721A',
    address: '0x1F39f08DFA162b5C49853AeAd053fDE420Cee24b',
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
