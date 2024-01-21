// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract CrowdFunding {

    mapping (address => bool) public isRegistered;
    mapping (address => uint) public isReclaimable;
    mapping (address => uint[]) public fundsInvolvedIn;
    mapping (uint => address[]) public fundToFunders;
    FundData[] public ongoingFunds;
    FundersData[] public fundersData;


    struct FundData{
        uint fundId;
        uint fundAmount;
        uint depositedFund;
        uint totalFunders;
        address requestingWallet;
        string fundReason;
        uint fundTime;
    }

    struct FundersData{
        uint totalRequestsFunded;
        uint totalAmountSpent;
        address funderAddress;
    }

    modifier onlyBeneficiary (uint _fundId) {
        require(msg.sender == ongoingFunds[_fundId].requestingWallet, "Sender not beneficiary");
        _;
    }

    function register() public {
        isRegistered[msg.sender] = true;
    }

    function postRequest(uint _fundAmount, address _requestingWallet, string memory _fundReason, uint _fundTime) public {
        require(isRegistered[msg.sender], "Please Register First");
        uint requestId = ongoingFunds.length;
        ongoingFunds.push(FundData(requestId, _fundAmount, 0, 0, _requestingWallet, _fundReason, _fundTime ));
    }

    function contribute(uint _fundId) public payable {
        require(ongoingFunds[_fundId].fundTime <= block.timestamp, "Fundraising Period is past");
        require(ongoingFunds[_fundId].depositedFund <= ongoingFunds[_fundId].fundAmount, "Fund Anount Reached" );
        if(msg.value <= ongoingFunds[_fundId].fundAmount){
            ongoingFunds[_fundId].depositedFund = ongoingFunds[_fundId].depositedFund + msg.value;
        }
        isReclaimable[msg.sender] = msg.value;
        fundsInvolvedIn[msg.sender].push(_fundId);
        fundToFunders[_fundId].push(msg.sender);
    }

    function withdraw(uint _fundId) public payable onlyBeneficiary(_fundId) {
        require(ongoingFunds[_fundId].fundTime > block.timestamp, "Wait till fund is completed");
        address payable _address = payable(ongoingFunds[_fundId].requestingWallet);
        _address.transfer(ongoingFunds[_fundId].depositedFund);
        ongoingFunds[_fundId].depositedFund = 0;
    }

    function getrefund(uint _fundId, address payable _address) public payable {
        require(ongoingFunds[_fundId].fundTime > block.timestamp, "Wait till fund is completed");
       //checks if user deposits in particular fund
        address currentAddress = address(0);
        for(uint i = 0; i < fundToFunders[_fundId].length; i++){            
            if(fundToFunders[_fundId][i] == _address){
                currentAddress = _address;
            } 
        }
        require(currentAddress == _address, "Address did not participate in this Fund");
        _address = payable(msg.sender);
        uint refundable = isReclaimable[_address];
        require(refundable > 0, "No amount to refund");
        _address.transfer(refundable);
    }

    function getReward(address _address) public payable {
        uint amountSpent;
        for(uint i = 0; i < fundersData.length; i++){            
            if(fundersData[i].funderAddress == _address){
                amountSpent = fundersData[i].totalAmountSpent;
            }
        }
        require(amountSpent >= 1 ether);
        payable(_address).transfer(2**15);
        //Continue by making sure user dont claim reward repeatedly.
    }

    function getFundInfo(uint _fundId) public view returns (FundData memory) {
        return ongoingFunds[_fundId];
    }

    function destroy(address _address) public {
        selfdestruct(payable(_address));
    }
}