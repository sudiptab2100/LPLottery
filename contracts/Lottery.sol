// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery {
    using SafeMath for uint256;

    uint256 private prizeValue;
    address private manager;
    uint256 private entriesRequired;
    uint256 private currentTicketId;
    bool private isActive;
    address private tokenBUSD;
    mapping(uint256 => address) allParticipants;

    constructor(uint256 _prizeValue, address _manager, address _tokenBUSD) {
        prizeValue = _prizeValue;
        entriesRequired = _prizeValue;
        manager = _manager;
        isActive=true;
        tokenBUSD=_tokenBUSD;
    }

    function participate(uint256 _amount, address _particpant) public {
        require(entriesRequired != 0, "context is full");
        require(isActive == true, "context is not active anymore");

        uint256 _tickets = _amount.div(10**18);
        require(
            entriesRequired >= _tickets,
            "entree fee should be smaller than entries required"
        );
        for (uint256 i = currentTicketId; i < _tickets; i++) {
            allParticipants[i] = _particpant;
            currentTicketId++;
        }
        entriesRequired = entriesRequired.sub(_tickets);
        emit PlayerParticipated(_particpant);
    }

    function declareWinner() public restricted returns(address){
        require(isActive,"Context is not active anymore");
        isActive=false;
        uint256 winnerTicketNo = random().mod(prizeValue);
        return allParticipants[winnerTicketNo];
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        prizeValue
                    )
                )
            );
    }

    function getPrizeValue() public view returns(uint256) {
        return prizeValue;
    }
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    event PlayerParticipated(
        address playerAddress
    );
}
