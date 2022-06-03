/**
 *Submitted for verification at Arbiscan on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract CrowdFundingStorage {
    struct Campaign {
        address payable receiver;       
        uint numFunders;
        uint fundingGoal;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }


    mapping(uint => mapping(address => bool)) public isParticipate;
}


contract CrowdFunding is CrowdFundingStorage {

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(owner == msg.sender);
        _;
    }


    modifier judgeParticipate(uint _campaignID) {
        require(isParticipate[_campaignID][msg.sender] == false);
        _;
    }


    uint public numCampaigns;               
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;      

    function newCampaign(address payable _receiver, uint _goal) external isOwner returns(uint campaignID) {
        campaignID = numCampaigns++;
        Campaign storage campaign = campaigns[campaignID];
        campaign.receiver = _receiver;
        campaign.fundingGoal = _goal;
    }

    // 用户参与
    function bid(uint _campaignID) external payable judgeParticipate(_campaignID) {
        Campaign storage campaign = campaigns[_campaignID];

        campaign.totalAmount += msg.value;
        campaign.numFunders += 1;

        funders[_campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[_campaignID][msg.sender] = true;
    }


    function withdraw(uint _campaignID) external returns(bool reached) {
        Campaign storage campaign = campaigns[_campaignID];

        if (campaign.totalAmount < campaign.fundingGoal) {
            return false;
        }

        uint amount = campaign.totalAmount;
        campaign.totalAmount = 0;               
        campaign.receiver.transfer(amount);

        return true;
    }
}