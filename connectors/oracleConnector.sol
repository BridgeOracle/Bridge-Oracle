pragma solidity ^0.5.8;


contract Oracle {
    
    event Log1(address sender, string _datasource, string _arg);
    
    
    mapping (address => uint) internal reqc;
	
	 function query(string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id) {
	  reqc[msg.sender]++;
	  bytes32 customHash = keccak256('keyvan');
	  emit Log1(msg.sender, _datasource, _arg);
	  return customHash;
    }
    
}