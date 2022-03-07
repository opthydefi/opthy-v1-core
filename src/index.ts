import IERC20METADATA from "./IERC20Metadata_metadata.json";
import OPTHY from "./Opthy_metadata.json";
import OPTHYS from "./Opthys_metadata.json";


export enum ChainId {
    RinkebyTestnet = 4,
    GodwokenTestnet = 71393,
}


export const opthysAddress = (chainId: ChainId): string => {
    if (ChainId.RinkebyTestnet == chainId) {
        return "0x8fCC0Fb16aA03E4dEe6a06643722c11c5826F49B";
    }


    if (ChainId.GodwokenTestnet == chainId) {
        return "0x0000000000000000000000000000000000000000";//TO DO...
    }

    throw new Error(`No deployed Opthys contract found on ${ChainId[chainId]}`)
}


export const ERC20Whitelist = (chainId: ChainId) => {
    if (ChainId.RinkebyTestnet == chainId) {
        return new Set([])//TO DO...
    }

    if (ChainId.GodwokenTestnet == chainId) {
        return new Set([
            "0x034f40c41Bb7D27965623f7bb136CC44D78be5E7", // ckETH
            "0xC818545C50a0E2568E031Ef9150849b396992880", // ckDAI
            "0x1b98136005d568B23b7328F279948648992e1fD2", // ckUSDC
            "0xEabAe0083967F2360848efC65C9c967135e80EE4", // ckUSDT
        ])
    }

    throw new Error(`No whitelisted ERC20 found on ${ChainId[chainId]}`)
}


export enum Contracts {
    IERC20Metadata,
    Opthy,
    Opthys
}


export const contract2ABI = (contract: Contracts) => {
    if (Contracts.IERC20Metadata == contract) {
        return IERC20METADATA.output.abi;
    }

    if (Contracts.Opthy == contract) {
        return OPTHY.output.abi;
    }

    if (Contracts.Opthys == contract) {
        return OPTHYS.output.abi;
    }

    throw new Error(`Contract name ${Contracts[contract]} not found`)
}