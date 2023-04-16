pragma solidity ^0.5.1;

contract Proposal {
    
    enum DecisionType{ YES, NO, NOIDEA}
    enum CredentialType{ACCOUNTS_POSSESSION, ROL}
    
    //make sure that caller is a registered actor
    modifier registeredActor(string did) {
      bool registered = registryContract.call(bytes4(keccak256("isRegistered(string)")),did);
      if (registered) {
         _;
      }
    }

    modifier ownerOfDID(string did, address adr) {
        //msg.sender available ise adr parametresne gerek yok
      bool sonuc = registryContract.call(bytes4(keccak256("checkAddress(string,address)")),did, adr);
      if (registered) {
         _;
      }
    }
    
    modifier notSealed() {
      if (!sealed) {
         _;
      }
    }
    struct VerifiableCredential{
        CredentialType cType;
        bytes body; 
    }
    
    struct Vote{
        string voterDID;
        DecisionType vote; 
        uint vDate;
        VerifiableCredential [] credentials;

        string signature; // signature cretaed by proposer for all fields above
        bool valid;
        //fields derived
        ActorType rol;    // filled by this contract 
        uint eligibleBalance;
    }
    

    VotingHandlerContract handler;
    address votingHandlerContract;
    address registryContract;

    Proposal public prop;  //proposal details
    
    //Vote[] votes;  //accumulates votes submitted: (voter, vote, role, weight, accounts)
    mapping (string => Vote) votes // accumulates votes submitted: (voter, vote, role, weight, accounts)
    string[] public voters;
    
    struct Follow{
        string followedDID;
        string followerDID;
        VerifiableCredential [] credentials;
        DecisionType bacupVote;  //use this if followed wont vote
        address [] accountUsed;
        
        bool flag;
    }
    
    mapping(string => Follow[]) followOrders; 

    
    
    bool selaed = false; //voting in progress
    
    constructor(Proposal p, address vhc, address rc){
        votingHandlerContract = vhc;
        registryContract = rc;
        prop = p;
    }
    
    function vote(Vote v) public 
                    registeredActor(v.voterDID) 
                    ownerOfDID(v.voterDID,msg.sender)
                    notSealed{
        //ensure that the voter didn’t vote before? OR override vote
        //check Vote issued by actor herself
        //require(registry.isRegistered(v.voterDID), "Unknown voter");

        //address voter = registry.getDDO(v.voterDID).signAddress;
        //require(msg.sender==signer);
        bool sonuc = registryContract.call(bytes4(keccak256("checkAddress(string,address)")),v.voterDID, msg.sender);
        require(sonuc,"Illegal attempt");
     
        
        require(!votes[v.voterDID],"already voted");
        
        //verify VCs

        // verify delegation, if VCs include delegation credential(s)
        //calculate eligible balance of actor
        //IF VCs includes VC-Delegation THEN
            // ensure that the delegator didn’t vote before with the stake(s) specified
            // verify delegation credential(s)
            //(eligibleBalacevoter+ eligibleBalacedelegator)

        // store vote including eligible balance of both voter and [if any] delegator(s)
        // store Vote
        votes[v.voterDID] = vote; 
        voters.push[v.voterDID];
    }


    function follow (Follow f) public 
                        registeredActor(f.followerDID)
                        ownerOfDID(f.followerDID,msg.sender)
                        notSealed{
        
        //ensure that caller didn’t cast a vote before
        require(!votes[f.followerDID].flag,"Vote already casted. Follow is not possible");
        
        //remove other follow of the caller (if any)
        
        //confirm content of VCs and ensure that follower has possessions of accounts and verify role of the follower 
        //ensure that these accounts were not used in any other follow request
        
        //store data to evaluate during closing actions of ballot
        followsOrders[f.followedDID] = f; // if followed before, override new one
    }

    function unfollow (did, did2follow) public 
                                registeredActor(did)
                                ownerOfDID(did, msg.sender)
                                notSealed{
        //ensure that caller has a valid follow to be canceld
        require(followOrders[did2follow].flag);  //existing follow
        require(followOrders[did2follow].followerDID==did);
        //bool sonuc = registryContract.call(bytes4(keccak256("checkAddress(string,address)")),did, msg.sender);
        //require(sonuc,"Illegal attempt");
        
        //cancel this follow request
        followOrders[did2follow].flag=false; 
        delete followOrders[did]; //mapping icermeyeni silmek
    }


    function closeVoting ( ) public notSealed{
        //check closing conditions (time, participation)
        //take the follow requests into account
        for follow in Follows do
            // If follower voted OR any account specified in follow.VCs was already used with another vote then skip
            // Calculate voting contribution of the follower
            // Compute eligible balance of follower with accounts specified in follow.VCs
            // If followed expert voted then use it else use follower’s backup decision 
            //vote ← Votes[follow.did2follow]  OR follow.backupVote
            Votes.push(follow.did, follow.role, vote, balance, follow.VC.accounts)
            // Update reputation value of the followed actor 
            //registryContract.updateReputation(follow.did2follow, votingWeightofFollower)
        end for
        // count the votes (by weighting each vote with role, balance) in Votes and calculate decision of ballot
        ProposalStatus result;     
        // We know the length of the array
        uint arrayLength = voters.length;// total number of voters
        uint totalYes;
        uint totalNo;
        uint totalNoIdea;
        for (uint i=0; i<arrayLength; i++) {
            Vote v = votes[voters[i]];
            if(v.vote==DecisionType.YES){
                totalYes++;
            }
            if(v.vote==DecisionType.NO){
                totalNo++;
            }
            if(v.vote==DecisionType.NOIDEA){
                totalNoIdea++;
            }
        }
        
        if((totalYes>totalNo) && (totalYes>totalNoIdea)){
            result = ProposalStatus.ACCEPTED;
        }else if((totalNo>totalYes) && (totalNo>totalNoIdea)){
            result = ProposalStatus.REJECTED;     
        }else{
            //handle sub scenarios
            result = ProposalStatus.REJECTED;     
        }
        // trigger VotingContract and forward the result of ballot
        //votingContract.finalizeProposal(Proposal.id, result, Proposal.policy)
        votingHandlerContract.call(bytes4(keccak256("finalizeProposal(uint,ProposalStatus)",prop.id, result);
    }  
    
    function freeze() notSealed{
        //only VotingHandlerContract can freeze this contract
        require(msg.address==votingHandlerContract);
        sealed = true;
    }

    
}