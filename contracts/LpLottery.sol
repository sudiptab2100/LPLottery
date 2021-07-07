// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PancakeClass.sol";
import "./Lottery.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LpLottery is PancakeClass {
    address private admin;
    uint256 private lotteryId;
    mapping(uint256=>Lottery) private lotteryStructs;
    using SafeMath for uint256;

    constructor(
        address _routerAddres,
        address _tokenSafeMars,
        address _tokenBUSD
    ) PancakeClass(_routerAddres, _tokenSafeMars, _tokenBUSD) {
        admin=msg.sender;
    }
    function createContext(uint256 _prizeValue) public restricted{
       lotteryId++;
       lotteryStructs[lotteryId] = new Lottery(_prizeValue, address(this),tokenBUSD);
       emit LotteryCreated(lotteryId);
    }

    function declareWinner(uint256 _lotteryId) public restricted{
        lotteryStructs[_lotteryId].declareWinner();
    }

    function participateInBusd(uint256 _lotteryId,uint256 amount) public {
        uint256 entryFee=amount.mul(4).div(100);
        IERC20(tokenBUSD).transfer(address(this),entryFee);
        lotteryStructs[_lotteryId].participate(entryFee,msg.sender);
        uint256 stakingAmount=amount.sub(entryFee);
        stakeInBUSD(stakingAmount, msg.sender);
    }

    function participateInSafemars(uint256 _lotteryId,uint256 amount) public {
        uint256 entryFee=amount.mul(4).div(100);
        uint256 tokensGetInBusd = convertSafeMarsToBUSD(entryFee);
        IERC20(tokenBUSD).transfer(address(this),tokensGetInBusd);
        lotteryStructs[_lotteryId].participate(tokensGetInBusd,msg.sender);
        uint256 stakingAmount=amount.sub(entryFee);
        stakeInBUSD(stakingAmount, msg.sender);
    } 

    modifier restricted() {
        require(msg.sender == admin);
        _;
    }

    event LotteryCreated(
        uint256 lotteryId
    );
}
