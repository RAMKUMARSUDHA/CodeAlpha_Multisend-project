const hre = require("hardhat");

async function main() {
  console.log("Deploying MultiSend contract...");

  // Get the contract factory and deploy with no constructor args
  const MultiSend = await hre.ethers.getContractFactory("MultiSend");
  const multiSend = await MultiSend.deploy();

  await multiSend.waitForDeployment();

  const address = await multiSend.getAddress();
  console.log(`MultiSend deployed to: ${address}`);

  console.log("\nNext steps:");
  console.log(`  - Verify on Etherscan (testnet only):`);
  console.log(`    npx hardhat verify --network sepolia ${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
