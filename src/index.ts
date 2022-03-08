import IERC20METADATA from "./IERC20Metadata_metadata.json";
import OPTHY from "./Opthy_metadata.json";
import OPTHYS from "./Opthys_metadata.json";
import OPTHYSVIEW from "./OpthysView_metadata.json";


export enum ChainId {
    RinkebyTestnet = 4,         //ETH
    GodwokenTestnet = 71393,    //Nervos
}

export const ERC20 = (chainId: ChainId) => {
    let ABI = IERC20METADATA.output.abi;

    if (ChainId.RinkebyTestnet == chainId) {
        return {
            address: new Set([
                "0xc778417E063141139Fce010982780140Aa0cD5Ab",   //WETH
                "0x7af456bf0065aadab2e6bec6dad3731899550b84",   //DAI
                "0x265566d4365d80152515e800ca39424300374a83",   //USDC
                "0x74a3dbd5831f45cd0f3002bb87a59b7c15b1b5e6"    //USDT
            ]),
            ABI: ABI
        }
    }

    if (ChainId.GodwokenTestnet == chainId) {
        return {
            address: new Set([
                "0x034f40c41Bb7D27965623f7bb136CC44D78be5E7",   //ckETH
                "0xC818545C50a0E2568E031Ef9150849b396992880",   //ckDAI
                "0x1b98136005d568B23b7328F279948648992e1fD2",   //ckUSDC
                "0xEabAe0083967F2360848efC65C9c967135e80EE4"    //ckUSDT
            ]),
            ABI: ABI
        }
    }

    throw new Error(`No whitelisted ERC20 found on ${ChainId[chainId]}`)
}


export const OpthyABI = (_chainId: ChainId) => {
    return OPTHY.output.abi;
}


export const Opthys = (chainId: ChainId) => {
    let ABI = OPTHYS.output.abi;

    if (ChainId.RinkebyTestnet == chainId) {
        return {
            address: "0xd23Aaf04FDbd3333e79B20D425CB9bF49928A6A4",
            ABI: ABI
        }
    }

    if (ChainId.GodwokenTestnet == chainId) {
        return {
            address: "0x0000000000000000000000000000000000000000",  //TO BE DEPLOYED...
            ABI: ABI
        }
    }

    throw new Error(`No deployed Opthys contract found on ${ChainId[chainId]}`)
}

export const OpthysView = (chainId: ChainId) => {
    let ABI = OPTHYSVIEW.output.abi;

    if (ChainId.RinkebyTestnet == chainId) {
        return {
            address: "0xC6F559c06606Ff51fd2c2081d2d435670388EEFf",
            ABI: ABI
        }
    }

    if (ChainId.GodwokenTestnet == chainId) {
        return {
            address: "0x0000000000000000000000000000000000000000",  //TO BE DEPLOYED...
            ABI: ABI
        }
    }

    throw new Error(`No deployed OpthysView contract found on ${ChainId[chainId]}`)
}