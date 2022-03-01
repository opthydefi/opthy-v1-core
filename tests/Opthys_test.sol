// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

// Run these tests with 'Solidity Unit Testing' plugin
// https://remix-ide.readthedocs.io/en/latest/unittesting.html
import "remix_tests.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "../contracts/Opthys.sol";
import "./Utils.sol";


contract Opthys_CreateNewOpthy {
    using SafeERC20 for IERC20;

    Opthys opthys;
    IERC20 token0_;
    IERC20 token1_;
    Forwarder user;

    // declare createNewOpthy default parameters
    bool iProvideLiquidy;
    uint128 feeAmountT0;
    uint256 expiration;
    IERC20 token0;
    IERC20 token1;
    uint128 rT0;
    uint128 rT1;
    uint128 fundingAmountT0;

    string referenceMessage;

    function beforeAll() public {
        opthys = new Opthys();
        token0_ = new testERC20("token0","token0");
        token1_ = new testERC20("token1","token1");

        //Whitelist tokens in opthy
        opthys.setTokenRule(token0_, type(uint8).max, type(uint64).max);       
        opthys.setTokenRule(token1_, type(uint8).max, type(uint64).max);

        //Fund and approve token0 for usage by user
        user = new Forwarder();
        token0_.safeTransfer(address(user), type(uint256).max);
        IERC20(user.to(address(token0_))).safeApprove(address(opthys),type(uint256).max);
    }

    function beforeEach() public {
        // (re)initialize createNewOpthy parameters as a liquidity provider role
        iProvideLiquidy = true;
        feeAmountT0 = type(uint64).max >> 1;
        expiration = type(uint256).max;
        token0 = token0_;
        token1 = token1_;
        rT0 = type(uint64).max;
        rT1 = type(uint32).max;
        fundingAmountT0 = rT0;

        //The method should raise no exception
        referenceMessage = "";
    }

    function createNewOpthy() public {
        Opthy opthy = Opthys(user.to(address(opthys))).createNewOpthy(
            iProvideLiquidy,
            feeAmountT0,
            expiration,
            token0,
            token1,
            rT0,
            rT1,
            fundingAmountT0
        );

        Assert.equal(opthy.swapper(), address(user), "Swapper mismatch");
        Assert.equal(opthy.liquidityProvider(), address(user), "Liquidity Provider mismatch");
        Assert.equal(opthy.expiration(), expiration, "Expiration mismatch");
        Assert.equal(address(opthy.token0()), address(token0), "Token0 mismatch");
        Assert.equal(address(opthy.token1()), address(token1), "Token1 mismatch");
        Assert.equal(opthy.rT0(), rT0, "RT0 mismatch");
        Assert.equal(opthy.rT1(), rT1, "RT1 mismatch");

        (IERC20 feeToken, uint128 feeAmount) = opthy.getSwapperFee();
        Assert.equal(address(feeToken), address(token0), "Swapper fee token mismatch");
        Assert.equal(feeAmount, iProvideLiquidy?feeAmountT0:0, "Swapper fee amount mismatch");

        (feeToken, feeAmount) = opthy.getLiquidityProviderFee();
        Assert.equal(address(feeToken), address(token0), "Liquidity Provider fee token mismatch");
        Assert.equal(feeAmount, iProvideLiquidy?0:feeAmountT0, "Liquidity Provider fee amount mismatch");

        (uint256 b0, uint256 b1) = opthy.balance();
        Assert.equal(b0, fundingAmountT0, "Opthy balance in token0 mismatch");
        Assert.equal(b1, 0, "Opthy balance in token1 mismatch");
    }

    function createNewOpthyAsSwapper() public {
        iProvideLiquidy = false;
        fundingAmountT0 = feeAmountT0;
        feeAmountT0 = rT0 - feeAmountT0;
        createNewOpthy();
    }

    function CreateDoomedOpthy() private {
        try Opthys(user.to(address(opthys))).createNewOpthy(
            iProvideLiquidy,
            feeAmountT0,
            expiration,
            token0,
            token1,
            rT0,
            rT1,
            fundingAmountT0
        ) {
            Assert.ok(false, "Must raise an exception");
        } catch Error(string memory message) {
            Assert.equal(message, referenceMessage, "Exception mismatch");          
        }
    }    

    function blockExpired() public {
        expiration = block.timestamp;
        referenceMessage = "Opthys: already expired";
        CreateDoomedOpthy();
    }

    function blockToken0NotWhitelisted() public {
        token0 = IERC20(address(0));
        referenceMessage = "Opthys: token not whitelisted";
        CreateDoomedOpthy();
    }

    function blockToken1NotWhitelisted() public {
        token1 = IERC20(address(0));
        referenceMessage = "Opthys: token not whitelisted";
        CreateDoomedOpthy();
    }

    function blockZeroFeeAmount() public {
        feeAmountT0 = 0;
        referenceMessage = "Opthys: invalid quantity";
        CreateDoomedOpthy();
    }

    function blockBigFeeAmount() public {
        feeAmountT0 = rT0 + 1;
        referenceMessage = "Opthys: invalid quantity";
        CreateDoomedOpthy();
    }

    function blockSmallFundingAmount() public {
        fundingAmountT0 = 1; 
        referenceMessage = "Opthys: invalid quantity";
        CreateDoomedOpthy();
    }

    function blockBigFundingAmount() public {
        fundingAmountT0 = rT0 + 1;
        referenceMessage = "Opthys: invalid quantity";
        CreateDoomedOpthy();
    }

    function blockSmallRt0() public {
        (uint128 minT0, uint128 maxT0) = opthys.tokenRules(token0);
        rT0 = minT0 - 1; 
        referenceMessage = "Opthys: invalid quantity";
        CreateDoomedOpthy();
    }

    function blockBigRt0() public {
        (uint128 minT0, uint128 maxT0) = opthys.tokenRules(token0);
        rT0 = maxT0 + 1; 
        referenceMessage = "Opthys: invalid quantity";
        CreateDoomedOpthy();
    }

    function blockSmallRt1() public {
        (uint128 minT1, uint128 maxT1) = opthys.tokenRules(token1);
        rT1 = minT1 - 1; 
        referenceMessage = "Opthys: invalid quantity";
        CreateDoomedOpthy();
    }

    function blockBigRt1() public {
        (uint128 minT1, uint128 maxT1) = opthys.tokenRules(token1);
        rT1 = maxT1 + 1; 
        referenceMessage = "Opthys: invalid quantity";
        CreateDoomedOpthy();
    }

    function blockBothSameToken() public {
        token1 = token0;        
        referenceMessage = "Opthys: same token";
        CreateDoomedOpthy();
    }

    function blockInvalidLiquidityAsLiquidityProvider() public {
        fundingAmountT0--;
        referenceMessage = "Opthys: invalid liquidity";
        CreateDoomedOpthy();
    }

    function blockInvalidLiquidityAsSwapper() public {
        iProvideLiquidy = false;
        fundingAmountT0 = feeAmountT0;
        feeAmountT0 = rT0 - feeAmountT0 - 1;
        referenceMessage = "Opthys: invalid liquidity";
        CreateDoomedOpthy();
    }

    function blockUnapprovedFromLiquidityProvider() public {
        token0 = token1_;
        token1 = token0_;
        referenceMessage = "ERC20: insufficient allowance";
        CreateDoomedOpthy();
    }

    function blockUnapprovedFromSwapper() public {
        token0 = token1_;
        token1 = token0_;
        iProvideLiquidy = false;
        fundingAmountT0 = feeAmountT0;
        feeAmountT0 = rT0 - feeAmountT0;
        referenceMessage = "ERC20: insufficient allowance";
        CreateDoomedOpthy();
    }
}



