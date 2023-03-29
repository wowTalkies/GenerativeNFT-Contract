const { run } = require('hardhat');
async function main() {
  await run(`verify:verify`, {
    contract: 'contracts/WowTNft721A.sol:WowTNft721A',
    address: '0xB38A653Ad3FD7F61D6b8D0F5Bbb43bc2f3f6587E',
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
