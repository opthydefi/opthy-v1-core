// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./Opthys.sol";

contract OpthysView {
    Opthys private immutable opthys;

    constructor(Opthys opthys_) {
        opthys = opthys_;
    }

    struct opthy {
        address opthy;

        address swapper;
        IERC20 swapperFeeToken;
        uint128 swapperFeeAmount;

        address liquidityProvider;
        IERC20 liquidityProviderFeeToken;
        uint128 liquidityProviderFeeAmount;
                
        uint256 expiration;
        
        IERC20  token0;
        IERC20  token1;
        
        uint256 balanceT0;
        uint256 balanceT1;

        uint128 rT0;
        uint128 rT1;
    }
    
    function all() external view returns(opthy[] memory) {
        uint256 opthysLength = opthys.length();
        opthy[] memory result = new opthy[](opthysLength);
        
        for (uint i=0; i<opthysLength; i++) {
            Opthy o = opthys.get(i);
            
            (IERC20 swapperFeeToken, uint128 swapperFeeAmount) = o.getSwapperFee();
            (IERC20 liquidityProviderFeeToken, uint128 liquidityProviderFeeAmount) = o.getLiquidityProviderFee();

            (uint256 balanceT0, uint256 balanceT1) = o.balance();

            result[i] = opthy(
                address(o),
                o.swapper(),
                swapperFeeToken,
                swapperFeeAmount,
                o.liquidityProvider(),
                liquidityProviderFeeToken,
                liquidityProviderFeeAmount,
                o.expiration(),
                o.token0(),
                o.token1(),
                balanceT0,
                balanceT1,
                o.rT0(),
                o.rT1()
            );
        }
    
        return result;
    }

}