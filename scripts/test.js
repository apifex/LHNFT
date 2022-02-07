// scripts/index.js

module.exports = async function main(callback) {
    try {
        const accounts = await web3.eth.getAccounts();
    
        const NFT = artifacts.require("NFT");
    
        console.log('NFT address: ', NFT.address)
            
        const NFTContract = await NFT.deployed()

        const DEX = artifacts.require("DEX");
    
        console.log('DEX address: ', DEX.address)
            
        const DEXContract = await DEX.deployed()
       
       
        let mintArrayAccounts = []
        let mintArrayIds = []
        let mintArrayJSONs= []

        for (let i=1; i<256; i++) {
            mintArrayAccounts.push(accounts[0])
            mintArrayIds.push(i)
            mintArrayJSONs.push(`${i}.json`)
        }
    
        await NFTContract.setBaseURI('https://ipfs.io/ipfs/QmcR4CPMWQ6yadhPqH3eSeU7NxMhCDyMyFGZrC8GjT2tms/')
        await NFTContract.safeMint(accounts[0], 0, '0.json')
        await NFTContract.mintMultiple(mintArrayAccounts, mintArrayIds, mintArrayJSONs);
        
        console.log('Token 0 metadata URI', await NFTContract.tokenUri(0))
        console.log('Token 1 metadata URI', await NFTContract.tokenUri(1))
        console.log('Token 2 metadata URI', await NFTContract.tokenUri(2))
        console.log('Token 3 metadata URI', await NFTContract.tokenUri(3))
        console.log('Token 255 metadata URI', await NFTContract.tokenUri(255))

        await NFTContract.approve('0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B' ,0)
        await NFTContract.approve('0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B' ,2)

        console.log('owner of 0: ', await NFTContract.ownerOf(0))
        console.log('owner of 1: ', await NFTContract.ownerOf(1))
        console.log('owner of 2: ', await NFTContract.ownerOf(2))
        
        console.log('get approved 0: ', await NFTContract.getApproved(0))
        console.log('get approved 1: ', await NFTContract.getApproved(1))

        await DEXContract.makeAuctionOrder('0xCfEB869F69431e42cdB54A4F4f105C19C080A601', 2, 200, 100000000)

        console.log((await NFTContract.tokenUri(0)).toString())
        console.log(('ballance of', await NFTContract.balanceOf(accounts[0])).toString())
        console.log('seller orders', (await DEXContract.sellerTotalOrder(accounts[0])).toString())
      
    
        // let hash = '0x96b0d546c642218e78a6a2c49d59783e946e85ef14e7014f6d6d088c127322b3'
        await DEXContract.bid(hash, {from: accounts[1], value: web3.utils.toWei("0.8", "ether")})
        // console.log((await DEXContract.getCurrentPrice(hash)).toString())
        // await DEXContract.bid(hash, {from: accounts[2], value: web3.utils.toWei("1", "ether")})
        // console.log((await DEXContract.getCurrentPrice(hash)).toString())
        
       
        callback(0);
    } catch (error) {
        console.error(error);
        callback(1);
    }
};

