pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;

//import "RegistryContract.sol";
import "./RegistryContract.sol"; //or include Interfaca in this file
import "./ProposalContract.sol";

contract VotingHandlerContract {
    
    enum ProposalType{ IMPROVEMENT, BUG, BUSINESS, OTHER}
    enum ProposalCategory{ CONSENSUSPROTOCOL, VM, P2P, CORE, GOVERNANCE, MINING, OTHER}
    enum ProposalStatus{ ACTIVE, REJECTED, WITHDRAWN, ACCEPTED}
    
    uint constant MIN_ELIGIBLE_BALANCE_TO_PROPOSE = 1 wei;
    
    //vote weights per roles
    uint constant WEIGHT_FOUNDER = 1;
    uint constant WEIGHT_INIT_DEV = 1;
    uint constant WEIGHT_USER = 1;
    uint constant WEIGHT_MINER = 1;
    uint constant WEIGHT_EXCHANGE_OWNER = 1;
    uint constant WEIGHT_EXCHANGE_USER = 1;

    //make sure that caller is authorized (proposr)
    modifier onlyItsPropoer(uint pid) {
      if (msg.sender == proposals[pid].signatureAddress) {
         _;
      }
    }
    
    struct Policy{
        uint256 id;
        string title;
        string description;
        string policyL;   // encoded as policy sytnax supported by the Platform
        uint date;
    }
    
    struct Proposal{
        uint256 id;
        string title;
        string proposerDID;
        Policy policyProposed;
        string discussionURL;
        ProposalType pType; 
        ProposalCategory pCategory;
        uint pDate;
        uint pExpireDate;
        string signature;  //signature cretaed by proposer for all fields above
        
        //belows are out of signing scope
        ProposalStatus pStatus;
        uint lockedStake; //locked stake
        address proposalContract;
    }
    
    event NewProposal(Proposal p, address pContract);
    
    mapping (uint => Proposal) public proposals; // all proposals proposed so far
    mapping (uint => address) proposalContracts; // all proposals contracts created so far
    uint public proposalCount=0;
    
    mapping (uint => Policy) public policies;    // active policy set being enforced
    
    RegistryContract registry;  //address of the RegistryContract
    
    constructor(address regContractAddr) internal{
        registry = regContractAddr;
    }
    
    //to propose a new policy 
    function proposeNew (Proposal memory prop) public payable{ 
        // verify DID of proposer
        require(registry.isRegistered(prop.proposerDID),"Proposer is not known by the Governance Framework");
        
        //verify signature of proposal
        address signer = registry.getDDO(prop.proposerDID).signAddress;
        require(msg.sender==signer);
        
        //verify signature ... not required in fact.
        
        // lock stake of proposer
        //require(address(signer).balance>= MIN_ELIGIBLE_BALANCE_TO_PROPOSEN);
        require(msg.value>= MIN_ELIGIBLE_BALANCE_TO_PROPOSE);
        
        //address(signer).transfer(this,MIN_ELIGIBLE_BALANCE_TO_PROPOSEN); //this amount should be higher than creating a proposal contract. Otherwise not deterrent
        prop.lockedStake = msg.value;
        
        
        // create a new proposal contract (proposal, this, regC) 
        ProposalContract pc = new ProposalContract(prop, address(this), registry)
        proposalContracts[proposalCount]= pc;

        prop.ProposalContract = address(pc);
        proposals[proposalCount]=prop;
        proposalCount++;
        // announce “a new voting started” 
        emit NewProposal(prop, address(pc));
        // start a new voting
    }
    
    //to propose removal of an existing policy 
    /*function proposeRemove (Proposal prop) public payable{ 
        // verify DID of proposer
        require(registry.isRegistered(prop.proposerDID),"Proposer is not known by the Governance Framework");
        
        //ensure that proposal var mi, policy field dolu olmayabilir
        
        
        //verify signature of proposal
        address signer = registry.getDDO(prop.proposerDID).signAddress;
        //verify signature
        
        // lock stake of proposer
        //require(address(signer).balance>= MIN_ELIGIBLE_BALANCE_TO_PROPOSEN);
        require(msg.value>= MIN_ELIGIBLE_BALANCE_TO_PROPOSEN);

        //address(signer).transfer(this,MIN_ELIGIBLE_BALANCE_TO_PROPOSEN); //this amount should be higher than creating a proposal contract. Otherwise not deterrent
        proposals[proposalCount]=Proposal;
        
        // create a new proposal contract (proposal, this, regC) 
        proposaCOntracs[proposalCount]=ProposalContract(address(this), prop);

        proposalCount++;
        // announce “a new voting started” 
        emit NewProposal(prop);
        // start a new voting
    }*/
    function withdrawProposal(string memory pDID, uint pid ) public onlyItsPropoer(pid){
        //require(proposals[pid].signAddress==msg.address);

        require(proposals[pid].proposerDID==pDID);
        //for simplicity, ethernet account address is used as did keys
        
        //release locked stake of proposer
        address(proposals[pid].signAddress).transfer(prop.lockedStake);
        
        //seal related proposal contract    
        proposalContracts[pid].call(bytes4(keccak256("seal")));
    }
    
    //called by Proposal Contract who is triggered by a timeSevice call this or manual call
    function finalizeProposal (uint pid, ProposalStatus result) public { //onlyItsPropoer(pid){

        require((proposalContracts[pid]==msg.sender), "Caller Proposal Contract is unknown");
        //do closing actions
        
        proposals[pd].pStatus = result;
        
        if (result == ProposalStatus.ACCEPTED){ 
            policies[pid] = proposal.policy;
             //trigger policy activation/deactivation 
        }
        
        // Unlock stake of proposer
        address(proposals[pid].signAddress).transfer(prop.lockedStake);
        
        //seal related proposal contract    
        proposalContracts[pid].call(bytes4(keccak256("freeze")));
        //or
        //bytes memory data = abi.encodeWithSignature("seal"); 
        //address(BAddr).call(data);
    }    
    
    
    // retrieve list of proposals
    function getAllProposals() public view returns (Proposal[] memory){
        Proposal[] memory ret = new Proposal[](proposalCount);
        for (uint i = 0; i < proposalCount; i++) {
            ret[i] = proposals[i];
        }
        return ret;
    }    
}
