// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;


contract CrowdFunding{
    mapping (address=> uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint public minimumContribution;
    uint public deadline ; //timestamp
    uint public goal;
    uint public raisedAmount;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters; //voters status by default are false until each votes
    }

    
    uint public numRequests;

    mapping(uint=> Request) public requests;

    constructor(uint _goal, uint _deadline){
        goal= _goal;
        deadline= block.timestamp + _deadline;
        minimumContribution= 100 wei;
        admin= msg.sender; //account that deploys the contract
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);


    function contribute () public payable{
        // require(numRequests>0, "No request at the moment");
       require(block.timestamp<deadline, "Deadline has passed");
       require(msg.value>=minimumContribution, "Minimum contribution is 100 wei");
       if(contributors[msg.sender]==0){ //This is when user is sending eth for the first time
            noOfContributors++; //increase number of contributors
       }
       contributors[msg.sender]+= msg.value;
       raisedAmount += msg.value;

       emit ContributeEvent(msg.sender, msg.value);
    }

    receive() payable  external{
        contribute(); 
    }

    //function that returns the contract balance in wei
    function getBalance() public view returns(uint){
        return address(this).balance; //This gives the balance in the current contract
    }

    function getRefund() public payable{
        require(block.timestamp>deadline && raisedAmount<goal, "You can only get a refund when campaigne ends and goal is not reached"); //if deadline has passed and goal is not reached
        require(contributors[msg.sender] > 0, "Unauthorized to get a refund");
        
        address payable recipient=payable(msg.sender);
        uint refundAmount = contributors[msg.sender];
        
        recipient.transfer(refundAmount); //withdraw value of fund contributed
        
        raisedAmount-= refundAmount;
        contributors[msg.sender]=0;

    }

    modifier onlyAdmin(){
        require(msg.sender==admin, "Only Admin can call this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public  onlyAdmin{
        require(raisedAmount>0, "Balance is 0");
        require(_value<=raisedAmount, "You cannot request more than the raised amount");
        Request storage newRequest= requests[numRequests];
        numRequests++;

    newRequest.description= _description;
    newRequest.recipient=_recipient;
    newRequest.value= _value;
    newRequest.completed=false;
    newRequest.noOfVoters=0;

    emit CreateRequestEvent(_description, _recipient, _value);
    }


    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0, "You must be a contributor to vote");
        Request storage thisRequest= requests[_requestNo];

        require(thisRequest.voters[msg.sender]== false, "You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount>=goal);
        Request storage thisRequest= requests[_requestNo];
        require(thisRequest.completed == false, "The request has been completed");
        require(thisRequest.noOfVoters> noOfContributors /2, "Majority of voters did not vote for this request"); //50% of contributors voted for this request
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed= true;
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}

