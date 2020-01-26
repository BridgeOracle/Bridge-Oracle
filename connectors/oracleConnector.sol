pragma solidity ^0.5.8;


contract Oracle {
    
    event Log1(address sender, string _datasource, string _arg);
    
    
    mapping (address => uint) internal reqc;
	
	function query(string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id) {
		//set gasLimit tron blockchain
	 	return query1(0, _datasource, _arg, 200000);
    }

    function query1(uint _timestamp, string memory _datasource, string memory _arg, uint _gaslimit) public payable returns(bytes32 _id) {
    	reqc[msg.sender]++;
	  	bytes32 customHash = keccak256('keyvan');
	  	emit Log1(msg.sender, _datasource, _arg);
	  	return customHash;
    }
}