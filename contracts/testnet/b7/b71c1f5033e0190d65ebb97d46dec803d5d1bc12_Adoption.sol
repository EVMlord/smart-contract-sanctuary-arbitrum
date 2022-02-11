/**
 *Submitted for verification at arbiscan.io on 2022-02-06
*/

pragma solidity ^0.7.0;

contract Adoption {


    event PetAdopted(uint returnValue);

	address[16] public adopters;

	// Adopting a pet
	function adopt(uint petId) public returns (uint) {
  		require(petId >= 0 && petId <= 15);

  		adopters[petId] = msg.sender;
        emit PetAdopted(petId);
  		return petId;
	}

	// Retrieving the adopters
	function getAdopters() public view returns (address[16] memory) {
  		return adopters;
	}
}