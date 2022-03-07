"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var IERC20Metadata_metadata_json_1 = __importDefault(require("./IERC20Metadata_metadata.json"));
var Opthy_metadata_json_1 = __importDefault(require("./Opthy_metadata.json"));
var Opthys_metadata_json_1 = __importDefault(require("./Opthys_metadata.json"));
var ChainId;
(function (ChainId) {
    ChainId[ChainId["RinkebyTestnet"] = 4] = "RinkebyTestnet";
    ChainId[ChainId["GodwokenTestnet"] = 71393] = "GodwokenTestnet";
})(ChainId = exports.ChainId || (exports.ChainId = {}));
exports.opthysAddress = function (chainId) {
    if (ChainId.RinkebyTestnet == chainId) {
        return "0x8fCC0Fb16aA03E4dEe6a06643722c11c5826F49B";
    }
    if (ChainId.GodwokenTestnet == chainId) {
        return "0x0000000000000000000000000000000000000000"; //TO DO...
    }
    throw new Error("No deployed Opthys contract found on " + ChainId[chainId]);
};
exports.ERC20Whitelist = function (chainId) {
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
var Contracts;
(function (Contracts) {
    Contracts[Contracts["IERC20Metadata"] = 0] = "IERC20Metadata";
    Contracts[Contracts["Opthy"] = 1] = "Opthy";
    Contracts[Contracts["Opthys"] = 2] = "Opthys";
})(Contracts = exports.Contracts || (exports.Contracts = {}));
exports.contract2ABI = function (contract) {
    if (Contracts.IERC20Metadata == contract) {
        return IERC20Metadata_metadata_json_1.default.output.abi;
    }
    if (Contracts.Opthy == contract) {
        return Opthy_metadata_json_1.default.output.abi;
    }
    if (Contracts.Opthys == contract) {
        return Opthys_metadata_json_1.default.output.abi;
    }
    throw new Error("Contract name " + Contracts[contract] + " not found");
};
