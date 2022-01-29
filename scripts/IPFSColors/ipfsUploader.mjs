const require = createRequire(import.meta.url);
const pinataSDK = require('@pinata/sdk')
import { createRequire } from "module";
const pinataCredentials = require('./pinataCredentials.json')

const pinata = pinataSDK(pinataCredentials.APIKey, pinataCredentials.APISecret)

async function uploadToIPFS(sourcePath, name) {
    const options = {
        pinataMetadata: {
            name: name,
        },
        pinataOptions: {
            cidVersion: 0
        }
    };
    try {
        const result = await pinata.pinFromFS(sourcePath, options)
        return result
    }
    catch (err) {
        console.log(err)
    }
}

export default uploadToIPFS


