// migrations/2_deploy.js

const NFT = artifacts.require('NFT');

const DEX = artifacts.require('DEX');

module.exports = async function (deployer) {
  const accounts = await web3.eth.getAccounts()
  nftContract = await deployer.deploy(NFT, accounts[0], 50000, 1000)
  
  console.log("NFT Contract address: ", nftContract.address)
  
  dexContract = await deployer.deploy(DEX, 1000, 100)

  console.log("DEX Contract address: ", dexContract.address)

};
