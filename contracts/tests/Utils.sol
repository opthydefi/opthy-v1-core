// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract testERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_,symbol_) {
        _mint(msg.sender,type(uint256).max);
    }
}

contract Forwarder {
    //_baseContract is meant to be ephemeral: for every call to a _baseContract method via fallback
    // there must have been a corresponding call to the 'to' method. The idea is to use a call as such:
    // (a,b,c) = BaseContract(forwarder.to(address(baseContract))).baseContractMethod(d,e,f);
    address private _baseContract;
    uint256 private _blockNumber;
    
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function to(address baseContract_) external returns(address) {
        require(msg.sender == _owner, "Forwarder: unauthorized access");

        _baseContract = baseContract_;
        _blockNumber = block.number;

        return address(this);
    }

    fallback (bytes calldata _input) external returns (bytes memory _output) {
        require(msg.sender == _owner, "Forwarder: unauthorized access");
        require(_baseContract != address(0) && block.number == _blockNumber, "Forwarder: stale base contract");
        
        bool success;

        (success, _output) = _baseContract.call(_input);
    
        if (!success && _output.length >= 68) {
            assembly {
                _output := add(_output, 0x04)
                }
            revert(abi.decode(_output, (string)));
        }

        if (!success) {
            revert();
        }

        return _output;
    }
}