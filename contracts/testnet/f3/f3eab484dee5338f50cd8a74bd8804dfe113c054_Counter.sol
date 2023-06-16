/**
 *Submitted for verification at Arbiscan on 2023-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Counter {
    uint public count = 0;
    
    function increment() public returns(uint) {
        count += 1;
        return count;
    }

    function addInteger(uint intToAdd) public returns(uint) {
        count += intToAdd;
        return count;
    }

    function reset() public returns(uint) {
        count = 0;
        return count;
    }
}