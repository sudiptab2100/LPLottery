// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PancakeClass.sol";
import "./Lottery.sol";

contract LpLottery is PancakeClass {
    address private admin;
    uint256 private lotteryId;
    mapping(uint256 => Lottery) public lotteryStructs;
    mapping(uint256 => bool) public lotteryWinnerDeclared;
    using SafeMath for uint256;

    constructor(
        address _routerAddres,
        address _tokenSafeMars,
        address _tokenBUSD
    ) PancakeClass(_routerAddres, _tokenSafeMars, _tokenBUSD) {
        admin = msg.sender;
    }
    function createContext(uint256 _prizeValue) public restricted {
       lotteryStructs[lotteryId] = new Lottery(_prizeValue, address(this), tokenBUSD);
       lotteryId++;
       emit LotteryCreated(lotteryId);
    }

    function declareWinner(uint256 _lotteryId) public restricted {
        require(!lotteryWinnerDeclared[_lotteryId], "Winner already declared");
        lotteryWinnerDeclared[_lotteryId] = true;
        address winner = lotteryStructs[_lotteryId].declareWinner();
        uint256 tokensGetInSafemars = convertBUSDToSafeMars(lotteryStructs[_lotteryId].getPrizeValue());
        IERC20(tokenSafeMars).transfer(winner, tokensGetInSafemars);
    }

    function viewWinner(uint256 _lotteryId) public view returns(address) {
        return lotteryStructs[_lotteryId].getWinner();
    }

    function participateInBusd(uint256 _lotteryId, uint256 amount) public {
        IERC20(tokenBUSD).transferFrom(msg.sender, address(this), amount);

        uint256 entryFee = amount.mul(4).div(100);
        lotteryStructs[_lotteryId].participate(entryFee, msg.sender);
        uint256 stakingAmount = amount.sub(entryFee);
        stakeInBUSD(stakingAmount, msg.sender);
    }

    function participateInSafemars(uint256 _lotteryId, uint256 amount) public nonReentrant {
        uint256 initBalance = IERC20(tokenSafeMars).balanceOf(address(this));
        IERC20(tokenSafeMars).transferFrom(msg.sender, address(this), amount);
        amount = IERC20(tokenSafeMars).balanceOf(address(this)).sub(initBalance);
        
        uint256 entryFee = amount.mul(4).div(100);
        uint256 tokensGetInBusd = convertSafeMarsToBUSD(entryFee);
        lotteryStructs[_lotteryId].participate(tokensGetInBusd, msg.sender);

        uint256 stakingAmount = amount.sub(entryFee);
        stakeInSafeMars(stakingAmount, msg.sender);
    }

    function exit(uint256 _lotteryId) public {
        require(lotteryWinnerDeclared[_lotteryId], "Winner not declared");
        unstakeAllToSafeMars(msg.sender);
    }

    modifier restricted() {
        require(msg.sender == admin);
        _;
    }

    event LotteryCreated(
        uint256 lotteryId
    );
}
