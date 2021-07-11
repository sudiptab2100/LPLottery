const util = require('util')
const exec = util.promisify(require('child_process').exec)


const contractName = "LPLottery"
const contractAddress = "0x17494Dc0fE220398AdDe344bF39ECE21662ed5C1"
const network = "testnet"

const verify = async (_contractName, _contractAddress, _network) => {
    console.log("\nVerifying ...")
    console.log('Contract:', _contractName)
    console.log('Address:', _contractAddress)
    console.log('Network:', _network)

    const { stdout, stderr } = await exec(`truffle run verify ${_contractName}@${_contractAddress} --network ${_network}`)
    if(stderr != null) {
        console.log(stdout)
    } else {
        console.log('stderr:', stderr)
    }
}

verify(contractName, contractAddress, network)