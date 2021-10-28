// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ICrowdfunding.sol";
import "../interfaces/IERC20TokenHandler.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/Calculations.sol";

//Declare the base logic for ICO contract
abstract contract CrowdfundingBase is ICrowdfunding {
    using SafeMath for uint256;

    CrowdfundingStatus internal status;
    address payable private owner;
    address internal tokenAddress;

    modifier onlyOwner() {
        require(msg.sender == owner, "Access Denied");
        _;
    }

    modifier canPay(address _sender, uint256 _amount) {
        require(_sender != address(0), "Cannot use Zero address");
        require(_sender.balance > _amount, "Insufficient balance");
        _;
    }

    event TransferEthereum(address _from, uint256 _value);
    event TransferToken(address _to, uint256 _value, address _tokenAddress);

    constructor(address _tokenAddress) {
        //On Deploy the ICO is NOT Started
        status = CrowdfundingStatus.NotStarted;
        owner = payable(_getSender()); //setting the owner of the ICO
        tokenAddress = _tokenAddress;
    }

    //TODO:
    function buy()
        public
        payable
        virtual
        override
        canPay(msg.sender, msg.value)
        returns (bool)
    {
        uint256 tokensToBeSend = _getTokenAmount(msg.value);

        require(tokensToBeSend > 0, "Not Enought EHT amount for 1 token");

        emit TransferEthereum(msg.sender, msg.value);

        owner.transfer(msg.value); // transfering the amount to token address

        //transafer token to sender address

        IERC20TokenHandler tokenHandler = _getERC20TokenHandler(tokenAddress);

        //tokenHandler.transfer(msg.sender, msg.value);

        emit TransferToken(msg.sender, msg.value, owner);

        return true;
    }

    function _getTokenAmount(uint256 ethAmount)
        internal
        view
        virtual
        returns (uint256 tokenAmount)
    {
        IERC20TokenHandler tokenHandler = _getERC20TokenHandler(tokenAddress);

        return
            Calculations.calculatetTokenAmount(
                ethAmount,
                tokenHandler.getDecimals(),
                _getRate(ethAmount)
            );
    }

    function getStatus() public virtual override returns (CrowdfundingStatus) {
        return status;
    }

    function _getSender() internal view returns (address) {
        return msg.sender;
    }

    //Implement the required IERC20TokenHandler
    function _getERC20TokenHandler(address _tokenAddress)
        internal
        view
        virtual
        returns (IERC20TokenHandler);

    //Implement logic for calculating the rate for exchanging ETH to Token
    function _getRate(uint256 ethAmount)
        internal
        view
        virtual
        returns (uint256 tokenAmount);
}
