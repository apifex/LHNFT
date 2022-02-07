const { expect } = require('chai');
const truffleAssert = require('truffle-assertions');
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const DEX = artifacts.require('DEX')
const NFT = artifacts.require("NFT");

contract('DEX', function (accounts) {

    before(async function () {
        this.dex = await DEX.new(1000, 100)
        const NFTContract = await NFT.deployed()
        
        let mintArrayAccounts = []
        let mintArrayIds = []
        let mintArrayJSONs = []
        let mintArrayRoyalties = []

        for (let i = 1; i < 10; i++) {
            mintArrayAccounts.push(accounts[0])
            mintArrayIds.push(i)
            mintArrayJSONs.push(`${i}.json`)
            mintArrayRoyalties.push(200*i)
        }

        await NFTContract.setBaseURI('https://ipfs.io/ipfs/QmcR4CPMWQ6yadhPqH3eSeU7NxMhCDyMyFGZrC8GjT2tms/')
        await NFTContract.safeMint(accounts[1], 0, '0.json', 1000)
        await NFTContract.mintMultiple(mintArrayAccounts, mintArrayIds, mintArrayJSONs, mintArrayRoyalties);

        const roy = await NFTContract.royaltyInfo(0, 200);
        console.log("roy", roy)

        await NFTContract.approve(this.dex.address, 0, { from: accounts[1] })
        await NFTContract.setApprovalForAll(this.dex.address, true)
    })


    it('make auction order', async function () {
        const order = await this.dex.makeAuctionOrder(NFT.address, 1, 200, 1000)
        truffleAssert.eventEmitted(order, "MakeOrder", (event) => {
            return event.tokenContract == NFT.address && event.tokenId == 1 && event.seller == accounts[0]
        })
        expect((await this.dex.sellerTotalOrder(accounts[0])).toString()).to.equal('1')
    })

   

    it('make fixed order', async function () {
        const order = await this.dex.makeFixedPriceOrder(NFT.address, 3, web3.utils.toWei("0.2", "ether"), 2000)
        const orderId = order.logs[0].args.orderId
        truffleAssert.eventEmitted(order, "MakeOrder", (event) => {
            return event.tokenContract == NFT.address && event.tokenId == 3 && event.seller == accounts[0]
        })

        expectRevert(
            this.dex.buyItNow(orderId, { from: accounts[4], value: web3.utils.toWei("0.1", "ether") }),
            "Wrong price for 'Buy it now!'")

        const buyNow = await this.dex.buyItNow(orderId, { from: accounts[4], value: web3.utils.toWei("0.2", "ether") })
        truffleAssert.eventEmitted(buyNow, "Claim", (event) => {
            return event.tokenContract == NFT.address && event.tokenId == 3 && event.seller == accounts[0] && event.taker == accounts[4] && event.price == web3.utils.toWei("0.2", "ether")
        })
        expect((await this.dex.sellerTotalOrder(accounts[0])).toString()).to.equal('2')
    })

    it('check finished order', async function () {
        const order = await this.dex.makeAuctionOrder(NFT.address, 4, 500, 1)
        const orderId = order.logs[0].args.orderId
        const bid = await this.dex.bid(orderId, { from: accounts[3], value: web3.utils.toWei("0.08", "ether") })


       it('check for errors'), async function() {
        truffleAssert.eventEmitted(bid, "Bid", (event) => {
            return event.tokenContract == NFT.address && event.tokenId == 4 && event.bidder == accounts[3] && event.bidPrice == web3.utils.toWei("0.08", "ether")
        })

        function timeout(ms) {
              return new Promise(resolve => setTimeout(resolve, ms));
            }

        await timeout(16000);

        
        await expectRevert(
            this.dex.bid(orderId, { from: accounts[4], value: web3.utils.toWei("0.08", "ether") }),
            "This order is over or canceled"
        )
       }
        

        expect((await this.dex.sellerTotalOrder(accounts[0])).toString()).to.equal('3')
    })

    it('bid', async function () {
        const order = await this.dex.makeAuctionOrder(NFT.address, 2, 300, 10)
        const orderId = order.logs[0].args.orderId
        const bid = await this.dex.bid(orderId, { from: accounts[3], value: web3.utils.toWei("0.08", "ether") })

        truffleAssert.eventEmitted(bid, "Bid", (event) => {
            return event.tokenContract == NFT.address && event.tokenId == 2 && event.bidder == accounts[3] && event.bidPrice == web3.utils.toWei("0.08", "ether")
        })

        await expectRevert(
            this.dex.bid(orderId, { from: accounts[4], value: 299 }),
            "Price can't be less than 'start price'"
        )
       
        // expectRevert(
        //     this.dex.bid(orderId, { from: accounts[0], value: web3.utils.toWei("0.5", "ether") }),
        //     "Can not bid to your order"
        // )
        // expectRevert(
        //     this.dex.bid(orderId, { from: accounts[6] }),
        //     "Price can't be zero"
        // )

        // expectRevert(
        //     this.dex.buyItNow(orderId, { from: accounts[5], value: web3.utils.toWei("1", "ether") }),
        //     "It's an auction, you can't 'buy it now'"
        // )
    })

    it('get current price', async function () {
        const order = await this.dex.makeAuctionOrder(NFT.address, 0, 300, 1000, { from: accounts[1] })
        const { logs } = order
        expect((await this.dex.getCurrentPrice(logs[0].args.orderId)).toString()).to.equal('300')
    })

  
})

