import fs from 'fs'
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const colors = require('./256-colors.json');



async function createMetadata (ipfsBaseAddress) {
    for (let i = 0; i < colors.length; i++) {
        let metadata = {
            "title": "NFT Color",
            "type": "image",
            "properties": {
                "name": `${colors[i].name}`,
                "description": `Color: ${colors[i].hexString}`,
                "image": `https://ipfs.io/ipfs/${ipfsBaseAddress}/${colors[i].colorId}.svg`
            }
        }
        
        fs.writeFileSync(`./colorsMetadata/${colors[i].colorId}.json`, JSON.stringify(metadata))
    }
}

export default createMetadata
