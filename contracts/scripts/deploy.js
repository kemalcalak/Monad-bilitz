const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying contracts to Monad Testnet...");

  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("📝 Deploying with account:", deployer.address);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "MON");

  // Deploy HierarchyManager
  console.log("\n📦 Deploying HierarchyManager...");
  const HierarchyManager = await hre.ethers.getContractFactory("HierarchyManager");
  const hierarchyManager = await HierarchyManager.deploy();
  await hierarchyManager.waitForDeployment();
  const hierarchyAddress = await hierarchyManager.getAddress();
  console.log("✅ HierarchyManager deployed to:", hierarchyAddress);

  // Deploy SignatureAuthority
  console.log("\n📦 Deploying SignatureAuthority...");
  const SignatureAuthority = await hre.ethers.getContractFactory("SignatureAuthority");
  const signatureAuthority = await SignatureAuthority.deploy(hierarchyAddress);
  await signatureAuthority.waitForDeployment();
  const signatureAddress = await signatureAuthority.getAddress();
  console.log("✅ SignatureAuthority deployed to:", signatureAddress);

  // Create demo hierarchy groups
  console.log("\n🏗️  Creating demo hierarchy groups...");
  
  const groups = [
    { id: "CEO", name: "Chief Executive Officer", level: 1, score: 100 },
    { id: "CFO", name: "Chief Financial Officer", level: 2, score: 80 },
    { id: "CTO", name: "Chief Technology Officer", level: 2, score: 80 },
    { id: "DEPT_HEAD", name: "Department Head", level: 3, score: 50 },
    { id: "MANAGER", name: "Manager", level: 4, score: 30 },
    { id: "EMPLOYEE", name: "Employee", level: 5, score: 10 },
  ];

  for (const group of groups) {
    const tx = await hierarchyManager.createGroup(
      group.id,
      group.name,
      group.level,
      group.score
    );
    await tx.wait();
    console.log(`  ✓ Created group: ${group.name} (score: ${group.score})`);
  }

  // Summary
  console.log("\n" + "=".repeat(60));
  console.log("🎉 Deployment Complete!");
  console.log("=".repeat(60));
  console.log("\n📋 Contract Addresses:");
  console.log("  HierarchyManager:", hierarchyAddress);
  console.log("  SignatureAuthority:", signatureAddress);
  console.log("\n📝 Save these addresses to your backend .env file:");
  console.log(`  HIERARCHY_MANAGER_ADDRESS=${hierarchyAddress}`);
  console.log(`  SIGNATURE_AUTHORITY_ADDRESS=${signatureAddress}`);
  console.log("\n🔗 Network: Monad Testnet");
  console.log("⛽ Gas used: Check transaction receipts above");
  console.log("=".repeat(60) + "\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
