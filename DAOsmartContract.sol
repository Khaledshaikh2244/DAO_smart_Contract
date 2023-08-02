// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract DAOworld{
    struct Proposal {
            uint id;
            string description;
            uint amount;
            address payable recipient;
            uint votes;
            uint end;
            bool isExecuted;
            
    }

    mapping(address=>bool) private isInvestor;
    mapping(address=>uint)public numbOfshares;
    mapping(address=>mapping(uint=>bool))public isVoted;
    mapping (address=>mapping(address=>bool)) public withdrawlStatus;
    address[] public investorList;
    mapping(uint=>Proposal) public proposals;

    uint public totalShares;
    uint public availableFunds;
    uint public contributionTimeEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public manager;
     

     constructor (uint _contributionTimeEnd,  uint _voteTime,uint _quorum) {
         require(_quorum >0 && _quorum<100,"Not valid values ");
         contributionTimeEnd=block.timestamp+_contributionTimeEnd;
         voteTime=_voteTime;
         quorum=_quorum;
         manager=msg.sender;
          
     }
        modifier onlyInvestor() {
            require(isInvestor[msg.sender]==true,"YOu are not an Investor ");
            _;
        }

        
        modifier onlyManager() {
            require(manager==msg.sender,"YOu are not an manager ");
            _;
        }

        function contribution() public payable {
            require(contributionTimeEnd>=block.timestamp, "contribution Time ended !");//contributionTimeEnd+2hr
            require(msg.value>0,"send more than 0 Ether");
            isInvestor[msg.sender]=true;//above 2 condtion  is satisfied
            numbOfshares[msg.sender]=numbOfshares[msg.sender]+msg.value;
            totalShares+=msg.value;//totalShares=totalShares+msg,value
            availableFunds+=msg.value;
            investorList.push(msg.sender);
            
        }

        function reedemShare(uint amount) public onlyInvestor(){
            require(numbOfshares[msg.sender]>amount,"you dont have enough Shares !");
            require(availableFunds>=amount,"Not enough funds");
            numbOfshares[msg.sender]-=amount;
            if(numbOfshares[msg.sender]==0){
                isInvestor[msg.sender]=false;
            }
            availableFunds-=amount;
            payable (msg.sender).transfer(amount);//transfering of Ethers
             
        }

        function transferShares(uint amount ,address to ) public onlyInvestor(){
            require(availableFunds>=amount,"Not enough Funds !");
            require(numbOfshares[msg.sender]>=amount,"you dont have enough shares");
            numbOfshares[msg.sender]-=amount;
            if(numbOfshares[msg.sender]==0){
                isInvestor[msg.sender]=false;

            }
            numbOfshares[to]+=amount;  
            isInvestor[to]=true;
            investorList.push(to);

        }


        function createProposal(string calldata description , uint amount,address payable
         recipient) public {
            require(availableFunds>= amount,"Not enough funds");
            proposals[nextProposalId]=Proposal(nextProposalId,description,amount,
            recipient,0,block.timestamp+voteTime,false);
            nextProposalId++;
        }
        

        function votePrposal(uint proposalId) public onlyInvestor(){
            Proposal storage proposal = proposals[proposalId];
            require (isVoted[msg.sender][proposalId]==false,"you have already voted for this proposal !");
            require(proposal.end>=block.timestamp,"Voting Time ended");
            require(proposal.isExecuted==false,"it is really executed");
            isVoted[msg.sender][proposalId]=true;
            proposal.votes+=numbOfshares[msg.sender];//
        }

        function executedPropsal(uint proposalId) public onlyManager (){
            Proposal storage proposal=proposals[proposalId];
            require(((proposal.votes*100)/totalShares)>=quorum,"Majority does not support");
            proposal.isExecuted=true;
            availableFunds-=proposal.amount;
            _transfer(proposal.amount,proposal.recipient);

        }

        function _transfer(uint amount, address payable recipient)public{
            recipient.transfer(amount);
        }

        function ProposalList() public view  returns (Proposal[] memory ){
            Proposal[] memory arr = new Proposal[](nextProposalId-1);// am Empty Array of length=nextProposalId-1
            for (uint i=0; i<nextProposalId;i++) {
                arr[i-1]=proposals[i];
            }
            return arr;
        }
        
}