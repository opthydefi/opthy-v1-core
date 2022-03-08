// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";
import "./Opthy.sol";

//TODO: block.timestamp is potentially unsafe in production as it can manipulated by block miners.
//For low liquidity opthy contracts in practice it can be trusted.
//For high liquidity opthy contracts is best to safeguard it with a time oracle.

//Opthys is the registry of all Opthy contracts
contract Opthys is ReentrancyGuard,Ownable,Pausable {
    using SafeERC20 for IERC20;

    Opthy[] private opthys;
    
    mapping(IERC20 => tokenRule) private _tokenRules;
    
    struct tokenRule {
        uint128 min;
        uint128 max;
    }

    event OpthyCreated(address indexed opthy);
    function createNewOpthy(
        bool iProvideLiquidy_,
        uint128 feeAmountT0_,
        uint256 expiration_,
        IERC20 token0_,
        IERC20 token1_,
        uint128 rT0_,
        uint128 rT1_,
        uint128 fundingAmountT0_
    ) external nonReentrant whenNotPaused returns(Opthy) {
        require(block.timestamp < expiration_,"Opthys: already expired");


        (uint256 minT0, uint256 maxT0) = tokenRules(token0_);
        (uint256 minT1, uint256 maxT1) = tokenRules(token1_);

        require(maxT0 > 0 && maxT1 > 0, "Opthys: token not whitelisted");

        require(
            0 < feeAmountT0_          &&   feeAmountT0_ <= rT0_ &&
            minT0 <= fundingAmountT0_ &&   fundingAmountT0_ <= rT0_ &&
          /*minT0 <= rT0_             &&*/ rT0_ <= maxT0 && //check not needed as implied by previous checks
            minT1 <= rT1_             &&   rT1_ <= maxT1,
            "Opthys: invalid quantity"
        );

        Opthy o = new Opthy(msg.sender, iProvideLiquidy_, feeAmountT0_, expiration_, token0_, token1_, rT0_, rT1_);
        opthys.push(o);
        
        token0_.safeTransferFrom(msg.sender, address(o), fundingAmountT0_);
        
        (uint256 balanceT0, uint256 balanceT1) = o.balance();
        require(balanceT0 != balanceT1,"Opthys: same token");
        require(iProvideLiquidy_? rT0_ == balanceT0 : rT0_ == balanceT0+feeAmountT0_,"Opthys: invalid liquidity");
    
        emit OpthyCreated(address(o));
        
        return o;
    }
    
    function setTokenRule(IERC20 token_, uint128 min_, uint128 max_) onlyOwner external {
        //this call will bubble up an exception if balanceOf method doesn't exist
        token_.balanceOf(address(this));
        _tokenRules[token_] = tokenRule(min_,max_);
    }

    function tokenRules(IERC20 token) public view returns (uint128 min, uint128 max) {
        tokenRule memory tr = _tokenRules[token];
        return (tr.min, tr.max);
    }
    
    function pause() onlyOwner external {
        _pause();
    }

    function unpause() onlyOwner external {
        _unpause();
    }

    function get(uint256 i) external view returns (Opthy) {
        return opthys[i];
    }

    function length() external view returns (uint256) {
        return opthys.length;
    }
}