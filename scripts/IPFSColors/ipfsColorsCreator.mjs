import uploadToIPFS from './ipfsUploader.mjs';
import createColors from './svgColorCreator.mjs';
import createMetadata from './metadataCreator.mjs'


async function ipfsColorCreator () {
    await createColors()
    const ipfs = await uploadToIPFS('./colors', 'colors')
    await createMetadata(ipfs.IpfsHash)
    const metadataIpfs = await uploadToIPFS('./colorsMetadata', 'colorsMetadata')
    console.log(metadataIpfs.IpfsHash)

}

ipfsColorCreator()