pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;

contract RegistryContract {
    enum ActorType{ FOUNDER, INITIAL_DEVELOPER, OTHER}
    
    struct Signature{
        uint8 v;
        bytes32 r; 
        bytes32 s;
    }
    
    // DDO type.
    struct DDO {
        address signAddress;
        //bytes pubKey;  or accountAddress
        string onboarder;
        string did;
        bytes signature;   //TODO make this Signature type. Then check whether auto parse a hexstring given as parameter
        //bool status;
        uint8 flag;  //default 38
    }

    mapping (string => uint256) reputations;   // reputations of experts

    mapping (string => DDO) founders; // DDOs of founders. Created in Genesis Transactions. RO (Read-only)
    mapping (string => DDO) initialDevelopers; // DDOs of initial developers. Created in Genesis Transactions. RO (Read-only)
    mapping (string => DDO) actors; // registered DDOs of other actors
    uint public numActors=0;
    
    //EVENTS
    event HashCalculated(bytes32 hashl);
    event SignCalculated(bool result);

    //CONSTRUCTOR
    constructor() internal{
        //create founder numDDOs
        //bytes memory pubf1 = "0x627306090abaB3A6e1400e9345bC60c78a8BEf57";
        address pubf1=0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
        //address pubf1=0x627306090abab3a6e1400e9345bc60c78a8bef57;
        founders["did.founder.1"] = DDO(pubf1, "genesis", "did.founder.1","0x00010203", 38);
        //founders["did.founder.2"] = DDO(hex"627306090abaB3A6e1400e9345bC60c78a8BEf57", "", "did.founder.2","0x00010203");
        founders["did.founder.2"] = DDO(0xf17f52151EbEF6C7334FAD080c5704D77216b732, "genesis", "did.founder.2","0x00010203",38);

        //initial DevelopersDDOs
        initialDevelopers["did.idev.1"] = DDO(0x627306090abaB3A6e1400e9345bC60c78a8BEf57, "did.founder.1", "did.idev.1", "0x00010203",38);
        initialDevelopers["did.idev.2"] = DDO(0x627306090abaB3A6e1400e9345bC60c78a8BEf57, "did.founder.1", "did.idev.2", "0x00010203",38);
        initialDevelopers["did.idev.3"] = DDO(0x627306090abaB3A6e1400e9345bC60c78a8BEf57, "did.founder.1", "did.idev.3", "0x00010203",38);
    }

    function onboardActor(address pubAdr, string memory onboarderDid, string memory did, bytes memory signature) public returns (bool result) {
        //check existance
        require(actors[did].flag != 38, "Already exists");
        
        // verify DDO_of_Actor 
        //check signature
        
        DDO memory obF = founders[onboarderDid];
        if (obF.flag != 38){ //check if found
            obF = actors[onboarderDid];  // onboarder may be another actor
            require(obF.flag == 38);
        }
        
        //calculate hash of   signAddress ||onboarder||did||signature;
        //abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        //bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n", uint2str(_msgHex.length), _msgHex);
        bytes memory data = abi.encode(pubAdr, onboarderDid, did); //paddingli encode yapar
        bytes32 hash = keccak256(data);
        emit HashCalculated(hash);
        bool sonuc = verify(obF.signAddress, hash, signature);
        
        emit SignCalculated(true);
        require(sonuc,"DDO's signature cannot be verified");
        //add to registry DDO_of_Actor
        actors[did] = DDO(pubAdr, onboarderDid, did, signature,38);
        reputations[did] = 0; //default reputation
        
        numActors++; // num of actors

        return sonuc;
    }

    function getDDO(string memory did) public view returns (ActorType t, DDO memory kimlik) {
        DDO memory found;
        if(founders[did].flag==38){
            return (ActorType.FOUNDER,founders[did]);
        }
        if(initialDevelopers[did].flag==38){
          return (ActorType.INITIAL_DEVELOPER, initialDevelopers[did]);
            //return actors[did];
        }
        if(actors[did].flag==38){
            found = actors[did];
            //return actors[did];
        }

        //require(actors[did].flag==38);//check if found
        return (ActorType.OTHER, found);
    }
    
    function checkAddress(string memory did, address adr) public view returns (bool) {
        ActorType t, DDO kimlik = getDDO(did);
        if(kimlik.flag==38){
            return (kimlik.signAddress == adr);
        }else{
            return false;   
        }
    }
    
    function isRegistered(string memory did) public view returns (bool) {
        if(founders[did].flag==38){
            return true;
        }
        if(initialDevelopers[did].flag==38){
          return true;
        }
        if(actors[did].flag==38){
            return true;
        }else{
            return false;
        }

    }
    

    function updateReputation(string memory did, uint value) public {
        //TODO add existance control
        reputations[did]= value;
    }
    
    function reportAbuse (string memory didMissbehave, string memory didReporter, uint pid) public{
        //verify claim
        //freeze DID
    }
    
    function() external payable {}

      /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
  
  function verify(address p, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns(bool) {
        
        // Note: this only verifies that signer is correct.
        // You'll also need to verify that the hash of the data is also correct.
        //convert toEthSignedMessageHash
        //bytes _msgHex
        //bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n", uint2str(_msgHex.length), _msgHex);
        //address signer = ecrecover(prefixedHash, v, r, s);
        
        //signature = signature.substr(2); //remove 0x
        //const r = '0x' + signature.slice(0, 64)
        //const s = '0x' + signature.slice(64, 128)
        //const v = '0x' + signature.slice(128, 130)
        //const v_decimal = web3.toDecimal(v)
        
        return ecrecover(hash, v, r, s) == p;  //compare with the address given
   }
    
    /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function verify(address p, bytes32 hash, bytes memory signature)
    internal
    pure
    returns (bool)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
        return false;
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
        //r := mload(add(signature, 0x20))   //load 32 bytes starting from 
        //s := mload(add(signature, 0x40))
        //v := byte(0, mload(add(signature, 0x60)))
        r := mload(add(signature, 0x21))   //load 32 bytes starting from 
        s := mload(add(signature, 0x41))
        v := byte(0, mload(add(signature, 0x20)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
        return false;
    } else {
      // solium-disable-next-line arg-overflow
      address adr = ecrecover(hash, v, r, s);
      return (ecrecover(hash, v, r, s) == p);
    }
  }
  
}

