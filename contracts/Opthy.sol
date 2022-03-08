// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";


//TODO: block.timestamp is potentially unsafe in production as it can manipulated by block miners.
//For low liquidity opthy contracts in practice it can be trusted.
//For high liquidity opthy contracts is best to safeguard it with a time oracle.

contract Opthy is ReentrancyGuard {
    using SafeERC20 for IERC20;
    //swapper is the swapper address and it's always a valid address
    address public swapper;
    //liquidityProvider is the liquidityProvider address and it's always a valid address
    address public liquidityProvider;
    
    //_swapperFeeAmount is the amount of token to pay to become the swapper, zero if not for sale
    uint128 private _swapperFeeAmount;
    //_liquidityProviderFeeAmount is the amount to pay to become the liquidityProvider, zero if not for sale
    uint128 private _liquidityProviderFeeAmount;
    //_isSwapperFeeT1 determines if _swapperFeeAmount is to be paid in token1 or token0
    bool private _isSwapperFeeT1;
    //_isLiquidityProviderFeeT1 determines if _liquidityProviderFeeAmount is to be paid in token1 or token0
    bool private _isLiquidityProviderFeeT1;
    
    //_isFullyFunded is true if and only if the liquidity inequality is satisfied
    bool private _isFullyFunded;
    
    
    //These fields are constant after creation
    
    //expiration contains the timestamp at which the opthy expires
    uint256 public immutable expiration;
    
    //tokens used in the opthy
    //token0 is the token in which the fees are paid and the token that the liquidityProvider deposits
    IERC20 public immutable token0;
    //token1 is the token that the swapper can swap for token0
    IERC20 public immutable token1;
    
    //Inequality for checking that the contract contains at least the liquidityProvider's liquidity:
    // balanceT0 >= rT0 (at agreement)
    // rT1 * balanceT0 + rT0 * balanceT1 >= rT0*rT1 (until expiration)
    // Idea: say the opthy is a put opthy of 1 WETH for 1000DAI, then rT0=1000 and rT1=1
    //       (each value is in its decimals representation, so the same as would be memorized in its ERC20)
    uint128 public immutable rT0;
    uint128 public immutable rT1;

    event Created(address indexed creator, bool iProvideLiquidy, IERC20 feeToken, uint128 feeAmount);
    constructor(
        address creator_,
        bool iProvideLiquidy_,
        uint128 feeAmountT0_,
        uint256 expiration_,
        IERC20 token0_,
        IERC20 token1_,
        uint128 rT0_,
        uint128 rT1_
    ) {
        //This contract is created, registred and funded by Opthys.newOpthy contract method,
        //so all the checks are over there

        swapper = creator_;
        liquidityProvider = creator_;
        
        if (iProvideLiquidy_) {//contract created by liquidityProvider
            _isFullyFunded = true;
            _swapperFeeAmount = feeAmountT0_;
            // _isSwapperFeeT1 = false;
        } else {//contract created by swapper
            // _isFullyFunded = false;
            _liquidityProviderFeeAmount = feeAmountT0_;
            // _isLiquidityProviderFeeT1 = false;
        }
        
        expiration = expiration_;
        token0      =   token0_;
        token1      =   token1_;
        rT0          =   rT0_;
        rT1          =   rT1_;
        
        emit Created(creator_, iProvideLiquidy_, token0_, feeAmountT0_);
    }
    

    //_isToken1 returns:
    // - true if given address is of token1
    // - false if given address is of token0
    // - revert otherwise
    function _isToken1(IERC20 token) private view returns(bool) {
        if (token == token0) {
            return false;
        }

        if (token == token1) {
            return true;
        }
        
        revert("Opthy: unknown Token");
    }

    event SwapperChanged(address indexed newSwapper, IERC20 feeToken, uint128 feeAmount);
    function buySwapperRole(uint128 balanceT0_, uint128 balanceT1_, IERC20 feeToken_, uint128 feeAmount_) external nonReentrant {
        //Opthy contract needs to be still active
        require(_isFullyFunded, "Opthy: not fully funded");//_isFullyFunded := (rT1 * balanceT0 + rT0 * balanceT1 >= rT0*rT1)
        require(block.timestamp < expiration, "Opthy: expired");

        require(_swapperFeeAmount > 0, "Opthy: not for sale");
        require(feeAmount_ == _swapperFeeAmount && _isToken1(feeToken_) == _isSwapperFeeT1, "Opthy: fee mismatch");
        
        (uint256 balanceT0, uint256 balanceT1) = balance();
        require(balanceT0_ == balanceT0 && balanceT1_ == balanceT1, "Opthy: balance mismatch");
        
        feeToken_.safeTransferFrom(msg.sender, swapper, feeAmount_);
        
        swapper = msg.sender;
        _swapperFeeAmount = 0;

        emit SwapperChanged(msg.sender, feeToken_, feeAmount_);
    }
    
    event LiquidityProviderChanged(address indexed newLiquidityProvider, IERC20 feeToken, uint128 feeAmount);
    function buyLiquidityProviderRole(IERC20 feeToken_, uint128 feeAmount_) external nonReentrant {
        require(block.timestamp < expiration, "Opthy: expired");
        
        require(_liquidityProviderFeeAmount > 0, "Opthy: not for sale");
        require(feeAmount_ == _liquidityProviderFeeAmount && _isToken1(feeToken_) == _isLiquidityProviderFeeT1, "Opthy: fee mismatch");
        
        if (_isFullyFunded) {// This contract is already active
            feeToken_.safeTransferFrom(msg.sender, liquidityProvider, feeAmount_);
        } else {
            //This contract has been created by the swapper, so its balance only contains 
            // the fee from the swapper to the liquidity provider. So this method has been called 
            // by the aspiring liquidity provider to add the remaining liquidity for activating the contract.
            feeToken_.safeTransferFrom(msg.sender, address(this), feeAmount_);
            require(rT0 <= token0.balanceOf(address(this)), "Opthy: insufficient liquidity");
            _isFullyFunded = true;
        }
        
        liquidityProvider = msg.sender;
        _liquidityProviderFeeAmount = 0;

        emit LiquidityProviderChanged(msg.sender, feeToken_, feeAmount_);
    }

    event SwapperFeeChanged(address indexed swapper, IERC20 newFeeToken, uint128 newFeeAmount);
    function setSwapperFee(IERC20 feeToken_, uint128 feeAmount_) external {
        require(msg.sender == swapper, "Opthy: unauthorized access");

        //Opthy contract needs to be still active
        require(_isFullyFunded, "Opthy: not fully funded");//_isFullyFunded := (rT1 * balanceT0 + rT0 * balanceT1 >= rT0*rT1)
        require(block.timestamp < expiration, "Opthy: expired");
        
        _isSwapperFeeT1 = _isToken1(feeToken_);
        _swapperFeeAmount = feeAmount_;

        require(_isSwapperFeeT1? feeAmount_<= rT1 : feeAmount_<= rT0, "Opthy: fee too big");

        emit SwapperFeeChanged(swapper, feeToken_, feeAmount_);
    }
    
    event LiquidityProviderFeeChanged(address indexed liquidityProvider, IERC20 newFeeToken, uint128 newFeeAmount);
    function setLiquidityProviderFee(IERC20 feeToken_, uint128 feeAmount_) external {
        require(msg.sender == liquidityProvider, "Opthy: unauthorized access");

        //Opthy contract needs to be still active
        require(_isFullyFunded, "Opthy: not fully funded");//_isFullyFunded := (rT1 * balanceT0 + rT0 * balanceT1 >= rT0*rT1)
        require(block.timestamp < expiration, "Opthy: expired");

        _isLiquidityProviderFeeT1 = _isToken1(feeToken_);
        _liquidityProviderFeeAmount = feeAmount_;

        require(_isLiquidityProviderFeeT1? feeAmount_<= rT1 : feeAmount_<= rT0, "Opthy: fee too big");

        emit LiquidityProviderFeeChanged(liquidityProvider, feeToken_, feeAmount_);
    }

    function getSwapperFee() external view returns(IERC20 feeToken_, uint128 feeAmount_) {
        return (_isSwapperFeeT1?token1:token0, _swapperFeeAmount);
    }  

    function getLiquidityProviderFee() external view returns(IERC20 feeToken_, uint128 feeAmount_) {
        return (_isLiquidityProviderFeeT1?token1:token0, _liquidityProviderFeeAmount);
    }  

    
    event Swapped(address indexed swapper, uint128 inAmountT0, uint128 inAmountT1, uint128 outAmountT0, uint128 outAmountT1);
    function swap(
        uint128 inAmountT0_,
        uint128 inAmountT1_,
        uint128 outAmountT0_,
        uint128 outAmountT1_
        ) external nonReentrant {
        require(msg.sender == swapper, "Opthy: unauthorized access");

        //Opthy contract needs to be still active
        require(_isFullyFunded, "Opthy: not fully funded");//_isFullyFunded := (rT1 * balanceT0 + rT0 * balanceT1 >= rT0*rT1)
        require(block.timestamp < expiration, "Opthy: expired");
        
        //Transfer inputs
        if (inAmountT0_ > 0) {
            token0.safeTransferFrom(msg.sender, address(this), inAmountT0_);
        }
        if (inAmountT1_ > 0) {
            token1.safeTransferFrom(msg.sender, address(this), inAmountT1_);
        }
        
        //Transfer outputs
        if (outAmountT0_ > 0) {
            token0.safeTransfer(swapper, outAmountT0_);    
        }
        if (outAmountT1_ > 0) {
            token1.safeTransfer(swapper, outAmountT1_);
        }
        
        //Check if there is at least the liquidityProvider's liquidity
        (uint256 balanceT0, uint256 balanceT1) = balance();
        require(
            rT0 <= balanceT0 || 
            rT1 <= balanceT1 || 
            rT1 * balanceT0 + rT0 * balanceT1 >= uint256(rT0)*uint256(rT1),
            "Opthy: insufficient liquidity"
        );

        emit Swapped(swapper, inAmountT0_, inAmountT1_, outAmountT0_, outAmountT1_);
    }
    
           
    event Reclaimed(address indexed liquidityProvider, uint256 balanceT0, uint256 balanceT1);
    function reclaim() external nonReentrant {
        require(msg.sender == liquidityProvider, "Opthy: unauthorized access");
        require(msg.sender == swapper || expiration <= block.timestamp, "Opthy: still active");
        
        (uint256 balanceT0, uint256 balanceT1) = balance();
        
        if (balanceT0 > 0) {
            token0.safeTransfer(liquidityProvider, balanceT0);
        }
        
        if (balanceT1 > 0) {
            token1.safeTransfer(liquidityProvider, balanceT1);
        }
        
        _swapperFeeAmount = 0;
        _liquidityProviderFeeAmount = 0;
        _isFullyFunded = false;
        
        emit Reclaimed(liquidityProvider, balanceT0, balanceT1);
    }
    
    
    function balance() public view returns(uint256,uint256) {
        return (token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }    
}