contract Opthys_TokenRules {
    Opthys opthys;
    Forwarder user;
    IERC20 token;

    function beforeEach() public {
        opthys = new Opthys();
        user = new Forwarder();
        token = new testERC20("token","token");
    }

    function noRuleForToken() public {
        // (uint min, uint max) = opthys.tokenRules(token);
        (uint min, uint max) = Opthys(user.to(address(opthys))).tokenRules(token);
        Assert.equal(min, 0, "min should be equal to 0");
        Assert.equal(max, 0, "max should be equal to 0");
    }

    function setTokenRule() public {
        opthys.setTokenRule(token, 42, 666);
        (uint128 min, uint128 max) = Opthys(user.to(address(opthys))).tokenRules(token);
        Assert.equal(min, 42, "min should be equal to 42");
        Assert.equal(max, 666, "max should be equal to 666");
    }

    function overwriteTokenRule() public {
        opthys.setTokenRule(token, 1, 10);
        setTokenRule();
    }

    function resetTokenRule() public {
        opthys.setTokenRule(token, 1, 10);
        opthys.setTokenRule(token, 0, 0);
        noRuleForToken();
    }

    function blockUnauthorizedSetTokenRule() public {
        try Opthys(user.to(address(opthys))).setTokenRule(token, 42, 666) {
            Assert.ok(false, "Must raise an exception");
        } catch Error(string memory message) {
            Assert.equal(message, "Ownable: caller is not the owner", "Exception mismatch");
        }
    }
}



contract Opthys_Pause {
    Opthys opthys;
    Forwarder user;

    function beforeEach() public {
        opthys = new Opthys();
        user = new Forwarder();
    }

    function pause() public {
        opthys.pause();
        Assert.ok(opthys.paused(), "Unpaused but should be paused");
    }

    function unpause() public {
        opthys.pause();
        opthys.unpause();
        Assert.ok(!opthys.paused(), "Paused but should be unpaused");
    }

    function blockUnauthorizedPause() public {
        try Opthys(user.to(address(opthys))).pause() {
            Assert.ok(false, "Must raise an exception");
        } catch Error(string memory message) {
            Assert.equal(message, "Ownable: caller is not the owner", "Exception mismatch");
        }
    }

    function blockUnauthorizedUnpause() public {
        try Opthys(user.to(address(opthys))).unpause() {
            Assert.ok(false, "Must raise an exception");
        } catch Error(string memory message) {
            Assert.equal(message, "Ownable: caller is not the owner", "Exception mismatch");
        }
    }

    function blockCreatenewopthyWhilePaused() public {
        opthys.pause();
        try Opthys(user.to(address(opthys))).createNewOpthy(false,0,0,IERC20(address(0)),IERC20(address(0)),0,0,0) {
            Assert.ok(false, "Must raise an exception");
        } catch Error(string memory message) {
            Assert.equal(message, "Pausable: paused", "Exception mismatch");
        }
    }
}