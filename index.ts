"use strict"

export enum ChainId {
    RinkebyTestnet = 4,
    GodwokenTestnet = 71393,
}

export const opthysAddress = (chainId: number) => {
    if (ChainId.RinkebyTestnet == chainId) {
        return "0x8fCC0Fb16aA03E4dEe6a06643722c11c5826F49B";
    }

    //TO DO...
    // if (ChainId.GodwokenTestnet == chainId) {
    //     return "0x8fCC0Fb16aA03E4dEe6a06643722c11c5826F49B";
    // }

    throw new Error(`No Opthys found on Chain ${chainId}`)
}

export const ERC20Whitelist = (chainId: number) => {
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

    throw new Error(`Chain ID ${chainId} not found`)
}