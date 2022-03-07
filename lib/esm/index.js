import IERC20METADATA from "./IERC20Metadata_metadata.json";
import OPTHY from "./Opthy_metadata.json";
import OPTHYS from "./Opthys_metadata.json";
export var ChainId;
(function (ChainId) {
    ChainId[ChainId["RinkebyTestnet"] = 4] = "RinkebyTestnet";
    ChainId[ChainId["GodwokenTestnet"] = 71393] = "GodwokenTestnet";
})(ChainId || (ChainId = {}));
export var opthysAddress = function (chainId) {
    if (ChainId.RinkebyTestnet == chainId) {
        return "0x8fCC0Fb16aA03E4dEe6a06643722c11c5826F49B";
    }
    if (ChainId.GodwokenTestnet == chainId) {
        return "0x0000000000000000000000000000000000000000"; //TO DO...
    }
    throw new Error("No deployed Opthys contract found on " + ChainId[chainId]);
};
export var ERC20Whitelist = function (chainId) {
    if (ChainId.RinkebyTestnet == chainId) {
        return new Set([]); //TO DO...
    }
    if (ChainId.GodwokenTestnet == chainId) {
        return new Set([
            "0x034f40c41Bb7D27965623f7bb136CC44D78be5E7",
            "0xC818545C50a0E2568E031Ef9150849b396992880",
            "0x1b98136005d568B23b7328F279948648992e1fD2",
            "0xEabAe0083967F2360848efC65C9c967135e80EE4",
        ]);
    }
    throw new Error("No whitelisted ERC20 found on " + ChainId[chainId]);
};
export var Contracts;
(function (Contracts) {
    Contracts[Contracts["IERC20Metadata"] = 0] = "IERC20Metadata";
    Contracts[Contracts["Opthy"] = 1] = "Opthy";
    Contracts[Contracts["Opthys"] = 2] = "Opthys";
})(Contracts || (Contracts = {}));
export var contract2ABI = function (contract) {
    if (Contracts.IERC20Metadata == contract) {
        return IERC20METADATA.output.abi;
    }
    if (Contracts.Opthy == contract) {
        return OPTHY.output.abi;
    }
    if (Contracts.Opthys == contract) {
        return OPTHYS.output.abi;
    }
    throw new Error("Missing ABI for Contract " + Contracts[contract]);
};
