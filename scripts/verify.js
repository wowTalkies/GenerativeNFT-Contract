const { run } = require('hardhat');
async function main() {
  await run(`verify:verify`, {
    contract: 'contracts/WowTNft721A.sol:WowTNft721A',
    address: '0xeE22Ce7744dC4101fEaBA4Db2bB13Dfcd54019B2',
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
