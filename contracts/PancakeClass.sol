// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./PancakeInterfaces/IPancakeRouter02.sol";
import "./PancakeInterfaces/IPancakeFactory.sol";
import "./PancakeInterfaces/IPancakePair.sol";

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
        (uint256 _amountSafeMars, uint256 _amountBUSD) = _removeLiquidity(usrBal.balanceLP);
        uint256 out = _sellXGetY(tokenBUSD, tokenSafeMars, _amountBUSD);
        usrBal.balanceBUSD = 0;
        usrBal.balanceSafeMars = 0;
        usrBal.balanceLP = 0;
        out = out.add(_amountSafeMars);
        IERC20(tokenSafeMars).transfer(account, out);
    }

    function convertBUSDToSafeMars(uint256 _amountIn) internal returns(uint256 amountOut) {
        return _sellXGetY(tokenBUSD, tokenSafeMars, _amountIn);
    }

    function convertSafeMarsToBUSD(uint256 _amountIn) internal returns(uint256 amountOut) {
        return _sellXGetY(tokenSafeMars, tokenBUSD, _amountIn);
    }

    function _addLiquidity(uint256 _amountSafeMars, uint256 _amountBUSD, address account) private {
        IERC20(tokenSafeMars).approve(address(router), _amountSafeMars);
        IERC20(tokenBUSD).approve(address(router), _amountBUSD);

        uint256 bal = IERC20(_getPairAddress()).balanceOf(address(this));
        router.addLiquidity(
            tokenSafeMars, 
            tokenBUSD, 
            _amountSafeMars, 
            _amountBUSD, 
            0, 
            0, 
            address(this), 
            block.timestamp + 360
        );
        uint256 bal2 = IERC20(_getPairAddress()).balanceOf(address(this));
        uint256 _liquidity = bal2.sub(bal);

        UserBalance storage usrBal = allUserBalance[account];
        usrBal.balanceLP = (usrBal.balanceLP).add(_liquidity);
    }

    function _removeLiquidity(uint256 _liquidity) private returns(uint256 _amountSafeMars, uint256 _amountBUSD) {
        IERC20(_getPairAddress()).approve(address(router), _liquidity);
        uint256 balY = IERC20(tokenSafeMars).balanceOf(address(this));
        (, _amountBUSD) = router.removeLiquidity(
            tokenSafeMars, 
            tokenBUSD, 
            _liquidity, 
            0, 
            0, 
            address(this), 
            block.timestamp + 360
        );
        uint256 balY2 = IERC20(tokenSafeMars).balanceOf(address(this));
        _amountSafeMars = balY2.sub(balY);
    }

    function _sellXGetY(address _tokenXAddress, address _tokenYAddress, uint256 _amountXIn) private returns(uint256 _amountYOut) {
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
        uint256 balY2 = IERC20(_tokenYAddress).balanceOf(address(this));
        _amountYOut = balY2.sub(balY);
    }

    function _getPairAddress() private view returns(address) {
        IPancakeFactory factory = IPancakeFactory(router.factory());
        IPancakePair pair = IPancakePair(factory.getPair(tokenSafeMars, tokenBUSD));
        return address(pair);
    }

    function _isSafeMarsTokenA() private view returns(bool) {
        return (tokenSafeMars < tokenBUSD) ? true : false;
    }

}