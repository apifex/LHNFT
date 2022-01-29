import Web3 from 'web3'
import fs from 'fs'

const NFT = fs.readFileSync('./build/contracts/NFT.json')
const DEX = fs.readFileSync('./build/contracts/DEX.json')

const nftContract = JSON.parse(NFT)
const dexContract = JSON.parse(DEX)
const web3 = new Web3(Web3.givenProvider || "ws://127.0.0.1:8545")

const nft = new web3.eth.Contract(nftContract.abi)
const dex = new web3.eth.Contract(dexContract.abi)
const accounts = await web3.eth.getAccounts();
nft.options.address = '0xCfEB869F69431e42cdB54A4F4f105C19C080A601'
dex.options.address = '0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B'

const listen = () => {
    dex.events.MakeOrder()  
    .on('data', async event => {
        console.log(event.event, event.returnValues.hash)
        const currentPrice = await dex.methods.getCurrentPrice(event.returnValues.hash).call()
        console.log('current Price: ', currentPrice)

        await dex.methods.bid(event.returnValues.hash).send({from: accounts[1], value: web3.utils.toWei("0.05", "ether")})
        const currentPrice2 = await dex.methods.getCurrentPrice(event.returnValues.hash).call()

        console.log('current Price: ', currentPrice2)
    
    })
    .on('changed', changed => console.log(changed))
    .on('error', err => {console.log('errrr'); throw err})
    .on('connected', str => console.log(str))

    dex.events.allEvents()
    .on('data', event => console.log(event.event, event.returnValues))
    .on('changed', changed => console.log(changed))
    .on('error', err => {console.log('errrr'); throw err})
    .on('connected', str => console.log(str))

    nft.events.allEvents()
    .on('data', event => console.log(event.event, event.returnValues))
    .on('changed', changed => console.log(changed))
    .on('error', err => {console.log('errrr'); throw err})
    .on('connected', str => console.log(str))
    
}
listen()