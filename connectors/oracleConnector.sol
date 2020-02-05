pragma solidity ^0.5.8;


contract Oracle {
    
    event Log1(address sender, bytes32 cid, uint timestamp, string _datasource, string _arg, uint gaslimit, byte proofType, uint gasPrice);
    event Log2(address sender, bytes32 cid, uint timestamp, string _datasource, string _arg1, string _arg2, uint gaslimit, byte proofType, uint gasPrice);
    
    mapping(address => byte) internal addr_proofType;
    mapping(address => uint) internal addr_gasPrice;

    mapping(address => uint) internal reqc;
    
    uint public basePrice;
    uint256 public maxBandWidthPrice;

    address private owner;

    constructor() internal {
    	owner = msg.sender;
    }


    modifier onlyAdmin() {
    	require(owner == msg.sender);
    	_;
    }

    function setMaxBandWidthPrice(uint256 new_maxBandWidthPrice) external onlyAdmin {
        maxBandWidthPrice = new_maxBandWidthPrice
    }

    function setBasePrice(uint new_baseprice) external onlyAdmin {
        basePrice = new_baseprice;
    }

    function setBasePrice(uint new_baseprice, bytes calldata proofID) external onlyAdmin {
        basePrice = new_baseprice;
    }

    function getPrice(string memory _datasource) public returns(uint _dsPrice) {
        return getPrice(_datasource, msg.sender);
    }

    function getPrice(string memory _datasource, uint _gasLimit) public returns(uint _dsprice) {
        return getPrice(_datasource, _gasLimit, msg.sender);
    }

    function getPrice(string memory _datasource, address _addr) private returns(uint _dsprice) {
        return getPrice(_datasource, 200000, _addr);
    }

    function getPrice(string memory _datasource, uint _feeLimit, address _addr) private returns(uint _dsprice) {
        
    }

    function costs(string memory datasource, uint gaslimit) private returns(uint price) {
        price = getPrice(datasource, gaslimit, msg.sender);
    }

    function setProofType(byte _proofType) external {
    	addr_proofType[msg.sender] = _proofType;
    }

    function setCustomGasPrice(uint _gasPrice) external {
    	addr_gasPrice[msg.sender] = _gasPrice;
    }

	function withdrawFunds(address _addr) external onlyAdmin {
		_addr.send(this.balance);
	}

	function query(string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id) {
		//set gasLimit tron blockchain
	 	return query1(0, _datasource, _arg, 200000);
    }

    function query(uint _timestamp, string calldata _datasource, string calldata _arg) payable external returns(bytes32 _id) {
    	return query1(_timestamp, _datasource, _arg, 200000);
    }

    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gaslimit) external payable returns(bytes32 _id) {
    	return query1(_timestamp, _datasource, _arg, _gaslimit);
    }

    function query2(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2) external payable returns(bytes32 _id) {
    	return query2(_timestamp, _datasource, _arg1, _arg2, 200000);
    }

    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns(bytes32 _id) {
    	return query2(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
    }

    function query1(uint _timestamp, string memory _datasource, string memory _arg, uint _gaslimit) public payable returns(bytes32 _id) {
        costs(_datasource, _gaslimit);
        bytes memory cl = bytes(abi.encodePacked(msg.sender));
        bytes memory co = bytes(abi.encodePacked(this));
        bytes memory n = toBytes(reqc[msg.sender]);
        bytes memory concat = abi.encodePacked(co, cl, n);
        _id = sha256(concat);
    	reqc[msg.sender]++;
	  	emit Log1(msg.sender, _id, _timestamp, _datasource, _arg, _gaslimit, addr_proofType[msg.sender], addr_gasPrice[msg.sender]);
	  	return _id;
    }

    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gaslimit) public payable returns(bytes32 _id) {
    	costs(_datasource, _gaslimit);
        bytes memory cl = bytes(abi.encodePacked(msg.sender));
        bytes memory co = bytes(abi.encodePacked(this));
        bytes memory n = toBytes(reqc[msg.sender]);
        bytes memory concat = abi.encodePacked(co, cl, n);
        _id = sha256(concat);
        reqc[msg.sender]++;
	  	emit Log2(msg.sender, _id, _timestamp, _datasource, _arg1, _arg2, _gaslimit, addr_proofType[msg.sender], addr_gasPrice[msg.sender]);
	  	return _id;
    }

    function toBytes(uint256 x) public returns (bytes memory b) {
        b = new bytes(32);
        assembly {
        mstore(add(b, 32), x) 
    }
}



}