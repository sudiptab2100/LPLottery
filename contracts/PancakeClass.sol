// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PancakeInterfaces/IPancakeRouter02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PancakeClass is ReentrancyGuard {
    using SafeMath for uint256;

    IPancakeRouter02 public router;
    address public tokenSafeMars;
    address public tokenBUSD;

    struct UserBalance {
        uint256 balanceSafeMars;
        uint256 balanceBUSD;
        uint256 balanceLP;
    } mapping(address => UserBalance) internal allUserBalance;

    constructor(
        address _routerAddres,
        address _tokenSafeMars,
        address _tokenBUSD
    ) {
        router = IPancakeRouter02(_routerAddres);
        tokenSafeMars = _tokenSafeMars;
        tokenBUSD = _tokenBUSD;
    }

    function stakeInSafeMars(uint256 amount, address account) internal {
        uint256 oneHalf = amount.div(2);
        uint256 anoterHalf = amount.sub(oneHalf);
        uint256 tokensGet = _sellXGetY(tokenSafeMars, tokenBUSD, anoterHalf);

        _addLiquidity(oneHalf, tokensGet, account);
    }

    function stakeInBUSD(uint256 amount, address account) internal {
        uint256 oneHalf = amount.div(2);
        uint256 anoterHalf = amount.sub(oneHalf);
        uint256 tokensGet = _sellXGetY(tokenBUSD, tokenSafeMars, anoterHalf);

        _addLiquidity(tokensGet, oneHalf, account);
    }

    function unstakeAllToSafeMars(address account) internal {
        UserBalance storage usrBal = allUserBalance[account];
        _removeLiquidity(usrBal.balanceLP, account);
        uint256 out = _sellXGetY(tokenBUSD, tokenSafeMars, usrBal.balanceBUSD);
        usrBal.balanceBUSD = 0;
        usrBal.balanceSafeMars = 0;
        out = out.add(usrBal.balanceSafeMars);
        IERC20(tokenSafeMars).transfer(account, out);
    }

    function _addLiquidity(uint256 _amountSafeMars, uint256 _amountBUSD, address account) private {
        IERC20(tokenSafeMars).approve(address(router), _amountSafeMars);
        IERC20(tokenBUSD).approve(address(router), _amountBUSD);

        (uint256 amountA, uint256 amountB, uint256 _liquidity) = router.addLiquidity(
            tokenSafeMars, 
            tokenBUSD, 
            _amountSafeMars, 
            _amountBUSD, 
            0, 
            0, 
            address(this), 
            block.timestamp + 360
        );
        
        uint256 leftSafeMars; 
        uint256 leftBUSD;
        if(_isSafeMarsTokenA()) {
            (leftSafeMars, leftBUSD) = (_amountSafeMars.sub(amountA), _amountBUSD.sub(amountB));
        } else {
            (leftSafeMars, leftBUSD) = (_amountSafeMars.sub(amountB), _amountBUSD.sub(amountA));
        }
        UserBalance storage usrBal = allUserBalance[account];
        usrBal.balanceSafeMars = (usrBal.balanceSafeMars).add(leftSafeMars);
        usrBal.balanceBUSD = (usrBal.balanceBUSD).add(leftBUSD);
        usrBal.balanceLP = (usrBal.balanceLP).add(_liquidity);
    }

    function _removeLiquidity(uint256 _liquidity, address account) private {
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            tokenSafeMars, 
            tokenBUSD, 
            _liquidity, 
            0, 
            0, 
            address(this), 
            block.timestamp + 360
        );
        UserBalance storage usrBal = allUserBalance[account];
        if(_isSafeMarsTokenA()) {
            usrBal.balanceSafeMars = (usrBal.balanceSafeMars).add(amountA);
            usrBal.balanceBUSD = (usrBal.balanceBUSD).add(amountB);
        } else {
            usrBal.balanceSafeMars = (usrBal.balanceSafeMars).add(amountB);
            usrBal.balanceBUSD = (usrBal.balanceBUSD).add(amountA);
        }
        usrBal.balanceLP = (usrBal.balanceLP).sub(_liquidity);
    }

    function _sellXGetY(address _tokenXAddress, address _tokenYAddress, uint256 _amountXIn) private nonReentrant returns(uint256 _amountYOut) {
        IERC20(_tokenXAddress).approve(address(router), _amountXIn);

        address[] memory path = new address[](2);
        path[0] = _tokenXAddress;
        path[1] = _tokenYAddress;

        uint256 balY = IERC20(_tokenYAddress).balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountXIn,
            0,
            path,
            address(this),
            block.timestamp + 60
        );
        _amountYOut = (IERC20(_tokenYAddress).balanceOf(address(this))).sub(balY);
    }

    function _isSafeMarsTokenA() private view returns(bool) {
        return (tokenSafeMars < tokenBUSD) ? true : false;
    }

}