const hre = require("hardhat")

const main = async () => {
  const nftContractFactory = await hre.ethers.getContractFactory("Givables");
  const nftContract = await nftContractFactory.deploy(
    "https://www.givables.xyz/assets/token_art.jpg",
    "Access to the Givables community of Undergraduate Artists"
  );
  await nftContract.deployed();
  console.log("Contract deployed to:", nftContract.address);

  // Call the function.
  let txn = await nftContract.adminIssueToken(
    "0x5bfad8b41f8172375db73344b53318fa290b1030"
  );
  // Wait for it to be mined.
  await txn.wait();

  let json = await nftContract.tokenURI(0);

  console.log(json)

  await nftContract.updateTokenURI("we changed bby");
  await nftContract.updateDescription("we changed bby");

  json = await nftContract.tokenURI(0);

  console.log(json)
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
